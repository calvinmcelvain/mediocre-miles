# built-in.
import os
import time
import json
import logging
from typing import Dict, Any, Optional, List
from pathlib import Path

# third-party.
import stravalib
from stravalib import Client
import pandas as pd
from flask import current_app, session
from datetime import datetime, timedelta

# local.
from src.mediocremiles.utils import load_config, load_envs, create_directory


log = logging.getLogger(__name__)


CONFIGS: Dict[str, Any] = load_config()



class StravaClient:
    """
    Handles Strava API interactions for accessing athlete data and activities.
    """
    def __init__(self):
        load_envs(CONFIGS["paths"]["env"])
        
        self.client_id = int(os.environ.get(CONFIGS["env"]["client_id"]))
        self.client_secret = os.environ.get(CONFIGS["env"]["client_secret"])
        
        self.data_dir = Path(CONFIGS.get("paths", {}).get("data_dir", "data"))
        create_directory(self.data_dir)
        
        self.client = Client()
        self._initiate_and_authorize()
    
    def _initiate_and_authorize(self) -> Optional[Client]:
        """
        Initiates Strava API client and checks to see if authorization code is 
        already stored in env vars. If not, prompts to authorize.
        """
        auth_code = os.environ.get(CONFIGS["env"]["code"])
        
        if not auth_code:
            url = self.client.authorization_url(
                client_id=self.client_id,
                redirect_uri=CONFIGS["routes"]["auth"],
                scope=['read_all', 'activity:read_all']
            )
            
            auth_code = input(
                f"Follow the following link: {url}\n"
                "Code:"
            )
            os.environ[CONFIGS["env"]["code"]] = auth_code
            
        try:
            access_token = self.client.exchange_code_for_token(
                client_id=self.client_id,
                client_secret=self.client_secret,
                code=str(auth_code)
            )
            
            self.client.access_token = access_token["access_token"]
            self._save_token_to_file(access_token)
            
            return self.client
        except Exception as e:
            if current_app:
                current_app.logger.error(f"Authorization failed: {str(e)}")
            else:
                log.error(f"Authorization failed: {str(e)}")
            return None
    
    def check_refresh(self) -> bool:
        """
        Check if token needs refresh and refresh if needed.
        """
        if 'refresh_token' in session and 'expires_at' in session:
            if session['expires_at'] < time.time():
                return self.refresh_token() is not None
            else:
                self.client.access_token = session['access_token']
                return True
                
        token_data = self._load_token_from_file()
        if token_data:
            if token_data['expires_at'] < time.time():
                token_response = self.refresh_token(token_data['refresh_token'])
                return (token_response is not None)
            else:
                session['access_token'] = token_data['access_token']
                session['refresh_token'] = token_data['refresh_token']
                session['expires_at'] = token_data['expires_at']
                self.client.access_token = token_data['access_token']
                return True
        
        return False
        
    def refresh_token(self, refresh_token=None) -> Optional[dict]:
        """
        Refresh the access token.
        """
        if not refresh_token and 'refresh_token' in session:
            refresh_token = session['refresh_token']
            
        if not refresh_token:
            return None
            
        try:
            token_response = self.client.refresh_access_token(
                client_id=current_app.config['STRAVA_CLIENT_ID'],
                client_secret=current_app.config['STRAVA_CLIENT_SECRET'],
                refresh_token=refresh_token
            )
            
            session['access_token'] = token_response['access_token']
            session['refresh_token'] = token_response['refresh_token']
            session['expires_at'] = token_response['expires_at']
            
            self._save_token_to_file(token_response)
            self.client.access_token = token_response['access_token']
            
            return token_response
        except Exception as e:
            if current_app:
                current_app.logger.error(f"Error refreshing token: {str(e)}")
            else:
                log.error(f"Error refreshing token: {str(e)}")
            return None
    
    def _save_token_to_file(self, token_data: dict) -> None:
        """
        Save token to file.
        """ 
        token_file = Path(self.data_dir / CONFIGS.get("paths", {}).get("token"))
        with token_file.open("w") as f:
            json.dump(token_data, f)
    
    def _load_token_from_file(self) -> Optional[dict]:
        """
        Load token from file.
        """
        token_file = Path(self.data_dir / CONFIGS.get("paths", {}).get("token"))
        if token_file.exists():
            with token_file.open() as f:
                return json.load(f)
        return None
    
    def get_athlete(self):
        """
        Get authenticated athlete information.
        """
        if not self.is_authenticated(): return None
        return self.client.get_athlete()
    
    def get_athlete_stats(self):
        """
        Get athlete statistics.
        """
        if not self.is_authenticated(): return None
            
        athlete = self.get_athlete()
        if athlete: return self.client.get_athlete_stats(athlete.id)
        return None
    
    def get_activities(
        self, limit: int = 30, after: datetime = None, before: datetime = None
    ) -> List[stravalib.model.SummaryActivity]:
        """
        Get athlete activities.
        """
        if not self.is_authenticated(): return []
            
        if not after: after = datetime.now() - timedelta(days=30)
            
        return list(self.client.get_activities(limit=limit, after=after, before=before))
    
    def get_activity(self, activity_id: int) -> stravalib.model.DetailedActivity:
        """
        Get detailed activity data.
        """
        if not self.is_authenticated(): return None
        return self.client.get_activity(activity_id)
    
    def is_authenticated(self):
        """
        Check if the client is authenticated.
        """
        return self.check_refresh()

    def save_run_activities_to_csv(self) -> None:
        """
        Fetches all run activities from Strava and saves them to a CSV file.
        """
        activities = self.get_activities(limit=100)
        run_activities = [
            {
                "id": activity.id,
                "name": activity.name,
                "distance": activity.distance.num,
                "moving_time": activity.moving_time.total_seconds(),
                "elapsed_time": activity.elapsed_time.total_seconds(),
                "start_date": activity.start_date.isoformat(),
                "type": activity.type,
                "average_speed": getattr(activity, "average_speed"),
                "total_elevation_gain": getattr(activity, "total_elevation_gain"),
                "average_heartrate": getattr(activity, "average_heartrate"),
                "max_heartrate": getattr(activity, "max_heartrate"),
            }
            for activity in activities if activity.type == "Run"
        ]

        if not run_activities:
            if current_app:
                current_app.logger.info("No run activities found.")
            else:
                log.info("No run activities found.")
            return None

        data_path = self.data_dir
        df = pd.DataFrame(run_activities)
        df.to_csv(data_path, index=False)
        
        print(f"Run activities saved to {data_path}.")
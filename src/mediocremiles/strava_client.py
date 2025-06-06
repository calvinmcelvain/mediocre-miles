"""
Contains the StravaClient model.
"""
import logging
import time
import json
from os import environ
from typing import Optional, List, Dict, Any, Union
from pathlib import Path

from stravalib import Client
from stravalib.util.limiter import DefaultRateLimiter
from stravalib.model import DetailedActivity, SummaryActivity, AthleteStats
from stravalib.strava_model import Zones
from datetime import datetime

from src.mediocremiles.models.activity import ActivityModel
from utils import load_config, load_envs


log = logging.getLogger("app.strava_client")


CONFIGS = load_config()
ENV_VARS: Dict[str, str] = CONFIGS["env"]
PATHS: Dict[str, Any] = CONFIGS["paths"]
ROUTES: Dict[str, Any] = CONFIGS["routes"]



class StravaClient:
    """
    Handles Strava API interactions for accessing athlete data and activities.
    """
    def __init__(self):
        # Loading env. vars.
        load_envs(PATHS.get("env"))
        
        self.client_id = int(environ.get(ENV_VARS.get("client_id")))
        self.client_secret = environ.get(ENV_VARS.get("client_secret"))
        
        host = ROUTES.get("host")
        port = ROUTES.get("port")
        self.redirect = f"https://{host}:{port}"
        
        self.token_file = Path(PATHS.get("token")).resolve()
        
        self.client = Client(rate_limiter=DefaultRateLimiter("medium"))
        self._initiate_and_authorize()
    
    def _initiate_and_authorize(self) -> Optional[Client]:
        """
        Initiates Strava API client and checks to see if authorization code is 
        already stored in env vars. If not, prompts to authorize.
        """
        if not self.check_refresh():
            url = self.client.authorization_url(
                client_id=self.client_id,
                redirect_uri=self.redirect,
                scope=['read_all', 'activity:read_all', 'profile:read_all']
            )
            
            auth_code = input(
                f"Follow the following link: {url}\n"
                "Code:"
            ).strip()
            
            try:
                access_token = self.client.exchange_code_for_token(
                    client_id=self.client_id,
                    client_secret=self.client_secret,
                    code=str(auth_code)
                )
                self._save_token_to_file(access_token)
            except Exception as e:
                log.error(f"Authorization failed: {str(e)}")
                raise 
        
        access_token = self._load_token_from_file()
        self.client.access_token = access_token["access_token"]
        self.client.refresh_token = access_token["refresh_token"]
        self.client.token_expires = access_token["expires_at"]
        return None
    
    def check_refresh(self) -> bool:
        """
        Check if token needs refresh and refresh if needed.
        """
        token_data = self._load_token_from_file()
        if token_data:
            if token_data['expires_at'] < time.time():
                token_response = self.refresh_token(token_data['refresh_token'])
                return (token_response is not None)
            else:
                self.client.access_token = token_data['access_token']
                self.client.refresh_token = token_data["refresh_token"]
                self.client.token_expires = token_data["expires_at"]
                return True

        return False
    
    def exchange_code_for_token(self, code: str) -> None:
        """
        Exchange authorization code for access token.
        """
        token_response = self.client.exchange_code_for_token(
            client_id=self.client_id,
            client_secret=self.client_secret,
            code=code
        )
        self._save_token_to_file(token_response)
        return None
        
    def refresh_token(self, refresh_token: str = None) -> Optional[dict]:
        """
        Refresh the access token.
        """
        token_file = self._load_token_from_file()
        if not refresh_token and 'refresh_token' in token_file.keys():
            refresh_token = token_file['refresh_token']
            
        if not refresh_token:
            return None
            
        try:
            token_response = self.client.refresh_access_token(
                client_id=self.client_id,
                client_secret=self.client_secret,
                refresh_token=refresh_token
            )
            
            self._save_token_to_file(token_response)
            self.client.access_token = token_response['access_token']
            self.client.refresh_token = token_response['refresh_token']
            self.client.token_expires = token_response["expires_at"]
            
            return token_response
        except Exception as e:
            log.error(f"Error refreshing token: {str(e)}")
            raise
    
    def _save_token_to_file(self, token_data: dict) -> None:
        """
        Save token to file.
        """ 
        with self.token_file.open("w") as f:
            json.dump(token_data, f)
        
        log.info(f"Token data saved to: {self.token_file.as_posix()}")
        return None
    
    def _load_token_from_file(self) -> Dict[str, str]:
        """
        Load token from file.
        """
        if self.token_file.exists():
            with self.token_file.open() as f:
                return json.load(f)
        log.info(f"Token file loaded from: {self.token_file.as_posix()}")
        return None
    
    def get_athlete_stats(self) -> AthleteStats:
        """
        Get athlete statistics.
        """
        if not self.is_authenticated(): return None
            
        return self.client.get_athlete_stats()
    
    def get_athlete_zones(self) -> Zones:
        """
        Get athlete zones.
        """
        if not self.is_authenticated(): return None
        
        return self.client.get_athlete_zones()
    
    def get_activities(
        self,
        limit: Optional[int] = None,
        after: Optional[datetime] = None,
        before: Optional[datetime] = None
    ) -> List[Union[SummaryActivity, ActivityModel]]:
        """
        Get athlete activities.
        """
        if not self.is_authenticated(): return []
        
        # Restricted to 100 requests every 15min & 2000 daily.
        activities = None
        while not activities:
            try:
                activities = self.client.get_activities(
                    limit=limit, after=after, before=before)
            except Exception as e:
                log.exception(f"Exception in getting activities: {str(e)}")
                return None
        return list(activities)
    
    def get_detailed_activity(
        self, activity: Union[SummaryActivity, ActivityModel]
    ) -> List[DetailedActivity]:
        """
        Gets detailed activity data with robust rate limit handling.
        """
        if not self.is_authenticated(): return None

        detailed_activity = None
        while not detailed_activity:
            try:
                detailed_activity = self.client.get_activity(activity.id)
            except Exception as e:
                log.exception(f"Got exception: {str(e)}")
                return None
        return detailed_activity
    
    def is_authenticated(self) -> bool:
        """
        Check if the client is authenticated.
        """
        if self.check_refresh():
            return True
        
        try:
            self.refresh_token()
            return True
        except Exception as e:
            log.error(f"Authentication error: {e}")
            raise
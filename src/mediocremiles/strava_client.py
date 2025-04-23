"""
Contains the StravaClient model.
"""
# built-in.
import os
import time
import json
import logging
from typing import Optional, List, Dict
from pathlib import Path

# third-party.
from stravalib import Client
from stravalib.exc import AccessUnauthorized, RateLimitExceeded, RateLimitTimeout
from stravalib.model import DetailedActivity, SummaryActivity, AthleteStats
from datetime import datetime

# local.
from src.mediocremiles.utils import load_config, load_envs, create_directories


log = logging.getLogger(__name__)


CONFIGS = load_config()



class StravaClient:
    """
    Handles Strava API interactions for accessing athlete data and activities.
    """
    def __init__(self):
        load_envs(CONFIGS["paths"]["env"])
        
        self.client_id = int(os.environ.get(CONFIGS["env"]["client_id"]))
        self.client_secret = os.environ.get(CONFIGS["env"]["client_secret"])
        
        host = CONFIGS["routes"]["host"]
        port = CONFIGS["routes"]["port"]
        self.redirect = f"https://{host}:{port}"
        
        self.token_file = Path(CONFIGS.get("paths").get("token")).resolve()
        
        create_directories(Path("data").resolve())
        
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
                redirect_uri=self.redirect,
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
            self.client.refresh_token = access_token["refresh_token"]
            self.client.token_expires = access_token["expires_at"]
            self._save_token_to_file(access_token)
            
            return self.client
        except Exception as e:
            log.exception(f"Authorization failed: {str(e)}")
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
            log.exception(f"Error refreshing token: {str(e)}")
            return None
    
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
    
    def get_athlete(self):
        """
        Get authenticated athlete information.
        """
        if not self.is_authenticated(): return None
        return self.client.get_athlete()
    
    def get_athlete_stats(self) -> AthleteStats:
        """
        Get athlete statistics.
        """
        if not self.is_authenticated(): return None
            
        athlete = self.get_athlete()
        if athlete: return self.client.get_athlete_stats(athlete.id)
        return None
    
    def get_activities(
        self,
        limit: Optional[int] = None,
        after: Optional[datetime] = None,
        before: Optional[datetime] = None
    ) -> List[SummaryActivity]:
        """
        Get athlete activities.
        """
        if not self.is_authenticated(): return []
        
        # Restricted to 100 requests every 15min & 2000 daily.
        activities = None
        retried = False
        while not activities:
            try:
                activities = self.client.get_activities(
                    limit=limit, after=after, before=before)
                retried = False
            except (RateLimitTimeout, RateLimitExceeded):
                if retried:
                    log.exception(
                        "Strava API rate day limit exceeded. Try again tomorrow."
                    )
                    return None
                log.exception("Strava API rate limit exceeded. Retrying...")
                retried = True
        
        return list(activities)
    
    def get_detailed_activities(
        self, activities: List[SummaryActivity]
    ) -> List[DetailedActivity]:
        """
        Gets detailed activity data.
        """
        if not self.is_authenticated(): return None
        
        # rate limit is 100 requests per 15min & 2000 per day.
        detailed_activities = []
        retried = False
        for activity in activities:
            detailed_activity = None
            while not detailed_activity:
                try:
                    detailed_activity = self.client.get_activity(activity.id)
                    detailed_activities.append(detailed_activity)
                    retried = False
                except (RateLimitTimeout, RateLimitExceeded):
                    # If still rate limit exception, it means day rate limit 
                    # reached.
                    if retried:
                        log.exception(
                            "Strava API rate day limit exceeded. Try again tomorrow."
                        )
                        adjusted_activities = activities[len(detailed_activities):]
                        return detailed_activities + adjusted_activities
                    log.exception("Strava API rate limit exceeded. Retrying...")
                    retried = True
                except Exception as e:
                    log.exception(f"Got exception: {str(e)}")
                    adjusted_activities = activities[len(detailed_activities):]
                    return detailed_activities + adjusted_activities
        return detailed_activities
    
    def is_authenticated(self) -> bool:
        """
        Check if the client is authenticated.
        """
        if self.check_refresh():
            return True
        
        try:
            self.refresh_if_needed()
            self.client.get_athlete()
            return True
        except AccessUnauthorized:
            log.exception(f"Strava client could not be authenticated")
            return False
        except Exception as e:
            log.exception(f"Authentication error: {e}")
            return False
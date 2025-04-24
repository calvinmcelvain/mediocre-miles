"""
Contains the StravaClient model.
"""
# built-in.
import time
import json
from tqdm import tqdm
from os import environ
from typing import Optional, List, Dict, Any
from pathlib import Path

# third-party.
from stravalib import Client
from stravalib.exc import AccessUnauthorized, RateLimitExceeded, RateLimitTimeout
from stravalib.model import DetailedActivity, SummaryActivity, AthleteStats
from stravalib.strava_model import Zones
from datetime import datetime

# local.
from src.mediocremiles.utils import load_config, load_envs


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
        
        self.client = Client()
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
                print(f"Authorization failed: {str(e)}")
                return None
        
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
            print(f"Error refreshing token: {str(e)}")
            return None
    
    def _save_token_to_file(self, token_data: dict) -> None:
        """
        Save token to file.
        """ 
        with self.token_file.open("w") as f:
            json.dump(token_data, f)
        
        print(f"Token data saved to: {self.token_file.as_posix()}")
        return None
    
    def _load_token_from_file(self) -> Dict[str, str]:
        """
        Load token from file.
        """
        if self.token_file.exists():
            with self.token_file.open() as f:
                return json.load(f)
        print(f"Token file loaded from: {self.token_file.as_posix()}")
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
                    print(
                        "Strava API rate day limit exceeded. Try again tomorrow."
                    )
                    return None
                print("Strava API rate limit exceeded. Retrying...")
                retried = True
        return list(activities)
    
    def get_detailed_activities(
        self, activities: List[SummaryActivity]
    ) -> List[DetailedActivity]:
        """
        Gets detailed activity data with robust rate limit handling.
        """
        if not self.is_authenticated(): return None

        # rate limit is 100 requests per 15min & 2000 per day.
        detailed_activities = []
        retry_count = 0
        max_retries = 3
        base_wait_time = 60
        
        pbar = tqdm(
            activities,
            desc="Fetching detailed activities",
            unit="activity",
            ncols=80
        )
        
        for activity in pbar:
            detailed_activity = None
            current_retry = 0
            
            while not detailed_activity and current_retry <= max_retries:
                try:
                    detailed_activity = self.client.get_activity(activity.id)
                    if detailed_activity:
                        detailed_activities.append(detailed_activity)
                        retry_count = 0
                        
                except (RateLimitTimeout, RateLimitExceeded) as e:
                    retry_count += 1
                    current_retry += 1
                    
                    # Calculate wait time with exponential backoff.
                    # For first rate limit: 15 minutes (900 seconds).
                    # For subsequent ones: longer.
                    wait_time = 900 + base_wait_time * (2 ** (current_retry - 1))
                    
                    print(
                        f"Rate limit exceeded ({str(e)}). Waiting for"
                        f" {wait_time/60:.1f} minutes..."
                    )
                    
                    pbar.set_description(f"Rate limited, waiting {wait_time/60:.1f}m")
                    time.sleep(wait_time)
                    
                    pbar.set_description("Fetching detailed activities")
                    
                    if current_retry >= max_retries:
                        print(
                            f"Max retries ({max_retries}) reached after rate"
                            " limiting. Returning partial results."
                        )
                        adjusted_activities = activities[len(detailed_activities):]
                        return detailed_activities + adjusted_activities
                        
                except Exception as e:
                    print(f"Got exception: {str(e)}")
                    
                    # Check specifically for HTTP 429 error.
                    if "429" in str(e) and "Too Many Requests" in str(e):
                        print(
                            "Detected 429 Too Many Requests error."
                            " Waiting for 15 minutes..."
                        )
                        pbar.set_description("Rate limited, waiting 15m")
                        time.sleep(900)
                        pbar.set_description("Fetching detailed activities")
                        continue
                    
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
            self.refresh_token()
            return True
        except AccessUnauthorized:
            print(f"Strava client could not be authenticated")
            return False
        except Exception as e:
            print(f"Authentication error: {e}")
            return False
# built-in.
import os
from typing import Dict, Any

# third-party.
from stravalib import Client
import pandas as pd  # Add this import for handling CSV operations

# local.
from src.mediocremiles.utils import load_config, load_envs


CONFIGS: Dict[str, Any] = load_config()



class StravaClient:
    def __init__(self):
        load_envs(CONFIGS["paths"]["env"])
        
        self.client_id = int(os.environ.get(CONFIGS["env"]["client_id"]))
        self.client_secret = os.environ.get(CONFIGS["env"]["client_secret"])
        
        # Initializing client.
        self.client = self._initiate_and_authorize()
    
    def _initiate_and_authorize(self) -> Client:
        """
        Initiated Strava API client and checks to see if authorization code is 
        already stored in env vars. If not, prompted to authorize.
        """
        strava_client = Client()
        
        auth_code = os.environ.get(CONFIGS["env"]["code"])
        
        if not auth_code:
            # Getting auth url.
            url = strava_client.authorization_url(
                client_id=self.client_id,
                redirect_uri=CONFIGS["routes"]["auth"],
                scope=['read_all', 'activity:read_all']
            )
            
            auth_code = input(
                f"Follow the following link: {url}\n"
                "Code:"
            )
            os.environ[CONFIGS["env"]["code"]] = auth_code
            
            
        access_token = strava_client.exchange_code_for_token(
            client_id=self.client_id,
            client_secret=self.client_secret,
            code=str(auth_code)
        )
        strava_client.access_token = access_token["access_token"]
        return strava_client

    def save_run_activities_to_csv(self) -> None:
        """
        Fetches all run activities from Strava and saves them to a CSV file.
        """
        activities = self.client.get_activities()
        run_activities = [
            {
                "id": activity.id,
                "name": activity.name,
                "distance": activity.distance.num,
                "moving_time": activity.moving_time.total_seconds(),
                "elapsed_time": activity.elapsed_time.total_seconds(),
                "start_date": activity.start_date.isoformat(),
                "type": activity.type,
            }
            for activity in activities if activity.type == "Run"
        ]

        if not run_activities:
            print("No run activities found.")
            return

        data_path = CONFIGS["paths"]["data"]
        df = pd.DataFrame(run_activities)
        df.to_csv(data_path, index=False)
        print(f"Run activities saved to {data_path}.")

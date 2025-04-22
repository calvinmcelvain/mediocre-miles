# built-in.
import logging
import argparse
from typing import Optional, List
from datetime import datetime, timedelta

# local.
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.processors.data_processor import ActivityProcessor
from src.mediocremiles.utils import get_date_n_days_ago, load_config


log = logging.getLogger(__name__)


CONFIG = load_config()




def authenticate_client() -> StravaClient:
    """
    Handle authentication with Strava.
    """
    client = StravaClient()
    
    if not client.is_authenticated():
        auth_url = client.get_authorization_url()
        log.info(
            f"Please authorize the application by visiting: {auth_url}\n"
            "After authorization, you'll be redirected to your redirect URI.\n"
            "Copy the 'code' parameter from the URL and paste it below:"
        )
        
        code = input("Enter the authorization code: ").strip()
        client.exchange_code_for_token(code)
        
        if not client.is_authenticated(): return None
    
    return client


def fetch_activities(
    client: StravaClient, after_date: Optional[datetime] = None
) -> List[ActivityModel]:
    """
    Fetch activities from Strava API after the specified date (if applicable).
    """
    if after_date: log.info(f"Fetching activities after {after_date}...")
    
    strava_activities = client.get_activities(after=after_date)
    activities = [ActivityModel.from_strava_activity(a) for a in strava_activities]
    
    if activities:
        log.info(f"Fetched {len(activities)} activities from Strava API")
    else:
        log.info("No new activities found.")
    
    return activities


def main():
    parser = argparse.ArgumentParser(description='Strava Activity CSV Exporter')
    parser.add_argument('--days', type=int, default=None, 
                       help='Number of days to fetch (overrides latest activity in CSV)')
    parser.add_argument('--all', action='store_true', 
                       help='Fetch all activities (overrides --days)')
    parser.add_argument('--detailed', action='store_true', 
                       help='Fetches the detailed activity data for each activity fetched.')
    args = parser.parse_args()
    
    client = authenticate_client()
    if not client: return
    
    after_date = None
    
    if args.all: 
        log.info("Fetching all activities...")
    elif args.days is not None:
        after_date = get_date_n_days_ago(args.days)
        log.info(f"Fetching activities from the last {args.days} days...")
    else:
        latest_date = ActivityProcessor().get_latest_activity_date()
        
        if latest_date:
            # avoids timezone issues.
            after_date = latest_date - timedelta(hours=1)
            log.info(f"Fetching activities newer than {latest_date}...")
        else:
            after_date = get_date_n_days_ago(30)
            log.info(
                "No existing CSV found. Fetching activities from the last 30 days..."
            )
    
    activities = fetch_activities(client, after_date)
    
    if not activities:
        log.info("No activities to export.")
        return
    
    ActivityProcessor().update_activities_csv(activities)
    
    if args.detailed: client.get_detailed_activities(activities)
    
    ActivityProcessor().update_activities_csv(activities)
    
    log.info(
        f"All activities have been saved to: {ActivityProcessor().data_path.as_posix()}"
    )


if __name__ == "__main__":
    main()
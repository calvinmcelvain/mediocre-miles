# built-in.
import logging
import argparse
from typing import Optional, List, Literal
from datetime import datetime, timedelta

# local.
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.processors.activity_processor import ActivityProcessor
from src.mediocremiles.processors.athlete_processor import AthleteProcessor
from src.mediocremiles.utils import get_date_n_days_ago, load_config


log = logging.getLogger(__name__)


CONFIG = load_config()


WorkoutType = Literal["run", "ride"]


def fetch_activities(
    client: StravaClient, 
    after_date: Optional[datetime] = None, 
    detailed: bool = False,
    activity_type: Optional[WorkoutType] = None
) -> List[ActivityModel]:
    """
    Fetch activities from Strava API after the specified date (if applicable).
    Get detailed activity data if requested.
    Filter by activity_type if specified.
    """
    if after_date: log.info(f"Fetching activities after {after_date}...")
    if activity_type: log.info(f"Filtering activities to type: {activity_type}")
    
    summary_activities = client.get_activities(after=after_date)
    
    if not summary_activities:
        log.info("No new activities found.")
        return []
    
    if activity_type:
        filtered_activities = list(filter(
            lambda a: a.type.root.lower() == activity_type.lower(),
            summary_activities
        ))
        
        log.info(f"Filtered to {len(filtered_activities)} {activity_type} activities")
        summary_activities = filtered_activities
    
    if not summary_activities:
        log.info(f"No {activity_type} activities found after filtering.")
        return []
    
    if detailed:
        log.info(f"Fetching detailed data for {len(summary_activities)} activities...")
        detailed_activities = client.get_detailed_activities(summary_activities)
        activities = [ActivityModel.from_strava_activity(a) for a in detailed_activities]
    else:
        activities = [ActivityModel.from_strava_activity(a) for a in summary_activities]
    
    log.info(f"Fetched {len(activities)} activities from Strava API")
    return activities


def main():
    parser = argparse.ArgumentParser(description='Strava Activity CSV Exporter')
    parser.add_argument('--days', type=int, default=None, 
                       help='Number of days to fetch (overrides latest activity in CSV)')
    parser.add_argument('--all', action='store_true', 
                       help='Fetch all activities (overrides --days)')
    parser.add_argument('--detailed', action='store_true', 
                       help='Fetches the detailed activity data for each activity fetched.')
    parser.add_argument('--zones', action='store_true',
                       help='Export athlete zones to CSV')
    parser.add_argument('--athlete-stats', action='store_true',
                       help='Export athlete statistics to JSON')
    parser.add_argument('--type', type=str, choices=list(WorkoutType.__args__),
                       help='Filter activities by type (run or ride)')
    args = parser.parse_args()
    
    client = StravaClient()
    
    if not client: return None
    
    if args.zones: AthleteProcessor().export_athlete_zones(client)
    
    if args.athlete_stats: AthleteProcessor().export_athlete_stats(client)
    
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
            log.info("Fetching activities from the last 30 days...")
    
    activities = fetch_activities(
        client, 
        after_date, 
        args.detailed, 
        args.type
    )
    
    if not activities:
        log.info("No activities to export.")
        return
    
    ActivityProcessor().update_activities_csv(activities)


if __name__ == "__main__":
    main()
# built-in.
import argparse
from tqdm import tqdm
from typing import Optional, List, Literal
from datetime import datetime, timedelta

# local.
import src.mediocremiles.errors as exe
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.processors.activity_processor import ActivityProcessor
from src.mediocremiles.processors.athlete_processor import AthleteProcessor
from src.mediocremiles.utils import get_date_n_days_ago, load_config



CONFIG = load_config()


WorkoutType = Literal["run", "ride"]


def fetch_activities(
    client: StravaClient, 
    after_date: Optional[datetime] = None,
    before_date: Optional[datetime] = None,
    detailed: bool = False,
    activity_type: Optional[WorkoutType] = None
) -> List[ActivityModel]:
    """
    Fetch activities from Strava API after and/or before specified dates (if 
    applicable).
    Get detailed activity data if requested.
    Filter by activity_type if specified.
    """
    processor = ActivityProcessor()
    
    summary_activities = client.get_activities(
        after=after_date, before=before_date)
    
    if not summary_activities:
        print("No new activities found.")
        return None
    
    print(f"Fetched {len(summary_activities)} summary activities from Strava API")
    
    if activity_type:
        print(f"Filtering activities to type: {activity_type}")
        
        filtered_activities = list(filter(
            lambda a: a.type.root.lower() == activity_type.lower(),
            summary_activities
        ))
        
        print(f"Filtered to {len(filtered_activities)} {activity_type} activities")
        summary_activities = filtered_activities
    
    if not summary_activities:
        print(f"No {activity_type} activities found after filtering.")
        return None
    
    activities = [ActivityModel.from_strava_activity(a) for a in summary_activities]
    process = processor.update_new_activities_csv(activities)
    
    assert not isinstance(process, exe.CSVUpdateError)
    
    if detailed:
        print(f"Fetching detailed data for {len(summary_activities)} activities...")
        
        pbar = tqdm(
            summary_activities,
            desc="Fetching detailed activities",
            unit="activity",
            ncols=120
        )
        
        for activity in pbar:
            detailed_activity = client.get_detailed_activity(activity)
            
            if detailed_activity: 
                activity_model = ActivityModel.from_strava_activity(detailed_activity)
                process = processor.update_csv_detailed_activity(activity_model)
                assert not isinstance(process, exe.CSVUpdateError)
            else:
                last_activity_idx = summary_activities.index(activity) - 1
                last_activity = summary_activities[last_activity_idx]
                print(
                    "Error occured. Couldn't fetch all detailed activities."
                    f" Last detailed activity fetched: {last_activity.model_dump()}"
                )
    return None


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
    parser.add_argument('--before', type=str,
                       help='Fetch activities before this date (YYYY-MM-DD format)')
    args = parser.parse_args()
    
    client = StravaClient()
    
    if not client: return None
    
    if args.zones: AthleteProcessor().export_athlete_zones(client)
    
    if args.athlete_stats: AthleteProcessor().export_athlete_stats(client)
    
    after_date = None
    before_date = None
    
    if args.before:
        try:
            before_date = datetime.strptime(args.before, '%Y-%m-%d')
            print(f"Fetching activities before {before_date.isoformat()}.")
        except ValueError:
            print("Error: --before date must be in YYYY-MM-DD format")
            return
    
    if args.all: 
        print("Fetching all activities...")
    elif args.days is not None:
        after_date = get_date_n_days_ago(args.days)
        print(f"Fetching activities from the last {args.days} days...")
    else:
        latest_date = ActivityProcessor().get_latest_activity_date()
        
        if latest_date:
            # avoids timezone issues.
            after_date = latest_date - timedelta(hours=1)
            print(f"Fetching activities newer than {latest_date}...")
        else:
            after_date = get_date_n_days_ago(30)
            print("Fetching activities from the last 30 days...")
    
    fetch_activities(
        client, 
        after_date,
        before_date,
        args.detailed, 
        args.type
    )


if __name__ == "__main__":
    main()
import logging
import argparse
from tqdm import tqdm
from datetime import datetime

from logger import LoggerManager
from src.mediocremiles.models.athlete_data import AthleteData
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.data_processor import DataProcessor
from utils import get_date_n_days_ago, load_config, load_json_n_validate



CONFIG = load_config()


def assrt_complete_process(callback: str) -> None:
    assert callback == "complete", (
        f"Processing activities failed. Got: {callback}"
    )
    return None


def main():
    log_manager = LoggerManager()
    log_manager.clear_logs()
    
    log = logging.getLogger("app")
    
    processor = DataProcessor()
    
    parser = argparse.ArgumentParser(description='Strava Activity CSV Exporter')
    parser.add_argument('--days', type=int, default=None, 
                       help='Number of days to fetch (overrides latest activity in JSON)')
    parser.add_argument('--all', action='store_true', 
                       help='Fetch all activities (overrides --days)')
    parser.add_argument('--detailed', action='store_true', 
                       help='Fetches the detailed activity data for each activity fetched.')
    parser.add_argument('--zones', action='store_true',
                       help='Get athlete HR and Power Zones')
    parser.add_argument('--athlete-stats', action='store_true',
                       help='Get athlete stats')
    parser.add_argument('--before', type=str,
                       help='Fetch activities before this date (YYYY-MM-DD format)')
    args = parser.parse_args()
    
    client = StravaClient()
    
    if not client: return 
    
    after_date = before_date = None
    
    if args.before:
        try:
            before_date = datetime.strptime(args.before, '%Y-%m-%d')
            log.info(f"Fetching activities before {before_date.isoformat()}.")
        except ValueError:
            log.error("Error: --before date must be in YYYY-MM-DD format")
            return
    
    if args.all: 
        log.info("Fetching all activities...")
    elif args.days is not None:
        after_date = get_date_n_days_ago(args.days)
        log.info(f"Fetching activities from the last {args.days} days...")
    
    summary_activities = None
    if any((args.all, args.days, args.before)):
        summary_activities = client.get_activities(
            after=after_date, before=before_date)
    
        if summary_activities is None:
            log.info("No new activities found.")
            return 
        
        log.info(
            f"Fetched {len(summary_activities)} summary activities from Strava API"
        )
        
        assrt_complete_process(processor.update_activities(summary_activities))
    
    if args.athlete_stats:
        log.info("Fetching athlete stats...")
        stats = client.get_athlete_stats()
        assrt_complete_process(processor.update_stats(stats))
    
    if args.zones:
        log.info("Fetching athlete zones...")
        zones = client.get_athlete_zones()
        assrt_complete_process(processor.update_zones(zones))
    
    if args.detailed:
        if summary_activities: log.info(
            f"Fetching detailed data for {len(summary_activities)} activities...")
        else:
            try:
                data = load_json_n_validate(CONFIG["paths"]["data"], AthleteData)
                summary_activities = list(data.activities.values())
            except Exception as e:
                log.info("No data to get detailed data from.")
                return
        
        pbar = tqdm(
            summary_activities,
            desc="Fetching detailed activities",
            unit="activity",
            ncols=120
        )
        
        for activity in pbar:
            detailed_activity = client.get_detailed_activity(activity)
            
            if detailed_activity: 
                assrt_complete_process(processor.update_activities(detailed_activity))
            else:
                last_activity_idx = summary_activities.index(activity) - 1
                last_activity = summary_activities[last_activity_idx]
                log.error(
                    "Error occured. Couldn't fetch all detailed activities."
                    f" Last detailed activity fetched: {last_activity.id}"
                )


if __name__ == "__main__":
    main()
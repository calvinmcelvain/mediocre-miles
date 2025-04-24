"""
Contains the ActivityProcessor model.
"""
# built-in.
import copy
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Dict

# third-party.
import pandas as pd
from stravalib import unit_helper
from src.mediocremiles.utils import load_config
from src.mediocremiles.models.activity import ActivityModel


CONFIGS = load_config()
DATA_PATHS: Dict[str, str] = CONFIGS["paths"]["data"]



class ActivityProcessor:
    """
    Just a wrapper for activity data processing.
    """
    activity_data_file = Path(DATA_PATHS.get("activity_data")).resolve()
    
    def get_latest_activity_date(self) -> Optional[datetime]:
        """
        Get the date of the most recent activity in the CSV file.
        """
        try:
            df = pd.read_csv(self.activity_data_file)
            if df.empty or 'start_date' not in df.columns:
                return None
            df['start_date'] = pd.to_datetime(df['start_date'])
            return df['start_date'].max().to_pydatetime()
        except (FileNotFoundError, Exception):
            print("No existing CSV found.")
            return None
    
    @staticmethod
    def _dump_activities(activities: List[ActivityModel]):
        """
        Converts activies to dict.
        if splits is specified, also creates new attributes fot those.
        """
        new_activities = []
        for a in activities:
            dumped = a.model_dump()
            splits = False
            if hasattr(a, 'splits_standard'):
                miles = 0
                split_tottime = dumped["start_date"]
                splits = True
                for split in a.splits_standard:
                    distance = unit_helper.miles(split.distance).magnitude
                    split_tottime += timedelta(seconds=split.moving_time)
                    miles += distance
                    dumped['total_split_distance'] = miles
                    dumped['split_cumtime'] = split_tottime.isoformat()
                    dumped['split_time'] = split.moving_time / 60
                    dumped['split_avghr'] = split.average_heartrate
                    dumped['split_distance'] = distance
                    dumped['split_pace'] = unit_helper.miles_per_hour(split.average_speed).magnitude
                    dumped['split_elevation'] = unit_helper.feet(split.elevation_difference).magnitude
                    dumped_copy = copy.deepcopy(dumped)
                    del dumped_copy["splits_standard"]
                    new_activities.append(dumped_copy)
            if not splits: new_activities.append(dumped)
        return new_activities
    
    def update_activities_csv(self, new_activities: List[ActivityModel]) -> None:
        """
        Update CSV with new activities, avoiding duplicates.
        """
        try:
            new_df = pd.DataFrame(self._dump_activities(new_activities))
            
            try:
                existing_df = pd.read_csv(self.activity_data_file)
                combined_df = pd.concat([existing_df, new_df], ignore_index=True)
                combined_df = combined_df.drop_duplicates(subset=['id', 'split_cumtime'], keep='last')
            except FileNotFoundError:
                combined_df = new_df
            
            if 'start_date' in combined_df.columns:
                combined_df['start_date'] = pd.to_datetime(combined_df['start_date'])
                combined_df = combined_df.sort_values('start_date', ascending=False)
            
            combined_df.to_csv(self.activity_data_file, index=False)
            print(f"Updated CSV with {len(new_df)} rows")
            print(
                "All activities have been saved to:"
                f" {self.activity_data_file.as_posix()}"
            )
            
        except Exception as e:
            print(f"Error updating CSV: {e}")
            return new_activities

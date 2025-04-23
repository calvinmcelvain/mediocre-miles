"""
Contains the ActivityProcessor model.
"""

# built-in.
from datetime import datetime
from pathlib import Path
from typing import List, Optional

# third-party.
import pandas as pd
from src.mediocremiles.utils import load_config
from src.mediocremiles.models.activity import ActivityModel


CONFIGS = load_config()



class ActivityProcessor:
    """
    Just a wrapper for activity data processing.
    """
    activity_data_file = Path(CONFIGS.get("paths").get("data")).resolve()

    def export_activities_to_csv(self, activities: List[ActivityModel]) -> None:
        """
        Export activities to CSV file.
        """
        activities_data = [activity.to_dict() for activity in activities]
        df = pd.DataFrame(activities_data)
        df.to_csv(self.activity_data_file, index=False)
        print(f"Exported {len(activities)} activities to {self.activity_data_file}")
    
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
            return None
    
    def update_activities_csv(self, new_activities: List[ActivityModel]) -> None:
        """
        Update CSV with new activities, avoiding duplicates.
        """
        try:
            new_df = pd.DataFrame([activity.to_dict() for activity in new_activities])
            
            try:
                existing_df = pd.read_csv(self.activity_data_file)
                combined_df = pd.concat([existing_df, new_df], ignore_index=True)
                combined_df = combined_df.drop_duplicates(subset=['id'], keep='last')
            except FileNotFoundError:
                combined_df = new_df
            
            if 'start_date' in combined_df.columns:
                combined_df['start_date'] = pd.to_datetime(combined_df['start_date'])
                combined_df = combined_df.sort_values('start_date', ascending=False)
            
            combined_df.to_csv(self.activity_data_file, index=False)
            print(f"Updated CSV with {len(new_df)} activities")
            
        except Exception as e:
            print(f"Error updating CSV: {e}")

"""
Contains the ActivityProcessor model.
"""
# built-in.
import copy
import pytz
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Dict

# third-party.
import pandas as pd

# local.
from src.mediocremiles.utils import load_config, convert_distance, convert_speed
from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.weather import Weather
import src.mediocremiles.errors as exe


log = logging.getLogger(__name__)


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
            return df['start_date'].max()
        except (FileNotFoundError, Exception):
            log.debug("No existing CSV found.")
            return None
    
    @staticmethod
    def _dump_activities(activities: List[ActivityModel]):
        """
        Converts activies to dict.
        if splits is specified, also creates new attributes fot those.
        """
        new_activities = []
        for a in activities:
            # Adjusting for timezone.
            tz = a.timezone.split(') ')[1] if a.timezone else 'UTC'
            a.start_date = a.start_date.astimezone(pytz.timezone(tz))
            
            dumped = a.model_dump()
            splits = False
            if a.splits_standard:
                miles = 0
                split_tottime = dumped["start_date"]
                splits = True
                for split in a.splits_standard:
                    distance = convert_distance(split.distance, "mi")
                    split_tottime += timedelta(seconds=split.moving_time)
                    miles += distance
                    dumped['split_cuml_distance'] = miles
                    dumped['split_cuml_time'] = split_tottime
                    dumped['split_time'] = split.moving_time / 60
                    dumped['split_avghr'] = split.average_heartrate
                    dumped['split_distance'] = distance
                    dumped['split_pace'] = convert_speed(split.average_speed, "mi")
                    dumped['split_elevation'] = convert_distance(split.elevation_difference, "ft")
                    dumped_copy = copy.deepcopy(dumped)
                    del dumped_copy["splits_standard"]
                    new_activities.append(dumped_copy)
            if not splits:
                del dumped["splits_standard"]
                new_activities.append(dumped)
        return new_activities
    
    def update_new_activities_csv(self, new_activities: List[ActivityModel]) -> None:
        """
        Update CSV with new activities, avoiding duplicates.
        """
        try:
            new_df = pd.DataFrame(self._dump_activities(new_activities))
            
            # Adding weather.
            client = Weather()
            for idx, row in new_df.iterrows():
                lat = row["start_lat"]
                lon = row["start_lon"]
                date = pd.to_datetime(row["start_date"]).replace(tzinfo=None)
                if lat and lon:
                    weather_df = client.get_hourly_conditions(lat, lon, date)
                    if weather_df.empty: continue
                    
                    new_df.loc[idx, "temp_c"] = weather_df.iloc[0]["temp"]
                    new_df.loc[idx, "temp_f"] = weather_df.iloc[0]["temp_f"]
                    new_df.loc[idx, "dew_point_c"] = weather_df.iloc[0]["dwpt"]
                    new_df.loc[idx, "dew_point_f"] = weather_df.iloc[0]["dwpt_f"]
                    new_df.loc[idx, "humidity"] = weather_df.iloc[0]["rhum"]
                    new_df.loc[idx, "pressure"] = weather_df.iloc[0]["pres"]
                    new_df.loc[idx, "wind_direction"] = weather_df.iloc[0]["wdir"]
                    new_df.loc[idx, "wind_speed_kpm"] = weather_df.iloc[0]["wspd"]
                    new_df.loc[idx, "wind_speed_mph"] = weather_df.iloc[0]["wspd_mph"]
                    new_df.loc[idx, "snow_mm"] = weather_df.iloc[0]["snow"]
                    new_df.loc[idx, "snow_inch"] = weather_df.iloc[0]["snow_inch"]
                    new_df.loc[idx, "precipitation_mm"] = weather_df.iloc[0]["prcp"]
                    new_df.loc[idx, "precipitation_inch"] = weather_df.iloc[0]["prcp_inch"]
                    new_df.loc[idx, "conditions"] = weather_df.iloc[0]["conditions"]
                
            try:
                existing_df = pd.read_csv(self.activity_data_file)
                combined_df = pd.concat([existing_df, new_df], ignore_index=True)
                
                # If existing detailed activities, need additional condition for 
                # dropping duplicates.
                try:
                    combined_df = combined_df.drop_duplicates(
                        subset=['id', 'split_cuml_time'], keep='last')
                except Exception:
                    combined_df = combined_df.drop_duplicates(subset=['id'], keep='last')
            except FileNotFoundError:
                combined_df = new_df
            
            combined_df['start_date'] = pd.to_datetime(combined_df['start_date'])
            combined_df = combined_df.sort_values('start_date', ascending=False)
            
            combined_df.to_csv(self.activity_data_file, index=False)
            
            log.info(f"Updated CSV with {len(new_df)} activities.")
            log.info(
                "All activities have been saved to:"
                f" {self.activity_data_file.as_posix()}"
            )
            return None
        except Exception as e:
            log.exception(f"Error updating CSV: {e}")
            return exe.CSVUpdateError

    def update_csv_detailed_activity(self, detailed_activity: ActivityModel) -> None:
        """
        Update CSV with a detailed activity.
        """
        try:
            new_df = pd.DataFrame(self._dump_activities([detailed_activity]))
            
            existing_df = pd.read_csv(self.activity_data_file)
            
            # removing the summary activities from og df
            detailed_ids = new_df["id"].unique().tolist()
            existing_df = existing_df[~(existing_df["id"].isin(detailed_ids))]
            
            combined_df = pd.concat([existing_df, new_df], ignore_index=True)
            
            # Sort on date and cummulative split time.
            combined_df['start_date'] = pd.to_datetime(combined_df['start_date'])
            combined_df['split_cuml_time'] = pd.to_datetime(combined_df['split_cuml_time'])
            combined_df = combined_df.sort_values(['start_date', 'split_cuml_time'], ascending=False)
            
            combined_df.to_csv(self.activity_data_file, index=False)
            # no logs since iteration.
            return None
        except Exception as e:
            log.exception(f"Error updating CSV: {e}")
            return exe.CSVUpdateError
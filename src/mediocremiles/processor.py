"""
Contains the DataProcessor model.
"""
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Union

from stravalib.model import DetailedActivity, AthleteStats
from stravalib.strava_model import Zones

from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.models.athlete_zones import AthleteZones
from src.mediocremiles.models.athlete_stats import AthleteStatistics
from src.mediocremiles.models.athlete_data import AthleteData
from src.mediocremiles.utils import load_config, load_json_n_validate, write_json, to_list


log = logging.getLogger("app.activity_processor")


CONFIGS = load_config()



class DataProcessor:
    """
    Just a wrapper for data processing.
    """
    activity_data_file = Path(CONFIGS["paths"]["data"]).resolve()
    
    def get_latest_activity_date(self) -> Optional[datetime]:
        """
        Get the date of the most recent activity.
        """
        try:
            data = load_json_n_validate(self.activity_data_file, AthleteData)
            activity_data: Dict[int, Dict] = data["activities"]
            
            datetimes = [
                datetime.fromisoformat(a["start_date"])
                for a in activity_data.values()
            ]
            
            return max(datetimes)
        except (FileNotFoundError, Exception):
            log.debug("No existing data found.")
            return None
    
    @staticmethod
    def _format_activities(activities: List[DetailedActivity]) -> Dict[int, Dict]:
        """
        Returns dict w/ activity ids as keys and Activity model as values.
        """
        return {a.id: a for a in activities}
    
    def update_activities(
        self,
        new_activities: Union[DetailedActivity, List[DetailedActivity]]
    ) -> str:
        """
        Update JSON with new activities, avoiding duplicates.
        """
        try:
            activities = [
                ActivityModel.from_strava_activity(a)
                for a in to_list(new_activities)
            ]
            new_activity_data = self._format_activities(activities)
                
            try:
                new_data = load_json_n_validate(self.activity_data_file, AthleteData)
                new_data = new_data.activities.update(new_activity_data)
            except FileNotFoundError:
                new_data = AthleteData(activities = new_activity_data)
            
            write_json(self.activity_data_file, new_data.model_dump())
            
            log.debug(f"Updated data with activity ids: {set(new_data.activities)}")
            log.debug(f"Saved to: {self.activity_data_file.as_posix()}")
            return "complete"
        except Exception as e:
            return str(e)
    
    def update_zones(self, zones: Zones) -> str:
        """
        Update JSON with new athlete zones.
        """
        try:
            new_zones = AthleteZones.from_strava_zones(zones)
                
            try:
                new_zone_data = load_json_n_validate(self.activity_data_file, AthleteData)
                new_zone_data.zones = new_zones
            except FileNotFoundError:
                new_zone_data = AthleteData(zones=new_zones)
            
            write_json(self.activity_data_file, new_zone_data.model_dump())
            
            log.info(f"Zones saved to: {self.activity_data_file.as_posix()}")
            return "complete"
        except Exception as e:
            return str(e)
    
    def update_stats(self, stats: AthleteStats) -> str:
        """
        Update JSON with new athlete stats.
        """
        try:
            new_stats = AthleteStatistics.from_strava_stats(stats)
                
            try:
                new_stats_data = load_json_n_validate(self.activity_data_file, AthleteData)
                new_stats_data.stats = new_stats
            except FileNotFoundError:
                new_stats_data = AthleteData(stats=new_stats)
            
            write_json(self.activity_data_file, new_stats_data.model_dump())
            
            log.info(f"Athlete stats saved to: {self.activity_data_file.as_posix()}")
            return "complete"
        except Exception as e:
            return str(e)
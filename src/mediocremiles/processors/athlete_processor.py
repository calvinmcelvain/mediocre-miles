"""
Contains the AthleteProcessor model.
"""

# built-in.
import json
import logging
from pathlib import Path
from typing import Dict

# third-party.
import pandas as pd

# local.
from src.mediocremiles.utils import load_config
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.models.athlete_stats import AthleteStatistics
from src.mediocremiles.models.athlete_zones import AthleteZones


log = logging.getLogger(__name__)


CONFIGS = load_config()
DATA_PATHS: Dict[str, str] = CONFIGS["paths"]["data"]



class AthleteProcessor:
    """
    Processor for athlete data including HR zones and stats.
    """
    zones_file = Path(DATA_PATHS.get("athlete_zones")).resolve()
    stats_file = Path(DATA_PATHS.get("athlete_stats")).resolve()
    
    def export_athlete_zones(self, client: StravaClient) -> None:
        """
        Fetch and export athlete zones (HR and Power) to JSON.
        """
        try:
            zones_data = client.client.get_athlete_zones()
            if not zones_data:
                log.warning("No zones data available")
                return None
            
            athlete_zones = AthleteZones.from_strava_zones(zones_data)
            
            with open(self.zones_file, 'w') as f:
                json.dump(athlete_zones.to_dict(), f, indent=4)
            log.info(f"Exported all zones data to: {self.zones_file.as_posix()}")
            
        except Exception as e:
            log.exception(f"Error exporting athlete zones: {e}")
            return None
    
    def export_athlete_stats(self, client: StravaClient) -> None:
        """
        Export athlete statistics to JSON file.
        """
        try:
            strava_stats = client.get_athlete_stats()
            if not strava_stats:
                log.warning("Could not retrieve athlete stats")
                return None
            
            stats = AthleteStatistics.from_strava_stats(strava_stats)
            
            with open(self.stats_file, 'w') as f:
                json.dump(stats.to_dict(), f, indent=4)
            
            log.info(f"Exported athlete stats to: {self.stats_file.as_posix()}")
            
        except Exception as e:
            log.exception(f"Error exporting athlete stats: {e}")
            return None
"""
Contains the AthleteProcessor model.
"""

# built-in.
import pandas as pd
from pathlib import Path
from typing import Dict

# local.
from src.mediocremiles.utils import load_config
from src.mediocremiles.strava_client import StravaClient
from src.mediocremiles.models.athlete_stats import AthleteStatistics
from src.mediocremiles.models.athlete_zones import AthleteZones


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
            zones_data = client.get_athlete_zones()
            if not zones_data:
                print("No zones data available")
                return None
            
            athlete_zones = AthleteZones.from_strava_zones(zones_data)
            
            data = athlete_zones.model_dump()
            
            rows = []
            zone_types = ["hear_rate", "power"]
            for zone in zone_types:
                key = f"{zone}_zones"
                if key in data:
                    row = data[key]
                    row['zone_type'] = zone
                    row['fetched_at'] = data['fetched_at']
                    rows.append(row)
            
            df = pd.DataFrame.from_records(rows)
            
            df.to_csv(self.zones_file)
            
            print(f"Exported all zones data to: {self.zones_file.as_posix()}")
            
        except Exception as e:
            print(f"Error exporting athlete zones: {e}")
            return None
    
    def export_athlete_stats(self, client: StravaClient) -> None:
        """
        Export athlete statistics to JSON file.
        """
        try:
            strava_stats = client.get_athlete_stats()
            if not strava_stats:
                print("Could not retrieve athlete stats")
                return None
            
            stats = AthleteStatistics.from_strava_stats(strava_stats)
            
            data = stats.model_dump()

            activities = ['ride', 'run', 'swim']
            periods = ['recent', 'ytd', 'all']

            rows = []

            for period in periods:
                for activity in activities:
                    key = f'{period}_{activity}_totals'
                    if key in data:
                        row = data[key]
                        row['period'] = period
                        row['activity_type'] = activity
                        row['fetched_at'] = data['fetched_at']
                        rows.append(row)

            df = pd.DataFrame.from_records(rows)
            
            df.to_csv(self.stats_file)
            print(f"Exported athlete stats to: {self.stats_file.as_posix()}")
            
        except Exception as e:
            print(f"Error exporting athlete stats: {e}")
            return None
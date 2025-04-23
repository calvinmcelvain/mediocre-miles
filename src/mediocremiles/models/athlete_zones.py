"""
Contains the AthleteZone model.
"""

# built-in.
from dataclasses import dataclass, asdict
from typing import List, Optional, Dict, Any
from datetime import datetime

# third-party.
from stravalib.strava_model import Zones



@dataclass
class HeartRateZone:
    zone_number: int
    min_bpm: int
    max_bpm: Optional[int] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class PowerZone:
    zone_number: int
    min_watts: int
    max_watts: Optional[int] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class AthleteZones:
    heart_rate_zones: List[Dict]
    power_zones: List[Optional[Dict]]
    fetched_at: datetime = datetime.now()
    
    @classmethod
    def from_strava_zones(cls, strava_zones: Zones) -> 'AthleteZones':
        """
        Create AthleteZones from Strava zones data.
        """
        hr_zones = []
        power_zones = []
        
        # Process heart rate zones.
        hr_data = strava_zones.heart_rate
        if hasattr(hr_data, 'zones'):
            for i, zone in enumerate(hr_data.zones.root):
                hr_zones.append(HeartRateZone(
                    zone_number=i+1,
                    min_bpm=getattr(zone, 'min', None),
                    max_bpm=getattr(zone, 'max', None)
                ).to_dict())
        
        # Process power zones.
        power_data = strava_zones.power
        if hasattr(power_data, 'zones'):
            for i, zone in enumerate(power_data.zones.root):
                power_zones.append(HeartRateZone(
                    zone_number=i+1,
                    min_bpm=getattr(zone, 'min', None),
                    max_bpm=getattr(zone, 'max', None)
                ).to_dict())
        
        return cls(
            heart_rate_zones=hr_zones,
            power_zones=power_zones,
            fetched_at=datetime.now()
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convert to dictionary for JSON export.
        """
        zone_dict = asdict(self)
        
        # Converting datetime objects to iso format.
        zone_dict["fetched_at"] = self.fetched_at.isoformat()
        
        return zone_dict
        
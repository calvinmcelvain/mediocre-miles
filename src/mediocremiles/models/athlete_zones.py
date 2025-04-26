"""
Contains the AthleteZone model.
"""
from typing import List, Optional
from datetime import datetime

from stravalib.strava_model import Zones
from pydantic import BaseModel



class HeartRateZone(BaseModel):
    zone_number: int
    min_bpm: Optional[int]
    max_bpm: Optional[int]
    
    class Config:
        orm_mode = True


class PowerZone(BaseModel):
    zone_number: int
    min_watts: Optional[int]
    max_watts: Optional[int]
    
    class Config:
        orm_mode = True


class AthleteZones(BaseModel):
    heart_rate_zones: List[Optional[HeartRateZone]]
    power_zones: List[Optional[PowerZone]]
    fetched_at: str
    
    @classmethod
    def from_strava_zones(cls, strava_zones: Zones) -> 'AthleteZones':
        """
        Create AthleteZones from Strava zones data.
        """
        hr_zones = []
        power_zones = []
        
        # Process heart rate zones.
        hr_data = strava_zones.heart_rate
        if hr_data:
            for i, zone in enumerate(hr_data.zones.root):
                if hasattr(zone, 'max'):
                    if zone.max < 0: zone.max = None 
                
                hr_zones.append(HeartRateZone(
                    zone_number=i+1,
                    min_bpm=getattr(zone, 'min', None),
                    max_bpm=getattr(zone, 'max', None)
                ))
        
        # Process power zones.
        power_data = strava_zones.power
        if power_data:
            for i, zone in enumerate(power_data.zones.root):
                if hasattr(zone, 'max'):
                    if zone.max < 0: zone.max = None
                
                power_zones.append(HeartRateZone(
                    zone_number=i+1,
                    min_bpm=getattr(zone, 'min', None),
                    max_bpm=getattr(zone, 'max', None)
                ))
        
        return cls(
            heart_rate_zones=hr_zones,
            power_zones=power_zones,
            fetched_at=datetime.now().isoformat()
        )
    
    class Config:
        orm_mode = True

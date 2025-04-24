"""
Contains the ActivityModel.
"""

# built-in
from datetime import datetime, timedelta
from typing import Optional

# third-party.
from stravalib import unit_helper
from stravalib.model import DetailedActivity
from pydantic import BaseModel, computed_field



class ActivityModel(BaseModel):
    id: int
    name: str
    activity_type: str
    start_date: datetime
    distance_meters: float
    moving_time_seconds: int
    elapsed_time_seconds: int
    elevation_gain_meters: float
    average_speed_meters_sec: float
    max_speed_meters_sec: float
    kudos_count: int
    pr_count: Optional[int]
    average_heartrate: Optional[float]
    max_heartrate: Optional[float]
    average_cadence: Optional[float]
    shoes: Optional[str]
    shoe_total_distance: Optional[float]
    average_temp: Optional[int]
    city: Optional[str]
    calories: Optional[float]
    start_lat: Optional[float] 
    start_lon: Optional[float] 
    end_lat: Optional[float] 
    end_lon: Optional[float] 
    perceived_exertion: Optional[float] 
    suffer_score: Optional[int] 
    weighted_average_power: Optional[float] 
    splits_standard: Optional[list]
    device_name: Optional[str]
    
    @computed_field
    @property
    def distance_km(self) -> float:
        return unit_helper.kilometers(self.distance_meters).magnitude
    
    @computed_field
    @property
    def distance_miles(self) -> float:
        return unit_helper.miles(self.distance_meters).magnitude
    
    @computed_field
    @property
    def moving_time_minutes(self) -> float:
        return self.moving_time_seconds / 60
    
    @computed_field
    @property
    def elapsed_time_minutes(self) -> float:
        return self.elapsed_time_seconds / 60
    
    @computed_field
    @property
    def moving_time_hours(self) -> float:
        return unit_helper.hours(self.moving_time_seconds).magnitude
    
    @computed_field
    @property
    def elapsed_time_hours(self) -> float:
        return unit_helper.hours(self.elapsed_time_seconds).magnitude
    
    @computed_field
    @property
    def average_speed_kmh(self) -> float:
        return unit_helper.kilometers_per_hour(self.average_speed_meters_sec).magnitude
    
    @computed_field
    @property
    def average_speed_mph(self) -> float:
        return unit_helper.miles_per_hour(self.average_speed_meters_sec).magnitude
    
    @computed_field
    @property
    def max_speed_kmh(self) -> float:
        return unit_helper.kilometers_per_hour(self.max_speed_meters_sec).magnitude
    
    @computed_field
    @property
    def max_speed_mph(self) -> float:
        return unit_helper.miles_per_hour(self.max_speed_meters_sec).magnitude
    
    @computed_field
    @property
    def elevation_gain_feet(self) -> float:
        return unit_helper.feet(self.elevation_gain_meters).magnitude
    
    @computed_field
    @property
    def starting_week(self) -> datetime:
        return self.start_date - timedelta(days=self.start_date.weekday())
    
    @computed_field
    @property
    def month(self) -> datetime:
        return self.start_date.month
    
    @classmethod
    def from_strava_activity(cls, strava_activity: DetailedActivity) -> 'ActivityModel':
        """
        convert stravalib Activity to our model.
        """
        end_lat = end_lon = None
        if getattr(strava_activity, "end_latlng"):
            end_lat = strava_activity.end_latlng.lat
            end_lon = strava_activity.end_latlng.lon
        
        start_lat = start_lon = None
        if getattr(strava_activity, "start_latlng"):
            start_lat = strava_activity.start_latlng.lat
            start_lon = strava_activity.start_latlng.lon
            
        gear = getattr(strava_activity, 'gear', None)
        shoe = shoe_total = None
        if gear:
            shoe = getattr(gear, 'name', None)
            shoe_total = getattr(gear, 'distance', None)
        
        # Strava reports cadence as RPM. Converting to SPM if not Ride type.
        cadence = getattr(strava_activity, 'average_cadence', None)
        if cadence and strava_activity.type.root not in {"Ride", "EBikeRide", "VirtualRide"}:
            cadence *= 2
        
        return cls(
            id=getattr(strava_activity, 'id', None),
            name=getattr(strava_activity, 'name', None),
            activity_type=getattr(getattr(strava_activity, 'type'), 'root', None),
            start_date=getattr(strava_activity, 'start_date', None),
            distance_meters=getattr(strava_activity, 'distance', None),
            moving_time_seconds=getattr(strava_activity, 'moving_time', None),
            elapsed_time_seconds=getattr(strava_activity, 'elapsed_time', None),
            elevation_gain_meters=getattr(strava_activity, 'total_elevation_gain', None),
            average_speed_meters_sec=getattr(strava_activity, 'average_speed', None),
            max_speed_meters_sec=getattr(strava_activity, 'max_speed', None),
            kudos_count=getattr(strava_activity, 'kudos_count', None),
            pr_count=getattr(strava_activity, 'pr_count', None),
            average_heartrate=getattr(strava_activity, 'average_heartrate', None),
            max_heartrate=getattr(strava_activity, 'max_heartrate', None),
            average_cadence=cadence,
            shoes=shoe,
            shoe_total_distance=shoe_total,
            average_temp=getattr(strava_activity, 'average_temp', None),
            city=getattr(strava_activity, 'location_city', None),
            calories=getattr(strava_activity, 'calories', None),
            start_lat=start_lat,
            start_lon=start_lon,
            end_lat=end_lat,
            end_lon=end_lon,
            perceived_exertion=getattr(strava_activity, 'perceived_exertion', None),
            suffer_score=getattr(strava_activity, 'suffer_score', None),
            weighted_average_power=getattr(strava_activity, 'weighted_average_watts', None),
            splits_standard=getattr(strava_activity, 'splits_standard', None),
            device_name=getattr(strava_activity, 'device_name', None)
        )
    
    class Config:
        orm_mode = True
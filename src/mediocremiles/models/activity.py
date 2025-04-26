"""
Contains the ActivityModel.
"""
import pytz
from datetime import datetime, timedelta
from typing import Optional

from pydantic import BaseModel, computed_field
from stravalib.model import DetailedActivity

from src.mediocremiles.utils import convert_distance, convert_speed
from src.mediocremiles.weather_processor import WeatherProcessor
from src.mediocremiles.models.weather import Weather



class ActivityModel(BaseModel):
    id: int
    name: Optional[str]
    activity_type: Optional[str]
    start_date: Optional[datetime]
    timezone: Optional[str]
    total_distance_meters: Optional[float]
    total_moving_time_seconds: Optional[int]
    total_elapsed_time_seconds: Optional[int]
    total_elevation_gain_meters: Optional[float]
    average_speed_meters_sec: Optional[float]
    max_speed_meters_sec: Optional[float]
    kudos_count: Optional[int]
    workout_type: Optional[int]
    pr_count: Optional[int]
    average_heartrate: Optional[float]
    max_heartrate: Optional[float]
    average_cadence: Optional[float]
    shoes: Optional[str]
    shoe_total_distance: Optional[float]
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
    weather: Optional[Weather]
    
    @computed_field
    @property
    def distance_km(self) -> float:
        return float(convert_distance(self.total_distance_meters, "km"))
    
    @computed_field
    @property
    def distance_miles(self) -> float:
        return float(convert_distance(self.total_distance_meters, "mi"))
    
    @computed_field
    @property
    def moving_time_minutes(self) -> float:
        return float(self.total_moving_time_seconds / 60)
    
    @computed_field
    @property
    def elapsed_time_minutes(self) -> float:
        return float(self.total_elapsed_time_seconds / 60)
    
    @computed_field
    @property
    def moving_time_hours(self) -> float:
        return float(self.total_moving_time_seconds / 3600)
    
    @computed_field
    @property
    def elapsed_time_hours(self) -> float:
        return float(self.total_elapsed_time_seconds / 3600)
    
    @computed_field
    @property
    def average_speed_kmh(self) -> float:
        return float(convert_speed(self.average_speed_meters_sec, "km"))
    
    @computed_field
    @property
    def average_speed_mph(self) -> float:
        return float(convert_speed(self.average_speed_meters_sec, "mi"))
    
    @computed_field
    @property
    def max_speed_kmh(self) -> float:
        return float(convert_speed(self.max_speed_meters_sec, "km"))
    
    @computed_field
    @property
    def max_speed_mph(self) -> float:
        return float(convert_speed(self.max_speed_meters_sec, "mi"))
    
    @computed_field
    @property
    def elevation_gain_feet(self) -> float:
        return float(convert_distance(self.total_elevation_gain_meters, "ft"))
    
    @computed_field
    @property
    def starting_week(self) -> datetime:
        week = self.start_date - timedelta(days=self.start_date.weekday())
        return week.date()
    
    @computed_field
    @property
    def month(self) -> int:
        return self.start_date.month
    
    @classmethod
    def from_strava_activity(cls, strava_activity: DetailedActivity) -> 'ActivityModel':
        """
        convert stravalib Activity to our model.
        """
        # adjusting timezone of start_date.
        tz = strava_activity.timezone.split(') ')[1] if strava_activity.timezone else 'UTC'
        strava_activity.start_date = strava_activity.start_date.astimezone(pytz.timezone(tz))
    
        end_lat = end_lon = None
        if getattr(strava_activity, "end_latlng"):
            end_lat = strava_activity.end_latlng.lat
            end_lon = strava_activity.end_latlng.lon
        
        weather_processor = WeatherProcessor()
        start_lat = start_lon = weather =  None
        if getattr(strava_activity, "start_latlng"):
            start_lat = strava_activity.start_latlng.lat
            start_lon = strava_activity.start_latlng.lon
            weather = weather_processor.get_hourly_conditions(
                start_lat, start_lon, strava_activity.start_date)
            
        gear = getattr(strava_activity, 'gear', None)
        shoe = shoe_total = None
        if gear:
            shoe = gear.name
            shoe_total = convert_distance(gear.distance, "mi")
        
        # Strava reports cadence as RPM. Converting to SPM if not Ride type.
        cadence = getattr(strava_activity, 'average_cadence', None)
        if cadence and strava_activity.type.root not in {"Ride", "EBikeRide", "VirtualRide"}:
            cadence *= 2
        
        return cls(
            id=strava_activity.id,
            name=getattr(strava_activity, 'name', None),
            activity_type=getattr(getattr(strava_activity, 'type'), 'root', None),
            start_date=getattr(strava_activity, 'start_date', None),
            timezone=getattr(strava_activity, 'timezone', None),
            total_distance_meters=getattr(strava_activity, 'distance', None),
            total_moving_time_seconds=getattr(strava_activity, 'moving_time', None),
            total_elapsed_time_seconds=getattr(strava_activity, 'elapsed_time', None),
            total_elevation_gain_meters=getattr(strava_activity, 'total_elevation_gain', None),
            average_speed_meters_sec=getattr(strava_activity, 'average_speed', None),
            max_speed_meters_sec=getattr(strava_activity, 'max_speed', None),
            kudos_count=getattr(strava_activity, 'kudos_count', None),
            workout_type=getattr(strava_activity, 'workout_type', None),
            pr_count=getattr(strava_activity, 'pr_count', None),
            average_heartrate=getattr(strava_activity, 'average_heartrate', None),
            max_heartrate=getattr(strava_activity, 'max_heartrate', None),
            average_cadence=cadence,
            shoes=shoe,
            shoe_total_distance=shoe_total,
            calories=getattr(strava_activity, 'calories', None),
            start_lat=start_lat,
            start_lon=start_lon,
            end_lat=end_lat,
            end_lon=end_lon,
            perceived_exertion=getattr(strava_activity, 'perceived_exertion', None),
            suffer_score=getattr(strava_activity, 'suffer_score', None),
            weighted_average_power=getattr(strava_activity, 'weighted_average_watts', None),
            splits_standard=getattr(strava_activity, 'splits_standard', None),
            device_name=getattr(strava_activity, 'device_name', None),
            weather=weather
        )
    
    class Config:
        orm_mode = True
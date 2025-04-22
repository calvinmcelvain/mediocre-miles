"""
Contains the ActivityModel.
"""

# built-in
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional

# third-party.
from stravalib import unit_helper
from stravalib.model import DetailedActivity




@dataclass
class ActivityModel:
    id: int
    name: str
    activity_type: str
    start_date: datetime
    distance_meters: float
    moving_time_seconds: int
    elapsed_time_seconds: int
    total_elevation_gain_meters: float
    average_speed_meters_sec: float
    max_speed_meters_sec: float
    kudos_count: int
    pr_count: Optional[int] = None
    average_heartrate: Optional[float] = None
    max_heartrate: Optional[float] = None
    average_cadence: Optional[float] = None
    shoes: Optional[str] = None
    shoe_total_distance: Optional[float] = None
    average_temp: Optional[int] = None
    city: Optional[str] = None
    map_polyline: Optional[str] = None
    start_lat: Optional[float] = None
    start_lon: Optional[float] = None
    end_lat: Optional[float] = None
    end_lon: Optional[float] = None
    
    @property
    def distance_km(self):
        return unit_helper.kilometers(self.distance_meters).magnitude
    
    @property
    def distance_miles(self):
        return unit_helper.miles(self.distance_meters).magnitude
    
    @property
    def moving_time_minutes(self):
        return self.moving_time_seconds / 60
    
    @property
    def elapsed_time_minutes(self):
        return self.elapsed_time_seconds / 60
    
    @property
    def average_speed_kmh(self):
        return unit_helper.kilometers_per_hour(self.average_speed_meters_sec).magnitude
    
    @property
    def average_speed_mph(self):
        return unit_helper.miles_per_hour(self.average_speed_meters_sec).magnitude
    
    @property
    def max_speed_kmh(self):
        return unit_helper.kilometers_per_hour(self.max_speed_meters_sec).magnitude
    
    @property
    def max_speed_mph(self):
        return unit_helper.miles_per_hour(self.max_speed_meters_sec).magnitude
    
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
        
        return cls(
            id=getattr(strava_activity, 'id', None),
            name=getattr(strava_activity, 'name', None),
            activity_type=getattr(getattr(strava_activity, 'type'), 'root', None),
            start_date=getattr(strava_activity, 'start_date', None),
            distance_meters=getattr(strava_activity, 'distance', None),
            moving_time_seconds=getattr(strava_activity, 'moving_time', None),
            elapsed_time_seconds=getattr(strava_activity, 'elapsed_time', None),
            total_elevation_gain_meters=getattr(strava_activity, 'total_elevation_gain', None),
            average_speed_meters_sec=getattr(strava_activity, 'average_speed', None),
            max_speed_meters_sec=getattr(strava_activity, 'max_speed', None),
            kudos_count=getattr(strava_activity, 'kudos_count', None),
            pr_count=getattr(strava_activity, 'pr_count', None),
            average_heartrate=getattr(strava_activity, 'average_heartrate', None),
            max_heartrate=getattr(strava_activity, 'max_heartrate', None),
            average_cadence=getattr(strava_activity, 'average_cadence', None),
            shoes=shoe,
            shoe_total_distance=shoe_total,
            average_temp=getattr(strava_activity, 'average_temp', None),
            city=getattr(strava_activity, 'location_city', None),
            map_polyline=getattr(strava_activity, 'map_polyline', None),
            start_lat=start_lat,
            start_lon=start_lon,
            end_lat=end_lat,
            end_lon=end_lon
        )
    
    def to_dict(self):
        """
        Convert to dictionary for CSV export.
        """
        result = {
            'id': self.id,
            'name': self.name,
            'activity_type': self.activity_type,
            'start_date': self.start_date.isoformat(),
            'distance_km': float(self.distance_km),
            'distance_miles': float(self.distance_miles),
            'moving_time_minutes': self.moving_time_minutes,
            'elapsed_time_minutes': self.elapsed_time_minutes,
            'total_elevation_gain_meters': self.total_elevation_gain_meters,
            'average_speed_mph': float(self.average_speed_mph),
            'average_speed_kmh': float(self.average_speed_kmh),
            'max_speed_kmh': float(self.max_speed_kmh),
            'max_speed_mph': float(self.max_speed_mph),
            'kudos_count': self.kudos_count,
            'pr_count': self.pr_count,
            'average_heartrate': self.average_heartrate,
            'max_heartrate': self.max_heartrate,
            'average_cadence': self.average_cadence,
            'shoes': self.shoes,
            'shoe_total_distance': self.shoe_total_distance,
            'average_temp': self.average_temp,
            'city': self.city,
            'start_lat': self.start_lat,
            'start_lon': self.start_lon,
            'end_lat': self.end_lat,
            'end_lon': self.end_lon
        }
        return result
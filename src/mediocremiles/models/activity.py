# built-in
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

# third-party.
from stravalib.model import SummaryActivity as StravaActivity




@dataclass
class ActivityModel:
    id: int
    name: str
    type: str
    start_date: datetime
    distance_meters: float
    moving_time_seconds: int
    elapsed_time_seconds: int
    total_elevation_gain: float
    average_speed: float
    max_speed: float
    kudos_count: int
    average_heartrate: Optional[float] = None
    max_heartrate: Optional[float] = None
    map_polyline: Optional[str] = None
    start_latlng: Optional[tuple] = None
    end_latlng: Optional[tuple] = None
    
    @property
    def distance_km(self):
        return self.distance_meters / 1000
    
    @property
    def moving_time_minutes(self):
        return self.moving_time_seconds / 60
    
    @property
    def elapsed_time_minutes(self):
        return self.elapsed_time_seconds / 60
    
    @property
    def average_speed_kmh(self):
        return self.average_speed * 3.6
    
    @property
    def max_speed_kmh(self):
        return self.max_speed * 3.6
    
    @classmethod
    def from_strava_activity(cls, strava_activity: StravaActivity) -> 'ActivityModel':
        start_latlng = None
        if hasattr(strava_activity, 'start_latlng') and strava_activity.start_latlng:
            start_latlng = (strava_activity.start_latlng.lat, strava_activity.start_latlng.lon)
            
        end_latlng = None
        if hasattr(strava_activity, 'end_latlng') and strava_activity.end_latlng:
            end_latlng = (strava_activity.end_latlng.lat, strava_activity.end_latlng.lon)
            
        map_polyline = None
        if hasattr(strava_activity, 'map') and strava_activity.map:
            map_polyline = strava_activity.map.summary_polyline
            
        return cls(
            id=strava_activity.id,
            name=strava_activity.name,
            type=strava_activity.type,
            start_date=strava_activity.start_date,
            distance_meters=float(strava_activity.distance),
            moving_time_seconds=int(strava_activity.moving_time),
            elapsed_time_seconds=int(strava_activity.elapsed_time),
            total_elevation_gain=float(strava_activity.total_elevation_gain),
            average_speed=float(strava_activity.average_speed),
            max_speed=float(strava_activity.max_speed),
            kudos_count=strava_activity.kudos_count,
            average_heartrate=strava_activity.average_heartrate,
            max_heartrate=strava_activity.max_heartrate,
            map_polyline=map_polyline,
            start_latlng=start_latlng,
            end_latlng=end_latlng
        )
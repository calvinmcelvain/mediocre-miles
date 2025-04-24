"""
Contains the AthleteStatistics & ActivityTotal models.
"""
# built-in.
from typing import Any, Optional
from datetime import datetime

# third-party.
from stravalib import unit_helper
from stravalib.model import AthleteStats
from pydantic import BaseModel, computed_field



class ActivityTotal(BaseModel):
    count: int
    distance: float
    moving_time: int
    elapsed_time: int
    elevation_gain: float
    achievement_count: int
    
    @computed_field
    @property
    def distance_km(self) -> float:
        return unit_helper.kilometers(self.distance).magnitude
    
    @computed_field
    @property
    def distance_miles(self) -> float:
        return unit_helper.miles(self.distance).magnitude
    
    @computed_field
    @property
    def moving_time_hours(self) -> float:
        return unit_helper.hours(self.moving_time).magnitude
    
    @computed_field
    @property
    def elapsed_time_hours(self) -> float:
        return unit_helper.hours(self.elapsed_time).magnitude
    
    @classmethod
    def from_strava_total(cls, strava_total: Any) -> 'ActivityTotal':
        return cls(
            count=getattr(strava_total, 'count', 0),
            distance=getattr(strava_total, 'distance', 0),
            moving_time=getattr(strava_total, 'moving_time', 0),
            elapsed_time=getattr(strava_total, 'elapsed_time', 0),
            elevation_gain=getattr(strava_total, 'elevation_gain', 0),
            achievement_count=getattr(strava_total, 'achievement_count', 0) or 0
        )

    class Config:
        orm_mode = True


class AthleteStatistics(BaseModel):
    recent_ride_totals: ActivityTotal
    recent_run_totals: ActivityTotal
    recent_swim_totals: ActivityTotal
    ytd_ride_totals: ActivityTotal
    ytd_run_totals: ActivityTotal
    ytd_swim_totals: ActivityTotal
    all_ride_totals: ActivityTotal
    all_run_totals: ActivityTotal
    all_swim_totals: ActivityTotal
    biggest_ride_distance: Optional[float]
    biggest_climb_elevation_gain: Optional[float]
    fetched_at: str = datetime.now().isoformat()
    
    @classmethod
    def from_strava_stats(cls, strava_stats: AthleteStats) -> 'AthleteStatistics':
        """
        convert stravalib AthleteStats object to our model (only diff. is the 
        fetch_date).
        """
        return cls(
            recent_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_ride_totals),
            recent_run_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_run_totals),
            recent_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_swim_totals),
            ytd_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_ride_totals),
            ytd_run_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_run_totals),
            ytd_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_swim_totals),
            all_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.all_ride_totals),
            all_run_totals=ActivityTotal.from_strava_total(
                strava_stats.all_run_totals),
            all_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.all_swim_totals),
            biggest_ride_distance=getattr(
                strava_stats, 'biggest_ride_distance', 0),
            biggest_climb_elevation_gain=getattr(
                strava_stats, 'biggest_climb_elevation_gain', 0)
        )

    class Config:
        orm_mode = True
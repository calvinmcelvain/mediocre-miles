"""
Contains the AthleteStatistics & ActivityTotal models.
"""
# built-in.
from dataclasses import dataclass, asdict
from typing import Dict, Any
from datetime import datetime

# third-party.
from stravalib import unit_helper
from stravalib.model import AthleteStats



@dataclass
class ActivityTotal:
    count: int
    distance: float
    moving_time: int 
    elapsed_time: int 
    elevation_gain: float 
    achievement_count: int
    
    @property
    def distance_km(self) -> float:
        return unit_helper.kilometers(self.distance).magnitude
    
    @property
    def distance_miles(self) -> float:
        return unit_helper.miles(self.distance).magnitude
    
    @property
    def moving_time_hours(self) -> float:
        return unit_helper.hours(self.moving_time).magnitude
    
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
            achievement_count=getattr(strava_total, 'achievement_count', 0)
        )
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)



@dataclass
class AthleteStatistics:
    recent_ride_totals: Dict[str, Any]
    recent_run_totals: Dict[str, Any]
    recent_swim_totals: Dict[str, Any]
    ytd_ride_totals: Dict[str, Any]
    ytd_run_totals: Dict[str, Any]
    ytd_swim_totals: Dict[str, Any]
    all_ride_totals: Dict[str, Any]
    all_run_totals: Dict[str, Any]
    all_swim_totals: Dict[str, Any]
    biggest_ride_distance: float
    biggest_climb_elevation_gain: float
    fetched_at: datetime
    
    @classmethod
    def from_strava_stats(cls, strava_stats: AthleteStats) -> 'AthleteStatistics':
        """
        convert stravalib AthleteStats object to our model (only diff. is the 
        fetch_date).
        """
        return cls(
            recent_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_ride_totals).to_dict(),
            recent_run_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_run_totals).to_dict(),
            recent_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.recent_swim_totals).to_dict(),
            ytd_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_ride_totals).to_dict(),
            ytd_run_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_run_totals).to_dict(),
            ytd_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.ytd_swim_totals).to_dict(),
            all_ride_totals=ActivityTotal.from_strava_total(
                strava_stats.all_ride_totals).to_dict(),
            all_run_totals=ActivityTotal.from_strava_total(
                strava_stats.all_run_totals).to_dict(),
            all_swim_totals=ActivityTotal.from_strava_total(
                strava_stats.all_swim_totals).to_dict(),
            biggest_ride_distance=float(getattr(
                strava_stats, 'biggest_ride_distance', 0)),
            biggest_climb_elevation_gain=float(getattr(
                strava_stats, 'biggest_climb_elevation_gain', 0)),
            fetched_at=datetime.now()
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """
        converts to dictionary for JSON export.
        """
        athlete_stats_dict = asdict(self)
        
        # Converting datetime objects to iso format.
        athlete_stats_dict["fetch_date"] = self.fetched_at.isoformat()
        
        return athlete_stats_dict
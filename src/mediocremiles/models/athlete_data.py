"""
Contains the AthleteData model.
"""
from typing import Dict

from pydantic import BaseModel

from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.models.athlete_zones import AthleteZones
from src.mediocremiles.models.athlete_stats import AthleteStatistics



class AthleteData(BaseModel):
    """
    Wrapper for data models.
    """
    activities: Dict[int, ActivityModel] = None
    zones: AthleteZones = None
    stats: AthleteStatistics = None
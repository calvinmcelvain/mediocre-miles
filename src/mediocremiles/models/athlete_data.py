"""
Contains the AthleteData model.
"""
from typing import Dict, Optional

from pydantic import BaseModel

from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.models.athlete_zones import AthleteZones
from src.mediocremiles.models.athlete_stats import AthleteStatistics



class AthleteData(BaseModel):
    """
    Wrapper for data models.
    """
    activities: Optional[Dict[int, ActivityModel]] = None
    zones: Optional[AthleteZones] = None
    stats: Optional[AthleteStatistics] = None
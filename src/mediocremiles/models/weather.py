"""
Contains the Weather model.
"""
from typing import Optional

from pydantic import BaseModel, computed_field

from src.mediocremiles.utils import convert_distance, convert_speed, c_to_f



class Weather(BaseModel):
    temperature: Optional[float]
    dew_point: Optional[float]
    humidity: Optional[float]
    pressure: Optional[float]
    wind_direction: Optional[float]
    wind_speed: Optional[float]
    snow: Optional[float]
    precipitation: Optional[float]
    conditions: str
    
    @computed_field
    @property
    def temperature_f(self) -> Optional[float]:
        if self.temperature:
            return c_to_f(self.temperature)
        return None
    
    @computed_field
    @property
    def dew_point_f(self) -> Optional[float]:
        if self.dew_point:
            return c_to_f(self.dew_point)
        return None
    
    @computed_field
    @property
    def precipitation_inch(self) -> Optional[float]:
        if self.precipitation:
            return convert_distance(self.precipitation, "inch")
        return None
    
    @computed_field
    @property
    def snow_inch(self) -> Optional[float]:
        if self.snow:
            return convert_distance(self.snow, "inch")
        return None
    
    @computed_field
    @property
    def wind_speed_kmh(self) -> Optional[float]:
        if self.wind_speed:
            return convert_speed(self.wind_speed, "km")
        return None
    
    @computed_field
    @property
    def wind_speed_mph(self) -> Optional[float]:
        if self.wind_speed:
            return convert_speed(self.wind_speed, "mi")
        return None
        
    
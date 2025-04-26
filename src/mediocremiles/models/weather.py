"""
Contains the Weather model.
"""
from pydantic import BaseModel, computed_field

from src.mediocremiles.utils import convert_distance, convert_speed, c_to_f




class Weather(BaseModel):
    temperature: float
    dew_point: float
    humidity: float
    pressure: float
    wind_direction: float
    wind_speed: float
    snow: float
    precipitation: float
    conditions: str
    
    @computed_field
    @property
    def temperature_f(self):
        return c_to_f(self.temperature)
    
    @computed_field
    @property
    def dew_point_f(self):
        return c_to_f(self.dew_point)
    
    @computed_field
    @property
    def precipitation_inch(self):
        return convert_distance(self.precipitation, "inch")
    
    @computed_field
    @property
    def snow_inch(self):
        return convert_distance(self.snow, "inch")
    
    @computed_field
    @property
    def wind_speed_kmh(self):
        return convert_speed(self.wind_speed, "km")
    
    @computed_field
    @property
    def wind_speed_mph(self):
        return convert_speed(self.wind_speed, "mi")
        
    
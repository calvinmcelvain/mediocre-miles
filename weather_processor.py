"""
Contains the WeatherProcessor model.
"""
import logging
import pandas as pd
from typing import Dict, Optional, Any, List
from datetime import datetime, timedelta, timezone

from meteostat import Point, Hourly

from src.mediocremiles.models.weather import Weather


log = logging.getLogger("app.weather")



class WeatherProcessor:
    """
    A client for interacting with the Meteostat Python library to retrieve 
    hourly weather data for activity data.
    """
    def get_hourly_conditions(
        self, 
        latitude: float,
        longitude: float,
        start_date: datetime,
        altitude: Optional[float] = None
    ) -> List[Dict[str, Any]]:
        """
        Get hourly weather conditions for a specific location and time range.
        """
        try:
            # Ensure start_date is naive
            start_date = start_date.replace(tzinfo=None)
            
            # Create a Point and fetch data.
            point = self._create_point(latitude, longitude, altitude)
            end_date = start_date + timedelta(hours=2)
            data = Hourly(point, start_date, end_date)
            weather_data = data.fetch()
            
            if weather_data.empty:
                log.debug(
                    "No weather data found for coordinates:"
                    f"lat: {latitude}; lon: {longitude}"
                )
            
            df = self._format_data(weather_data)
            
            if df.empty: return None
            
            weather = df.iloc[0]
            return Weather(
                temperature=None if pd.isna(weather["temp"]) else weather["temp"],
                dew_point=None if pd.isna(weather["dwpt"]) else weather["dwpt"],
                humidity=None if pd.isna(weather["rhum"]) else weather["rhum"], 
                pressure=None if pd.isna(weather["pres"]) else weather["pres"],
                wind_direction=None if pd.isna(weather["wdir"]) else weather["wdir"],
                wind_speed=None if pd.isna(weather["wspd"]) else weather["wspd"],
                snow=None if pd.isna(weather["snow"]) else weather["snow"],
                precipitation=None if pd.isna(weather["prcp"]) else weather["prcp"],
                conditions=None if pd.isna(weather["conditions"]) else weather["conditions"]
            )
        except Exception as e:
            log.exception(f"Error retrieving hourly conditions: {str(e)}")
            return None
        
    def _create_point(
        self,
        latitude: float,
        longitude: float,
        altitude: Optional[float] = None
    ) -> Point:
        """
        Create a Meteostat Point object for the given coordinates.
        """
        if altitude:
            return Point(latitude, longitude, altitude)
        return Point(latitude, longitude)
        
    def _format_data(self, data: pd.DataFrame) -> pd.DataFrame:
        """
        Adds standard columns removes missing values.
        """
        df = data[~(data["temp"].isna())]
        df.loc[:, "conditions"] = df["coco"].apply(self._map_condition_code)
        return df
    
    def _map_condition_code(self, code: int) -> str:
        """
        map Meteostat condition code.
        """
        conditions = {
            1: "Clear",
            2: "Fair",
            3: "Cloudy",
            4: "Overcast",
            5: "Fog",
            6: "Freezing Fog",
            7: "Light Rain",
            8: "Rain",
            9: "Heavy Rain",
            10: "Freezing Rain",
            11: "Heavy Freezing Rain",
            12: "Sleet",
            13: "Heavy Sleet",
            14: "Light Snowfall",
            15: "Snowfall",
            16: "Heavy Snowfall",
            17: "Rain Shower",
            18: "Heavy Rain Shower",
            19: "Sleet Shower",
            20: "Heavy Sleet Shower",
            21: "Snow Shower",
            22: "Heavy Snow Shower",
            23: "Lightning",
            24: "Hail",
            25: "Thunderstorm",
            26: "Heavy Thunderstorm",
            27: "Storm"
        }
        
        return conditions.get(code, "Unknown condition")
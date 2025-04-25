"""
Contains the MeteostatClient
"""
# built-in.
from typing import Dict, Optional, Any, List
from datetime import datetime

# third-party
from meteostat import Point, Hourly




class MeteostatClient:
    """
    A client for interacting with the Meteostat Python library to retrieve 
    hourly weather data for activity data.
    """
    def create_point(
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
            # Create a Point and fetch data.
            point = self.create_point(latitude, longitude, altitude)
            print(point)
            data = Hourly(loc=point, start=start_date)
            print(data)
            weather_data = data.fetch()
            
            if weather_data.empty:
                print(
                    "No weather data found for coordinates:"
                    f"lat: {latitude}; lon: {longitude}"
                )
                return None
            
            return weather_data.to_dict('records')
            
        except Exception as e:
            print(f"Error retrieving hourly conditions: {str(e)}")
            return None
    
    def map_condition_code(self, code: int) -> str:
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
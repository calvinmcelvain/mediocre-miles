"""
Contains the model for unit tests of the WeatherProcessor model.
"""
import unittest
from datetime import datetime
from unittest.mock import patch, MagicMock

from src.mediocremiles.weather_processor import WeatherProcessor
from src.mediocremiles.models.weather import Weather



class TestWeatherProcessor(unittest.TestCase):
    
    def setUp(self):
        self.processor = WeatherProcessor()
    
    @patch('src.mediocremiles.weather_processor.Point')
    @patch('src.mediocremiles.weather_processor.Hourly')
    def test_get_hourly_conditions_success(self, mock_hourly, mock_point):
        """
        Test getting hourly weather conditions successfully.
        """
        mock_point_instance = MagicMock()
        mock_point.return_value = mock_point_instance
        
        mock_hourly_instance = MagicMock()
        mock_hourly.return_value = mock_hourly_instance
        
        mock_data = MagicMock()
        mock_data.empty = False
        
        mock_data.__getitem__.return_value.isna.return_value = False
        
        mock_hourly_instance.fetch.return_value = mock_data
        
        mock_formatted = MagicMock()
        mock_formatted.empty = False
        mock_formatted.index = [{
            'temp': 20, 'dwpt': 10, 'rhum': 50, 'pres': 1013, 'wdir': 180, 
            'wspd': 5, 'snow': 0, 'prcp': 0,'conditions': 'Clear'
        }]
        
        with patch.object(self.processor, '_format_data', return_value=mock_formatted):
            result = self.processor.get_hourly_conditions(
                latitude=40.7128, longitude=-74.0060, 
                start_date=datetime(2023, 1, 1)
            )
            
            self.assertIsInstance(result, Weather)
            self.assertEqual(result.temperature, 20)
            self.assertEqual(result.conditions, 'Clear')
    
    @patch('src.mediocremiles.weather_processor.Point')
    @patch('src.mediocremiles.weather_processor.Hourly')
    def test_get_hourly_conditions_empty_data(self, mock_hourly, mock_point):
        """
        Test getting hourly weather when no data is available.
        """
        mock_point_instance = MagicMock()
        mock_point.return_value = mock_point_instance
        
        mock_hourly_instance = MagicMock()
        mock_hourly.return_value = mock_hourly_instance
        
        mock_data = MagicMock()
        mock_data.empty = True
        mock_hourly_instance.fetch.return_value = mock_data
        
        result = self.processor.get_hourly_conditions(
            latitude=40.7128, longitude=-74.0060, 
            start_date=datetime(2023, 1, 1)
        )
        
        self.assertIsNone(result)
    
    @patch('src.mediocremiles.weather_processor.Point')
    @patch('src.mediocremiles.weather_processor.Hourly')
    def test_get_hourly_conditions_exception(self, mock_hourly, mock_point):
        """
        Test error handling when getting weather data.
        """
        mock_hourly.side_effect = Exception("API Error")
        
        result = self.processor.get_hourly_conditions(
            latitude=40.7128, longitude=-74.0060, 
            start_date=datetime(2023, 1, 1)
        )
        
        self.assertIsNone(result)
    
    def test_map_condition_code(self):
        """
        Test mapping condition codes to descriptions.
        """
        self.assertEqual(self.processor._map_condition_code(1), "Clear")
        self.assertEqual(self.processor._map_condition_code(8), "Rain")
        self.assertEqual(self.processor._map_condition_code(15), "Snowfall")
        self.assertEqual(self.processor._map_condition_code(999), "Unknown condition")
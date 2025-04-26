"""
Contains model for unit tests with DataProcessor.
"""
import unittest
from datetime import datetime
from unittest.mock import patch, MagicMock

from src.mediocremiles.processor import DataProcessor
from src.mediocremiles.models.activity import ActivityModel
from src.mediocremiles.models.athlete_data import AthleteData



class TestDataProcessor(unittest.TestCase):
    
    def setUp(self):
        self.processor = DataProcessor()
        
    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_get_latest_activity_date_with_data(self, mock_load):
        """
        Test getting latest activity date when data exists.
        """
        date1 = datetime(2023, 1, 1, 12, 0, 0)
        date2 = datetime(2023, 1, 2, 12, 0, 0)
        
        mock_data = {
            "activities": {
                "123": {"start_date": date1.isoformat()},
                "456": {"start_date": date2.isoformat()}
            }
        }
        mock_load.return_value = AthleteData(**mock_data)
        
        result = self.processor.get_latest_activity_date()
        
        self.assertEqual(result, date2)

    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_get_latest_activity_date_no_file(self, mock_load):
        """
        Test getting latest activity date when file doesn't exist.
        """
        mock_load.side_effect = FileNotFoundError
        
        result = self.processor.get_latest_activity_date()
        
        self.assertIsNone(result)

    @patch('src.mediocremiles.processor.write_json')
    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_update_activities_new_file(self, mock_load, mock_write):
        """
        Test updating activities when file doesn't exist yet.
        """
        mock_load.side_effect = FileNotFoundError
        activity = MagicMock()
        activity.id = 123
        
        with patch.object(ActivityModel, 'from_strava_activity', return_value=activity):
            result = self.processor.update_activities([activity])
        
        self.assertEqual(result, "complete")
        mock_write.assert_called_once()

    @patch('src.mediocremiles.processor.write_json')
    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_update_activities_existing_file(self, mock_load, mock_write):
        """
        Test updating activities when file exists.
        """
        existing_data = AthleteData(activities={})
        mock_load.return_value = existing_data
        
        activity = MagicMock()
        activity.id = 123
        
        with patch.object(ActivityModel, 'from_strava_activity', return_value=activity):
            result = self.processor.update_activities([activity])
        
        self.assertEqual(result, "complete")
        mock_write.assert_called_once()

    @patch('src.mediocremiles.processor.write_json')
    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_update_zones(self, mock_load, mock_write):
        """
        Test updating athlete zones.
        """
        existing_data = AthleteData(activities={})
        mock_load.return_value = existing_data
        
        zones = MagicMock()
        
        with patch('src.mediocremiles.models.athlete_zones.AthleteZones.from_strava_zones', return_value=MagicMock()):
            result = self.processor.update_zones(zones)
        
        self.assertEqual(result, "complete")
        mock_write.assert_called_once()

    @patch('src.mediocremiles.processor.write_json')
    @patch('src.mediocremiles.processor.load_json_n_validate')
    def test_update_stats(self, mock_load, mock_write):
        """
        Test updating athlete stats.
        """
        existing_data = AthleteData(activities={})
        mock_load.return_value = existing_data
        
        stats = MagicMock()
        
        with patch(
            'src.mediocremiles.models.athlete_stats.AthleteStatistics.from_strava_stats',
            return_value=MagicMock()
        ):
            result = self.processor.update_stats(stats)
        
        self.assertEqual(result, "complete")
        mock_write.assert_called_once()
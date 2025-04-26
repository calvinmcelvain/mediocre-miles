"""
Contains the unit tests for the StravaClient model.
"""
import unittest
import time
from unittest.mock import patch, MagicMock, mock_open
from pathlib import Path
from datetime import datetime

from src.mediocremiles.strava_client import StravaClient



class TestStravaClient(unittest.TestCase):
    @patch('src.mediocremiles.strava_client.load_envs')
    @patch('src.mediocremiles.strava_client.Client')
    @patch.object(StravaClient, '_initiate_and_authorize')
    def setUp(self, mock_init_auth, mock_client, mock_load_envs):
        self.mock_client_instance = MagicMock()
        mock_client.return_value = self.mock_client_instance
        self.client = StravaClient()
        self.client.client = self.mock_client_instance
        
    @patch.object(StravaClient, '_load_token_from_file')
    @patch.object(StravaClient, 'refresh_token')
    def test_check_refresh_token_expired(self, mock_refresh, mock_load_token):
        """
        Test refresh token when it's expired.
        """
        # Set up expired token
        mock_load_token.return_value = {
            'access_token': 'old_token',
            'refresh_token': 'refresh_token',
            'expires_at': time.time() - 1000
        }
        mock_refresh.return_value = {'access_token': 'new_token'}
        
        result = self.client.check_refresh()
        
        mock_refresh.assert_called_once_with('refresh_token')
        self.assertTrue(result)

    @patch.object(StravaClient, '_load_token_from_file')
    def test_check_refresh_token_valid(self, mock_load_token):
        """
        Test refresh check when token is still valid.
        """
        valid_token = {
            'access_token': 'valid_token',
            'refresh_token': 'refresh_token',
            'expires_at': time.time() + 3600
        }
        mock_load_token.return_value = valid_token
        
        result = self.client.check_refresh()
        
        self.assertTrue(result)
        self.assertEqual(self.client.client.access_token, 'valid_token')
        self.assertEqual(self.client.client.refresh_token, 'refresh_token')
        self.assertEqual(self.client.client.token_expires, valid_token['expires_at'])

    @patch.object(StravaClient, '_load_token_from_file')
    def test_check_refresh_no_token(self, mock_load_token):
        """
        Test refresh check when no token exists.
        """
        mock_load_token.return_value = None
        
        result = self.client.check_refresh()
        
        self.assertFalse(result)

    @patch.object(StravaClient, '_save_token_to_file')
    def test_refresh_token(self, mock_save):
        """
        Test refreshing token.
        """
        self.client.client_id = 12345
        self.client.client_secret = 'secret'
        
        mock_token_response = {
            'access_token': 'new_token',
            'refresh_token': 'new_refresh',
            'expires_at': time.time() + 3600
        }
        self.client.client.refresh_access_token.return_value = mock_token_response
        
        result = self.client.refresh_token('old_refresh')
        
        self.client.client.refresh_access_token.assert_called_once_with(
            client_id=12345,
            client_secret='secret',
            refresh_token='old_refresh'
        )
        mock_save.assert_called_once_with(mock_token_response)
        self.assertEqual(result, mock_token_response)
        self.assertEqual(self.client.client.access_token, 'new_token')
        self.assertEqual(self.client.client.refresh_token, 'new_refresh')

    @patch('builtins.open', new_callable=mock_open)
    @patch('json.dump')
    def test_save_token_to_file(self, mock_json_dump, mock_file):
        """
        Test saving token to file.
        """
        token_data = {'access_token': 'test_token'}
        self.client._save_token_to_file(token_data)
        
        mock_file.assert_called_once()
        mock_json_dump.assert_called_once_with(token_data, mock_file())

    @patch('builtins.open', new_callable=mock_open, read_data='{"access_token": "test_token"}')
    @patch('json.load')
    def test_load_token_from_file(self, mock_json_load, mock_file):
        """
        Test loading token from file.
        """
        token_data = {'access_token': 'test_token'}
        mock_json_load.return_value = token_data
        self.client.token_file = Path('/fake/path')
        
        with patch.object(Path, 'exists', return_value=True):
            result = self.client._load_token_from_file()
            
            mock_file.assert_called_once()
            mock_json_load.assert_called_once()
            self.assertEqual(result, token_data)

    @patch.object(StravaClient, 'is_authenticated', return_value=True)
    def test_get_athlete_stats(self, mock_auth):
        """
        Test fetching athlete stats.
        """
        expected_stats = MagicMock()
        self.client.client.get_athlete_stats.return_value = expected_stats
        
        result = self.client.get_athlete_stats()
        
        self.client.client.get_athlete_stats.assert_called_once()
        self.assertEqual(result, expected_stats)

    @patch.object(StravaClient, 'is_authenticated', return_value=True)
    def test_get_athlete_zones(self, mock_auth):
        """
        Test fetching athlete zones".
        """
        expected_zones = MagicMock()
        self.client.client.get_athlete_zones.return_value = expected_zones
        
        result = self.client.get_athlete_zones()
        
        self.client.client.get_athlete_zones.assert_called_once()
        self.assertEqual(result, expected_zones)

    @patch.object(StravaClient, 'is_authenticated', return_value=True)
    def test_get_activities_success(self, mock_auth):
        """
        Test fetching activities successfully.
        """
        activities = [MagicMock(), MagicMock()]
        self.client.client.get_activities.return_value = activities
        
        result = self.client.get_activities(limit=10, after=datetime.now())
        
        self.client.client.get_activities.assert_called_once()
        self.assertEqual(result, activities)

    @patch.object(StravaClient, 'is_authenticated', return_value=True)
    def test_get_activities_error(self, mock_auth):
        """
        Test error handling when fetching activities.
        """
        self.client.client.get_activities.side_effect = Exception("API Error")
        
        result = self.client.get_activities()
        
        self.assertIsNone(result)

    @patch.object(StravaClient, 'is_authenticated', return_value=True)
    def test_get_detailed_activity(self, mock_auth):
        """
        Test fetching detailed activity.
        """
        activity = MagicMock()
        activity.id = 12345
        detailed = MagicMock()
        self.client.client.get_activity.return_value = detailed
        
        result = self.client.get_detailed_activity(activity)
        
        self.client.client.get_activity.assert_called_once_with(12345)
        self.assertEqual(result, detailed)

    @patch.object(StravaClient, 'check_refresh', return_value=True)
    def test_is_authenticated_with_valid_token(self, mock_check):
        """
        Test is_authenticated with valid token.
        """
        result = self.client.is_authenticated()
        self.assertTrue(result)

    @patch.object(StravaClient, 'check_refresh', return_value=False)
    @patch.object(StravaClient, 'refresh_token', return_value=True)
    def test_is_authenticated_refresh_token(self, mock_refresh, mock_check):
        """
        Test is_authenticated with refresh.
        """
        result = self.client.is_authenticated()
        self.assertTrue(result)
        mock_refresh.assert_called_once()
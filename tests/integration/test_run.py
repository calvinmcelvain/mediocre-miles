"""
Contains the integration test for run.py
"""
import unittest
import argparse
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock

import run


class TestRun(unittest.TestCase):
    
    @patch('run.LoggerManager')
    @patch('run.StravaClient')
    @patch('run.DataProcessor')
    def setUp(self, mock_processor_class, mock_client_class, mock_logger_manager):
        self.mock_logger = MagicMock()
        self.mock_logger_manager = MagicMock()
        mock_logger_manager.return_value = self.mock_logger_manager
        
        self.mock_client = MagicMock()
        mock_client_class.return_value = self.mock_client
        
        self.mock_processor = MagicMock()
        mock_processor_class.return_value = self.mock_processor
        
        self.mock_log = MagicMock()
        self.patcher = patch('logging.getLogger')
        mock_get_logger = self.patcher.start()
        mock_get_logger.return_value = self.mock_log
    
    def tearDown(self):
        self.patcher.stop()
    
    def test_assrt_complete_process_success(self):
        """
        Test asserting complete process with success.
        """
        try:
            run.assrt_complete_process("complete")
            passed = True
        except AssertionError:
            passed = False
        
        self.assertTrue(passed)
    
    def test_assrt_complete_process_failure(self):
        """
        Test asserting complete process with failure.
        """
        with self.assertRaises(AssertionError):
            run.assrt_complete_process("error")
    
    @patch('run.argparse.ArgumentParser.parse_args')
    @patch('run.get_date_n_days_ago')
    def test_main_with_days_arg(self, mock_get_date, mock_parse_args):
        """
        Test main function with days argument.
        """
        mock_args = argparse.Namespace(
            days=7, all=False, detailed=False, zones=False, 
            athlete_stats=False, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        date_7_days_ago = datetime.now() - timedelta(days=7)
        mock_get_date.return_value = date_7_days_ago
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        
        run.main()
        
        self.mock_client.get_activities.assert_called_once_with(
            after=date_7_days_ago, before=None
        )
        self.mock_processor.update_activities.assert_called_once()
    
    @patch('run.argparse.ArgumentParser.parse_args')
    def test_main_with_all_arg(self, mock_parse_args):
        """
        Test main function with all argument.
        """
        mock_args = argparse.Namespace(
            days=None, all=True, detailed=False, zones=False, 
            athlete_stats=False, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        
        run.main()
        
        self.mock_client.get_activities.assert_called_once_with(
            after=None, before=None
        )
        self.mock_processor.update_activities.assert_called_once()
    
    @patch('run.argparse.ArgumentParser.parse_args')
    def test_main_with_latest_activity(self, mock_parse_args):
        """
        Test main function using latest activity date.
        """
        mock_args = argparse.Namespace(
            days=None, all=False, detailed=False, zones=False, 
            athlete_stats=False, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        latest_date = datetime(2023, 1, 1, 12, 0, 0)
        self.mock_processor.get_latest_activity_date.return_value = latest_date
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        
        run.main()
        
        expected_after = latest_date - timedelta(hours=1)
        self.mock_client.get_activities.assert_called_once_with(
            after=expected_after, before=None
        )
        self.mock_processor.update_activities.assert_called_once()
    
    @patch('run.argparse.ArgumentParser.parse_args')
    def test_main_with_zones_arg(self, mock_parse_args):
        """
        Test main function with zones argument.
        """
        mock_args = argparse.Namespace(
            days=None, all=True, detailed=False, zones=True, 
            athlete_stats=False, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        self.mock_processor.update_zones.return_value = "complete"
        
        run.main()
        
        self.mock_client.get_athlete_zones.assert_called_once()
        self.mock_processor.update_zones.assert_called_once()
    
    @patch('run.argparse.ArgumentParser.parse_args')
    def test_main_with_athlete_stats_arg(self, mock_parse_args):
        """
        Test main function with athlete_stats argument.
        """
        mock_args = argparse.Namespace(
            days=None, all=True, detailed=False, zones=False, 
            athlete_stats=True, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        self.mock_processor.update_stats.return_value = "complete"
        
        run.main()
        
        self.mock_client.get_athlete_stats.assert_called_once()
        self.mock_processor.update_stats.assert_called_once()
    
    @patch('run.argparse.ArgumentParser.parse_args')
    @patch('run.tqdm')
    def test_main_with_detailed_arg(self, mock_tqdm, mock_parse_args):
        """
        Test main function with detailed argument.
        """
        mock_args = argparse.Namespace(
            days=None, all=True, detailed=True, zones=False, 
            athlete_stats=False, before=None, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        activities = [MagicMock(), MagicMock()]
        self.mock_client.get_activities.return_value = activities
        self.mock_processor.update_activities.return_value = "complete"
        
        mock_tqdm.return_value = activities
        
        run.main()
        
        self.assertEqual(self.mock_client.get_detailed_activity.call_count, 2)
        self.assertEqual(self.mock_processor.update_activities.call_count, 3)
    
    @patch('run.argparse.ArgumentParser.parse_args')
    def test_main_with_before_arg(self, mock_parse_args):
        """
        Test main function with before argument.
        """
        before_date_str = "2023-01-15"
        before_date = datetime.strptime(before_date_str, '%Y-%m-%d')
        
        mock_args = argparse.Namespace(
            days=None, all=True, detailed=False, zones=False, 
            athlete_stats=False, before=before_date_str, no_wait=False
        )
        mock_parse_args.return_value = mock_args
        
        self.mock_client.get_activities.return_value = [MagicMock()]
        self.mock_processor.update_activities.return_value = "complete"
        
        run.main()
        
        self.mock_client.get_activities.assert_called_once_with(
            after=None, before=before_date)
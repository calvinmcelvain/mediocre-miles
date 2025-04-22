# built-in.
from datetime import datetime
from typing import List

# third-party.
import pandas as pd
from src.mediocremiles.models.activity import ActivityModel



class ActivityProcessor:
    @staticmethod
    def activities_to_dataframe(activities: List[ActivityModel]) -> pd.DataFrame:
        data = [{
            'id': a.id,
            'name': a.name,
            'type': a.type,
            'date': a.start_date,
            'day_of_week': a.start_date.strftime('%A'),
            'distance_km': a.distance_km,
            'moving_time_min': a.moving_time_minutes,
            'elapsed_time_min': a.elapsed_time_minutes,
            'elevation_gain_m': a.total_elevation_gain,
            'avg_speed_kmh': a.average_speed_kmh,
            'max_speed_kmh': a.max_speed_kmh,
            'avg_heartrate': a.average_heartrate,
            'max_heartrate': a.max_heartrate,
            'kudos_count': a.kudos_count
        } for a in activities]
        
        df = pd.DataFrame(data)
        # Add derived time columns
        if not df.empty:
            df['week'] = df['date'].dt.isocalendar().week
            df['month'] = df['date'].dt.month
            df['year'] = df['date'].dt.year
            df['day'] = df['date'].dt.day
        
        return df
    
    @staticmethod
    def calculate_weekly_summary(df: pd.DataFrame) -> pd.DataFrame:
        if df.empty:
            return pd.DataFrame()
            
        weekly = df.copy()
        
        summary = weekly.groupby(['year', 'week']).agg({
            'distance_km': 'sum',
            'moving_time_min': 'sum',
            'elevation_gain_m': 'sum',
            'id': 'count'
        }).reset_index()
        
        def get_week_start(row):
            year, week = row['year'], row['week']
            first_day = datetime.fromisocalendar(year, week, 1)
            return first_day
            
        summary['week_start'] = summary.apply(get_week_start, axis=1)
        summary.rename(columns={'id': 'activity_count'}, inplace=True)
        
        return summary
    
    @staticmethod
    def activity_type_summary(df: pd.DataFrame) -> pd.DataFrame:
        if df.empty:
            return pd.DataFrame()
            
        return df.groupby('type').agg({
            'distance_km': 'sum',
            'moving_time_min': 'sum',
            'elevation_gain_m': 'sum',
            'id': 'count'
        }).reset_index().rename(columns={'id': 'count'})
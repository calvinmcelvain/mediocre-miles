"""
Useful functions.
"""
# built-in.
import logging
import json
from datetime import datetime, timedelta
from typing import Dict, Union, List, Any, TypeVar, Literal
from pathlib import Path

# third-party.
from dotenv import load_dotenv


log = logging.getLogger(__name__)


T = TypeVar("T")



def to_list(arg: Union[T, List[T]]) -> List[T]:
    """
    Returns listed arg.
    """
    if isinstance(arg, list):
        return arg
    return [arg]


def load_envs(env_path: Union[str, Path]) -> None:
    """
    Sets env vars. NOTE: Path starts at home dir.
    """
    env_path = Path().home().resolve() / env_path
    if env_path.exists():
        load_dotenv(env_path, override=True)
    else:
        log.warning(f"No environment file ({env_path}) found.")
    return None


def load_config(config: str = "config.json") -> Dict[str, Any]:
    """
    Loads JSON config file.
    """
    if not config.strip():
        raise ValueError("Config filename cannot be empty.")
    
    config_file = Path(config).resolve()
    try:
        with config_file.open("r") as file:
            return json.load(file)
    except FileNotFoundError:
        log.error(f"Configuration file not found: {config}")
        raise
    except json.JSONDecodeError as e:
        log.error(f"Error parsing JSON file '{config}': {e}")
        raise
    
    
def create_directories(paths: Union[List[Path], Path]) -> None:
    """
    Creates directory for path.
    """
    for path in to_list(paths):
        if path.is_file(): path = path.parent
        try:
            if not path.exists():
                path.mkdir(exist_ok=True, parents=True)
                log.info(f"Created directory: {path.as_posix()}")
        except Exception as e:
            log.error(f"Error creating directory '{path}': {e}")
            raise
    return None


def get_date_n_days_ago(days: int = 30) -> datetime:
    """
    Get datetime object for n days ago.
    """
    return datetime.now() - timedelta(days=days)


def convert_distance(
    meters: float, unit: Literal["m", "km", "mi", "ft", "inch"]) -> float:
    """
    Convert meters to kilometers, miles, and feet.
    """
    km = meters / 1000
    miles = meters *  0.00062137119223733
    feet = meters * 3.28083989501312
    
    factor = {
        "m": meters,
        "km": km,
        "mi": miles,
        "ft": feet,
        "inch": feet / 12
    }
    
    return factor[unit]


def convert_speed(
    meters_per_sec: float, unit: Literal["m", "km", "mi"]) -> float:
    """
    Convert meters/second to km/hour and miles/hour.
    """
    km_per_hour = meters_per_sec * 3.6
    miles_per_hour = meters_per_sec * 2.2369362920544
    
    factor = {
        "m": meters_per_sec,
        "km": km_per_hour,
        "mi": miles_per_hour
    }
    
    return factor[unit]


def c_to_f(celsius: float) -> float:
    """
    Converts celsius to fahrenheit.
    """
    return celsius * (9 / 5) + 32
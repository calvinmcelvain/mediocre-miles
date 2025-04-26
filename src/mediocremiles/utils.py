"""
Useful functions.
"""
import logging
import json
from datetime import datetime, timedelta
from typing import Dict, Union, List, Any, TypeVar, Literal, Type
from pathlib import Path

import pydantic

from dotenv import load_dotenv


log = logging.getLogger("app.utils")


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


def load_json(
    file_path: Union[str, Path], dumps: bool = False
) -> Union[str, Dict]:
    """
    Returns the JSON object (or string) from a JSON file.
    """
    try:
        json_data = json.loads(Path(file_path).read_text())
    except (json.JSONDecodeError, FileNotFoundError) as e:
        log.error(f"Error loading JSON from {file_path}: {e}")
        raise
    return json.dumps(json_data) if dumps else json_data


def validate_json(json_data: dict, schema: Type[T]) -> T:
    """
    Returns the object from json schema validation.
    """
    try:
        schema_obj = schema.model_validate(json_data)
        return schema_obj
    except pydantic.ValidationError as e:
        log.exception(
            f"Validation error for schema '{schema.__name__}': {e}\n"
            f"JSON data: {json.dumps(json_data, indent=2)}"
        )
    except Exception as e:
        log.error(f"Unexpected error in validate_json: {e}")
        raise


def load_json_n_validate(file_path: Union[str, Path], schema: Type[T]) -> T:
    """
    Loads json file and validates for schema.
    """
    try:
        json_data = load_json(file_path)
        return validate_json(json_data, schema)
    except FileNotFoundError:
        log.error(f"File not found: {file_path}")
        raise
    except json.JSONDecodeError as e:
        log.error(f"Error decoding JSON from file '{file_path}': {e}")
        raise
    except pydantic.ValidationError as e:
        log.error(f"Validation error for schema '{schema.__name__}': {e}")
        raise
    except Exception as e:
        log.error(f"Unexpected error in load_json_n_validate: {e}")
        raise


def load_config(config: str = "config.json") -> Dict[str, Any]:
    """
    Loads JSON config file.
    """
    if not config.strip():
        raise ValueError("Config filename cannot be empty.")
    
    config_file = Path(config).resolve()
    return load_json(config_file)


def write_json(file_path: Union[str, Path], data: dict, indent: int = 4) -> None:
    """
    Write JSON data to a file at the given path.
    """
    try:
        path = Path(file_path)
        path.parent.mkdir(exist_ok=True, parents=True)
        path.write_text(json.dumps(data, indent=indent))
    except TypeError as e:
        log.error(f"Error serializing JSON data: {e}")
        raise
    except Exception as e:
        log.error(f"Error writing JSON to file '{file_path}': {e}")
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
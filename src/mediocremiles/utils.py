"""
Useful functions.
"""
# built-in.
import json
from datetime import datetime, timedelta
from typing import Dict, Union, List, Any, TypeVar
from pathlib import Path

# third-party.
from dotenv import load_dotenv


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
        print(f"No environment file ({env_path}) found.")
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
        print(f"Configuration file not found: {config}")
        raise
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON file '{config}': {e}")
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
                print(f"Created directory: {path.as_posix()}")
        except Exception as e:
            print(f"Error creating directory '{path}': {e}")
            raise
    return None


def get_date_n_days_ago(days: int = 30) -> datetime:
    """
    Get datetime object for n days ago.
    """
    return datetime.now() - timedelta(days=days)
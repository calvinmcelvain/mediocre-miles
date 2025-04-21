"""
Genetal useful functions.
"""
import os
import json
import logging
from typing import Dict, Union
from pathlib import Path
from dotenv import load_dotenv


log = logging.getLogger("app")




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


def load_config(config: str = "config.json") -> Dict:
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
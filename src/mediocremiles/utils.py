"""
Genetal useful functions.
"""
# built-in.
import json
import logging
from typing import Dict, Union
from pathlib import Path

# third-party.
from dotenv import load_dotenv
from flask import current_app


log = logging.getLogger(__name__)




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
    
    
def create_directory(path: Path) -> None:
    """
    Creates directory for path.
    """
    try:
        if not path.exists():
            path.mkdir(exist_ok=True, parents=True)
            if current_app:
                current_app.logger.info(f"PATH: Created directory: {path.as_posix()}")
        else:
            if current_app:
                current_app.logger.info(f"PATH: Path exists: {path.as_posix()}")
    except Exception as e:
        log.error(f"Error creating directory '{path}': {e}")
        raise
    return None
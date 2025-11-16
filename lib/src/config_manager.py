"""
Configuration manager for hyprchrp
Handles loading, saving, and managing application settings
"""

import json
from pathlib import Path
from typing import Any, Dict


class ConfigManager:
    """Manages application configuration and settings"""

    def __init__(self):
        # Default configuration values - minimal set for hyprchrp
        self.default_config = {
            'primary_shortcut': 'Ctrl+Shift',  # Default primary shortcut
            'stt_backend': 'parakeet',  # "whisper" or "parakeet"
            'model': 'base',
            'parakeet_model': 'nemo-parakeet-tdt-0.6b-v3',  # Default Parakeet model
            'parakeet_model_path': None,  # Custom path override for Parakeet models
            'parakeet_use_quantized': False,  # Use int8 quantized models (faster, less accurate)
            'threads': 4,  # Thread count for whisper processing
            # Language code (None = auto-detect, or 'en', 'nl', 'fr', etc.)
            'language': None,
            # Dictionary of word replacements: {"original": "replacement"}
            'word_overrides': {},
            'whisper_prompt': (
                'Transcribe with proper capitalization, including sentence beginnings, '
                'proper nouns, titles, and standard English capitalization rules.'
            ),
            # Boolean: true = clear clipboard after delay, false = keep current behavior
            'clipboard_behavior': False,
            # Float seconds before clearing clipboard (used only if clipboard_behavior is true)
            'clipboard_clear_delay': 5.0,
            # Values: "super" | "ctrl_shift" | "ctrl"; default aligns with Super+V on Omarchy
            'paste_mode': 'super',
            # Back-compat for older configs (used only if paste_mode is absent):
            'shift_paste': True  # true = Ctrl+Shift+V, false = Ctrl+V
        }

        # Set up config directory and file path
        self.config_dir = Path.home() / '.config' / 'hyprchrp'
        self.config_file = self.config_dir / 'config.json'

        # Current configuration (starts with defaults)
        self.config = self.default_config.copy()

        # Ensure config directory exists
        self._ensure_config_dir()

        # Load existing configuration
        self._load_config()

    def _ensure_config_dir(self):
        """Ensure the configuration directory exists"""
        try:
            self.config_dir.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            try:
                from .logger import log_warning
                log_warning(f"Could not create config directory: {e}", "CONFIG")
            except ImportError:
                print(f"Warning: Could not create config directory: {e}")

    def _load_config(self):
        """Load configuration from file"""
        try:
            if self.config_file.exists():
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)

                # Merge loaded config with defaults (preserving any new default keys)
                self.config.update(loaded_config)
                print(f"Configuration loaded from {self.config_file}")
            else:
                print("No existing configuration found, using defaults")
                # Save default configuration
                self.save_config()

        except Exception as e:
            print(f"Warning: Could not load configuration: {e}")
            print("Using default configuration")

    def save_config(self) -> bool:
        """Save current configuration to file"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2)
            print(f"Configuration saved to {self.config_file}")
            return True
        except Exception as e:
            print(f"Error: Could not save configuration: {e}")
            return False

    def get_setting(self, key: str, default: Any = None) -> Any:
        """Get a configuration setting"""
        return self.config.get(key, default)

    def set_setting(self, key: str, value: Any):
        """Set a configuration setting"""
        self.config[key] = value

    def get_all_settings(self) -> Dict[str, Any]:
        """Get all configuration settings"""
        return self.config.copy()

    def reset_to_defaults(self):
        """Reset configuration to default values"""
        self.config = self.default_config.copy()
        print("Configuration reset to defaults")

    def get_temp_directory(self) -> Path:
        """Get the temporary directory for audio files"""
        # Use user-writable temp directory instead of system installation directory
        temp_dir = Path.home() / '.local' / 'share' / 'hyprchrp' / 'temp'
        temp_dir.mkdir(parents=True, exist_ok=True)
        return temp_dir

    def get_word_overrides(self) -> Dict[str, str]:
        """Get the word overrides dictionary"""
        return self.config.get('word_overrides', {}).copy()

    def add_word_override(self, original: str, replacement: str):
        """Add or update a word override"""
        if 'word_overrides' not in self.config:
            self.config['word_overrides'] = {}
        self.config['word_overrides'][original.lower().strip()] = replacement.strip()

    def remove_word_override(self, original: str):
        """Remove a word override"""
        if 'word_overrides' in self.config:
            self.config['word_overrides'].pop(original.lower().strip(), None)

    def clear_word_overrides(self):
        """Clear all word overrides"""
        self.config['word_overrides'] = {}

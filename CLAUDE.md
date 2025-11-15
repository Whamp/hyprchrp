# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**hyprwhspr** is a native speech-to-text application for Arch Linux/Omarchy with Hyprland desktop environment. It now offers dual backends: Parakeet TDT v3 via ONNX-ASR (CPU-only, Whisper-large-level accuracy) and OpenAI's Whisper via pywhispercpp (with optional CUDA/ROCm/Vulkan acceleration).

**Key Features:**
- Global hotkey dictation (Super+Alt+D by default)
- Hot model loading via pywhispercpp backend
- CPU-only Parakeet backend powered by onnx-asr + ONNX Runtime
- GPU acceleration support (Whisper backend)
- Configurable STT backend selection (`stt_backend`: `parakeet` or `whisper`)
- Waybar integration
- Audio feedback
- Text injection into any application
- Word overrides and custom prompts
- Automatic punctuation/symbol conversion

## Common Development Commands

### Installation & Setup
```bash
# Full installation for Omarchy/Arch
./scripts/install-omarchy.sh

# Only install/update systemd services
./scripts/install-services.sh

# Test service configuration
./scripts/test-services.sh

# Fix uinput permissions
/usr/lib/hyprwhspr/scripts/fix-uinput-permissions.sh
```

### Running the Application
```bash
# Via systemd service (recommended)
systemctl --user start hyprwhspr.service
systemctl --user stop hyprwhspr.service
systemctl --user restart hyprwhspr.service
systemctl --user status hyprwhspr.service

# View logs
journalctl --user -u hyprwhspr.service -f
journalctl --user -u ydotool.service -f

# Direct execution (development)
./bin/hyprwhspr

# Or directly with Python
source ~/.local/share/hyprwhspr/venv/bin/activate
python3 lib/main.py
```

### Dependencies
Python dependencies are managed via `requirements.txt`:
- **Audio processing:** sounddevice, numpy, scipy
- **Global shortcuts:** evdev, pyperclip
- **Whisper integration:** pywhispercpp (v1.3.3)
- **Parakeet integration:** onnxruntime (>=1.15.0), onnx-asr (>=0.7.0)
- **System integration:** psutil, rich

Dependencies are installed into a user-space virtual environment at `~/.local/share/hyprwhspr/venv/`.

### Service Management
The application uses two systemd services:
- **hyprwhspr.service** - Main application with auto-restart
- **ydotool.service** - Input injection daemon

Both are user-level services (no root required).

## Architecture

### Directory Structure
```
/home/will/Applications/hyprwhspr
├── bin/hyprwhspr                    # Main launcher script
├── lib/
│   ├── main.py                      # Entry point, application orchestrator
│   └── src/                         # Core modules
│       ├── config_manager.py        # Configuration management (JSON-based)
│       ├── whisper_manager.py       # Speech-to-text via pywhispercpp
│       ├── parakeet_manager.py      # Speech-to-text via onnx-asr Parakeet TDT v3
│       ├── stt_backend.py           # Abstract interface for STT engines
│       ├── stt_backend_factory.py   # Chooses backend (Parakeet vs Whisper)
│       ├── audio_capture.py         # Audio recording from microphone
│       ├── audio_manager.py         # Audio feedback (start/stop sounds)
│       ├── audio_utils.py           # Shared audio helpers (WAV writes for Parakeet)
│       ├── text_injector.py         # Text injection into applications
│       ├── global_shortcuts.py      # Global keyboard shortcuts (evdev)
│       └── logger.py                # Logging utilities
├── scripts/
│   ├── install-omarchy.sh           # Main installation script
│   ├── install-services.sh          # Systemd service setup
│   ├── test-services.sh             # Service testing
│   └── fix-uinput-permissions.sh    # Permission fix
├── config/                          # Configuration templates
│   ├── hyprland/                    # Hyprland/Waybar integration
│   ├── systemd/                     # Systemd service templates
│   └── waybar/                      # Waybar module files
├── share/assets/                    # Sound files and resources
└── requirements.txt                 # Python dependencies
```

### Core Application Flow

**Entry Point:** `lib/main.py` - `hyprwhsprApp` class

1. **Initialization:**
   - `ConfigManager` - Loads config from `~/.config/hyprwhspr/config.json`
   - `AudioCapture` - Sets up audio device for recording
   - `AudioManager` - Configures audio feedback sounds
   - `STTBackendFactory` - Creates either `ParakeetManager` (ONNX-ASR) or `WhisperManager` (pywhispercpp) based on `stt_backend`
   - `TextInjector` - Sets up text injection mechanism
   - `GlobalShortcuts` - Registers global hotkey (default: Super+Alt+D)

2. **Runtime Flow:**
   - User presses hotkey → `_on_shortcut_triggered()`
   - If not recording → `_start_recording()` → audio feedback → start capture
   - If recording → `_stop_recording()` → audio feedback → process audio
   - `_process_audio()` → Active STT backend (Parakeet or Whisper) transcribes → `_inject_text()` → paste

3. **System Integration:**
   - **Audio:** Uses `sounddevice` for capture, 16kHz sample rate
   - **Shortcuts:** Uses `evdev` for global keyboard monitoring
   - **Text Injection:** Clipboard-based with configurable paste method
   - **Model Loading:** `ParakeetManager` streams audio via temp WAV files into onnx-asr, while `WhisperManager` keeps models hot in memory through pywhispercpp
   - **Acceleration:** Parakeet is CPU-only via ONNX Runtime; Whisper can leverage CUDA/ROCm/Vulkan or fall back to CPU

### Configuration System

**Location:** `~/.config/hyprwhspr/config.json`

**Key Settings:**
- `primary_shortcut` - Global hotkey (format: "SUPER+ALT+D")
- `stt_backend` - Selects STT engine (`"whisper"` or `"parakeet"`; defaults to Whisper for backward compatibility)
- `model` - Whisper model name ("base", "small", "medium", "large", etc.)
- `parakeet_model` - Parakeet TDT v3 model alias (default `nemo-parakeet-tdt-0.6b-v3`)
- `parakeet_model_path` - Optional path override if users manually manage ONNX files
- `parakeet_use_quantized` - Boolean flag to request the `-int8` Parakeet build
- `threads` - CPU thread count for processing
- `language` - Language code (null for auto-detect)
- `word_overrides` - Dictionary of word replacements
- `whisper_prompt` - Transcription prompt/guidance
- `paste_mode` - "super" | "ctrl_shift" | "ctrl"
- `clipboard_behavior` - Auto-clear clipboard after injection
- `audio_feedback` - Enable/disable sound notifications

**Defaults** are defined in `config_manager.py:16-30`. The `threads` value directly affects Whisper; Parakeet stores the value for future ONNX Runtime reloads but live behavior is governed by ONNX Runtime itself.

### Service Architecture

**Systemd Services** are defined in `config/systemd/`:

**hyprwhspr.service:**
- Runs the main Python application
- User-level service
- Restarts on failure
- Depends on ydotool.service

**ydotool.service:**
- Runs ydotool daemon for input injection
- User-level service
- Required for text injection functionality

Both services are started automatically on login if enabled.

### Waybar Integration

**Files:** `config/waybar/hyprwhspr-style.css`, `config/hyprland/hyprwhspr-tray.sh`

The tray script `hyprwhspr-tray.sh` provides:
- Status monitoring (reads from `~/.config/hyprwhspr/recording_status`)
- Start/stop/toggle operations via systemd
- Waybar JSON output for dynamic icon display

Click interactions:
- Left-click: Toggle dictation
- Right-click: Start (if not running)
- Middle-click: Restart service

## Installation Details

**Installation Directory:** `/usr/lib/hyprwhspr/` (read-only system files)
**User Data:** `~/.local/share/hyprwhspr/` (Python venv, runtime data)
**Config:** `~/.config/hyprwhspr/` (user configuration)
**Models:** `~/.local/share/pywhispercpp/models/` (Whisper model files)

**Installation Process** (`scripts/install-omarchy.sh:1-200`):
1. Detects actual user (supports sudo usage)
2. Creates directory structure
3. Copies system files to `/usr/lib/hyprwhspr/`
4. Sets up Python venv in user space
5. Installs pywhispercpp backend
6. Downloads base Whisper model
7. Configures systemd services
8. Sets up Waybar integration
9. Runs health checks

**Models:** Default model is `ggml-base.en.bin` (~148MB). GPU models (large, large-v3) require NVIDIA CUDA or AMD ROCm.

## Text Injection System

**Mechanism:** Clipboard-based with configurable paste methods:

1. **Super Mode (default):** Copies text to clipboard, sends Super+V
2. **Ctrl+Shift Mode:** Copies to clipboard, sends Ctrl+Shift+V
3. **Ctrl Mode:** Copies to clipboard, sends Ctrl+V

**Punctuation Replacement:** Automatic conversion of spoken punctuation to symbols (e.g., "period" → ".", "comma" → ",") - defined in `text_injector.py`.

**Clipboard Management:** Configurable auto-clear after delay via `clipboard_behavior` setting.

## Development Notes

- **No test suite:** The project doesn't include automated tests
- **No build system:** Uses simple Python script execution, no setup.py or pyproject.toml
- **Single entry point:** All functionality flows through `lib/main.py`
- **Dual STT backends:** `STTBackendFactory` instantiates either `WhisperManager` (pywhispercpp) or `ParakeetManager` (onnx-asr); implement `STTBackend` to add new engines
- **Hot model loading:** Whisper backend keeps models resident via pywhispercpp; Parakeet streams audio through temp WAV files into onnx-asr/ONNX Runtime
- **Event-driven:** Based on global shortcut events, not a GUI loop
- **State tracking:** Simple booleans for recording/processing state
- **No logging file:** Uses console output, logs via `logger.py` module
- **Configuration-driven:** Behavior primarily controlled via config.json
- **Backend smoke tests:** `scripts/test-parakeet.py` loads the Parakeet model through onnx-asr for quick verification

## Troubleshooting Resources

- Service status: `systemctl --user status hyprwhspr.service ydotool.service`
- Service logs: `journalctl --user -u hyprwhspr.service -f`
- Audio devices: `pactl list short sources`
- Whisper model files: `ls -la ~/.local/share/pywhispercpp/models/`
- Parakeet model bundle (manual install path): `ls -la ~/.local/share/hyprwhspr/models/parakeet/`
- Config file: `cat ~/.config/hyprwhspr/config.json`
- Health check: `/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh health`

## External Dependencies

**System-level (installed by installer):**
- ydotool - Input injection daemon
- PipeWire/PulseAudio - Audio system
- systemd - Service management

**Python (in requirements.txt):**
- pywhispercpp (1.3.3) - Whisper backend with hot model loading
- onnxruntime (>=1.15.0) - ONNX Runtime execution provider for Parakeet backend
- onnx-asr (>=0.7.0) - High-level ASR wrapper for Parakeet TDT v3
- sounddevice - Audio capture
- evdev - Global keyboard shortcuts
- pyperclip - Clipboard access
- numpy, scipy - Audio processing
- psutil - System utilities
- rich - Terminal formatting

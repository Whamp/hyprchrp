# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**hyprchrp** is a native speech-to-text application for Arch Linux/Omarchy with Hyprland desktop environment. It now offers dual backends: Parakeet TDT v3 via ONNX-ASR (CPU-only, Whisper-large-level accuracy) and OpenAI's Whisper via pywhispercpp (with optional CUDA/ROCm/Vulkan acceleration).

> HyprChrp is a fork of hyprwhspr, modernized to make the Parakeet V3 ONNX backend first-class while still shipping the full Whisper + pywhispercpp workflow.

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
/usr/lib/hyprchrp/scripts/fix-uinput-permissions.sh
```

### Running the Application
```bash
# Via systemd service (recommended)
systemctl --user start hyprchrp.service
systemctl --user stop hyprchrp.service
systemctl --user restart hyprchrp.service
systemctl --user status hyprchrp.service

# View logs
journalctl --user -u hyprchrp.service -f
journalctl --user -u ydotool.service -f

# Direct execution (development)
./bin/hyprchrp

# Or directly with mise
mise exec -- python3 lib/main.py
```

### Dependencies

**Production Dependencies** (`requirements.txt`):
- **Audio processing:** sounddevice, numpy, scipy
- **Global shortcuts:** evdev, pyperclip
- **Whisper integration:** pywhispercpp (v1.3.3)
- **Parakeet integration:** onnxruntime (>=1.15.0), onnx-asr (>=0.7.0)
- **System integration:** psutil, rich

**Development Dependencies** (managed via mise, optional uv enhancement):
- **Testing:** pytest, pytest-cov
- **Code quality:** black, ruff, mypy
- **Development tools:** pre-commit

**Dependency Management:**
- **Development**: Managed via mise (Python 3.13.8) with optional uv for faster dependency management
- **Production**: `requirements.txt` generated from mise/uv development environment
- **Installation**: Production dependencies installed into user-space venv at `~/.local/share/hyprchrp/venv/` (created with mise Python)

### Service Management
The application uses two systemd services:
- **hyprchrp.service** - Main application with auto-restart
- **ydotool.service** - Input injection daemon

Both are user-level services (no root required).

## Development Workflow

### Developer Setup (mise-first)

This project uses **mise** for Python version management and execution. **uv** is optional for enhanced dependency management. End users never need to install these tools - they're only used during development.

**mise is guaranteed on Omarchy systems** - no installation needed.

**Developer Setup**
```bash
# Initial developer setup (one-time)
./scripts/dev-setup.sh

# mise-first development commands
mise run hyprchrp                   # Run the application
mise run test                      # Run tests
mise run lint                      # Lint code
mise run format                    # Format code
mise run type-check                # Type checking
mise run sync-prod                 # Sync production requirements

# mise shortcuts
mise run r                          # Run hyprchrp
mise run t                          # Test
mise run l                          # Lint
mise run f                          # Format

# Direct mise exec
mise exec -- python lib/main.py    # Run the application
mise exec -- pytest                # Run tests
mise exec -- black .               # Format code
mise exec -- ruff check .          # Lint code
```

**Enhanced Workflow (with optional uv)**
```bash
# uv provides faster dependency management (optional)
uv run python lib/main.py          # Run hyprchrp (faster)
uv run pytest                      # Run tests (faster)
uv run black .                     # Format code (faster)
uv add new-package                 # Add dependency
./scripts/sync-production.sh       # Update production requirements
```

### Production Sync Workflow

After making changes to dependencies in development, sync to production:

```bash
# Generate production artifacts from uv development environment
./scripts/sync-production.sh

# This creates:
# - requirements.txt        - Production dependencies (pip-compatible)
# - requirements-dev.txt    - Development dependencies (for reference)
# - dependency-tree.txt     - Dependency tree documentation
```

### Project Structure

```
hyprchrp/
├── .mise.toml                   # mise configuration (Python version management + tasks)
├── pyproject.toml              # Project configuration
├── requirements.txt            # Production dependencies (for end users)
├── scripts/
│   ├── dev-setup.sh           # Developer environment setup (mise-first)
│   ├── sync-production.sh     # Generate production requirements
│   └── update-deps.sh         # Dependency management helper
├── bin/hyprchrp                # Legacy launcher script (backwards compatibility)
├── config/systemd/hyprchrp.service # systemd service (mise exec)
└── [existing files...]
```

### Key Benefits

**For Developers:**
- **mise-first workflow**: Consistent Python environment management across Omarchy
- **Simple setup**: Single tool (mise) handles Python version and execution
- **Optional uv enhancement**: Faster dependency management when available
- **Modern tooling**: Clean mise task-based workflow
- **IDE integration**: Perfect Python environment detection

**For End Users:**
- **Zero changes**: Same installation process and commands
- **No development tools required**: Users never need uv or mise
- **Automatic Python version control**: mise ensures compatible Python 3.13.8
- **Faster installs**: Production uses mise-optimized requirements
- **Reliable execution**: Proven pip/venv approach with mise-managed Python

**Workflow:**
1. **Development**: Use mise-first workflow (uv optional for speed)
2. **CI/CD**: Run `sync-production.sh` before releases
3. **Production**: Users install using traditional pip/venv with mise-managed Python
4. **Maintenance**: Update deps in dev, sync to production automatically

**Omarchy Advantages:**
- **Guaranteed mise**: All Omarchy systems have mise pre-installed
- **Consistent environments**: Same Python version across all installations
- **Simplified debugging**: Single source of truth for Python management
- **Future-proof**: Easy Python version transitions
- **Reduced complexity**: No fallback code or system Python detection

## Architecture

### Directory Structure
```
/home/will/Applications/hyprchrp
├── bin/hyprchrp                    # Main launcher script
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

**Entry Point:** `lib/main.py` - `hyprchrpApp` class

1. **Initialization:**
   - `ConfigManager` - Loads config from `~/.config/hyprchrp/config.json`
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

**Location:** `~/.config/hyprchrp/config.json`

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

### Service Architecture

**Systemd Services** are defined in `config/systemd/`:

**hyprchrp.service:**
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

**Files:** `config/waybar/hyprchrp-style.css`, `config/hyprland/hyprchrp-tray.sh`

The tray script `hyprchrp-tray.sh` provides:
- Status monitoring (reads from `~/.config/hyprchrp/recording_status`)
- Start/stop/toggle operations via systemd
- Waybar JSON output for dynamic icon display

Click interactions:
- Left-click: Toggle dictation
- Right-click: Start (if not running)
- Middle-click: Restart service

## Installation Details

**Installation Directory:** `/usr/lib/hyprchrp/` (read-only system files)
**User Data:** `~/.local/share/hyprchrp/` (Python venv, runtime data)
**Config:** `~/.config/hyprchrp/` (user configuration)
**Models:** `~/.local/share/pywhispercpp/models/` (Whisper model files)

**Installation Process** (`scripts/install-omarchy.sh:1-200`):
1. Detects actual user (supports sudo usage)
2. Creates directory structure
3. Copies system files to `/usr/lib/hyprchrp/`
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

- Service status: `systemctl --user status hyprchrp.service ydotool.service`
- Service logs: `journalctl --user -u hyprchrp.service -f`
- Audio devices: `pactl list short sources`
- Whisper model files: `ls -la ~/.local/share/pywhispercpp/models/`
- Parakeet model bundle (manual install path): `ls -la ~/.local/share/hyprchrp/models/parakeet/`
- Config file: `cat ~/.config/hyprchrp/config.json`
- Health check: `/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh health`

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

## Troubleshooting

### Python Version Issues

**Problem**: Installation fails with Python version errors or dependency installation failures.

**Solution**: On Omarchy, mise should handle Python automatically. If issues occur:

```bash
# Verify mise is working (should be pre-installed on Omarchy)
mise --version
mise where python@3.13.8

# Re-run installation (mise should install correct Python automatically)
./scripts/install-omarchy.sh

# If mise is not working on your Omarchy system:
curl https://mise.run | sh
source ~/.bashrc
mise install python@3.13.8
./scripts/install-omarchy.sh
```

**Check Python environment:**
```bash
# Check mise Python installation
mise exec -- python --version

# Verify correct Python version (should be 3.13.8)
mise exec -- python -c "import sys; print(sys.version)"

# Check what the installer will use
./scripts/install-omarchy.sh --check
```

### mise Issues

**Problem**: mise commands not working or Python installation fails.

**Solution:**
```bash
# Ensure mise is available (should be on Omarchy)
command -v mise || { echo "mise missing - this shouldn't happen on Omarchy"; exit 1; }

# Reset mise Python installation
mise uninstall python@3.13.8
mise install python@3.13.8

# Verify mise setup
mise where python@3.13.8
mise exec -- python --version
```

### Development Environment Issues

**Problem**: mise tasks not working after dev-setup.

**Solution:**
```bash
# Verify mise is properly activated
mise run hyprchrp --version 2>/dev/null || {
    echo "mise not properly activated"
    eval "$(mise activate bash)"
    mise run hyprchrp --version
}

# Re-run setup
./scripts/dev-setup.sh

# Try direct mise exec
mise exec -- python lib/main.py --version
```

### Service Issues

**Problem**: systemd service fails to start with mise errors.

**Solution:**
```bash
# Check mise availability for systemd
systemctl --user status hyprchrp.service
journalctl --user -u hyprchrp.service -f

# Test mise exec directly
/usr/bin/mise exec -- python /usr/lib/hyprchrp/lib/main.py --version

# If mise is not available to systemd, fall back to traditional launcher:
# The bin/hyprchrp script still works as a fallback
```

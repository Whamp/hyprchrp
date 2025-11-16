<h1 align="center">
    hyprchrp
</h1>

<p align="center">
    <b>Native speech-to-text for Arch / Omarchy</b> - Fast, accurate and easy system-wide dictation with parakeet V3
</p>

<p align="center">
all local | waybar integration | audio feedback | auto-paste | cpu-first Parakeet | optional gpu
</p>

---

- **Optimized for Arch Linux / Omarchy** - Seamless integration with [Omarchy](https://omarchy.org/) / [Hyprland](https://github.com/hyprwm/Hyprland) & [Waybar](https://github.com/Alexays/Waybar)
- **Parakeet V3 (CPU-only)** - Whisper-large-level accuracy on plain CPUs via [ONNX-ASR](https://github.com/istvank/onnx-asr) + ONNX Runtime (no GPU needed)
- **Dual backends (Parakeet or Whisper)** - Choose Parakeet for zero-GPU installs or [OpenAI's Whisper](https://github.com/openai/whisper) via pywhispercpp when you want CUDA/ROCm/Vulkan acceleration
- **Cross-platform GPU support (Whisper backend)** - Automatic detection and acceleration for NVIDIA (CUDA) / AMD (ROCm) when you opt into Whisper
- **Hot model loading** - pywhispercpp backend keeps models in memory for _fast_ transcription
- **Word overrides** - Customize transcriptions, prompt and corrections
- **Run as user** - Runs in user space, just sudo once for the installer

> 🔐 **PRIVATE**: hyprchrp is local and never reads any clipboard / audio content 

> ℹ️ **Fork note:** hyprchrp is a hard fork of the original hyprwhspr project, layering Parakeet V3 ONNX-ASR support on top of the existing Whisper + pywhispercpp stack.

## Quick start

### Prerequisites

- **[Omarchy](https://omarchy.org/)** or **[Arch Linux](https://archlinux.org/)**
- **No discrete GPU required** – Parakeet V3 runs entirely on CPU via ONNX Runtime
- **NVIDIA GPU** (optional, for CUDA acceleration when using the Whisper backend)
- **AMD GPU** (optional, for ROCm acceleration when using the Whisper backend)

### Installation

"Just works" with Omarchy.

```bash
# Clone the repository
git clone https://github.com/Whamp/hyprchrp.git
cd hyprchrp

# Run the automated installer
./scripts/install-omarchy.sh
```

**The installer will:**

1. ✅ Install system dependencies (ydotool, etc.)
2. ✅ Copy application files to system directory (`/usr/lib/hyprchrp`)
3. ✅ Set up mise-managed Python environment (Python 3.13.8)
4. ✅ Install pywhispercpp backend
5. ✅ Download base model to user space (`~/.local/share/pywhispercpp/models/ggml-base.en.bin`)
6. ✅ Set up systemd services for hyprchrp & ydotool (uses `mise exec` directly)
7. ✅ Configure Waybar integration
8. ✅ Test everything works

### First use

> Ensure your microphone of choice is available in audio settings!

1. **Log out and back in** (for group permissions)
2. **Press `Super+Alt+D`** to start dictation - _beep!_
3. **Speak naturally**
4. **Press `Super+Alt+D`** again to stop dictation - _boop!_
5. **Bam!** Text appears in active buffer!

Any snags, please [create an issue](https://github.com/Whamp/hyprchrp/issues/new/choose) or visit [Omarchy Discord](https://discord.com/channels/1390012484194275541/1410373168765468774).

## Development Setup

hyprchrp uses a **mise-first** development workflow. On Omarchy systems, mise is pre-installed and handles Python version management automatically.

### Quick Development Setup

```bash
# Clone the repository
git clone https://github.com/Whamp/hyprchrp.git
cd hyprchrp

# One-time development environment setup
./scripts/dev-setup.sh

# Run during development
mise run hyprchrp          # Run the application
mise run test             # Run tests
mise run lint             # Lint code
mise run format           # Format code
mise run type-check       # Type checking
mise run sync-prod        # Sync production requirements
```

### Development Commands

**mise-first workflow:**
```bash
mise run hyprchrp          # Run hyprchrp (main app)
mise run test             # Run tests
mise run lint             # Lint code with ruff
mise run format           # Format code with black
mise run type-check       # Type checking with mypy

# Shortcuts
mise run r                 # Run hyprchrp
mise run t                 # Test
mise run l                 # Lint
mise run f                 # Format

# Direct mise exec
mise exec -- python lib/main.py
mise exec -- pytest
mise exec -- black .
```

**Enhanced workflow (optional uv):**
```bash
# uv provides faster dependency management (optional enhancement)
uv run python lib/main.py   # Run hyprchrp (faster)
uv run pytest               # Run tests (faster)
uv add new-package          # Add dependency
```

### Architecture Notes

- **mise-first**: All Python version management handled by mise
- **Optional uv**: Enhanced dependency management when available
- **Production**: Users install with traditional pip/venv - no development tools needed
- **Consistent**: Same Python 3.13.8 across all Omarchy installations

## Usage

### Toggle-able global hotkey

- **`Super+Alt+D`** - Toggle dictation on/off

## Configuration

Edit `~/.config/hyprchrp/config.json`:

**Minimal config** - only the essentials:

```jsonc
{
    "primary_shortcut": "SUPER+ALT+D",
    "stt_backend": "parakeet",        // "parakeet" (CPU-only) or "whisper"
    "model": "base.en",              // Whisper backend model (ignored by Parakeet)
    "parakeet_model": "nemo-parakeet-tdt-0.6b-v3"
}
```

> `model` controls the Whisper backend, while `parakeet_model` controls the Parakeet backend. For Whisper model choices, see [model instructions](https://github.com/Whamp/hyprchrp/tree/main?tab=readme-ov-file#whisper-models).

### Parakeet configuration

```jsonc
{
    "stt_backend": "parakeet",
    "parakeet_model": "nemo-parakeet-tdt-0.6b-v3",   // Default CPU-only model (auto-downloads ~3.2 GB)
    "parakeet_model_path": null,                      // Optional custom directory with encoder/decoder/vocab files
    "parakeet_use_quantized": false                   // true -> use "-int8" quantized model for lower RAM/CPU
}
```

- **`parakeet_model`** – symbolic model name handled by `onnx-asr`. Leave at default to auto-download.
- **`parakeet_model_path`** – point to a local folder if you manually manage ONNX files (encoder, decoder, vocab).
- **`parakeet_use_quantized`** – appends `-int8` to the model name for a smaller quantized build (minor accuracy tradeoff).

Set `stt_backend` to `"parakeet"` to make the ONNX-ASR backend the default; omit or set to `"whisper"` if you prefer the pywhispercpp path.

**Custom hotkey** - extensive key support:

```json
{
    "primary_shortcut": "CTRL+SHIFT+SPACE"
}
```

Supported key types:

- **Modifiers**: `ctrl`, `alt`, `shift`, `super` (left) or `rctrl`, `ralt`, `rshift`, `rsuper` (right)
- **Function keys**: `f1` through `f24`
- **Letters**: `a` through `z`
- **Numbers**: `1` through `9`, `0`
- **Arrow keys**: `up`, `down`, `left`, `right`
- **Special keys**: `enter`, `space`, `tab`, `esc`, `backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`
- **Lock keys**: `capslock`, `numlock`, `scrolllock`
- **Media keys**: `mute`, `volumeup`, `volumedown`, `play`, `nextsong`, `previoussong`
- **Numpad**: `kp0` through `kp9`, `kpenter`, `kpplus`, `kpminus`

Or use direct evdev key names for any key not in the alias list:

```json
{
    "primary_shortcut": "SUPER+KEY_COMMA"
}
```

Examples:

- `"SUPER+SHIFT+M"` - Super + Shift + M
- `"CTRL+ALT+F1"` - Ctrl + Alt + F1
- `"F12"` - Just F12 (no modifier)
- `"RCTRL+RSHIFT+ENTER"` - Right Ctrl + Right Shift + Enter

**Word overrides** - customize transcriptions:

```json
{
    "word_overrides": {
        "hyperwhisper": "hyprchrp",
        "omarchie": "Omarchy"
    }
}
```

**Whisper prompt** - customize transcription behavior:

```json
{
    "whisper_prompt": "Transcribe with proper capitalization, including sentence beginnings, proper nouns, titles, and standard English capitalization rules."
}
```

The prompt influences how Whisper interprets and transcribes your audio, eg:

- `"Transcribe as technical documentation with proper capitalization, acronyms and technical terminology."`

- `"Transcribe as casual conversation with natural speech patterns."`
  
- `"Transcribe as an ornery pirate on the cusp of scurvy."`

**Audio feedback** - optional sound notifications:

```jsonc
{
    "audio_feedback": true,            // Enable audio feedback (default: false)
    "start_sound_volume": 0.3,        // Start recording sound volume (0.1 to 1.0)
    "stop_sound_volume": 0.3,         // Stop recording sound volume (0.1 to 1.0)
    "start_sound_path": "custom-start.ogg",  // Custom start sound (relative to assets)
    "stop_sound_path": "custom-stop.ogg"     // Custom stop sound (relative to assets)
}
```

**Default sounds included:**

- **Start recording**: `ping-up.ogg` (ascending tone)
- **Stop recording**: `ping-down.ogg` (descending tone)

**Custom sounds:**

- **Supported formats**: `.ogg`, `.wav`, `.mp3`
- **Fallback**: Uses defaults if custom files don't exist

_Thanks for [the sounds](https://github.com/akx/Notifications), @akx!_

**Text replacement:** Automatically converts spoken words to symbols / punctuation:

**Punctuation:**

- "period" → "."
- "comma" → ","
- "question mark" → "?"
- "exclamation mark" → "!"
- "colon" → ":"
- "semicolon" → ";"

**Symbols:**

- "at symbol" → "@"
- "hash" → "#"
- "plus" → "+"
- "equals" → "="
- "dash" → "-"
- "underscore" → "_"

**Brackets:**

- "open paren" → "("
- "close paren" → ")"
- "open bracket" → "["
- "close bracket" → "]"
- "open brace" → "{"
- "close brace" → "}"

**Special commands:**

- "new line" → new line
- "tab" → tab character

_Speech-to-text replacement list via [WhisperTux](https://github.com/cjams/whispertux), thanks @cjams!_

**Clipboard behavior** - control what happens to clipboard after text injection:

```jsonc
{
    "clipboard_behavior": false,       // Boolean: true = clear after delay, false = keep (default: false)
    "clipboard_clear_delay": 5.0      // Float: seconds to wait before clearing (default: 5.0, only used if clipboard_behavior is true)
}
```

- **`clipboard_behavior: true`** - Clipboard is automatically cleared after the specified delay
- **`clipboard_clear_delay`** - How long to wait before clearing (only matters when `clipboard_behavior` is `true`)

**Paste behavior** - control how text is pasted into applications:

```jsonc
{
    "paste_mode": "super"   // "super" | "ctrl_shift" | "ctrl"  (default: "super")
}
```

**Paste behavior options:**

- **`"super"`** (default) — Sends Super+V. Omarchy default.

- **`"ctrl_shift"`** — Sends Ctrl+Shift+V. Works in most terminals.

- **`"ctrl"`** — Sends Ctrl+V. Standard GUI paste.

**Add dynamic tray icon** to your `~/.config/waybar/config`:

```json
{
    "custom/hyprchrp": {
        "exec": "/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh status",
        "interval": 2,
        "return-type": "json",
        "exec-on-event": true,
        "format": "{}",
        "on-click": "/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh toggle",
        "on-click-right": "/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh start",
        "on-click-middle": "/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh restart",
        "tooltip": true
    }
}
```

**Add CSS styling** to your `~/.config/waybar/style.css`:

```css
@import "/usr/lib/hyprchrp/config/waybar/hyprchrp-style.css";
```

**Waybar icon click interactions**:

- **Left-click**: Toggle Hyprwhspr on/off
- **Right-click**: Start Hyprwhspr (if not running)
- **Middle-click**: Restart Hyprwhspr

**CPU performance options** - improve cpu transcription speed:

```jsonc
{
    "threads": 4            // thread count for whisper cpu processing
}
```

Increase for more CPU parallelism when using CPU; on GPU, modest values are fine.

> Parakeet uses ONNX Runtime under the hood; the `threads` value is stored for future reloads, but runtime behavior may still be governed by ONNX Runtime's own scheduling.

## Speech backends: Parakeet (CPU) vs Whisper (GPU-capable)

hyprchrp now supports two interchangeable speech-to-text engines via the `stt_backend` setting:

- **Parakeet V3 (recommended, CPU-only):** Uses [`onnx-asr`](https://github.com/istvank/onnx-asr) with ONNX Runtime to run the `nemo-parakeet-tdt-0.6b-v3` model at Whisper-large-level accuracy on plain CPUs. First run downloads ~3.2 GB automatically, or you can point to a local model folder. Great when you want top-tier accuracy without a GPU.
- **Whisper (pywhispercpp, GPU-capable):** Uses [`pywhispercpp`](https://github.com/abdeladim-s/pywhispercpp) for classic Whisper models (`tiny` → `large`), optionally accelerating with CUDA/ROCm/Vulkan when detected. Ideal if you already rely on Whisper models or have GPUs handy.

Select the backend explicitly in your config:

```jsonc
{
    "stt_backend": "parakeet",          // "parakeet" for ONNX-ASR or "whisper" for pywhispercpp
    "parakeet_model": "nemo-parakeet-tdt-0.6b-v3",
    "model": "base"                     // Still used when the Whisper backend is active
}
```

If `stt_backend` is omitted, hyprchrp falls back to `"whisper"` for backward compatibility—set it to `"parakeet"` to enjoy the new CPU-only backend by default.

## Parakeet V3 (ONNX-ASR, CPU-only)

- **Default model:** `nemo-parakeet-tdt-0.6b-v3` (~3.2 GB). Automatically downloaded by `onnx-asr` on first use.
- **Manual install option:** Download from [Hugging Face](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx) and place `encoder-model.onnx`, `decoder_joint-model.onnx`, and `vocab.txt` under `~/.local/share/hyprchrp/models/parakeet/`, then set `parakeet_model_path` to that directory.
- **Quantized builds:** Set `"parakeet_use_quantized": true` to use the `-int8` variant for lower RAM/CPU footprint.
- **Smoke test:** `python3 scripts/test-parakeet.py` loads the model via onnx-asr and runs a quick recognition pass against `2086-149220-0033.wav`.

## Whisper Models 

> This section applies when `"stt_backend"` is set to `"whisper"`.

**Default model installed:** `ggml-base.en.bin` (~148MB) to `~/.local/share/pywhispercpp/models/`

**GPU Acceleration (NVIDIA & AMD):**

- NVIDIA (CUDA) and AMD (ROCm) are detected automatically; pywhispercpp will use GPU when available
- No manual build steps required. 
    - If toolchains are present, installer can build pywhispercpp with GPU support; otherwise CPU wheel is used.

**Available models to download:**

- **`tiny`** - Fastest, good for real-time dictation
- **`base`** - Best balance of speed/accuracy (recommended)
- **`small`** - Better accuracy, still fast
- **`medium`** - High accuracy, slower processing
- **`large`** - Best accuracy, **requires GPU acceleration** for reasonable speed
- **`large-v3`** - Latest large model, **requires GPU acceleration** for reasonable speed

**⚠️ GPU required:** Models `large` and `large-v3` require GPU acceleration to perform. 

```bash
cd ~/.local/share/pywhispercpp/models/

# Tiny models (fastest, least accurate)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin

# Base models (good balance)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin

# Small models (better accuracy)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin

# Medium models (high accuracy)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin

# Large models (best accuracy, requires GPU)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin
```

**Update your config after downloading:**

```jsonc
{
    "model": "small.en" // Or just small if multi-lingual model. If both available, general model is chosen.
}
```

**Language detection** - control transcription language:

English only speakers use `.en` models which are smaller.

For multi-language detection, ensure you select a model which does not say `.en`:

```jsonc
{
    "language": null // null = auto-detect (default), or specify language code
}
```

Language options:
- **`null`** (default) - Auto-detect language from audio
- **`"en"`** - English transcription
- **`"nl"`** - Dutch transcription  
- **`"fr"`** - French transcription
- **`"de"`** - German transcription
- **`"es"`** - Spanish transcription
- **`etc.`** - Any supported language code

Prefer top-tier accuracy without a GPU? Jump back to [Parakeet V3 (ONNX-ASR, CPU-only)](#parakeet-v3-onnx-asr-cpu-only) to enable the CPU backend instead.

## Troubleshooting

### Reset Installation

If you're having persistent issues, you can completely reset hyprchrp:

```bash
# Stop services
systemctl --user stop hyprchrp ydotool

# Remove runtime data
rm -rf ~/.local/share/hyprchrp/

# Remove user config
rm -rf ~/.config/hyprchrp/

# Remove system files
sudo rm -rf /usr/lib/hyprchrp/
```

And then...

```bash
# Then reinstall fresh
./scripts/install-omarchy.sh
```

### Common issues

**I heard the sound, but don't see text!** 

It's fairly common in Arch and other distros for the microphone to need to be plugged in and set each time you log in and out of your session, including during a restart. Within sound options, ensure that the microphone is indeed set. The sound utility will show feedback from the microphone if it is.

**Hotkey not working:**

```bash
# Check service status for hyprchrp
systemctl --user status hyprchrp.service

# Check logs
journalctl --user -u hyprchrp.service -f
```

```bash
# Check service statusr for ydotool
systemctl --user status ydotool.service

# Check logs
journalctl --user -u ydotool.service -f
```

**Permission denied:**

```bash
# Fix uinput permissions
/usr/lib/hyprchrp/scripts/fix-uinput-permissions.sh

# Log out and back in
```

**No audio input:**

If your mic _actually_ available?

```bash
# Check audio devices
pactl list short sources

# Restart PipeWire
systemctl --user restart pipewire
```

**Audio feedback not working:**

```bash
# Check if audio feedback is enabled in config
cat ~/.config/hyprchrp/config.json | grep audio_feedback

# Verify sound files exist
ls -la /usr/lib/hyprchrp/share/assets/

# Check if ffplay/aplay/paplay is available
which ffplay aplay paplay
```

**Model not found:**

```bash
# Check if model exists
ls -la ~/.local/share/pywhispercpp/models/

# Download a different model
cd ~/.local/share/pywhispercpp/models/
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin

# Verify model path in config
cat ~/.config/hyprchrp/config.json | grep model
```

**Parakeet model not found / onnx-asr errors:**

```bash
# Ensure dependencies are installed (installer handles this)
pip install --upgrade onnx-asr onnxruntime

# Verify manual model files if you set parakeet_model_path
ls ~/.local/share/hyprchrp/models/parakeet/

# Download the official bundle if files are missing
xdg-open https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx
```

- Confirm `parakeet_model_path` points at the folder containing `encoder-model.onnx`, `decoder_joint-model.onnx`, and `vocab.txt`.
- Remove the directory to force `onnx-asr` to re-download if the cache is corrupted.

**Stuck recording state:**

```bash
# Check service health and auto-recover
/usr/lib/hyprchrp/config/hyprland/hyprchrp-tray.sh health

# Manual restart if needed
systemctl --user restart hyprchrp.service

# Check service status
systemctl --user status hyprchrp.service
```

## Architecture

**hyprchrp is designed as a system package:**

- **`/usr/lib/hyprchrp/`** - Main installation directory
- **`/usr/lib/hyprchrp/lib/`** - Python application
- **`~/.local/share/pywhispercpp/models/`** - Whisper models (user space)
- **`~/.config/hyprchrp/`** - User configuration
- **`~/.config/systemd/user/`** - Systemd service

### Systemd integration

**hyprchrp uses systemd for reliable service management with mise-first execution:**

- **`hyprchrp.service`** - Main application service (uses `mise exec -- python3` directly)
- **`ydotool.service`** - Input injection daemon service
- **Tray integration** - All tray operations use systemd commands
- **Process management** - No manual process killing or starting
- **Service dependencies** - Proper startup/shutdown ordering
- **mise-first execution** - systemd service runs `mise exec -- python3` for consistent Python environment

## Getting help

1. **Check logs**: `journalctl --user -u hyprchrp.service` `journalctl --user -u ydotool.service`
2. **Verify permissions**: Run the permissions fix script
3. **Test components**: Check ydotool, audio devices, whisper.cpp
4. **Report issues**: [Create an issue](https://github.com/Whamp/hyprchrp/issues/new/choose) or visit [Omarchy Discord](https://discord.com/channels/1390012484194275541/1410373168765468774) - logging info helpful!

## License

MIT License - see [LICENSE](LICENSE) file.


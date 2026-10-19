# Hashcat Studio Pro // Spatial Offensive Security Tool

<div align="center">

![Engine](https://img.shields.io/badge/Unreal_Engine-5.8.3_Linux-0E1128?logo=unrealengine)
![Vulkan](https://img.shields.io/badge/Vulkan-SM5_Native-red?logo=vulkan)
![Hardware](https://img.shields.io/badge/GPU_Cluster-4x_AMD_MI25_(64GB)-blue)
![Platform](https://img.shields.io/badge/OS-Linux_NUMA_0,1-orange?logo=linux)
![Languages](https://img.shields.io/badge/Languages-BG_%F0%9F%87%A7%F0%9F%87%AC_%7C_EN_%F0%9F%87%AC%F0%9F%87%A7-brightgreen)

**Next-Generation Spatial Operations & Cryptanalytic Intelligence Environment**  
Built natively on **Unreal Engine 5.8 (Linux Vulkan SM5)**, engineered for multi-GPU compute orchestration with diegetic Cyberpunk 2077 Breach Protocol interfaces.

</div>

---

## ⚡ Executive Summary

**Hashcat Studio Pro** is an immersive spatial operations deck and cryptographic terminal environment. Migrated from initial Godot 4 prototypes to high-performance **Unreal Engine 5.8 (Linux Vulkan)**, it bridges real-world cryptanalytic compute hardware (4x AMD Instinct MI25 compute units with 64GB HBM2 VRAM, ROCm architecture) with an intuitive first-person spatial interface, live wall telemetry, and full remote automation.

---

## 🚀 Key Features & Architecture

### 1. HUD & Settings Subsystem (`WBP_SettingsMenu`)
- **Centralized Subsystem Daemons**:
  - `01 // DISPLAY & RESOLUTION`: Live resolution matrix switching (1080p FHD, 1440p 2K, 4K UHD, 720p HD) and instant Fullscreen / Windowed display modes via native `UGameUserSettings`.
  - `02 // GRAPHICS & RENDER`: Scalability presets (Low 66%, Medium 75%, High 100%, Epic Max Quality) with live render scale feedback and framerate limits (60 FPS, 120 FPS, Uncapped).
  - `03 // CONTROLS & BINDINGS`: Dynamic Mouse Look Sensitivity slider (0.1x to 3.0x) and customizable operator keybindings.
  - `04 // AUDIO & CALIBRATION`: Master audio output level calibration and volume controls.
- **Multilingual Support (BG 🇧🇬 / EN 🇬🇧)**:
  - Instant in-game language toggle button (`Btn_LangToggle`) located directly in the Cyberpunk Top Header bar.
  - Dynamically updates all 56+ labels, daemon titles, section descriptions, live indicators, and buttons across both Bulgarian and English without restarting the engine.

### 2. First-Person Operator
- Clean, tactile operator movement with tactical sprint, jumping, and crouch navigation.
- Invisible high-precision interaction trace with zero intrusive laser debug artifacts.
- Atmospheric dual-language terminal telemetry prompts (BG/EN More will be added).

### 3. Compute Infrastructure & Hardware Orchestration
- **Hardware Architecture**: 4x AMD Instinct MI25 GPUs (Vega 10, 16GB HBM2 each, total 64GB VRAM) running under ROCm with Linux NUMA balancing (`--cpunodebind=0,1 --interleave=all`).
- **Telemetry System: Diegetic real-time wall screens tracking live GPU core temperatures, package wattage draw, compute hash rates, and attack dictionary progress.

---

## 🎮 Controls & Key Bindings

| Action | Primary Binding | Description |
| :--- | :---: | :--- |
| **Move Forward** | `W` | Operator navigation (forward) |
| **Move Backward** | `S` | Operator navigation (backward) |
| **Move Left / Strafe** | `A` | Operator navigation (left) |
| **Move Right / Strafe** | `D` | Operator navigation (right) |
| **Jump** | `SPACE` | Jump & obstacle clearance |
| **Tactical Sprint** | `LEFT SHIFT` | High-speed operator sprint |
| **Interact / Scan** | `E` / `LMB` | Terminal & rig interaction |
| **Settings / Menu** | `ESC` / `M` | Toggle Breach Settings Protocol |
| **Language Toggle** | `Click Button` | Switch between Bulgarian & English |

---

## 🛠️ Project Structure

```
hashcat-studio/
├── Config/                     # Unreal Engine Project Configurations
│   ├── DefaultEngine.ini       # Vulkan SM5 renderer & game viewport settings
│   ├── DefaultGame.ini         # Project identity & metadata
│   ├── DefaultInput.ini        # Input mappings & axis bindings
│   └── ...
├── Content/                    # Core UAsset Blueprints, Maps & UI
│   ├── BP_operator.uasset      # Operator character controller & interaction
│   ├── WBP_SettingsMenu.uasset # Cyberpunk Breach Protocol Settings UI
│   ├── GM_HashcatStudioPro     # Game Mode & spatial rules
│   ├── BP_WallTelemetry.uasset # Diegetic live GPU/Hashcat wall displays
│   ├── BP_UltronCore.uasset    # Holographic core engine actor
│   └── Python/                 # Editor automation scripts
├── Tools/                      # Automation & Remote Bridge Tooling
│   ├── ue_mcp.py               # Model Context Protocol bridge for UE5
│   ├── run_ue_py.py            # Headless UE python command runner
│   ├── wire_language_switcher  # Blueprint localization wiring pipeline
│   └── ...
├── HashcatStudio.uproject    # Unreal Engine 5.8 Project Descriptor
└── README.md                   # System documentation
```

---

## 💻 Launching & Development

### Requirements
- **Unreal Engine 5.8+** (Linux x86_64 build)
- **Vulkan SM5** drivers (`vulkan-tools`, ROCm/AMDGPU Pro drivers)
- **Python 3.10+** (with `unreal` module enabled in Editor settings)

### Launching Standalone Game
```bash
numactl --cpunodebind=0,1 --interleave=all \
  /path/to/UnrealEditor \
  /path/to/hashcat-studio/HashcatStudio.uproject \
  -game -vulkan -sm5 -ResX=1920 -ResY=1080 -WinX=0 -WinY=0 -log
```

---

## 📜 License & Credits

Developed by **The Puppeteer**  
All rights reserved © 2026 Hashcat Studio Pro.

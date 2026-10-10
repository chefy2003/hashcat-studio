# Master Context: Hashcat Intelligence Studio

## 1. Architectural Vision
`Hashcat Intelligence Studio` is an intuitive, high-performance desktop interface built in **Godot 4** (Vulkan Forward+) with a **C++ GDExtension** backend. It simplifies Hashcat's complex CLI flags through **Dynamic Operator Data Sampling** (contextualizing rules and masks using real operator data) and features an **Emergency Kill Circuit Breaker** (`SIGKILL`/`SIGTERM`).

## 2. Component Triad
- `Master_Context.md`: Architectural Blueprint and Vision.
- `Implementation-Plan.md`: Task checklist and roadmap.
- `Debug_Playbook.md`: Database of empirical fixes and debugging records.

## 3. Tech Stack & Integration
- **Frontend:** Godot 4.x Control UI, Custom Dark Neofuturistic Theme.
- **Backend Bridge:** C++ GDExtension (`libhashcat_bridge.so`) with POSIX Async PTY/Pipe execution.
- **Core Feature:** Real-Time Data Sampling & Contextual Command Intelligence.

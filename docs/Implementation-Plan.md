# Implementation Plan: Hashcat Intelligence Studio (v1.0)

This plan outlines the structured development phases for building the Godot 4 + C++ GDExtension Hashcat GUI.

---

## Phase 1: Project Scaffolding & Directory Setup
- [ ] Create Godot 4 project configuration (`project.godot`) in `/home/deliriumxs/.gemini/antigravity/scratch/hashcat-studio`.
- [ ] Set up C++ GDExtension build environment (`SConstruct` or `CMakeLists.txt` + `godot-cpp` bindings).
- [ ] Initialize git repository and `.gitignore`.

---

## Phase 2: C++ GDExtension Async Process Bridge (`libhashcat_bridge.so`)
- [ ] Build `HashcatBridge` GDExtension class extending `Node` or `RefCounted`.
- [ ] Implement POSIX subprocess launcher (`posix_openpt` / `fork` / `popen`) for asynchronous `hashcat` execution.
- [ ] Implement non-blocking `stdout` and `stderr` reader thread.
- [ ] Implement regex/string parser for Hashcat status lines (Speed H/s, ETA, Temp, Progress, Password Cracked).
- [ ] Expose Godot signals: `signal hashcat_status_updated`, `signal password_cracked`, `signal process_exited`.
- [ ] Implement Emergency Stop handler: `SIGKILL` / `SIGTERM` circuit breaker to release GPUs instantly.

---

## Phase 3: Dynamic Operator Data Sampling Engine
- [ ] Build file reader utility to sample top $N$ lines from operator's target hash file and dictionary files.
- [ ] Build Rule & Mask Candidate Simulation Engine (demonstrates rule transformation e.g. `-j 'c'` on actual dictionary sample words).
- [ ] Implement time and permutation estimation calculator based on GPU hashrate.

---

## Phase 4: Godot 4 Cyberpunk UI & Layout
- [ ] Implement Main Window layout (`Control` nodes, Theme, Custom Fonts/Colors).
- [ ] Build **Top Header:** Status indicators & Emergency Stop Button.
- [ ] Build **Left Panel:** Smart Presets Library & Dynamic Suggestion Cards.
- [ ] Build **Center Panel:** Attack Configurator, Interactive CLI Command Preview Chips, and Dynamic Example Explanations.
- [ ] Build **Right / Bottom Panel:** Real-time Hashrate Chart & Live Telemetry Inspector.

---

## Phase 5: Verification & Integration Testing
- [ ] Unit test C++ GDExtension process launching and Emergency Stop circuit breaker.
- [ ] Test Hashcat output parsing against real/mock hash execution.
- [ ] Verify zero UI frame drops during heavy output streaming.

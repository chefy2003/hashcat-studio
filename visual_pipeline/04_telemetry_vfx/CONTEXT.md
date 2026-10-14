# Phase 04: Telemetry VFX Contract

## Role
Connects Hashcat cracking activity and hardware sensor data (temperature, fan, load) to real-time visual FX.

## Inputs
- Signals from `Dashboard3DController`, `HashcatBridge`, and `HardwareInspector`

## Process
1. Server rack hardware blades:
   - Dynamic per-GPU LED arrays (4x AMD Instinct MI25 + CPU node).
   - Color grading per card state (Idle: emerald green; Cracking: energetic cyan/amber; Alert: neon crimson).
2. Energy conduits:
   - Pulsing emissive data packets streaming along floor cable conduits during active hashing.
3. GPU particle field:
   - GPUParticles3D data dust replacing CPU particles for silky 60+ FPS floating ambient motes with turbulence.

## Outputs
- `gpu_activity_leds.gd`
- Upgraded `energy_conduit_3d.gd` & `hashrate_visualizer_3d.gd`

## Human Check
- Do LED indicators illuminate and pulse in sync with cracking speed updates?
- Do energy pulses travel from server rack -> core -> terminal?

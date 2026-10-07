# Test 02: prop aircraft (MSFS SimConnect / X-Plane datarefs)

## Setup

- `ObjectDescriptor`: `type = aircraft`, `primary = true`, 1 × `propeller`
  drive point (`PropellerSpec`: diameter, blades), 3 × `wheel` drive points
  (landing gear — `SuspensionSpec` fits gear travel/stiffness/damping)
- Annex channels: `engine.throttle`, `engine.running`, `fuel.level`,
`fuel.rate`, `lights.headlights` (landing light)

## Core mapping

| Game field | LTS destination | Class |
|---|---|---|
| lat/lon/alt, local x/y/z (X-Plane OpenGL RH Z-up) | `position` (geodetic→local tangent + axis remap at sender) | direct |
| pitch/roll/heading (MSFS Euler) / `position/q` (X-Plane quaternion) | `orientation` | direct |
| VELOCITY WORLD / `local_vx..` | `kinematics.velocity` | direct |
| ACCELERATION WORLD | `kinematics.acceleration` | direct |
| angular velocities (X-Plane R/P/Y rates) | derivable from orientation deltas (slerp derivative) | recipe |
| ENG RPM / PROP RPM | `PropellerState.rpm` | direct |
| throttle lever % | `engine.throttle` | annex |
| fuel flow / tank quantity | `fuel.rate` / `fuel.level` | annex |
| mixture, oil temp/pressure | `mixture.*`, `engine.oilTemp`… | custom channel |
| gear compression (X-Plane per-gear deflection) | `WheelState.compression` ×3 | direct |
| nose-gear steer angle | `WheelExtended.steerAngle` | direct |
| gear position 0..1 | `gear.down` | convention channel |
| aileron/elevator/rudder/flaps/spoilers | `ctrl.*` | convention channel |
| airspeed TAS/IAS, AoA, Mach | `air.*` | convention channel |
| ambient wind dir/vel | `wind.trueDirection` / `wind.trueSpeed` | convention channel |
| ambient temp/pressure/density | `environment` (discovery-static — acceptable: slowly varying) | direct |
| stall warning / G meter | `air.stall`, `air.gLoad` | custom channel |
| avionics/FMS state | — | out of scope (instrument emulation) |

## Gaps found

| # | Problem | Resolution |
|---|---|---|
| — | Control surfaces have no schema home | `ctrl.*` convention channels — they are object-level quantities, channels are the honest home; `air.*`/`ctrl.*` flagged as annex candidates (≥2-game evidence exists) |
| — | Per-tick wind vs discovery-static `environment` | `wind.*` convention channels — wind gusts are per-tick data; recorded in CHANNELS.md |
| — | Propeller pitch/thrust often unmeasured (fixed-pitch props, estimated thrust) | `PropellerState` gained the `core`/`extended` union (rpm always; pitch+thrust when measured) |

## Verdict

**Covers cleanly.** Gear-as-wheels works naturally (`SuspensionSpec` models
oleo travel/stiffness/damping); the conventions (`ctrl.*`, `wind.*`, `air.*`)
cover the flight-control surface area without schema bloat.

# Test 03: jet (DCS-style export semantics)

## Setup

- `ObjectDescriptor`: `type = aircraft`, `primary = true`, 1 × `jet` drive
  point, 3 × `wheel` drive points (gear legs)

## Core mapping

| Game field (DCS export) | LTS destination | Class |
|---|---|---|
| pitch/bank/heading (Euler) | `orientation` (Euler→quat + axis remap) | direct |
| world/body velocity | `kinematics.velocity` | direct |
| body-frame G (normal accel) | `kinematics.acceleration` (rotate via orientation) | recipe |
| throttle position 0..1 | `JetState.throttle` | direct |
| engine thrust | `JetState.thrust` (now optional — DCS exposes %RPM, not N) | direct |
| engine RPM % | `jet.rpmPct` (% — deliberately NOT `engine.rpm`, whose ratified unit is rpm; the annex rule holds) | custom channel |
| EGT / oil press/temp / afterburner | `engine.egt`, `engine.oilPressure`, `engine.afterburner` | custom channel |
| internal fuel % / kg | `fuel.level` / `fuel.mass` | annex / custom |
| gear legs up/down + compression | 3 × `WheelState` (`compression`; `gear.down` channel) | direct |
| nose-wheel steering | `WheelExtended.steerAngle` | direct |
| flaps / airbrake / speedbrake | `ctrl.flaps`, `ctrl.airbrake`, `ctrl.speedbrake` | convention channel |
| IAS / Mach / AoA | `air.*` | convention channel |
| nav/strobe/landing lights | `lights.*` (landing light ≈ `lights.headlights`) | annex/close |
| weapons, countermeasures, radar | — | out of scope (combat systems) |

## Gaps found

| # | Problem | Resolution |
|---|---|---|
| — | DCS-style games expose %RPM, not thrust in Newtons; a plain `thrust` field would force sentinels | `JetState.thrust` made optional via `noThrust`/`thrust` union (idle ≈ 0 N is a real value) |

## Verdict

**Covers cleanly.** The jet case exercises the same conventions as 02 with
zero new machinery; %RPM-vs-rpm is exactly what the annex unit rule exists
for.

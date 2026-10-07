# Test 01: race car (Assetto Corsa-style + iRacing-style)

Two representative sources: the AC shared-memory physics block and the
iRacing SDK variable set (semantics as publicly documented). Field names are
representative, not exhaustive; the goal is coverage classification.

## Setup (identical for both games)

- `ObjectDescriptor`: `type = vehicle`, `primary = true`, 4 × `wheel` drive
  points (`radius`, `driven`, `steered`, suspension `travel`/`stiffness`)
- Annex channels declared in discovery: `engine.rpm`, `engine.throttle`,
`engine.torque`, `transmission.gear`, `brakes.pedal`, `brakes.pressure`,
`steering.input`, `input.clutch`, `fuel.level`, `aids.abs`, `aids.tcs`

## Core mapping

| Game field (AC / iRacing) | LTS destination | Class |
|---|---|---|
| position / world coords | `position` (+ axis remap, see below) | direct |
| rotation matrix / Euler yaw-pitch-roll | `orientation` (matrix→quat / Euler→quat at sender) | direct |
| velocity (world, m/s) | `kinematics.velocity` | direct |
| acceleration | `kinematics.acceleration` (see G-forces note) | direct |
| rpm | `engine.rpm` | annex |
| gear | `transmission.gear` | annex |
| gas / throttle | `engine.throttle` | annex |
| brake input / brakeLinePress (kPa) | `brakes.pedal` / `brakes.pressure` (Pa) | annex |
| steer / steering position | `steering.input` | annex |
| clutch | `input.clutch` | annex |
| fuel | `fuel.level` | annex |
| tcEnabled / absEnabled | `aids.tcs` / `aids.abs` | annex |
| per-wheel rpm | `WheelState.rpm` ×4 | direct |
| per-wheel drive torque | `WheelState.torque` | direct |
| per-wheel slip ratio / slip angle | `WheelState.slip` | direct |
| suspension travel / deflection | `WheelState.compression` | direct |
| per-wheel brake pressure | `WheelState.brakePressure` | direct |
| car damage (AC array) | `damage.*` channels | custom channel |
| drs state | `aids.drs` | custom channel (annex candidate) |
| lap / position / lap time / session | — | out of scope (race state deferred by design) |

## Gaps found (all resolved in v1)

| # | Field | Resolution |
|---|---|---|
| G1 | per-wheel steering angle (AC `wheelAngl`) | `WheelExtended.steerAngle` (rad, + = left, ISO) |
| G2 | suspension force / tyre vertical load (AC `susForce`/`tyreLoad`) | `WheelExtended.loadForce` (N, measured, incl. damping) + `SuspensionSpec.damping` so receivers can approximate when unmeasured |
| G3 | tyre pressure / temps / wear (iRacing 3-temp patches, wear %) | `WheelExtended.tyrePressure`/`tyreTemp` (carcass/average; zone temps ride channels)/`tyreWear` (1 = new) |

All ride the all-or-neither `extended` union variant of `WheelState`
(per-wheel physics pages arrive whole or not at all; Cap'n Proto structs
allow only one unnamed union, so independent per-field optionals are not
expressible).

## Conversion recipes (sender-side integration cost, not gaps)

1. **Axis remap** — AC and iRacing world frames differ from LTS (LH,
   Z-forward, Y-up). Senders rotate position/velocity/acceleration and
   convert orientation (matrix or Euler → quaternion in the LTS frame).
   One-time per game, unit-testable.
2. **Local-frame Gs → world acceleration** — iRacing's `LatAccel/LongAccel/
   VertAccel` (and AC's `accG`) are body-frame. Convert via orientation;
   receivers who want body-frame specific force (classical washout input)
   compute it back from world accel + orientation + gravity — document this
   recipe for rig authors rather than carrying both conventions on the wire.
3. **Units** — brake kPa→Pa; fuel fraction→%; steering ratio→percent where a
   game reports an angle.

## Verdict

**Covers cleanly — zero open gaps after pre-release fixes (G1–G3 resolved
in v1).** Engine/transmission/inputs/per-wheel dynamics including extended
wheel data all land in schema fields or annex channels with zero
configuration for a conforming receiver. Wheel count is naturally variable
(list) — motorcycles (2) and 6-wheel trucks extend trivially.

# Validation: mapping known game telemetry to LTS v1

Method: take a game's *documented* telemetry output (field list + semantics)
and map every field to its LTS destination. Every field must land in exactly
one of:

| Class | Meaning |
|---|---|
| **direct** | a schema field (pose, drive-point state, kinematics) |
| **annex** | a ratified `CHANNELS.md` channel (auto-maps in receivers) |
| **custom channel** | a free-named channel — works, needs receiver config |
| **GAP** | no honest home — schema or annex change needed |

Gaps are graded: *deferred-safe* (fixable additively in v1.x without wire
breakage) vs *blocking* (must change before release). Conversion recipes the
sender must apply (axis remap, Euler→quaternion, unit changes) are recorded
per game — they are integration cost, not schema gaps, but frequent ones get
a documented recipe.

Results so far:

| Test | Domains | Verdict |
|---|---|---|
| [01-race-car.md](01-race-car.md) | AC-style + iRacing-style car | Covers cleanly — per-wheel dynamics incl. extended data land in `WheelState` |
| [02-prop-aircraft.md](02-prop-aircraft.md) | MSFS SimConnect + X-Plane datarefs | Covers — gear as wheels; `ctrl.*`/`wind.*`/`air.*` channel families |
| [03-jet.md](03-jet.md) | DCS-style export | Covers — optional thrust; %RPM as its own channel |
| [04-sailboat.md](04-sailboat.md) | Sailaway-style | Covers — multi-sail via drive points; wind rides `wind.*` channels |
| [05-motorcycle.md](05-motorcycle.md) | GP Bikes-style | Covers cleanly — rider as second (`humanoid`) object |
| [06-drone-mech.md](06-drone-mech.md) | FPV sim / MAVLink-style + legged mech | Covers — multi-propeller objects; optional per-leg force |
| [07-elite-spacecraft.md](07-elite-spacecraft.md) | Elite Dangerous community memory offsets | Covers — `bodyDynamics` (accelerometer-class source); ship↔SRV primary switching; low-rate fused pose |
| [08-star-citizen.md](08-star-citizen.md) | Star Citizen / D-BOX (official, vendor-encapsulated) | Out of reach today — game→rig protocol closed; decoded-traffic scenario maps via `bodyDynamics` + impact channels |

Cross-domain results: every tested vehicle class maps to the two-layer
model using schema fields, annex channels, and channel families — no
dedicated drive-point variants beyond the ratified set. Recurring sender
recipes: axis remap, Euler→quaternion, local-frame G→world conversion,
geodetic→local tangent.

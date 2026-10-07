# Common Channels Annex

Status: informative annex to the LTS v1 schema. Channel names are *data*
carried in `ChannelDescriptor` — this annex has no schema or wire-format
impact. It ratifies well-known channel names **with required units** so
receivers can auto-map telemetry across games without per-game
configuration.

## For senders

- If a channel's concept matches a ratified name below, use the ratified
  name, type, and unit exactly (`engine.rpm` is `rpm` and a number).
- You MUST NOT reuse a ratified name with a different unit — that is a
  different channel; give it your own name.
- Concepts not covered: name freely (`boat.anchorDepth`, `mech.reactorHeat`).
  Anything recurring may be ratified later (see below).

## For receivers

Match **exactly** on the ratified name — never fuzzy-match or substring-match
ratified names. A channel whose name+unit match an annex entry can be bound
with zero configuration. For everything else, fall back to per-game profiles.
Discovery always carries the sender's name and unit, so this annex is a
semantic convenience, never a dependency.

## Ratification rules

1. The concept must exist in at least **two shipping games** (or clear
   equivalents across domains — e.g. `engine.rpm` for a car and a boat's
   propeller shaft).
2. Additions are pull requests to this file; OGSA reviews for name quality
   (lowercase, dotted hierarchy), unit sanity, and non-overlap.
3. Entries are never renamed or re-united — corrections supersede by adding
   a new name and noting the deprecation inline.

## Ratified channels (v1)

| Name | Type | Unit | Description |
|---|---|---|---|
| `engine.rpm` | number | `rpm` | Crankshaft / shaft revolutions per minute |
| `engine.throttle` | number | `%` | Driver throttle input, 0–100 |
| `engine.torque` | number | `Nm` | Current engine output torque |
| `engine.temperature` | number | `degC` | Coolant / motor temperature |
| `engine.running` | boolean | — | Engine/motor currently producing power |
| `transmission.gear` | number | — | −1 reverse, 0 neutral, 1…n forward |
| `vehicle.speed` | number | `m/s` | Speed over ground (display conversions are the receiver's job) |
| `brakes.pedal` | number | `%` | Driver brake input, 0–100 |
| `brakes.pressure` | number | `Pa` | Master cylinder brake pressure |
| `steering.input` | number | `%` | Driver steering input, −100 full left … +100 full right |
| `input.clutch` | number | `%` | Driver clutch input, 0–100 |
| `lights.headlights` | boolean | — | Headlights on |
| `lights.highBeam` | boolean | — | High beams on |
| `lights.wipers` | boolean | — | Wipers active |
| `lights.turnSignal` | number | — | −1 left, 0 none, 1 right |
| `aids.abs` | boolean | — | Anti-lock braking currently active |
| `aids.tcs` | boolean | — | Traction control currently active |
| `aids.esp` | boolean | — | Stability control currently active |
| `fuel.level` | number | `%` | Remaining fuel/energy, 0–100 |
| `fuel.rate` | number | `l/h` | Current consumption rate |

Deliberately out of scope for now: race state (`race.lap`,
`race.position`, lap timing) — recurring, but domain-specific enough to go
through the ratification process as a real first test of it.

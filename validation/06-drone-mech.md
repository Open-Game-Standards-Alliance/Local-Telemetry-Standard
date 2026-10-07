# Test 06: drone and mech (generic + legs + multi-propeller)

## Drone (FPV-sim / MAVLink-style)

- `ObjectDescriptor`: `type = aircraft`, 4 × `propeller` drive points
  (`PropellerSpec` from the model's prop geometry)
- position/attitude/velocity → pose + kinematics (MAVLink's local NED frame
  → LTS axis remap at sender)
- per-motor rpm → `PropellerState.rpm` ×4
- per-motor thrust (rarely measured in sims) → `PropellerExtended.thrust`
  when known, `core` variant otherwise — the optionality added in test 02
- battery → `fuel.level` (concept match)
- mode flags (angle/acro) → `flight.mode` text channel

## Mech (legged)

- `ObjectDescriptor`: `type = humanoid` or `other`, N × `leg` drive points
- pose → pose; footsteps → `LegState.contact` + `phase` (gait cycle 0..1)
- per-leg ground force → `LegState.force` (now optional, world-space N —
  mirrors `GenericState`)
- hover fans / jump jets → `generic` points with `force` — the escape hatch
  as designed
- heat/reactor → `mech.*` channels

## Gaps found

| # | Problem | Resolution |
|---|---|---|
| — | Per-motor thrust unmeasured in most sims; per-leg force needed for cueing | Both fixed in this batch: `PropellerState` core/extended union; `LegState.force` optional union |

## Verdict

**Covers.** The drive-point union plus the generic escape hatch absorbs both
exotic domains; nothing required a new dedicated variant.

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
| [01-race-car.md](01-race-car.md) | AC-style + iRacing-style car | Covers cleanly; G1–G3 found and fixed in v1 |

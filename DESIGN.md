# LTS Schema v1 — Two-Layer Design

Status: current (v1.0). Authoritative schema: `open_motion_telemetry.capnp`.

## 1. Goals

The schema serves the LTS requirements:

- Minimal, easily understood required telemetry — a game implementing just the
  pose core is compliant.
- Generic across game domains: racing, flight, marine, spacecraft, mechs — no
  domain's vocabulary is hardcoded into the structure.
- A structured extension mechanism: developers can add any telemetry datapoint
  as a well-documented, typed channel without schema changes.
- Network efficient and low latency at every stage; fits a UDP MTU at 60 Hz.
- Works on console and PC; read-only (the game never accepts input data).
- Supports multiple local clients (dashboards, motion rigs, haptics, loggers)
  without extra ports or proxying — via multicast.

## 2. Core idea: two layers

Telemetry data divides cleanly into two kinds with different change rates:

- **What a channel IS** — name, type, unit, valid range, geometry: changes never
  or rarely.
- **What a channel reads** — the sample: changes every frame.

Repeating metadata per frame bloats the wire; deleting it loses self-description.
The standard therefore defines two frames with separate cadences:

| Frame | Cadence | Contents |
|---|---|---|
| `DiscoveryFrame` | once per session, re-sent on change | game name, session anchor, environment, object descriptors, drive-point descriptors (incl. suspension spec), channel descriptors (id, name, unit, range, description) |
| `MotionFrame` | ~60 Hz | timestamp, per-object pose (position, forward, up), optional velocity/acceleration, drive-point state (typed union), channel values (id + typed value) |

This is the same split as motorsport CAN + DBC files: declare the signal
dictionary once, stream bare values. Senders key everything by `UInt16` ids
assigned in discovery; receivers that miss a descriptor wait for the next
discovery re-send.

## 3. Frame structure

`DiscoveryFrame` describes the session:

- `schemaVersion` — `1` for this schema.
- `gameName`, `sessionStartUnixUs` — wall-clock anchor; frame timestamps are
  seconds relative to it.
- `environment` — ambient conditions of the simulation medium: air density,
  temperature, pressure, gravity, and the dominant medium (`ContactMedium`).
- `objects` — one `ObjectDescriptor` per streamed object (primary first):
  identity (name/type/location), `DrivePointDescriptor`s, `ChannelDescriptor`s.

`MotionFrame` carries the samples:

- `timestamp` — seconds since session start.
- `objects` — one `MotionObject` per descriptor: pose core (position, forward,
  up — the required minimal set), optional velocity/acceleration, and per-tick
  drive-point state and channel values, keyed by the discovery ids.

Drive points are typed on both sides: the descriptor carries static geometry
(suspension travel/stiffness, wheel radius/driven/steered, propeller
diameter/blades) in a union; the motion frame carries the matching dynamic state
(`WheelState`, `PropellerState`, `JetState`, `SailState`, `LegState`,
`GenericState`) in a parallel union.

## 4. The extension mechanism

`ChannelDescriptor` + `ChannelValue` are the standard's extension point:

- A sender declares any datapoint it wants to expose — `engine.rpm` with unit
  `rpm` and a range, `headlights` as a boolean, `gear` as a number — and then
  streams bare values keyed by the descriptor's id.
- Receivers can render, normalize, and range-check channels without any prior
  knowledge of the game: unit and min/max come from the descriptor, type comes
  from the value's union variant (number/boolean/text).
- Drive points without a dedicated variant use `generic`: the descriptor states
  the geometry it can, and actual values travel as named channels.

New drive-point variants and new descriptor fields can be added in v1.x without
breaking deployed receivers (see §7).

## 5. Key decisions and rationale

- **Channel ids over per-frame names.** Names in every frame repeat ~10 bytes
  per channel per tick; ids cost 2 bytes. Discovery keeps names durable and
  human-readable where it is cheap. Ids are sender-assigned per object, stable
  for the session; discovery re-sends reset nothing (receivers key purely by id).
- **Unions for drive points.** Cap'n Proto unions give cheap tagged variants;
  unknown-union discriminants are skipped by old decoders, so new point types
  (e.g. `hoverFan`) can be added in v1.x without breaking deployed receivers.
- **Typed channel values.** Booleans (headlights, wipers) and text (mode labels)
  are first-class, not abused floats. Text at high rate is discouraged by
  comment, not banned — dashboards sometimes need label changes.
- **Optional derived kinematics.** Receiver-side derivation (velocity,
  acceleration computed by the client library) is the default; senders that
  already have accurate values may include them. Nullable pointer fields express
  "absent" honestly — no sentinel floats.
- **Discovery re-send on change.** Vehicle swap, channel set change, or medium
  change (air → water) re-sends the whole `DiscoveryFrame`. Idempotent by design.
- **Ranges in descriptors, not per frame.** Min/max per descriptor restores
  sane error handling — clients drop out-of-range values — without paying the
  cost on every frame.
- **Coordinate system.** Left-handed, Z-forward, Y-up, world space.
  Quaternion vs forward/up vectors stays an open question (§9).
- **Plain UDP over a messaging library.** At 60–120 Hz with sub-500-byte
  packets, transport latency is a few hundred microseconds at most — noise
  next to the physics tick, cueing filters, and actuator response. A high-
  performance messaging layer would add a media driver and client library to
  every integration for performance this use case cannot use. Plain UDP
  multicast is trivial to ship in engine plugins (see §7 and
  `implementation-udp.md`); Aeron remains an optional backend for extreme
  rates, strict ordering under load, or back-pressure across many subscribers.

## 6. Wire sizes

- `MotionFrame`, one object, pose only: ~76 bytes.
- + 4 wheels (`WheelState`) + 8 channels ≈ +200 bytes — still far under a
  1400-byte UDP MTU at 60 Hz.
- `DiscoveryFrame`: ~300–800 bytes once per session (strings dominate);
  negligible on any LAN and trivially fragmentable.

## 7. Transport

One UDP multicast group, one port. Each datagram carries an 8-byte envelope —
magic `OMT1`, a frame-type byte (`0x00` discovery, `0x01` motion), reserved —
followed by the Cap'n Proto message, which stays word-aligned and readable in
place. `DiscoveryFrame` is sent at session start, on change, and re-sent every
2 seconds so late joiners converge and lost discovery heals; `MotionFrame` is
fire-and-forget — receivers hold the last pose and interpolate across
occasional loss. Defaults: group `239.255.17.17`, port `40123`, TTL 1; all
configurable. See `implementation-udp.md`.

## 8. Evolution and compatibility

- `schemaVersion` distinguishes major schema revisions; `1` is current.
- Cap'n Proto unknown-field skipping: receivers ignore fields and descriptor
  variants they do not know; absent optional fields decode as defaults. v1.x
  may therefore add channels, drive-point variants, and optional fields freely.
- The Cap'n Proto schema is the single source of truth. If a JSON mirror is
  ever needed for tooling (e.g. web dashboards), it must be generated from
  the capnp — never hand-maintained.

## 9. Open questions

1. Orientation as quaternion vs forward/up vector pair (precision vs size vs
   gimbal concerns).
2. `objectType` as a ratified enum (aircraft/atv/boat/...) vs free text.
3. Channel-name namespace: informal (`engine.rpm`) vs a registry to prevent
   receiver-side guessing.
4. Whether `GenericState` should grow a small fixed payload (force vector).

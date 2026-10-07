# Open Game Standards Alliance — Local Telemetry Standard, schema v1 (two-layer)
#
# Layers (see DESIGN.md):
#   DiscoveryFrame — low rate: once per session, re-sent on change. Self-describing
#                    metadata: environment, objects, drive points, channel descriptors.
#   MotionFrame    — high rate (~60 Hz): bare kinematics + state values, keyed by the
#                    ids declared in DiscoveryFrame.
#
# Principles:
#   - Static metadata lives in discovery; per-frame samples stay bare (no repeated
#     units/ranges/enums on the wire).
#   - Domain generality: drive points are a union (wheel/propeller/jet/sail/leg/generic);
#     channels are typed key-values declared up front — any game, any domain.
#   - Unknown-field skipping in both directions: receivers ignore unknown fields and
#     unknown union variants, so v1.x can add without breaking deployed decoders.

@0x5fa84c118a0c2b03;

# ---------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------

struct Vector3 {
  x @0 :Float32;
  y @1 :Float32;
  z @2 :Float32;
}

struct Quaternion {
  # Unit quaternion (senders must normalize; receivers may renormalize
  # defensively). Either sign represents the same rotation. Rotates LTS
  # world axes (left-handed, Z-forward, Y-up) into object body axes.
  x @0 :Float32;
  y @1 :Float32;
  z @2 :Float32;
  w @3 :Float32;
}

struct Range {
  min @0 :Float64;
  max @1 :Float64;
}

enum ObjectType {
  # Coarse classification for cueing-preset selection and UI. Fine-grained
  # domain hints live in the drive-point union (wheel/propeller/sail/leg).
  # Unknown enumerants survive round-trips (UInt16 on the wire), so new
  # values may be ratified in v1.x without breaking deployed receivers.
  vehicle    @0;   # ground: car, kart, tank
  aircraft   @1;   # plane, helicopter, drone
  watercraft @2;   # boat, ship, submarine
  spacecraft @3;
  humanoid   @4;   # on-foot player or NPC
  camera     @5;   # spectator / free camera
  other      @6;   # escape hatch — never force a wrong class
}

enum ContactMedium {
  air         @0;
  asphalt     @1;
  dirt        @2;
  grass       @3;
  gravel      @4;
  rumbleStrip @5;
  water       @6;
  snow        @7;
  ice         @8;
  other       @9;
}

struct Environment {
  # Ambient conditions of the simulation medium. Sent in discovery; may be
  # re-sent on change (e.g. entering water). Units in comments.
  airDensity @0 :Float32;   # kg/m^3
  temperature @1 :Float32;  # °C
  pressure @2 :Float32;     # bar
  gravity @3 :Float32;      # m/s^2
  medium @4 :ContactMedium; # dominant surrounding medium
}

# ---------------------------------------------------------------------------
# Discovery frame (low rate)
# ---------------------------------------------------------------------------

struct DiscoveryFrame {
  schemaVersion @0 :UInt16;        # 1 for this schema
  gameName @1 :Text;
  sessionStartUnixUs @2 :Int64;    # wall-clock anchor; frame timestamps are relative
  environment @3 :Environment;
  objects @4 :List(ObjectDescriptor);

  # Re-send the whole frame when any descriptor changes (vehicle swap, channel
  # set change). Receivers key purely by ids, so re-sends are non-breaking.
}

struct ObjectDescriptor {
  name @0 :Text;                   # stable per session; matches MotionObject.name
  type @1 :ObjectType;             # coarse class; ratifiable enum
  location @2 :Text;               # e.g. track/place name (display-only)
  typeLabel @5 :Text;              # optional display label, e.g. "Formula 1 2024"
  primary @6 :Bool;                # reference object for motion rigs / compensation;
                                   # exactly one SHOULD be set per discovery frame
  drivePoints @3 :List(DrivePointDescriptor);
  channels @4 :List(ChannelDescriptor);
}

struct ChannelDescriptor {
  # Declares one generic telemetry channel. Ids are sender-assigned, unique
  # within the object. This is the extension mechanism of the standard: any
  # game can expose any datapoint as a well-documented, typed channel.
  id @0 :UInt16;
  name @1 :Text;                   # stable identifier, e.g. "engine.rpm"
  unit @2 :Text;                   # e.g. "rpm", "m/s", "bar", "" = unitless
  range @3 :Range;                 # optional (null when unbounded)
  description @4 :Text;            # human-readable, shown by dash tools
}

struct SuspensionSpec {
  # Static suspension geometry per drive point.
  travel @0 :Range;                # compression travel, meters
  stiffness @1 :Float32;           # N/m for unit displacement
  damping @2 :Float32;             # N·s/m; 0 = unspecified (force approximation then uses stiffness only)
}

struct DrivePointDescriptor {
  id @0 :UInt16;
  name @1 :Text;                   # e.g. "wheel_front_left"
  cogOffset @2 :Vector3;           # offset from object center of gravity, meters
  suspension @3 :SuspensionSpec;   # optional (null: not applicable)
  union {
    # Static, type-specific geometry. Extensible: add variants in v1.x —
    # old receivers skip unknown variants (unknown-union discriminant).
    wheel @4 :WheelSpec;
    propeller @5 :PropellerSpec;
    jet @6 :Void;
    sail @7 :Void;
    leg @8 :Void;
    generic @9 :GenericSpec;         # unspecified drive; state carried by GenericState
  }
}

struct WheelSpec {
  radius @0 :Float32;              # meters
  driven @1 :Bool;                 # power delivered through this wheel
  steered @2 :Bool;
}

struct PropellerSpec {
  diameter @0 :Float32;            # meters
  blades @1 :UInt16;
}

struct GenericSpec {
  ratedForce @0 :Float32;          # rated force magnitude, N; 0 = unspecified
}

# ---------------------------------------------------------------------------
# Motion frame (high rate)
# ---------------------------------------------------------------------------

struct MotionFrame {
  timestamp @0 :Float64;           # seconds since session start (anchor in discovery)
  objects @1 :List(MotionObject);  # primary object first
}

struct MotionObject {
  name @0 :Text;                   # matches ObjectDescriptor.name

  # Core pose — the LTS minimal set.
  position @1 :Vector3;            # world space, meters, left-handed, Z-forward, Y-up
  orientation @2 :Quaternion;      # unit quaternion: LTS world -> object axes

  # Derived kinematics — optional, both or neither. Cap'n Proto struct fields
  # are inline (not nullable pointers), so absence is expressed by the union
  # discriminant: the default variant means "not provided — receivers derive
  # from pose deltas".
  union {
    derivedKinematics @3 :Void;    # default: not provided
    kinematics @4 :Kinematics;     # velocity + acceleration, world space
  }

  drivePoints @5 :List(DrivePoint);   # only points with state this tick
  channels @6 :List(ChannelValue);    # only channels that changed / are streamed
}

struct Kinematics {
  velocity @0 :Vector3;            # m/s, world space
  acceleration @1 :Vector3;        # m/s^2, world space
}

struct DrivePoint {
  id @0 :UInt16;                   # matches DrivePointDescriptor.id
  union {
    # Dynamic state per drive-point type. Variants mirror the descriptor union.
    wheel @1 :WheelState;
    propeller @2 :PropellerState;
    jet @3 :JetState;
    sail @4 :SailState;
    leg @5 :LegState;
    generic @6 :GenericState;
  }
}

struct WheelState {
  rpm @0 :Float32;
  torque @1 :Float32;              # Nm
  brakePressure @2 :Float32;       # Pa
  slip @3 :Float32;                # slip ratio, 0 = rolling
  compression @4 :Float32;         # current suspension compression, meters
  contact @5 :ContactMedium;
  union {
    # Per-wheel extras arrive whole in practice (AC/iRacing-style physics
    # pages) or not at all — all-or-neither also fits Cap'n Proto's
    # single-unnamed-union rule. Inside extended, zeros are real values.
    core @6 :Void;                 # default: core fields only
    extended @7 :WheelExtended;    # steer angle, load force, tyre data
  }
}

struct WheelExtended {
  steerAngle @0 :Float32;          # radians; positive = left (ISO convention)
  loadForce @1 :Float32;           # N along suspension axis, measured (incl. damping)
  tyrePressure @2 :Float32;        # Pa
  tyreTemp @3 :Float32;            # degC, carcass/average (zone temps → channels)
  tyreWear @4 :Float32;            # 0..1 fraction remaining (1 = new)
}

struct PropellerState {
  rpm @0 :Float32;
  pitch @1 :Float32;               # radians
  thrust @2 :Float32;              # N
}

struct JetState {
  throttle @0 :Float32;            # 0..1
  thrust @1 :Float32;              # N
}

struct SailState {
  sheet @0 :Float32;               # 0..1
  angle @1 :Float32;               # radians relative to object
}

struct LegState {
  contact @0 :Bool;
  phase @1 :Float32;               # gait phase 0..1
}

struct GenericState {
  # Escape hatch for drive-point types without a dedicated variant. Multi-instance
  # by design (four hover fans = four generic drive points): physical quantities
  # are per-point fields; game-flavored quantities ride object channels.
  engaged @0 :Bool;
  union {
    noForce @1 :Void;              # default: force not available
    force @2 :Vector3;             # world space, N
  }
}

struct ChannelValue {
  id @0 :UInt16;                   # matches ChannelDescriptor.id
  union {
    number @1 :Float32;
    boolean @2 :Bool;
    text @3 :Text;                 # rare (labels, mode names); avoid per-frame
  }
}

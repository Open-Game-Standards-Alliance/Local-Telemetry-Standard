@0xafeb1234567890ab;  # Unique ID for this schema

# Root struct representing the full telemetry packet
struct MotionTelemetry {
  gameName       @0 :Text;           # Name of the game
  timestamp      @1 :Float64;        # Seconds since session start (double precision)
  motionObject   @2 :MotionObject;   # Core motion data
}

# Represents the motionObject structure
struct MotionObject {
  objectLocation @0 :Text;           # Location of the object (e.g., "car")
  objectName     @1 :Text;           # Name of the object
  objectType     @2 :Text;           # Type of the object (e.g., "vehicle")

  # Position in world space (meters, left-handed, Z-forward)
  positionX      @3 :Float32;
  positionY      @4 :Float32;
  positionZ      @5 :Float32;

  # Orientation in world space (left-handed, Z-forward)
  forward        @6 :Vector3;        # Forward vector (Z-forward)
  up             @7 :Vector3;        # Up vector (Y-up)

  # Array of drive points
  drivePoints    @8 :List(DrivePoint);

  # Aerodynamics data
  aerodynamics   @9 :Aerodynamics;

  # Feedback items (array of key-value pairs)
  feedbackItem   @10 :List(FeedbackItem);
}

# Represents a 3D vector
struct Vector3 {
  x @0 :Float32;
  y @1 :Float32;
  z @2 :Float32;
}

# Represents a single drive point
struct DrivePoint {
  name          @0 :Text;            # Name of the drive point (e.g., "wheel_front_left")
  type          @1 :Text;            # Type of the drive point
  cogOffsetX    @2 :Float32;         # Center of gravity offset X (meters)
  cogOffsetY    @3 :Float32;         # Center of gravity offset Y (meters)
  cogOffsetZ    @4 :Float32;         # Center of gravity offset Z (meters)
  rpm           @5 :Float32;         # Revolutions per minute
  torque        @6 :Float32;         # Torque in Newton-meters
  brakePressure @7 :Float32;         # Brake pressure (assumed Pascals or similar)
}

# Represents aerodynamics data
struct Aerodynamics {
  liftCoefficient @0 :Float32;       # Lift coefficient
  dragCoefficient @1 :Float32;       # Drag coefficient
  yawCoefficient  @2 :Float32;       # Yaw coefficient
}

# Represents a feedback item (key-value pair)
struct FeedbackItem {
  name           @0 :Text;           # Name of the feedback (e.g., "altitude")
  value          @1 :Float32;        # Value of the feedback
}
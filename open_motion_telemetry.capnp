@0xafeb1234567890ab;  # Unique ID for this schema

# Root struct representing the full telemetry packet
struct MotionTelemetry {
  gameName       @0 :Text;           # Name of the game
  maxSampleRate  @1 :Int32;          # Maximum sample rate in Hz
  timestamp      @2 :Int64;          # Unix timestamp (nanoseconds for precision)
  motionObject   @3 :MotionObject;   # Core motion data
}

# Represents the motionObject structure
struct MotionObject {
  objectLocation @0 :Text;           # Location of the object (e.g., "car")
  objectName     @1 :Text;           # Name of the object
  objectType     @2 :Text;           # Type of the object (e.g., "vehicle")

  # Acceleration (m/s²)
  accelerationX  @3 :Float32;
  accelerationY  @4 :Float32;
  accelerationZ  @5 :Float32;

  # Position (meters)
  positionX      @6 :Float32;
  positionY      @7 :Float32;
  positionZ      @8 :Float32;

  # Rotation (radians, assumed Euler angles)
  rotationX      @9 :Float32;
  rotationY      @10 :Float32;
  rotationZ      @11 :Float32;

  # Velocity (m/s)
  velocityX      @12 :Float32;
  velocityY      @13 :Float32;
  velocityZ      @14 :Float32;

  # Array of drive points
  drivePoints    @15 :List(DrivePoint);

  # Aerodynamics data
  aerodynamics   @16 :Aerodynamics;

  # Feedback items (array of key-value pairs)
  feedbackItem   @17 :List(FeedbackItem);
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
# Cap'n Proto Implementation

To implement the JSON schema this repository in [Cap’n Proto](https://capnproto.org/), we’ll create a `.capnp` file that defines the structure. Cap’n Proto is a zero-copy, binary serialization format optimized for speed and efficiency, making it an excellent choice for sending motion telemetry data over UDP. Unlike Protobuf, it avoids encoding/decoding overhead by using a memory-aligned layout, and it supports optional fields and nested structures efficiently.

### Conversion Process

1. **Root Structure**: The JSON schema’s top-level object becomes the main `MotionTelemetry` struct.
2. **Nested Objects**: `motionObject`, `drivePoints`, `aerodynamics`, and `feedbackItem` become nested structs.
3. **Arrays**: JSON arrays (`drivePoints`, `feedbackItem`) map to Cap’n Proto `List` types.
4. **Types**:
   - JSON strings → `Text`.
   - JSON numbers → `Float64` for `timestamp` (seconds since session start), `Float32` for all others (position, vectors, etc.).
5. **Optional Fields**: Cap’n Proto fields are optional by default unless explicitly required (we’ll keep them optional to match the JSON schema’s flexibility).

Here’s the Cap’n Proto schema based on the linked JSON:

---

### Cap’n Proto Schema (`open_motion_telemetry.capnp`)

```capnp
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
```

---

### Notes on the Conversion

1. **Field IDs**: Assigned sequentially (`@0`, `@1`, etc.) as required by Cap’n Proto. These are encoded compactly in the binary format.
2. **Types**:
   - `Text` for strings (null-terminated, dynamically sized).
   - `Float64` for `timestamp` (seconds since session start, double precision).
   - `Float32` for all floats (4 bytes, IEEE 754 single-precision).
3. **Lists**: `drivePoints` and `feedbackItem` are `List` types, dynamically sized at runtime.
4. **No Enums**: The schema doesn’t specify strict enumerations (e.g., for `objectType`), so they remain `Text`. You could add `enum` types if needed.
5. **Zero-Copy**: Cap’n Proto aligns data in memory, so the receiver can access fields directly without parsing.
6. **Coordinate System**: Position and orientation (forward, up vectors) are in world space, using a left-handed coordinate system with Z-forward and Y-up.

---

### Size Estimation

Cap’n Proto’s size depends on content (e.g., string lengths, list sizes), but for a minimal packet (e.g., `timestamp` + `motionObject` with position and orientation):
- **Fixed Fields**:
  - `timestamp` (8 bytes) + 3 position floats (12 bytes) + 6 vector floats (24 bytes) = 44 bytes.
- **Pointers**: Each struct/list field has an 8-byte pointer (offset + size metadata).
  - `motionObject` pointer: 8 bytes.
  - `forward` and `up` pointers: 16 bytes.
  - Total without strings/lists: ~68 bytes.
- **Strings**: `Text` fields (e.g., `gameName`) add their length + 1 (null terminator).
- **Lists**: `drivePoints` and `feedbackItem` add 8-byte list headers + per-element size.

Example with no strings/lists: ~68 bytes. With `gameName="RacingSim"` (9 chars + 1): ~78 bytes. Still far smaller than JSON (~150-200 bytes).

---

### Implementation Example (C++)

1. **Compile the Schema**:
   ```bash
   capnp compile -oc++ open_motion_telemetry.capnp
   ```
   This generates `open_motion_telemetry.capnp.h` and `.capnp.c++`.

2. **Sender Code**:
```cpp
#include "open_motion_telemetry.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize.h>
#include <sys/socket.h>

void sendTelemetry(int socket, struct sockaddr* dest_addr, socklen_t addr_len) {
    // Build the message
    ::capnp::MallocMessageBuilder message;
    MotionTelemetry::Builder telemetry = message.initRoot<MotionTelemetry>();

    telemetry.setGameName("RacingSim");
    telemetry.setTimestamp(1.234); // Seconds since session start

    MotionObject::Builder obj = telemetry.initMotionObject();
    obj.setObjectName("player_car");
    obj.setPositionX(1.5);
    obj.setPositionY(2.0);
    obj.setPositionZ(0.0);
    auto forward = obj.initForward();
    forward.setX(0.0);
    forward.setY(0.0);
    forward.setZ(1.0); // Z-forward
    auto up = obj.initUp();
    up.setX(0.0);
    up.setY(1.0); // Y-up
    up.setZ(0.0);

    // Add a drive point
    auto drivePoints = obj.initDrivePoints(1);
    drivePoints[0].setName("wheel_fl");
    drivePoints[0].setRpm(1200.0);

    // Serialize to a byte array
    kj::Array<capnp::word> words = capnp::messageToFlatArray(message);
    kj::ArrayPtr<const char> bytes = words.asBytes();

    // Send over UDP
    sendto(socket, bytes.begin(), bytes.size(), 0, dest_addr, addr_len);
}
```

3. **Receiver Code**:
```cpp
#include "open_motion_telemetry.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize.h>

void receiveTelemetry(int socket) {
    char buffer[1024]; // Adjust size as needed
    struct sockaddr src_addr;
    socklen_t addr_len = sizeof(src_addr);

    ssize_t bytes_received = recvfrom(socket, buffer, sizeof(buffer), 0, &src_addr, &addr_len);
    if (bytes_received < 0) return;

    // Interpret the raw bytes as a Cap’n Proto message
    kj::ArrayPtr<const char> rawBytes(buffer, bytes_received);
    kj::ArrayPtr<const capnp::word> words(reinterpret_cast<const capnp::word*>(rawBytes.begin()), bytes_received / sizeof(capnp::word));
    ::capnp::FlatArrayMessageReader message(words);

    MotionTelemetry::Reader telemetry = message.getRoot<MotionTelemetry>();
    printf("Game: %s, Timestamp: %f\n", telemetry.getGameName().cStr(), telemetry.getTimestamp());
    MotionObject::Reader obj = telemetry.getMotionObject();
    printf("Position: (%f, %f, %f)\n", obj.getPositionX(), obj.getPositionY(), obj.getPositionZ());
    auto forward = obj.getForward();
    printf("Forward: (%f, %f, %f)\n", forward.getX(), forward.getY(), forward.getZ());
    auto up = obj.getUp();
    printf("Up: (%f, %f, %f)\n", up.getX(), up.getY(), up.getZ());
}
```

---

### Handling Extra Fields

- **Forward Compatibility**: If the sender adds fields later, older receivers ignore them (Cap’n Proto only reads known fields).
- **Backward Compatibility**: If the receiver expects new fields, unset fields return defaults (e.g., 0 for numbers, empty for lists/text).

---

## Cap’n Proto Integration with Transport Abstraction

This section describes how Cap’n Proto is used to serialize the Local Telemetry Standard’s data, integrated with a transport abstraction layer (e.g., Aeron). The implementation provides a high-level C API for developers, hiding serialization and transport details, and uses a callback mechanism for receiving telemetry data. The library calculates derived values like velocity and acceleration on the receiver side, minimizing the math required by both the game and motion software.

### Cap’n Proto Schema

The telemetry data uses the `open_motion_telemetry.capnp` schema defined above.

Compile the schema with:
```bash
capnp compile -oc++ open_motion_telemetry.capnp
```

### Integration with Transport Layer

Cap’n Proto is used to serialize the telemetry data, which is then sent via a transport layer (e.g., Aeron). Cap’n Proto’s zero-copy serialization complements high-performance transports like Aeron, ensuring minimal latency for real-time motion telemetry. The transport is abstracted behind a `Transport` base class, with implementations like `AeronTransport` (see `implementation-aeron.md`). The library exposes a high-level C API for developers to set fields, send data, and retrieve both raw and derived data (e.g., velocity, acceleration).

### High-Level C API

The C API (`motion_telemetry.h`) allows developers to interact with the telemetry system without directly handling Cap’n Proto:

```c
typedef struct MotionTelemetryHandle MotionTelemetryHandle;
typedef void (*TelemetryCallback)(void* userData);

MotionTelemetryHandle* motion_telemetry_create_sender(const char* transportType, const char* channel, int streamId);
MotionTelemetryHandle* motion_telemetry_create_receiver(const char* transportType, const char* channel, int streamId);
void motion_telemetry_set_game_name(MotionTelemetryHandle* handle, const char* name);
void motion_telemetry_set_timestamp(MotionTelemetryHandle* handle, double timestamp);
void motion_telemetry_set_position_x(MotionTelemetryHandle* handle, float x);
void motion_telemetry_set_position_y(MotionTelemetryHandle* handle, float y);
void motion_telemetry_set_position_z(MotionTelemetryHandle* handle, float z);
void motion_telemetry_set_forward_x(MotionTelemetryHandle* handle, float x);
void motion_telemetry_set_forward_y(MotionTelemetryHandle* handle, float y);
void motion_telemetry_set_forward_z(MotionTelemetryHandle* handle, float z);
void motion_telemetry_set_up_x(MotionTelemetryHandle* handle, float x);
void motion_telemetry_set_up_y(MotionTelemetryHandle* handle, float y);
void motion_telemetry_set_up_z(MotionTelemetryHandle* handle, float z);
void motion_telemetry_send(MotionTelemetryHandle* handle);
void motion_telemetry_register_callback(MotionTelemetryHandle* handle, TelemetryCallback callback, void* userData);
void motion_telemetry_start_receiving(MotionTelemetryHandle* handle);
const char* motion_telemetry_get_game_name(MotionTelemetryHandle* handle);
double motion_telemetry_get_timestamp(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_z(MotionTelemetryHandle* handle);
float motion_telemetry_get_forward_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_forward_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_forward_z(MotionTelemetryHandle* handle);
float motion_telemetry_get_up_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_up_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_up_z(MotionTelemetryHandle* handle);
float motion_telemetry_get_velocity_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_velocity_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_velocity_z(MotionTelemetryHandle* handle);
float motion_telemetry_get_acceleration_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_acceleration_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_acceleration_z(MotionTelemetryHandle* handle);
void motion_telemetry_destroy(MotionTelemetryHandle* handle);
```

The full API includes setters and getters for all fields (e.g., `motion_telemetry_set_drive_point_rpm`, `motion_telemetry_get_aerodynamics_lift`), following the same pattern.

### Sender Example

The game sets telemetry fields and sends them continuously at 60 Hz until the user stops it:

```c
#include <sys/time.h>

double getTimeSinceStart() {
    static struct timeval start = {0, 0};
    if (start.tv_sec == 0) {
        gettimeofday(&start, NULL);
    }
    struct timeval now;
    gettimeofday(&now, NULL);
    return (now.tv_sec - start.tv_sec) + (now.tv_usec - start.tv_usec) / 1000000.0;
}

MotionTelemetryHandle* sender = motion_telemetry_create_sender("aeron", "aeron:udp?endpoint=localhost:40123", 1001);
if (!sender) {
    printf("Failed to create sender\n");
    return 1;
}

int i = 0;
printf("Sending telemetry data. Press Enter to stop...\n");
while (1) {
    // Check for user input to exit (non-blocking)
    fd_set set;
    struct timeval timeout = {0, 0}; // No wait
    FD_ZERO(&set);
    FD_SET(STDIN_FILENO, &set);
    if (select(STDIN_FILENO + 1, &set, NULL, NULL, &timeout) > 0) {
        break; // Exit on any input
    }

    motion_telemetry_set_game_name(sender, "RacingSim");
    motion_telemetry_set_timestamp(sender, getTimeSinceStart());
    motion_telemetry_set_position_x(sender, 1.5 + i * 0.1);
    motion_telemetry_set_position_y(sender, 2.0);
    motion_telemetry_set_position_z(sender, 0.0);
    motion_telemetry_set_forward_x(sender, 0.0);
    motion_telemetry_set_forward_y(sender, 0.0);
    motion_telemetry_set_forward_z(sender, 1.0); // Z-forward
    motion_telemetry_set_up_x(sender, 0.0);
    motion_telemetry_set_up_y(sender, 1.0); // Y-up
    motion_telemetry_set_up_z(sender, 0.0);
    motion_telemetry_send(sender);
    usleep(16667); // ~60 Hz
    i++;
}
motion_telemetry_destroy(sender);
```

### Receiver Example

The motion software registers a callback to be notified when new telemetry data arrives, then pulls the data (including derived velocity and acceleration) using the C API:

```c
void onTelemetry(void* userData) {
    MotionTelemetryHandle* handle = (MotionTelemetryHandle*)userData;
    const char* gameName = motion_telemetry_get_game_name(handle);
    double timestamp = motion_telemetry_get_timestamp(handle);
    float positionX = motion_telemetry_get_position_x(handle);
    float positionY = motion_telemetry_get_position_y(handle);
    float positionZ = motion_telemetry_get_position_z(handle);
    float forwardX = motion_telemetry_get_forward_x(handle);
    float forwardY = motion_telemetry_get_forward_y(handle);
    float forwardZ = motion_telemetry_get_forward_z(handle);
    float upX = motion_telemetry_get_up_x(handle);
    float upY = motion_telemetry_get_up_y(handle);
    float upZ = motion_telemetry_get_up_z(handle);
    float velocityX = motion_telemetry_get_velocity_x(handle);
    float velocityY = motion_telemetry_get_velocity_y(handle);
    float velocityZ = motion_telemetry_get_velocity_z(handle);
    float accelerationX = motion_telemetry_get_acceleration_x(handle);
    float accelerationY = motion_telemetry_get_acceleration_y(handle);
    float accelerationZ = motion_telemetry_get_acceleration_z(handle);
    printf("Received - Game: %s, Timestamp: %f\n", gameName, timestamp);
    printf("Position: (%f, %f, %f)\n", positionX, positionY, positionZ);
    printf("Forward: (%f, %f, %f), Up: (%f, %f, %f)\n", forwardX, forwardY, forwardZ, upX, upY, upZ);
    printf("Velocity: (%f, %f, %f)\n", velocityX, velocityY, velocityZ);
    printf("Acceleration: (%f, %f, %f)\n", accelerationX, accelerationY, accelerationZ);
}

MotionTelemetryHandle* receiver = motion_telemetry_create_receiver("aeron", "aeron:udp?endpoint=localhost:40123", 1001);
if (!receiver) {
    printf("Failed to create receiver\n");
    return 1;
}
motion_telemetry_register_callback(receiver, onTelemetry, receiver);
motion_telemetry_start_receiving(receiver);
getchar(); // Wait to exit
motion_telemetry_destroy(receiver);
```

### Benefits

- **Zero-Copy**: Cap’n Proto’s serialization allows direct memory access, minimizing CPU overhead.
- **Compact**: A minimal packet (e.g., timestamp + position + orientation) is ~68 bytes, far smaller than JSON.
- **Integration**: Works seamlessly with the transport abstraction, allowing developers to focus on telemetry logic.
- **Asynchronous Processing**: The callback API notifies the receiver of new data, allowing on-demand access to the full telemetry frame via getter functions.
- **Simplified Integration**: The library calculates velocity and acceleration, reducing the math required by both the game and motion software.

See `implementation-aeron.md` for details on the Aeron transport implementation.

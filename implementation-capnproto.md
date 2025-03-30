# Cap'n Proto Implementation

To implement the JSON schema this repository in [Cap’n Proto](https://capnproto.org/), we’ll create a `.capnp` file that defines the structure. Cap’n Proto is a zero-copy, binary serialization format optimized for speed and efficiency, making it an excellent choice for sending motion telemetry data over UDP. Unlike Protobuf, it avoids encoding/decoding overhead by using a memory-aligned layout, and it supports optional fields and nested structures efficiently.

### Conversion Process

1. **Root Structure**: The JSON schema’s top-level object becomes the main `MotionTelemetry` struct.
2. **Nested Objects**: `motionObject`, `drivePoints`, `aerodynamics`, and `feedbackItem` become nested structs.
3. **Arrays**: JSON arrays (`drivePoints`, `feedbackItem`) map to Cap’n Proto `List` types.
4. **Types**:
   - JSON strings → `Text`.
   - JSON numbers → `Int64` for `timestamp`, `Int32` for `maxSampleRate`, `Float32` for all others (position, velocity, etc.).
5. **Optional Fields**: Cap’n Proto fields are optional by default unless explicitly required (we’ll keep them optional to match the JSON schema’s flexibility).

Here’s the Cap’n Proto schema based on the linked JSON:

---

### Cap’n Proto Schema (`open_motion_telemetry.capnp`)

```capnp
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
```

---

### Notes on the Conversion

1. **Field IDs**: Assigned sequentially (`@0`, `@1`, etc.) as required by Cap’n Proto. These are encoded compactly in the binary format.
2. **Types**:
   - `Text` for strings (null-terminated, dynamically sized).
   - `Int64` for `timestamp` (nanoseconds assumed for precision; use `Int32` if seconds suffice).
   - `Int32` for `maxSampleRate` (assumes Hz values < 2^31).
   - `Float32` for all floats (4 bytes, IEEE 754 single-precision).
3. **Lists**: `drivePoints` and `feedbackItem` are `List` types, dynamically sized at runtime.
4. **No Enums**: The schema doesn’t specify strict enumerations (e.g., for `objectType`), so they remain `Text`. You could add `enum` types if needed.
5. **Zero-Copy**: Cap’n Proto aligns data in memory, so the receiver can access fields directly without parsing.

---

### Size Estimation

Cap’n Proto’s size depends on content (e.g., string lengths, list sizes), but for a minimal packet (e.g., `timestamp` + core `motionObject` fields):
- **Fixed Fields**:
  - `timestamp` (8 bytes) + 12 floats (48 bytes) = 56 bytes.
- **Pointers**: Each struct/list field has an 8-byte pointer (offset + size metadata).
  - `motionObject` pointer: 8 bytes.
  - Total without strings/lists: ~64 bytes.
- **Strings**: `Text` fields (e.g., `gameName`) add their length + 1 (null terminator).
- **Lists**: `drivePoints` and `feedbackItem` add 8-byte list headers + per-element size.

Example with no strings/lists: ~64 bytes. With `gameName="RacingSim"` (9 chars + 1): ~74 bytes. Far smaller than JSON (~150-200 bytes).

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
    telemetry.setMaxSampleRate(60);
    telemetry.setTimestamp(1649125392000000000);

    MotionObject::Builder obj = telemetry.initMotionObject();
    obj.setObjectName("player_car");
    obj.setPositionX(1.5);
    obj.setPositionY(2.0);
    obj.setPositionZ(0.0);
    obj.setRotationX(0.1);
    // ... set other fields ...

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
    printf("Game: %s, Timestamp: %ld\n", telemetry.getGameName().cStr(), telemetry.getTimestamp());
    MotionObject::Reader obj = telemetry.getMotionObject();
    printf("Position: (%f, %f, %f)\n", obj.getPositionX(), obj.getPositionY(), obj.getPositionZ());
    // Access other fields directly...
}
```

---

### Handling Extra Fields

- **Forward Compatibility**: If the sender adds fields later, older receivers ignore them (Cap’n Proto only reads known fields).
- **Backward Compatibility**: If the receiver expects new fields, unset fields return defaults (e.g., 0 for numbers, empty for lists/text).

---

## Cap’n Proto Integration with Transport Abstraction

This section describes how Cap’n Proto is used to serialize the Local Telemetry Standard’s data, integrated with a transport abstraction layer (e.g., Aeron). The implementation provides a high-level C API for developers, hiding serialization and transport details, and uses a callback mechanism for receiving telemetry data.

### Cap’n Proto Schema

The telemetry data uses the `open_motion_telemetry.capnp` schema defined above.

Compile the schema with:
```bash
capnp compile -oc++ open_motion_telemetry.capnp
```

### Integration with Transport Layer

Cap’n Proto is used to serialize the telemetry data, which is then sent via a transport layer (e.g., Aeron). Cap’n Proto’s zero-copy serialization complements high-performance transports like Aeron, ensuring minimal latency for real-time motion telemetry. The transport is abstracted behind a `Transport` base class, with implementations like `AeronTransport` (see `implementation-aeron.md`). The library exposes a high-level C API for developers to set fields and send data.

### High-Level C API
The C API (`motion_telemetry.h`) allows developers to interact with the telemetry system without directly handling Cap’n Proto:

```c
typedef struct MotionTelemetryHandle MotionTelemetryHandle;
typedef void (*TelemetryCallback)(void* userData);

MotionTelemetryHandle* motion_telemetry_create_sender(const char* transportType, const char* channel, int streamId);
MotionTelemetryHandle* motion_telemetry_create_receiver(const char* transportType, const char* channel, int streamId);
void motion_telemetry_set_game_name(MotionTelemetryHandle* handle, const char* name);
void motion_telemetry_set_position_x(MotionTelemetryHandle* handle, float x);
void motion_telemetry_set_position_y(MotionTelemetryHandle* handle, float y);
void motion_telemetry_set_position_z(MotionTelemetryHandle* handle, float z);
void motion_telemetry_send(MotionTelemetryHandle* handle);
void motion_telemetry_register_callback(MotionTelemetryHandle* handle, TelemetryCallback callback, void* userData);
void motion_telemetry_start_receiving(MotionTelemetryHandle* handle);
const char* motion_telemetry_get_game_name(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_x(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_y(MotionTelemetryHandle* handle);
float motion_telemetry_get_position_z(MotionTelemetryHandle* handle);
void motion_telemetry_destroy(MotionTelemetryHandle* handle);
```

The full API includes setters for all fields (e.g., `motion_telemetry_set_rotation_x`, `motion_telemetry_set_velocity_x`), following the same pattern.

### Sender Example
The game sets telemetry fields and sends them continuously at 60 Hz until the user stops it:

```c
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
    motion_telemetry_set_position_x(sender, 1.5 + i * 0.1);
    motion_telemetry_set_position_y(sender, 2.0);
    motion_telemetry_set_position_z(sender, 0.0);
    motion_telemetry_send(sender);
    usleep(16667); // ~60 Hz
    i++;
}
motion_telemetry_destroy(sender);
```

### Receiver Example

The motion software registers a callback to process incoming data:

```c
void onTelemetry(void* userData) {
    MotionTelemetryHandle* handle = (MotionTelemetryHandle*)userData;
    const char* gameName = motion_telemetry_get_game_name(handle);
    float positionX = motion_telemetry_get_position_x(handle);
    float positionY = motion_telemetry_get_position_y(handle);
    float positionZ = motion_telemetry_get_position_z(handle);
    printf("Received - Game: %s, Position: (%f, %f, %f)\n", gameName, positionX, positionY, positionZ);
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
- **Compact**: A minimal packet (e.g., timestamp + position) is ~64 bytes, far smaller than JSON.
- **Integration**: Works seamlessly with the transport abstraction, allowing developers to focus on telemetry logic.
- **Asynchronous Processing**: The callback API simplifies real-time telemetry processing by handling data as it arrives.

See `implementation-aeron.md` for details on the Aeron transport implementation.

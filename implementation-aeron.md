
# Aeron Implementation

To integrate Aeron with the Cap’n Proto example for sending motion telemetry data, we’ll combine Aeron’s high-performance messaging with Cap’n Proto’s efficient serialization. Aeron will handle the transport (over UDP), while Cap’n Proto defines the data structure. Below, I’ll outline a detailed implementation plan in C++, assuming a sender (game) and receiver (motion software) setup. This plan includes setup, code examples, and considerations for your use case.

---

### Overview

- **Cap’n Proto**: Serializes the `MotionTelemetry` struct into a compact, zero-copy binary format (from the `.capnp` schema I provided).
- **Aeron**: Publishes this binary data over UDP to one or more subscribers, ensuring low latency, ordering, and optional reliability.
- **Flow**:
  1. Game serializes telemetry data into a Cap’n Proto message.
  2. Aeron sends it via a publication channel.
  3. Motion software subscribes and receives the data, deserializing it with Cap’n Proto.

---

### Prerequisites

1. **Install Cap’n Proto**:
   - Download and build from [capnproto.org](https://capnproto.org/).
   - Compile the schema: `capnp compile -oc++ open_motion_telemetry.capnp`.
2. **Install Aeron**:
   - Clone from [GitHub](https://github.com/real-logic/aeron) and build with CMake.
   - Include Aeron’s C++ client library in your project (`libaeron_client`).
3. **Dependencies**: C++11 or later, UDP-capable network (LAN or localhost for testing).

---

### Implementation Plan

#### 1. Setup Aeron Environment

Aeron requires a media driver to manage UDP communication. You can run it as a separate process or embed it (simpler for testing).

- **Standalone Media Driver**:
  - Launch the driver: `java -cp aeron-all-<version>.jar io.aeron.driver.MediaDriver`.
  - Config (optional): Create `aeron.properties` with:
    ```properties
    aeron.dir=/tmp/aeron
    aeron.mtu=1408
    aeron.socket.buffer=2m
    ```
  - This runs on localhost, using UDP ports (default: 40123 for publications).

- **Embedded Driver** (Alternative):
  - Embed in your C++ app for simplicity (shown below).

#### 2. Define Aeron Channels

- **Channel**: A URI specifying the transport. For UDP:
  - Sender: `aeron:udp?endpoint=localhost:40123`
  - Receiver: Same URI to subscribe.
- **Stream ID**: A unique integer (e.g., `1001`) to identify this telemetry stream.

#### 3. Sender (Game) Implementation

The game serializes telemetry data with Cap’n Proto and publishes it via Aeron.

```cpp
#include "open_motion_telemetry.capnp.h"
#include <aeron/Aeron.h>
#include <aeron/Context.h>
#include <capnp/message.h>
#include <capnp/serialize.h>

class TelemetrySender {
public:
    TelemetrySender() {
        // Configure Aeron context
        aeron::Context context;
        context.aeronDir("/tmp/aeron"); // Shared memory dir

        // Connect to Aeron
        aeron_ = aeron::Aeron::connect(context);
        if (!aeron_) {
            throw std::runtime_error("Failed to connect to Aeron");
        }

        // Add publication
        std::int64_t pubId = aeron_->addPublication("aeron:udp?endpoint=localhost:40123", 1001);
        publication_ = aeron_->findPublication(pubId);
        while (!publication_) {
            std::this_thread::yield(); // Wait for publication to connect
            publication_ = aeron_->findPublication(pubId);
        }
    }

    void sendTelemetry() {
        // Build Cap’n Proto message
        ::capnp::MallocMessageBuilder message;
        MotionTelemetry::Builder telemetry = message.initRoot<MotionTelemetry>();

        telemetry.setGameName("RacingSim");
        telemetry.setMaxSampleRate(60);
        telemetry.setTimestamp(std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());

        MotionObject::Builder obj = telemetry.initMotionObject();
        obj.setObjectName("player_car");
        obj.setPositionX(1.5);
        obj.setPositionY(2.0);
        obj.setPositionZ(0.0);
        // ... set other fields ...

        auto drivePoints = obj.initDrivePoints(1);
        drivePoints[0].setName("wheel_fl");
        drivePoints[0].setRpm(1200.0);

        // Serialize to flat array
        kj::Array<capnp::word> words = capnp::messageToFlatArray(message);
        kj::ArrayPtr<const char> bytes = words.asBytes();

        // Publish via Aeron
        aeron::atomic_buffer::AtomicBuffer buffer(
            reinterpret_cast<uint8_t*>(const_cast<char*>(bytes.begin())), bytes.size());
        std::int64_t result = publication_->offer(buffer);
        if (result < 0) {
            if (result == aeron::NOT_CONNECTED) {
                std::cerr << "Not connected yet\n";
            } else if (result == aeron::BACK_PRESSURED) {
                std::cerr << "Back pressured\n";
            } else {
                std::cerr << "Offer failed: " << result << "\n";
            }
        }
    }

private:
    std::shared_ptr<aeron::Aeron> aeron_;
    std::shared_ptr<aeron::Publication> publication_;
};

int main() {
    TelemetrySender sender;
    while (true) {
        sender.sendTelemetry();
        std::this_thread::sleep_for(std::chrono::milliseconds(16)); // ~60 Hz
    }
    return 0;
}
```

#### 4. Receiver (Motion Software) Implementation

The motion software subscribes to the Aeron stream and deserializes the Cap’n Proto data.

```cpp
#include "open_motion_telemetry.capnp.h"
#include <aeron/Aeron.h>
#include <aeron/Context.h>
#include <capnp/message.h>
#include <capnp/serialize.h>

class TelemetryReceiver {
public:
    TelemetryReceiver() {
        // Configure Aeron context
        aeron::Context context;
        context.aeronDir("/tmp/aeron");

        // Connect to Aeron
        aeron_ = aeron::Aeron::connect(context);
        if (!aeron_) {
            throw std::runtime_error("Failed to connect to Aeron");
        }

        // Add subscription
        std::int64_t subId = aeron_->addSubscription(
            "aeron:udp?endpoint=localhost:40123", 1001,
            [&](const aeron::atomic_buffer::AtomicBuffer& buffer, aeron::index_t offset, aeron::index_t length, const aeron::Header&) {
                onMessage(buffer, offset, length);
            },
            [](const std::string&) { std::cout << "Subscription online\n"; }
        );
        subscription_ = aeron_->findSubscription(subId);
        while (!subscription_) {
            std::this_thread::yield();
            subscription_ = aeron_->findSubscription(subId);
        }
    }

    void poll() {
        subscription_->poll(1); // Process 1 fragment at a time
    }

private:
    void onMessage(const aeron::atomic_buffer::AtomicBuffer& buffer, aeron::index_t offset, aeron::index_t length) {
        // Extract raw bytes
        const char* data = reinterpret_cast<const char*>(buffer.buffer() + offset);
        kj::ArrayPtr<const char> rawBytes(data, length);

        // Ensure word-aligned (Cap’n Proto requires 8-byte alignment)
        size_t wordCount = (length + 7) / 8; // Round up to nearest word
        kj::ArrayPtr<const capnp::word> words(reinterpret_cast<const capnp::word*>(data), wordCount);

        // Deserialize
        ::capnp::FlatArrayMessageReader message(words);
        MotionTelemetry::Reader telemetry = message.getRoot<MotionTelemetry>();

        // Use the data
        printf("Game: %s, Timestamp: %ld\n", telemetry.getGameName().cStr(), telemetry.getTimestamp());
        MotionObject::Reader obj = telemetry.getMotionObject();
        printf("Position: (%f, %f, %f)\n", obj.getPositionX(), obj.getPositionY(), obj.getPositionZ());
        if (obj.getDrivePoints().size() > 0) {
            printf("Wheel RPM: %f\n", obj.getDrivePoints()[0].getRpm());
        }
    }

    std::shared_ptr<aeron::Aeron> aeron_;
    std::shared_ptr<aeron::Subscription> subscription_;
};

int main() {
    TelemetryReceiver receiver;
    while (true) {
        receiver.poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(1)); // Avoid busy-wait
    }
    return 0;
}
```

#### 5. Running the System

1. **Start Media Driver** (if standalone):
   - `java -cp aeron-all-<version>.jar io.aeron.driver.MediaDriver`.
2. **Run Receiver**: Compile and launch the receiver app.
3. **Run Sender**: Compile and launch the sender app.
4. **Test**: Sender publishes at ~60 Hz; receiver prints telemetry data as it arrives.

---

### Key Considerations

1. **Performance**:
   - Aeron’s latency is sub-millisecond (e.g., 20-50 µs on localhost). At 60 Hz (16 ms/frame), this is negligible.
   - Cap’n Proto’s zero-copy deserialization keeps CPU overhead low.

2. **Buffering**:
   - `publication_->offer` may return `BACK_PRESSURED` if the receiver lags. Add retry logic or drop outdated frames:
     ```cpp
     while (publication_->offer(buffer) < 0) {
         std::this_thread::yield();
     }
     ```

3. **Multicast**:
   - For multiple receivers, change the channel to: `aeron:udp?endpoint=224.0.1.1:40123|interface=127.0.0.1`.
   - All subscribers use the same URI.

4. **Size**:
   - A minimal `MotionTelemetry` packet (timestamp + 12 floats) is ~64 bytes with Cap’n Proto, plus Aeron’s small header (~32 bytes). Total < 100 bytes, well under UDP MTU.

5. **Error Handling**:
   - Check Aeron connection status and Cap’n Proto message validity (e.g., `message.getRoot()` throws on corruption).

---

### Alternative: Embedded Media Driver

For a single-app setup, embed the driver:
```cpp
#include <aeron/MediaDriver.h>

// In main()
aeron::Context driverContext;
driverContext.aeronDir("/tmp/aeron");
auto driver = aeron::MediaDriver::launchEmbedded(driverContext);
// Then proceed with sender/receiver as above
```

---

### Why This Works for Motion Telemetry

- **Low Latency**: Aeron’s optimized UDP transport + Cap’n Proto’s zero-copy parsing ensures data hits the motion software fast.
- **Reliability**: Aeron’s ordering and optional logging beat raw UDP without TCP’s overhead.
- **Scalability**: Add more subscribers (e.g., debug tools) without changing sender code.

---

## Enhanced Aeron Implementation with Transport Abstraction

This section describes an enhanced implementation of the Local Telemetry Standard using Aeron as the transport layer, integrated with Cap’n Proto for serialization. The implementation abstracts the transport layer behind a high-level C API, uses a callback mechanism for receiving telemetry data, and supports extensibility for other transports (e.g., raw UDP). This implementation improves on the polling approach in the previous example by using a callback API for asynchronous data processing.

### Overview
- **Aeron**: Used for low-latency, reliable transport over UDP, with support for ordering and multicast.
- **Cap’n Proto**: Handles serialization of the telemetry data (see `implementation-capnproto.md` for the schema).
- **Transport Abstraction**: A `Transport` base class allows swapping transports without changing the high-level API.
- **Callback API**: Receivers register a callback to process incoming telemetry data asynchronously.
- **High-Level C API**: Developers interact with simple functions like `motion_telemetry_set_position_x`, hiding transport and serialization details.

### Transport Abstraction
The transport layer is abstracted via a C++ base class `Transport`, with `AeronTransport` as a derived implementation:

```cpp
class Transport {
public:
    virtual ~Transport() = default;
    virtual void setGameName(const std::string& name) = 0;
    virtual void setMaxSampleRate(int32_t rate) = 0;
    virtual void setTimestamp(int64_t timestamp) = 0;
    virtual void setPositionX(float x) = 0;
    virtual void setPositionY(float y) = 0;
    virtual void setPositionZ(float z) = 0;
    virtual void send() = 0;
    virtual void registerCallback(TelemetryCallback callback) = 0;
    virtual void startReceiving() = 0;
};
```

`AeronTransport` implements this interface using Aeron’s publication/subscription model. It uses Cap’n Proto to serialize the telemetry data into a compact binary format before publishing it over Aeron’s UDP transport.

### High-Level C API
The library exposes a C API (`motion_telemetry.h`) for developers to interact with the telemetry system:

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
The game sends telemetry data continuously at 60 Hz until the user stops it:

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

### Aeron Configuration
Use the channel and stream ID configuration defined in the "Define Aeron Channels" section above. The media driver can be run standalone or embedded, as described in the "Setup Aeron Environment" section.

### Benefits
- **Low Latency**: Aeron ensures sub-millisecond delivery, ideal for real-time motion telemetry.
- **Abstraction**: Developers use a simple C API without touching Aeron directly.
- **Extensibility**: Add new transports (e.g., raw UDP) by implementing the `Transport` interface.
- **Asynchronous Processing**: The callback API simplifies real-time telemetry processing by handling data as it arrives.

See `implementation-capnproto.md` for details on the serialization format.

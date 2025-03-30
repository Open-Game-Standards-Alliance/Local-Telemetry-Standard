# Open Game Standards Alliance: Local Telemetry Standard (LTS)

The Local Telemetry Standard (LTS) provides a standardised method and format for exposing relevant telemetry data to hardware and software on the users local network.

It defines a logical minimal set of required telemetry to meet the standard, while also allowing developers the flexibility to include additional telemetry data in a well documented structure and format.

It defines the network protocols and provides tools to aid implementation in multiple game engines.

## Scope

The scope of the LTS encompasses the following key areas:

### Telemetry Transmission

The LTS defines common methodologies and protocols for transmitting a wide range of telemetry data to local software/hardware to provide expanded abilities for:

    - Motion Simulation
    - Haptics and Feedback
    - Performance logging, tracking and reporting tools

### Data Formatting

The LTS establishes standardized formats and schemas for organizing and structuring telemetry data, ensuring consistency and compatibility across different gaming platforms, devices, and software systems.

### Data Transmission

The LTS specifies standardized communication protocols and APIs for transmitting telemetry data to devices and software on the users local network.

## What OGTS Does Not Cover

While the LTS aims to provide a comprehensive framework for local telemetry transmission in the gaming industry, it does not cover the following areas:

### Game Content

The LTS does not dictate or regulate the content, design, or gameplay features of individual games. It focuses solely on the formatting, and transmission of telemetry data for devices and software on the users local network.

### Hardware Specifications

The LTS does not prescribe specific hardware requirements or standards for gaming devices or platforms. It is platform-agnostic and designed to be compatible with a wide range of hardware configurations and operating environments.

### Business Models

The LTS does not dictate or influence the business models, pricing strategies, or monetization methods adopted by game developers, publishers, or platform providers. It focuses exclusively on technical standards and practices related to telemetry data management.

## Requirements

- Data structure must be easily understandable
- Protocol must support multiple clients without the need for opening additional ports or proxying
- Must be implementable in both console and PC context
- Must allow structured addition of extra telemetry datapoints

## Constraints and limitations

- Must be network efficient
- Must have low latency at all areas of implementation
- Does not allow update of data within game (read-only) *TBC*

## Examples and Scenarios

1. User plays game on a console, uses PC with motion control software to control a motion simulator and haptics devices using telemetry from the console game.

2. User plays game on PC, has created a realistic physical cockpit matching that of game, uses telemetry data fed into software client that controls the devices on the physical cockpit.

3. User plays game on PC or Console, a software client is able to log performance metrics over multiple sessions and provides a user friendly interface showing user performance and progression over time.

## Decision Points and Trade-offs

With the need to support console devices any implementation method that only works with telemetry client software, or hardware directly running or connected to the device executing the game will not be entertained.

## Implementation

### Data format

We propose using Cap'n Proto as the data format. Cap’n Proto is a zero-copy, binary serialization format optimized for speed and efficiency, making it an excellent choice for sending motion telemetry data over UDP. It avoids encoding/decoding overhead by using a memory-aligned layout, and it supports optional fields and nested structures efficiently.

[Implementation details for Cap'n Proto data format](implementation-capnproto.md).

### Data Transport

We propose using Aeron as the data transport. Aeron is a high-performance messaging library that provides low-latency, reliable communication over UDP. It is designed to work well in environments with high message rates and low latency requirements, such as gaming. It allows for multicasting, which can be useful if multiple clients need to receive the same telemetry data.

[Implementation details for Aeron data transport](implementation-aeron.md).
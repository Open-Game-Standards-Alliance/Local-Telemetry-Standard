# Open Motion Alliance Telemetry Standard (Work in Progress)

There is a gaping hole in tools to help game developers add motion simulator support to their games, primarily the lack of a standard for doing so.

So I have set out to remedy the situation by doing the following:

- Step 1: Define a draft standard schema for motion data that is agnostic of the vehicle type https://github.com/Open-Motion-Alliance/Standard
- Step 2: Seek input from developers of games and motion software (current step)
- Step 3: Refine and ratify standard
- Step 4: Source developers to work on game engine plugins to output data in this schema
- Step 5: Develop plugins for game engines and motion software
- Step 6: Spread the tools to game developers and game consumers

## Why the Need?

Integrating motion data into games is often a daunting task due to incompatible formats and complex integration processes. The Open Telemetry Alliance Standard aims to eliminate these obstacles by providing a unified framework for motion data exchange.

## Enabling Seamless Integration

The aim is to provide free plugins for common Game engines facilitating effortless integration and unlocking new levels of realism.

With these plugins, game developers will be able to seamlessly incorporate motion data output into their projects, focusing on creating immersive experiences without worrying about compatibility issues.

## Empowering Motion Software

With a standardized format for telemetry the work to create plugins in Motion software plugins will be greatly reduced, it would most  even be possible to create a meta-plugin that would work for any game supporting the standard

## Join the Movement

Join us in shaping the future of motion integration in gaming with the Open Telemetry Alliance Standard. Together, we can redefine the possibilities of immersive gameplay experiences. https://discord.gg/2CEdbKYKsn

PS: Particurlarly looking for game developers with motion telemetry experience, be that developing games or plugins for motion tools.


# Proposal (Work in Progress)

Creating a standard for motion telemetry in video games involves establishing a set of guidelines or specifications that game developers can adhere to when implementing motion tracking and telemetry systems. Here's a proposal for such a standard:

1. **Data Format**: JSON (JavaScript Object Notation) is a lightweight data-interchange format. It is easy for humans to read and write. It is easy for machines to parse and generate. While JSON is probably the most popular format for exchanging data, JSON Schema is the vocabulary that enables JSON data consistency, validity, and interoperability at scale. Therefore the standard is [defined using JSON Schema](https://github.com/Open-Motion-Alliance/Standard/blob/main/open-motion-alliance-schema-v1.0.json).

2. **Units of Measurement**: Should specify the units of measurement to be used for each type of motion data (e.g., meters for position, radians for rotation, meters per second for velocity).

3. **Sampling Rate**: Establish a recommended sampling rate for capturing motion data. This should strike a balance between accuracy and performance, ensuring smooth motion without excessive computational overhead.

4. **Device Compatibility**: Identify compatible motion tracking devices and technologies that adhere to the standard. This may include accelerometers, gyroscopes, motion capture systems, VR controllers, etc.

5. **Calibration Procedures**: Define procedures for calibrating motion tracking devices to ensure accuracy and consistency across different hardware setups.

6. **Data Transmission**: UDP multicast so multiple client applications can inspect streamed data at the same time.

7. **Integration with Game Engines**: Provide guidelines for integrating motion telemetry data into popular game engines such as Unity or Unreal Engine. This may involve creating APIs or plugins to facilitate seamless integration.

8. **Data Privacy and Security**: Address concerns related to the collection and transmission of motion telemetry data, including privacy issues and security vulnerabilities. Implement encryption and authentication mechanisms to protect sensitive data.

9. **Error Handling**: Schema will define Min/Max values, data will contain timestamp. These allow for motion software plugins to drop late packets and values outside of allowed range.

10. **Documentation and Support**: Develop comprehensive documentation and support resources to assist developers in implementing the standard effectively. This could include tutorials, sample code, troubleshooting guides, and community forums.

11. **Testing and Certification**: Output of implementations can be validated against the schema using tools linked at https://json-schema.org/implementations#validators

12. **Versioning and Updates**: Plan for future updates and revisions to the standard to accommodate advances in technology and address feedback from developers and users.

By establishing a standard for motion telemetry in video games, developers can benefit from interoperability, improved compatibility, and reduced development time when implementing motion tracking features in their games. Additionally, players can enjoy a more consistent and immersive gaming experience across different platforms and hardware devices.

## Example telemetry output

```json
{
    "schema": "https://raw.githubusercontent.com/Open-Motion-Alliance/Standard/main/open-motion-alliance-schema-v1.0.json",
    "timestamp": 1649125392,
    "gameName": "Awesome Simulation Game",
    "maxSampleRate": "120",
    "motionObject": {
        "objectLocation": "track name",
        "objectName": "Name of Vehicle",
        "objectType": "aircraft, atv, boat, helicopter, hovercraft, motorcycle, spacecraft, submersible, tank, terrestrial, train, truck",
        "accelerationX": 2.0,
        "accelerationY": 0.0,
        "accelerationZ": 0.0,
        "positionX": 0.0,
        "positionY": 0.0,
        "positionZ": 0.0,
        "rotationX": 0.0,
        "rotationY": 0.0,
        "rotationZ": 0.0,
        "velocityX": 0.0,
        "velocityY": 0.0,
        "velocityZ": 0.0,
        "drivePoints": [
            {
                "name": "front_left",
                "type": "wheel",
                "currentTerrain": "asphalt",
                "cogOffsetX": 123.45,
                "cogOffsetY": 67.89,
                "cogOffsetZ": 100.0,
                "travelX": [0.25, -0.25, 0.0],
                "travelY": [0.25, -0.25, 0.0],
                "travelZ": [0.25, -0.25, 20.0],
            }
        ],
        "aerodynamics": {
            "lift_coefficient": 0.7,
            "drag_coefficient": 0.25,
            "yaw_moment_coefficient": 0.1
        },
        "feedbackItem": [
            {
              "name": "altitude",
              "type": "integer",
              "unit": "meters",
              "current": 1000,
              "max": 5000,
              "min": -5000
            },
            {
              "name": "environment_pressure",
              "type": "integer",
              "unit": "bar",
              "current": 100,
              "max": 200,
              "min": -200
            },
            {
              "name": "gear",
              "type": "integer",
              "measurement": "gear",
              "current": 3,
              "max": 6,
              "min": -1
            },
            {
              "name": "rpm",
              "type": "integer",
              "unit": "rpm",
              "max": 8000,
              "min": 0
            },
            {
              "name": "speed",
              "type": "integer",
              "unit": "m/s",
              "current": 50,
              "max": 300,
              "min": -20
            },
            {
              "name": "headlights",
              "type": "boolean",
              "current": true
            },
            {
              "name": "wiper_front",
              "type": "boolean",
              "current": true
            },
            {
              "name": "heading",
              "current": {"x": 2.0, "y": 0.0, "z": 0.0}, // radians
            },
            "elevator": 0.2,
            "aileron": 0.1,
            "rudder": 0.05,
            "dive_plane": 0.3,
            "engine": {
              "throttle_position": 50, // percentage
              "power_output": 200,
              "fuel_flow_rate": 1500,
              "temperature": 150
            }
        ]
    },
    "environment": {
        "density": 0.5,
        "temperature": -20,
        "temperature_metric": "celcius",
        "pressure": 50,
        "pressure_metric": "bar",
        "gravity": 1.6
    },
}
```

- `schema`: URI of schema version used for this data
- `timestamp`: Current game timestamp, for motion software plugin to know order of packets and what to ignore
- `gameName`: Name of game that is outputting this data
- `maxSampleRate`: Maximum samples per minute motion software plugin can poll at

#### Motion Object

The `motionObject` array holds information about the game object that is defining simulator movement.

- `objectName`: Name of the object, should be unique per game to allow for motion profile tweaking per object
- `objectLocation`: Location of the object. eg. place, airport code, track nam
- `objectType`: Type of the vehicle (e.g., Aircraft, ATV, Boat, etc.).
- `accelerationX`: Current acceleration in x direction.
- `accelerationX`: Current acceleration in y direction.
- `accelerationX`: Current acceleration in z direction.
- `positionX`: Current position of the vehicle in 3D space.
- `positionY`: Current position of the vehicle in 3D space.
- `positionZ`: Current position of the vehicle in 3D space.
- `rotationX`: Current rotation of the vehicle in 3D space.
- `rotationY`: Current rotation of the vehicle in 3D space.
- `rotationZ`: Current rotation of the vehicle in 3D space.
- `velocityX`: Current velocity of the vehicle in 3D space.
- `velocityY`: Current velocity of the vehicle in 3D space.
- `velocityZ`: Current velocity of the vehicle in 3D space.
- `aerodynamics`: Object containing aerodynamic properties of the vehicle, such as lift coefficient, drag coefficient, and yaw moment coefficient.

#### Drive Points

The `drivePoints` array provides information about each drive point (propulsion object), including name, type, currentTerrain, centre of gravity offsets, travel distance and stiffness. Declare as many as required.

#### Feedback Items

The `feedbackItems` array provides feedback data about the vehicle. This can be used for things like altitude, speedometer, gear, etc. Declare as many array objects as desired. This needs more refinement.

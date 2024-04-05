# Open Motion Alliance API Proposal (Work in Progress)

Creating a standard for motion telemetry in video games involves establishing a set of guidelines or specifications that game developers can adhere to when implementing motion tracking and telemetry systems. Here's a proposal for such a standard:

1. **Data Format**: JSON (JavaScript Object Notation) is a lightweight data-interchange format. It is easy for humans to read and write. It is easy for machines to parse and generate.

2. **Units of Measurement**: Should specify the units of measurement to be used for each type of motion data (e.g., meters for position, radians for rotation, meters per second for velocity).

3. **Sampling Rate**: Establish a recommended sampling rate for capturing motion data. This should strike a balance between accuracy and performance, ensuring smooth motion without excessive computational overhead.

4. **Device Compatibility**: Identify compatible motion tracking devices and technologies that adhere to the standard. This may include accelerometers, gyroscopes, motion capture systems, VR controllers, etc.

5. **Calibration Procedures**: Define procedures for calibrating motion tracking devices to ensure accuracy and consistency across different hardware setups.

6. **Data Transmission**: UDP multicast so multiple client applications can inspect streamed data at the same time.

7. **Integration with Game Engines**: Provide guidelines for integrating motion telemetry data into popular game engines such as Unity or Unreal Engine. This may involve creating APIs or plugins to facilitate seamless integration.

8. **Data Privacy and Security**: Address concerns related to the collection and transmission of motion telemetry data, including privacy issues and security vulnerabilities. Implement encryption and authentication mechanisms to protect sensitive data.

9. **Error Handling**: Always providing Min/Max values will allow for motion software to drop values outside of allowed range.

10. **Documentation and Support**: Develop comprehensive documentation and support resources to assist developers in implementing the standard effectively. This could include tutorials, sample code, troubleshooting guides, and community forums.

11. **Testing and Certification**: Establish testing criteria and certification processes to ensure compliance with the standard. This may involve third-party certification bodies or self-certification by developers.

12. **Versioning and Updates**: Plan for future updates and revisions to the standard to accommodate advances in technology and address feedback from developers and users.

By establishing a standard for motion telemetry in video games, developers can benefit from interoperability, improved compatibility, and reduced development time when implementing motion tracking features in their games. Additionally, players can enjoy a more consistent and immersive gaming experience across different platforms and hardware devices.

```json
{
    "api_version": "1.0",
    "maximum_sampling_rate": "120", // maximum samples per minute motion software plugin can use
    "game_name": "Awesome Simulator",
    "timestamp": 1649125392,
    "environment": {
        "density": 0.5,
        "temperature": -20,
        "temperature_metric": "celcius",
        "pressure": 50,
        "pressure_metric": "bar",
        "gravity": 1.6
    },
    "player": {
        "location": "place, airport code, track name",
        "vehicle": {
            "acceleration": {
              "measurement": "m/s^2",
              "type": "float",
              "x": {
                "current": 2.0,
                "max": 0,
                "min": 255
              },
              "y":{
                "current": 0.0,
                "max": 0,
                "min": 255
              },
              "z":{
                "current": 0,
                "max": 0,
                "min": 255
              }
            },
            "position": {
              "measurement": "meters",
              "type": "float",
              "x": {
                "current": 123.45,
                "max": 0,
                "min": 255
              },
              "y":{
                "current": 67.89,
                "max": 0,
                "min": 255
              },
              "z":{
                "current": 100.0,
                "max": 0,
                "min": 255
              }
            },
            "rotation": {
              "measurement": "radians",
              "type": "float",
              "x": {
                "current": 0.0,
                "max": 0,
                "min": 255
              },
              "y":{
                "current": 0.0,
                "max": 360,
                "min": 0
              },
              "z":{
                "current": 45.0,
                "max": 360,
                "min": 0
              }
            },
            "velocity": {
              "measurement": "m/s",
              "type": "float",
              "x": {
                "current": 30.0,
                "max": 0,
                "min": 255
              },
              "y":{
                "current": 0.0,
                "max": 0,
                "min": 255
              },
              "z":{
                "current": 0,
                "max": 0,
                "min": 255
              }
            },
            "vehicle_type": "Aircraft, ATV, Boat, Helicopter, Hovercraft, Motorcycle, Spacecraft, Submersible, Tank, Terrestrial, Train, Truck",
            "vehicle_name": "Name of Vehicle",
            "drive_system": {
                 "drive_point": [
                     {
                         "name": "front_left",
                         "type": "wheel, propeller, jet, track, sail, waterjet, leg",
                         "position": {
                            "measurement": "metres", // distance from centre +/- meters
                            "type": "float",
                            "offset_x": 123.45,
                            "offset_y": 67.89,
                            "offset_z": 100.0
                          },
                         "suspension": {
                            "type": "float",
                            "stiffness": 0.4,
                            "travel": 0.3,
                            "terrain": "atmosphere, asphalt, dirt, rumble strip, liquid"
                          }
                     },
                     {
                         "name": "front_right",
                         "type": "wheel, propeller, jet, track, sail, waterjet, leg",
                         "position": {
                            "measurement": "metres", // distance from centre +/- meters
                            "type": "float",
                            "offset_x": 123.45,
                            "offset_y": 67.89,
                            "offset_z": 100.0
                          },
                         "suspension": {
                            "type": "float",
                            "stiffness": 0.4,
                            "travel": 0.3,
                            "terrain": "gas, liquid, solid"
                          }
                     },
                     {
                         "name": "rear_left",
                         "type": "wheel, propeller, jet, track, sail, waterjet, leg",
                         "position": {
                            "measurement": "metres", // distance from centre +/- meters
                            "type": "float",
                            "offset_x": 123.45,
                            "offset_y": 67.89,
                            "offset_z": 100.0
                          },
                         "suspension": {
                            "type": "float",
                            "stiffness": 0.4,
                            "travel": 0.3,
                            "terrain": "gas, liquid, solid"
                          }
                     },
                     {
                         "name": "rear_right",
                         "type": "wheel, propeller, jet, track, sail, waterjet, leg",
                         "position": {
                            "measurement": "metres", // distance from centre +/- meters
                            "type": "float",
                            "offset_x": 123.45,
                            "offset_y": 67.89,
                            "offset_z": 100.0
                          },
                         "suspension": {
                            "type": "float",
                            "stiffness": 0.4,
                            "travel": 0.3,
                            "terrain": "gas, liquid, solid"
                          }
                     }
                  ]
                },
                "aerodynamics": {
                    "lift_coefficient": 0.7,
                    "drag_coefficient": 0.25,
                    "yaw_moment_coefficient": 0.1
                }
            },
            "vehicle_feedback": {
                "altitude": {
                  "type": "integer",
                  "measurement": "meters",
                  "current": 1000,
                  "max": 5000,
                  "min": -5000
                },
                "environment_pressure": {
                  "type": "integer",
                  "measurement": "bar",
                  "current": 100,
                  "max": 200,
                  "min": -200
                },
                "gear": {
                  "type": "integer",
                  "measurement": "gear",
                  "current": 3,
                  "max": 6,
                  "min": -1
                },
                "rpm": {
                  "type": "integer",
                  "measurement": "rpm",
                  "max": 8000,
                  "min": 0
                },
                "speed": {
                  "type": "integer",
                  "measurement": "m/s",
                  "current": 50,
                  "max": 300,
                  "min": -20
                },
                "headlights": {
                  "type": "boolean",
                  "current": true
                },
                "wiper_front": {
                  "type": "boolean",
                  "current": true
                },
                "heading": {"x": 2.0, "y": 0.0, "z": 0.0}, // radians
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
            }
        }
    }
}
```

### Player

The `player` object contains data related to the player's vehicle.

#### Vehicle

The `vehicle` object holds information about the player's vehicle.

- `acceleration`: Current acceleration in x, y, and z directions.
- `position`: Current position of the vehicle in 3D space.
- `rotation`: Current rotation of the vehicle in 3D space.
- `vehicle_type`: Type of the vehicle (e.g., Aircraft, ATV, Boat, etc.).
- `vehicle_name`: Name of the vehicle.
- `velocity`: Current velocity of the vehicle in x, y, and z directions.

#### Drive System

The `drive_system` object describes the propulsion and aerodynamics of the vehicle.

- `drive_points`: Information about each drive point, including type, position, suspension stiffness, travel, and terrain. Declare as many as required.
- `aerodynamics`: Aerodynamic properties of the vehicle, such as lift coefficient, drag coefficient, and yaw moment coefficient.

#### Vehicle Feedback

The `vehicle_feedback` object provides feedback data about the vehicle. Declare as many subkeys as desired. This needs more refinement.

```
                "[feedbackitemname]": {
                  "type": "boolean, float, integer, number, object, string", // < one of.. https://www.w3schools.com/js/js_datatypes.asp
                  "measurement": "meters", // measurment scale, only required if numeric
                  "current": 1000, // curent value
                  "max": 5000, // maximum value, only required if numeric
                  "min": -5000 // minimum value, only required if numeric
                },
```

- `gear`: Current gear of the vehicle.
- `speed`: Current speed of the vehicle.
- `heading`: Current heading direction of the vehicle.
- `elevator`, `aileron`, `rudder`, `dive_plane`: Control inputs for adjusting the vehicle's movement.
- `rpm`: Current and maximum RPM of the vehicle's engine.
- `engine`: Details about the engine, including throttle position, power output, fuel flow rate, and temperature.
- `environment_pressure`: Current and maximum pressure experienced by the vehicle's environment.
- `altitude`: Current altitude and maximum/minimum altitude the vehicle can reach.

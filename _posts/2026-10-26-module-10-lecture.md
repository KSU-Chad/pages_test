---
title: "Module 10 — Seeing the World: Lidar, Depth Cameras, Gazebo & RViz"
date: 2026-10-26 01:15:00 -0500
categories: [Module 10, Sensors in Simulation]
tags: [ros2, lidar, depth-camera, gazebo, rviz, interoperability, mentorpi, laserscan, pointcloud]
pin: false
---

<style>
.term {
  background: #1F1235;
  border-radius: 10px;
  padding: 14px 20px 20px;
  margin: 1.3em 0;
  box-shadow: 0 6px 18px rgba(0,0,0,0.28);
  overflow-x: auto;
}
.term-dots {
  margin-bottom: 10px;
}
.term-dots span {
  display: inline-block;
  width: 11px;
  height: 11px;
  border-radius: 50%;
  margin-right: 6px;
}
.term-dots span:nth-child(1) { background: #E8554E; }
.term-dots span:nth-child(2) { background: #F2C94C; }
.term-dots span:nth-child(3) { background: #27C93F; }
.term-body {
  margin: 0;
  background: transparent;
  border: none;
  padding: 0;
  font-family: "Courier New", Consolas, monospace;
  font-size: 0.92em;
  line-height: 1.6;
  color: #D1D1D1;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>

# ROS2 Review, Lidar, RGBD Camera, & Interoperability

## Part 1 — A Quick Review: Five Ways to Communicate

You have now used five ideas. Here they are on **our** robot.

| Idea | What it is | On our MentorPi | How to look at it |
|---|---|---|---|
| **Node** | One running program | `safety_gate`, `drive_distance`, `robot_state_publisher` | `ros2 node list` |
| **Topic** | A stream of messages anyone can listen to | `/cmd_vel_raw`, `/odom`, `/scan_raw` | `ros2 topic list` |
| **Service** | A quick question and a single answer | `/stop`, `/enable_motion` | `ros2 service list` |
| **Parameter** | A setting stored on a node | `max_speed`, `use_sim_time` | `ros2 param list` |
| **Action** | A long job with progress and a cancel | `/drive_distance` | `ros2 action list` |

- **Topics** are for data that keeps flowing.
- **Services** are for one-time requests.
- **Actions** are for jobs that take time.
- **Parameters** are for settings you want to change without editing code
- This module adds a new idea: **sensor data**. It flows continuously, so it's a topic

---

## ✏️ Pick the Right One

Topic, service, parameter, or action? Decide before you open the answers.

| # | The job |
|---|---|
| 1 | The lidar reports what it sees, ten times a second |
| 2 | Turn the camera on or off |
| 3 | Change the lidar's minimum range without editing the file |
| 4 | "Drive forward until something is closer than 0.5 m" |
| 5 | Ask the robot "are you in motion mode right now?" |
| 6 | The depth camera publishes a picture, fifteen times a second |

<details markdown="1">
<summary>Answers</summary>

1. **Topic.** It's a continuous stream.
2. **Service.** It's a one-time request with a yes/no result, like `/enable_motion`.
3. **Parameter.** It's a setting. (Some parameters can be changed while the node runs, like `max_speed`.)
4. **Action.** It takes time, you want progress, and you may want to cancel.
5. **Service** (or a topic, if the robot kept announcing its mode).
6. **Topic.** Same reason as 1.

</details>

---

## Part 2 — Gazebo vs RViz

We have used both Gazebo and RViz, so what is their purpose? Both show the robot, but they do very different jobs.

| | **Gazebo** | **RViz** |
|---|---|---|
| **What it is** | A **physics simulator** | A **visualizer** |
| **Job** | Makes a pretend world: walls, floors, physics, and sensors that produce data | Draws data that is already being published |
| **Where does its data come from?** | From its own simulated world (the walls, floor, and robot you see in Gazebo) | From ROS 2 topics. It doesn't know or care whether a simulator, a real robot, or a recorded rosbag is publishing them |
| **If you close it...** | The simulated robot and its sensors disappear, so nothing publishes sensor data anymore | Gazebo and the sensors keep running and publishing. You just can't see the data until you reopen RViz |

- Think of Gazebo as the movie set: the walls, the floor, and the robot all exist there.
- Think of RViz as the monitor in the control room. It shows what the robot’s sensors are reporting, but it doesn’t make it's own data.

```
Gazebo  --->  ros_gz_bridge  --->  ROS 2 topics  --->  RViz
(the world)   (translator)         /scan_raw           (the display)
                                   /odom
                                   /ascamera/...
```

- **RViz never talks to Gazebo.** It only subscribes to ROS 2 topics. That's why the same RViz setup will work on the real robot later: it doesn't know or care who published the data
- Gazebo has its **own** message system (`gz topic`). It is separate from ROS 2. The **bridge** copies messages from one to the other. If a topic exists in Gazebo but not in ROS 2, the bridge is the first suspect
- Gazebo knows the **truth** (the wall really is 1.93 m away). A sensor gives a **measurement** of the truth, with noise and limits. RViz shows the measurement. That gap between truth and measurement is a big part of robotics

> 📷 **[SCREENSHOT: Gazebo with the robot, the wall, the blue box, and the green cylinder]**
 ![Gazebo with robot, wall, blue box and green cylinder](/assets/gazebo_obstacles.png)

> 📷 **[SCREENSHOT: RViz showing the same scene as Gazebo but with LaserScan points]**
![RViz with robot, and LaserScan](/assets/rviz_obstacles.png)


### Truth vs Odometry: Why the Points Can Swing

- Gazebo knows where the robot really is. ROS only knows what the robot **thinks**, from `odom`, which is computed from how far the wheels turned
- Wheels slip, so `odom` **drifts**. Drive around for a while and the robot's idea of its position wanders away from the truth
- RViz draws everything relative to the **Fixed Frame**. With `odom` as the Fixed Frame, anything that depends on odom wobbles when odom is wrong
- This is exactly the problem that SLAM and localization exist to fix, and why robots add a lidar
- **If the scan looks like it's rotating more than the robot, check these first:**
  - Is the Fixed Frame really what you think it is? (`odom` vs `base_footprint` vs a camera frame)
  - Is the LaserScan **Decay Time** above 0? Old points stick around and look like smears
  - Is the simulation running slower than real time? Timing lag between the scan and the transform makes points lag the robot
  - Try a slow turn vs a fast one. If slow looks right and fast looks wrong, it's timing and not slip

---

## ✅ Checkpoint

**You close the Gazebo window while RViz is open. What happens in RViz, and why?**

<details markdown="1">
<summary>Answer</summary>

The scan and camera displays stop updating (and eventually go empty or stale), because the simulated sensors lived in Gazebo and are now gone, so nothing publishes. RViz itself is fine. It's still running and still subscribed. It just has nothing to draw.

</details>

---

## Part 3 — Why ROS 2? Interoperability

Here is the biggest benefit of ROS 2, and the main idea of this module.

**A sensor is just something that publishes a standard message on a topic.**

- A lidar driver reads the lidar's hardware and publishes a `sensor_msgs/LaserScan` message
- Anything that wants lidar data subscribes to that topic and reads that message type
- The lidar's brand, its connection, and its internal method **don't matter** to the subscriber

```
 Hardware          Driver                 Topic                  Consumers
+-----------+    +------------------+   +-------------+    +-------------------+
| LD19      | -> | ldlidar driver   | ->|             | -> | RViz              |
+-----------+    +------------------+   |             |    | your safety-stop  |
| MS200     | -> | ms200 driver     | ->| /scan_raw   | -> | SLAM, Nav2        |
+-----------+    +------------------+   | LaserScan   |    | rosbag2           |
| Gazebo    | -> | ros_gz_bridge    | ->|             | -> |                   |
+-----------+    +------------------+   +-------------+    +-------------------+
   (swap these)     (swap these)         (the contract)       (don't change)
```

- Everything on the left can be **replaced**. Everything on the right **stays the same**. The topic in the middle is the **contract**
- You've already seen this. Hiwonder's own launch files choose between several lidars (MS200, LD19, and others) with an environment variable. Whatever they pick, it ends up on the same kind of topic. And **our simulator is just another "lidar"** that publishes the same message
- That's why we can build the system in simulation now and move it to the real robot later, with little or no change

### What Makes the Contract

For two parts of the system to work together, they must agree on:

| Agreement | Our example |
|---|---|
| **Topic name** | `/scan_raw` |
| **Message type** | `sensor_msgs/msg/LaserScan` |
| **Frame** (`frame_id` in the header) | `lidar_frame` |
| **Units and axes** | meters, radians, x forward, y left, z up (REP-103) |
| **QoS** | sensors usually use "best effort" (REP-2003) |

- If any one of these differs, the connection fails quietly. Nothing crashes. The data just never arrives, or lands in the wrong place

### "The Same or Similar"

- Two lidars won't produce *identical* data. They differ in range, number of points, and speed
- The message type has **fields** that describe those differences (`range_max`, `angle_increment`). Good code **reads the fields** and doesn't assume numbers like "450 points"
- Example: a depth camera may report distance as a decimal number in meters, and another camera may report whole millimeters. Both are allowed. The message has an `encoding` field that tells you which. Code that ignores it will be wrong by a factor of 1000

### When the Contract Bends: Same Message, Different Configuration

- "Same message type" does **not** mean "same numbers." Moving from one lidar to another is where code quietly breaks
- Before you trust a scan, **inspect** it. One command shows the setup without printing the whole list:

```bash
ros2 topic echo /scan_raw --once --no-arr
```

| Field | What it tells you | What can differ between lidars |
|---|---|---|
| `frame_id` | Where the lidar is mounted on the robot | Different link name, different mounting orientation |
| `angle_min` | The angle of reading number 0 (the **start angle**) | One lidar starts at -pi, another at 0, another at some other angle |
| `angle_max` | The angle of the last reading | Not every lidar sees a full circle. Some have a blind arc |
| `angle_increment` | The step between readings (the **resolution**) | 0.8 degrees (0.01399 radians) on one, 0.25 degrees on another |
| `len(ranges)` | How many readings per scan | 450 on one, 1,000+ on another |
| `range_min`, `range_max` | The valid distance window | 0.12 m to 12 m on one, 0.15 m to 40 m on another |
| `scan_time` | How long one full turn takes | 10 Hz on one, 5 Hz on another |
| `intensities` | How strong each return was | Some lidars fill it in, some leave it empty |

- **Direction.** By ROS convention (REP-103), the angle grows **counterclockwise** looking down from above, with 0 straight ahead along x. A driver or a lidar mounted differently may start somewhere else or count the other way. The message tells you through `angle_min` and `angle_increment`
- **Invalid readings.** The convention is `inf` for "nothing hit." Some drivers publish `0.0` instead. Know which yours does
- **Which index is straight ahead?** Don't guess. Compute it from the message:

```
index_ahead = (0 - angle_min) / angle_increment
```

| Lidar | `angle_min` | `angle_increment` | Index straight ahead |
|---|---|---|---|
| Our simulated lidar | -3.14159 | 0.01398 | (3.14159 / 0.01398) = about **225** |
| A lidar that starts at 0 | 0 | 0.01398 | **0** |
| A lidar that starts at -pi with twice the readings | -3.14159 | 0.00699 | about **450** |

- Code that says "look at readings 220 to 230" is correct for exactly **one** lidar. Code that computes the index from `angle_min` and `angle_increment` works for all of them
- **Resolution matters at distance.** The gap between neighboring readings is about `distance x angle_increment`. At 0.014 rad and 5 m that's about 7 cm, so a thin object like a chair leg can slip between two readings. A finer resolution catches it

### ✏️ Work It By Hand: Swap the Lidar

Your safety-stop was written and tested against the simulated lidar. Tomorrow you replace it with a lidar that reports `angle_min = 0.0`, `angle_increment = 0.00873` (half a degree), and `range_max = 8.0`.

**1.** How many readings are in a full 360-degree turn?

**2.** Which index points straight ahead?

**3.** Which index points to the left (90 degrees)?

**4.** Your code skips any reading above 12.0 m as invalid. Is that still right?

<details markdown="1">
<summary>Answers</summary>

1. 2 pi / 0.00873 = about **720** readings.
2. (0 - 0) / 0.00873 = **0**. Straight ahead is the **first** reading, not the middle.
3. 1.571 / 0.00873 = about **180**.
4. **No.** The new `range_max` is 8.0, so the code should compare against `msg.range_max` from the message, not a number typed into the code.

None of that needed a new driver or a new message type. It just needed the code to **read the fields**.

</details>

### Conversions: LaserScan and PointCloud2

- **Is `PointCloud2` a better way to send a lidar's data than `LaserScan`?** No, they're different tools:

| | `LaserScan` | `PointCloud2` |
|---|---|---|
| Shape | A list of distances, one per angle (2D) | A list of points with x, y, z (3D) |
| Size | Small | Much larger |
| Needs the angle info? | Yes, from the message fields | No, each point already has a position |
| Used by | 2D SLAM, AMCL, Nav2 costmaps, simple safety-stops | 3D lidars, depth cameras, 3D mapping |
| Best for a 2D lidar | **Yes** | Only if a tool needs it |

- A 2D lidar's natural output is a `LaserScan`. Wrapping it in a `PointCloud2` makes the message bigger and gives you nothing new
- A depth camera's natural output is a `PointCloud2`. Many 2D tools can't read it directly
- **When the format doesn't match, convert it.** Standard ROS 2 packages do this so you don't rewrite the tool:
  - `pointcloud_to_laserscan` flattens a 3D cloud (such as a depth camera's) into a 2D `LaserScan` so a 2D tool can use it
  - `laser_geometry` converts a `LaserScan` into a `PointCloud2`
- That's interoperability again: if the tool wants a different format, you add a converter between them

### The Contract Covers the Data, Not the Extras

- The **data** (`LaserScan`) is standardized. Extra features are **driver-specific**
- Example: the RPLIDAR driver offers `/start_motor` and `/stop_motor` services. The LD19 driver we use doesn't have any like them
- So code that only reads `/scan_raw` moves between lidars easily. Code that calls a motor service is tied to one driver
- Rule of thumb: depend on the standard message, and treat anything beyond it as optional

### Other Benefits

- **Tools for free.** RViz, `rosbag2`, `rqt_graph`, and `ros2 topic` work with any topic of any robot
- **Software that expects the standard.** Navigation and mapping packages (Nav2, SLAM Toolbox) subscribe to `LaserScan`. Publish it and they work
- **Teamwork.** One person writes the driver, another the safety node, and neither needs the other's code

---

## Part 4 — How a 2D Lidar Works

**Lidar** means **Li**ght **D**etection **a**nd **R**anging.

- The sensor sends out a short pulse of light and measures how long it takes to come back
- Light travels at a known speed, so time gives distance:

```
distance = (speed of light x round-trip time) / 2
```

- The "divide by 2" is because the light goes out **and** back
- A **2D** lidar spins (or sweeps) so it repeats this in a circle, one distance for each angle. That gives a flat slice of the world, like looking at a floor plan from above
- A **3D** lidar does this in many planes at once and publishes a `PointCloud2`. A 2D lidar publishes a `LaserScan`

### 1D, 2D, and 3D

| Type | What it measures | Example | ROS 2 message |
|---|---|---|---|
| **1D** | One distance, in one direction (a "digital tape measure") | A handheld laser distance meter, a single-point sensor | `sensor_msgs/Range` |
| **2D** | A flat slice: one distance per angle | The LD19 on the MentorPi | `sensor_msgs/LaserScan` |
| **3D** | Many slices, or a distance for every pixel | A 3D lidar, a depth camera | `sensor_msgs/PointCloud2` |

- A 2D lidar is, in effect, a 1D sensor on a spinning mount that takes a reading at every angle
- The 1D sensor sends one number. The 2D lidar sends a list of numbers, plus the information needed to say **which direction each one points**

### 🔬 Demo: From a Laser Tape Measure to the LD19 (about 5 minutes)

**The 1D sensor (laser tape measure):**
- Point it at the wall and read one number
- That one number is a single `range`. Nothing else is needed, because the sensor only looks one way

**The 2D sensor (LD19 on the instructor's laptop):**
- The LD19 housing has a **mark that shows its zero direction**. Point that mark at the wall
- Echo the scan and look at `angle_min` and `angle_increment`

```bash
ros2 topic echo /scan_raw --once --no-arr
```

- **Predict, then check.** Using the formula from earlier, class works out which reading number should be pointing at the mark, then we check it by finding the short range in `ranges`
- Put a book at the mark, then 90 degrees to one side. Where does the short reading move to, and does it move toward a lower or a higher index?
- Compare the physical mark, the start angle in the message, and the resolution (readings per turn). If the real lidar doesn't match our simulated one, that's the lesson: the message tells you, so read it

---

## ✏️ Work It By Hand: Time of Flight

Use a speed of light of 3 x 10^8 m/s. A nanosecond (ns) is 10^-9 s.

| Round-trip time | Distance |
|---|---|
| 20 ns | ? |
| 40 ns | ? |
| 80 ns | ? |

<details markdown="1">
<summary>Answers</summary>

- 20 ns: (3 x 10^8 x 20 x 10^-9) / 2 = **3 m**
- 40 ns: **6 m**
- 80 ns: **12 m**, which is the maximum range of our simulated lidar

The times are tiny. The electronics inside the sensor have to measure differences of a few nanoseconds. That is one reason lidars are precise but costly.

</details>

---

## Anatomy of a `LaserScan`

One message holds one full turn of the lidar.

```
std_msgs/Header header        # timestamp and frame_id
float32 angle_min             # angle of the first reading, radians
float32 angle_max             # angle of the last reading, radians
float32 angle_increment       # angle between readings, radians
float32 time_increment        # time between readings
float32 scan_time             # time for a full scan
float32 range_min             # closest valid distance, meters
float32 range_max             # farthest valid distance, meters
float32[] ranges              # the distances, one per angle
float32[] intensities         # how strong each return was (may be empty)
```

- `ranges` is a **list**. The first number belongs to `angle_min`. Each next number is `angle_increment` further around
- To find the angle of reading number `i`:

```
angle = angle_min + i x angle_increment
```

- Our simulated lidar takes **450** readings around a full circle, so the spacing is about 2 pi / 450 = **0.014 rad (0.8 degrees)**
- Special values in `ranges`:
  - **`inf`** means "nothing was hit within range"
  - A value **below `range_min`** or **above `range_max`** is not trustworthy
  - **`nan`** means "no valid measurement"
- Good code skips those and uses only values inside `range_min` and `range_max`
- **`intensities`** is how strong each returning pulse was. A shiny or close surface returns more light than a dark or distant one. Many lidars fill it in, and RViz can color the scan by it. It's often empty, and our simulated lidar leaves it empty. Check before you use it

---

## ✏️ Work It By Hand: Which Reading Is Which?

Assume `angle_min = -3.14`, `angle_increment = 0.014`, and that angle 0 is straight ahead (x axis), positive angles are to the left.

| Index `i` | Angle (rad) | Direction |
|---|---|---|
| 0 | ? | ? |
| 225 | ? | ? |
| 337 | ? | ? |
| 100 | ? | ? |

<details markdown="1">
<summary>Answers</summary>

- `i = 0`: -3.14 rad, directly **behind** (180 degrees)
- `i = 225`: -3.14 + 225 x 0.014 = 0.01 rad, **straight ahead**
- `i = 337`: -3.14 + 337 x 0.014 = 1.58 rad, about 90 degrees, to the **left**
- `i = 100`: -3.14 + 1.4 = -1.74 rad, about -100 degrees, **right and a little behind**

So "what's directly ahead?" means "look at the readings around index 225."

On the real robot the numbers differ. Different lidars start their count at a different angle and may spin the other way. That's why the code must read `angle_min` and `angle_increment` from the message.

</details>

---

## What a 2D Lidar Can and Can't See

- It sees **one flat plane**, at the height of the sensor. On the MentorPi in simulation, that's about **0.16 m** above the floor
- Anything that doesn't reach that height is **invisible** to it, and so is anything above it
- Glass, mirrors, and very dark surfaces can fool it. Bright sunlight can too
- A lidar might hit parts of the **robot itself**, so we ignore anything closer than `range_min`

| Object | Does the lidar see it? |
|---|---|
| A box 0.30 m tall | ? |
| A box 0.10 m tall | ? |
| A table with a top at 0.7 m and thin legs | ? |
| A sign hanging at 0.5 m | ? |

<details markdown="1">
<summary>Answers</summary>

- 0.30 m box: **yes**. It crosses the 0.16 m plane. (This is why all our simulated obstacles are 0.3 m tall.)
- 0.10 m box: **no**. The scan passes over it.
- Table: **only the legs**. The lidar sees four thin posts and not the tabletop.
- Hanging sign: **no**. It's above the scan plane.

This is why robots that rely on lidar alone still bump into things. It's also a reason to add the depth camera, which sees a whole picture.

</details>

---


## Part 4 Wrap-Up

- Lidar measures distance with light, one reading per angle. The `LaserScan` message holds the list of readings and the numbers that describe them
- It sees one flat plane. Know the plane's height
- The same message works for any 2D lidar. That is interoperability

---


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

## Part 5 — How a Depth Camera Works

A normal camera gives a color for every pixel. A **depth camera** also gives a **distance** for every pixel.

| Method | How it measures depth |
|---|---|
| **Stereo** | Two cameras side by side. The shift of an object between the two pictures tells you how far it is (like your eyes) |
| **Structured light** | The camera projects a known pattern. Distortion of the pattern shows the shape |
| **Time of flight** | Like a lidar for every pixel: measure how long light takes to return |

<!-- INSTRUCTOR NOTE: add which method the MentorPi's ascamera depth camera uses once confirmed from the datasheet. -->

- All three give the same kind of result: a **depth image**, where each pixel value is a distance
- Our simulated camera, `rgbd_camera`, gives you three outputs at once:

| Output | ROS 2 message | What it is |
|---|---|---|
| Color image | `sensor_msgs/Image` | The normal picture |
| Depth image | `sensor_msgs/Image` | A picture where each pixel is a distance |
| Point cloud | `sensor_msgs/PointCloud2` | A list of 3D points (x, y, z), one per pixel |
| Camera info | `sensor_msgs/CameraInfo` | The camera's numbers (focal length, image size) |

> 📷 **[SCREENSHOT: the color image and the depth image in RViz]**

![RViz camera image](/assets/rviz_camera.png)
![RViz camera image](/assets/rviz_depth_camera.png)

---

## Camera Basics: What Is an Image?

- A camera sends light through a **lens** onto a **sensor**. The sensor records how much light hits each tiny spot. The result is a grid of numbers, one per **pixel**
- A **grayscale** image has one number per pixel (how bright). A **color** image has three: red, green, and blue (the **channels**)
- The usual size of each number is **8 bits**, so it ranges from 0 to 255. That's the `rgb8` in the `encoding` field. `bgr8` is the same three bytes in a different order, and OpenCV uses it
- Everything a ROS 2 node does with a camera starts from that grid of numbers

### Field of View and Focal Length

- **Focal length** (fx) is the distance from the lens to the sensor. A long focal length zooms in (narrow view). A short one zooms out (wide view)
- It only means something together with the sensor size, so cameras are usually described by **field of view (FOV)** instead:

```
horizontal FOV = 2 x atan( sensor_width / (2 x focal_length) )
```

- Robots usually want a **wide** view to see obstacles, so they use short focal lengths
- Check with our camera: `fx` is about 265 pixels and the image is 320 pixels wide, so FOV = 2 x atan(160 / 265) = 2 x 0.544 = **1.09 rad (62 degrees)**. That matches the `horizontal_fov` of 1.089 we set

### Raw Images Are Expensive

An image is a lot of numbers. Work out the cost:

| Camera setting | Bytes per frame | Frames per second | Data per second |
|---|---|---|---|
| 640 x 480, RGB | 640 x 480 x 3 = 921,600 | 15 | about **13.8 MB/s** (110 Mbit/s) |
| 320 x 240, RGB (ours) | 320 x 240 x 3 = 230,400 | 10 | about **2.3 MB/s** (18 Mbit/s) |
| A lidar scan, for comparison | 450 x 4 = 1,800 | 10 | about **0.018 MB/s** |

- The raw camera at full size moves about **750 times** more data than the lidar. That's why a Wi-Fi link can choke on camera video, and why our simulation slowed down until we lowered the image size
- **Compression** shrinks an image for sending:
  - **JPEG** is small but **lossy** (it blurs detail)
  - **PNG** is bigger but **lossless** (the pixels come back exactly)
- ROS 2 usually offers both forms of a camera topic: the raw `.../image_raw` and a compressed one, `.../image_raw/compressed` (a `sensor_msgs/CompressedImage`)
- **`image_transport`** is the system that handles this. A node asks for the camera stream, and `image_transport` picks raw or compressed. A `republish` node converts between them
- You can measure the cost yourself with `ros2 topic bw`. We'll do that in lab

### Lens Distortion and `image_proc`

- Real lenses bend the picture. Straight lines near the edge look curved. `CameraInfo` has a **distortion** field to describe that, and **calibration** is how you find the numbers
- The simulator's camera has perfect optics, so its distortion is all zeros. A real camera won't be
- The `image_proc` package takes a raw image and its `CameraInfo` and produces corrected (rectified) and color-converted versions. You won't use it this week, but you'll see it in real camera setups

### Three Ways to Look at an Image

| Tool | What it does |
|---|---|
| RViz **Image** display | Shows the picture in a panel |
| RViz **Camera** display | Overlays the picture on the 3D view, so you can check that what the camera sees lines up with the 3D scene |
| `rqt_image_view` | A small separate window for one image topic. Quick and light |

---

## Anatomy of the Camera Messages

### `Image`

```
std_msgs/Header header
uint32 height          # rows
uint32 width           # columns
string encoding        # how each pixel is stored
uint8 is_bigendian
uint32 step            # bytes per row
uint8[] data           # the pixels
```

- The `encoding` field matters most:
  - **`rgb8`** or **`bgr8`**: three bytes per pixel (color)
  - **`32FC1`**: one decimal number per pixel, normally **meters** (Gazebo's depth image)
  - **`16UC1`**: one whole number per pixel, normally **millimeters** (many real depth cameras)
- Both depth encodings are common. This is the "similar but not identical" case. Code that reads depth must **check `encoding`** first

### `CameraInfo`

- The camera's description: `width`, `height`, and a matrix `k` with the **focal lengths** (`fx`, `fy`) and the **center point** (`cx`, `cy`) of the image
- These numbers connect a pixel to a direction in 3D
- It also holds the lens **distortion** coefficients (`d`). They're all zero in the simulator and non-zero on a real camera

### `PointCloud2`

- A big packed list of points. The fields `x`, `y`, `z` say where each point is, and often a color too
- It's already the result of combining the depth image and `CameraInfo`. Many tools take it directly

---

## From Depth Pixel to 3D Point

A pixel at column `u`, with depth `Z`, and a camera that has a focal length `fx` (in pixels) and image center `cx`:

```
X = (u - cx) x Z / fx
```

- `Z` is straight out from the camera, `X` is sideways
- The focal length in pixels comes from the camera's field of view (FOV) and the image width `W`:

```
fx = (W / 2) / tan(FOV / 2)
```

- Our simulated camera: 320 pixels wide, horizontal FOV of 1.089 rad. `tan(0.5445)` is about 0.604, so `fx` is about **265 pixels**
- At full resolution (640 wide), `fx` doubles to about 530

### ✏️ Work It By Hand

A pixel is **80 pixels to the right** of the image center (`u - cx = 80`), and its depth is **2.0 m**. Using the 320-pixel camera, how far to the side is that point?

<details markdown="1">
<summary>Answer</summary>

X = 80 x 2.0 / 265 = **0.60 m** to the side, and 2.0 m ahead.

A point twice as far away (4 m) at the same pixel would be 1.2 m to the side. The same pixel covers more real-world space the farther away it is. That's why a depth camera needs both the pixel **and** the depth.

</details>

---

## Frames: Body vs Optical

- Robots use one convention for their own axes (REP-103): **x forward, y left, z up**
- Camera images use another: **x right, y down, z forward** (out of the lens). This is called the **optical frame**
- To move between them you rotate the frame: **-90 degrees about x, then -90 degrees about z**. In the URDF that is `rpy="-pi/2 0 -pi/2"`
- That's why we add a second link, `ascamera_color_0`, to the URDF, in simulation. On the real robot, the camera's driver publishes it
- Mixing up the two conventions is one of the most common reasons points show up sideways or upside down in RViz

> 📷 **[SCREENSHOT: RViz TF display showing depth_cam and the optical frame ascamera_color_0 with their different axis directions]**

<!-- INSTRUCTOR NOTE: add a short "what we found in the sim" paragraph here once the point cloud frame/rotation question is resolved. -->

---

## ✅ Checkpoint

**A real camera publishes depth as `16UC1` and a simulated one as `32FC1`. Both say the object is the same distance away. A depth value of 2000 appears in the first and 2.0 in the second. What are the units of each, and what field tells you?**

<details markdown="1">
<summary>Answer</summary>

`16UC1` here is **millimeters** (2000 mm = 2.0 m) and `32FC1` is **meters** (2.0 m). The `encoding` field in the `Image` message says which. Code that works on both must read `encoding` and convert.

</details>

---

## Part 6 — Adding Objects in Gazebo Harmonic

Your Gazebo is **Gazebo Harmonic**. If you search online, you'll find lots of older answers for **Gazebo Classic**. They look similar but do not work the same way.

| | Gazebo Classic (old) | Gazebo Harmonic (ours) |
|---|---|---|
| **Command** | `gazebo`, `gzserver`, `gzclient` | `gz sim` (and `gz topic`, `gz service`) |
| **ROS 2 connection** | `gazebo_ros` plugins inside the model | `ros_gz_bridge`, a separate node that copies topics |
| **Plugin names** | `libgazebo_ros_*.so` | `gz-sim-*-system` |
| **Sensors** | A `<plugin>` inside every sensor | A single **Sensors** system in the **world** |
| **Model search path** | `GAZEBO_MODEL_PATH` | `GZ_SIM_RESOURCE_PATH` |
| **Online models** | Model database | **Fuel** |

- If a tutorial says `gazebo` or `libgazebo_ros_ray_sensor.so`, it's Classic. Translate it before copying it

### A World File

A **world** is an `.sdf` file (Simulation Description Format). It's XML, like the URDF, but describes a whole scene. The one we use has four parts:

```xml
<sdf version="1.9">
  <world name="obstacle_course">

    <!-- 1. systems the world needs -->
    <plugin filename="gz-sim-physics-system" name="gz::sim::systems::Physics"/>
    <plugin filename="gz-sim-user-commands-system" name="gz::sim::systems::UserCommands"/>
    <plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>
    <plugin filename="gz-sim-sensors-system" name="gz::sim::systems::Sensors">
      <render_engine>ogre2</render_engine>
    </plugin>

    <!-- 2. light -->
    <light type="directional" name="sun"> ... </light>

    <!-- 3. the ground -->
    <model name="ground_plane"> ... </model>

    <!-- 4. things to hit -->
    <model name="wall_front"> ... </model>

  </world>
</sdf>
```

| System | What it does |
|---|---|
| **Physics** | Moves things and handles collisions |
| **UserCommands** | Lets you add and move things from the GUI |
| **SceneBroadcaster** | Sends the scene to the GUI so you can see it |
| **Sensors** | Makes the **sensors work**. Without it, a lidar or camera exists but publishes nothing |

- That last row is the one people miss. If Gazebo shows your robot but `gz topic -l` has no scan or camera topics, check for the Sensors system first

### One Object

```xml
<model name="box_left">
  <static>true</static>
  <pose>1.0 0.5 0.15 0 0 0</pose>
  <link name="link">
    <collision name="collision">
      <geometry><box><size>0.2 0.2 0.3</size></box></geometry>
    </collision>
    <visual name="visual">
      <geometry><box><size>0.2 0.2 0.3</size></box></geometry>
      <material>
        <ambient>0.1 0.4 0.8 1</ambient>
        <diffuse>0.1 0.4 0.8 1</diffuse>
      </material>
    </visual>
  </link>
</model>
```

| Part | Meaning |
|---|---|
| `<model name="box_left">` | One object in the world |
| `<static>true</static>` | It never moves. No physics cost, can't be pushed |
| `<pose>1.0 0.5 0.15 0 0 0</pose>` | Position `x y z` then rotation `roll pitch yaw` |
| `<collision>` | The shape the **physics** uses (what the robot bumps into) |
| `<visual>` | The shape and color you **see** |
| `<size>0.2 0.2 0.3</size>` | Width, depth, and height, in meters |

- The collision and the visual are separate. They are usually the same shape, but they don't have to be
- Poses use the same axes as the robot: **x forward, y left, z up**. The robot starts at the origin facing +x
- The box is 0.3 m tall, and its pose is `z = 0.15`, so it sits on the floor (half its height). That height crosses the lidar plane

---

## ✏️ Work It By Hand: Reading and Placing Objects

**1.** Where is a model with `<pose>1.5 -0.4 0.15 0 0 0</pose>` compared to the robot's start?

**2.** You want a cylinder 2 m ahead and 0.5 m to the left. What pose do you write (it's 0.3 m tall and sits on the floor)?

**3.** Why wouldn't a box with `<size>0.2 0.2 0.1</size>` show up in the lidar scan?

<details markdown="1">
<summary>Answers</summary>

1. **1.5 m ahead and 0.4 m to the right.** (+x is forward, and negative y is right.)
2. `<pose>2.0 0.5 0.15 0 0 0</pose>`
3. It's only 0.1 m tall, and the lidar plane is about 0.16 m up, so the scan passes over it.

</details>

---

## Part 7 — From URDF to RViz: The Sensor Pipeline

A simulated sensor goes through four steps. If anything fails, you will have no data, so you need to know them all.

```
1. URDF     --->  2. Gazebo  --->  3. Bridge        --->  4. ROS 2 topic  --->  RViz
 (sensor tag)      (Sensors       (copies gz topic       (/scan_raw)
                    system makes   to ROS topic)
                    the data)
```

### Step 1: The Sensor in the URDF

The Hiwonder model already has the **links** for the lidar and camera (`lidar_frame`, `depth_cam`), but it's only the shape. It doesn't say how it works. Our file `sensors.xacro` adds that.

```xml
<gazebo reference="lidar_frame">
  <sensor name="lidar" type="gpu_lidar">
    <topic>scan_raw</topic>
    <gz_frame_id>lidar_frame</gz_frame_id>
    <update_rate>10</update_rate>
    <always_on>true</always_on>
    <visualize>false</visualize>
    <lidar>
      <scan>
        <horizontal>
          <samples>450</samples>
          <resolution>1</resolution>
          <min_angle>-3.14159</min_angle>
          <max_angle>3.14159</max_angle>
        </horizontal>
      </scan>
      <range>
        <min>0.12</min>
        <max>12.0</max>
        <resolution>0.01</resolution>
      </range>
      <noise>
        <type>gaussian</type>
        <mean>0.0</mean>
        <stddev>0.01</stddev>
      </noise>
    </lidar>
  </sensor>
</gazebo>
```

| Line | What it controls |
|---|---|
| `<gazebo reference="lidar_frame">` | Attach this to the `lidar_frame` link. Gazebo-only settings live in `<gazebo>` tags |
| `type="gpu_lidar"` | A lidar measured with the graphics card |
| `<topic>scan_raw</topic>` | The Gazebo topic it publishes on |
| `<gz_frame_id>` | The `frame_id` stamped on every message |
| `<update_rate>10</update_rate>` | 10 scans per second |
| `<samples>450</samples>` | 450 readings per turn (matches the `LaserScan` we discussed) |
| `<min_angle>`, `<max_angle>` | A full circle, from -pi to +pi |
| `<range><min>`, `<max>` | `range_min` and `range_max` |
| `<noise>` | Random error added to each reading. Real sensors aren't perfect. A standard deviation of 0.01 means readings wander by about 1 cm |

- Every line here becomes a field in the message. `samples` and angles give `angle_increment`. `range` gives `range_min` and `range_max`
- `<visualize>false</visualize>` is on purpose. In Gazebo Harmonic that flag no longer draws the laser beams. To see the beams in Gazebo, add the **Visualize Lidar** plugin from the GUI's plugin menu (the three dots, top right)

> 📷 **[SCREENSHOT: Gazebo with the Visualize Lidar plugin showing the beams hitting the wall, box and cylinder]**

The camera is the same idea with different settings:

```xml
<gazebo reference="depth_cam">
  <sensor name="depth_cam" type="rgbd_camera">
    <topic>camera</topic>
    <gz_frame_id>depth_cam</gz_frame_id>
    <update_rate>10</update_rate>
    <camera>
      <horizontal_fov>1.089</horizontal_fov>
      <image>
        <width>320</width>
        <height>240</height>
      </image>
      <clip><near>0.1</near><far>8.0</far></clip>
      <depth_camera>
        <clip><near>0.1</near><far>8.0</far></clip>
      </depth_camera>
    </camera>
  </sensor>
</gazebo>
```

- `horizontal_fov` and `width` give you the focal length `fx` you calculated earlier
- `clip near/far` is the closest and farthest distance the camera will report
- `update_rate` and the image size are the load on the computer. Raise them and the simulation slows down. We lowered ours to 320x240 at 10 Hz so the lab computers keep up
- `sim_mode`: this file is only included in **simulation** (`sim_mode:=true`). On the real robot the sensors' real drivers provide the data, and including these tags too would be wrong

<!-- INSTRUCTOR NOTE: verify the camera gz_frame_id value against the point cloud rotation test before class. -->

### Step 2: Gazebo Makes the Data

- With the **Sensors** system loaded in the world, Gazebo creates the sensor and begins publishing on its own topics (`scan_raw`, `camera/image`, `camera/depth_image`, `camera/points`, `camera/camera_info`)
- You can see them with `gz topic -l`. These are **Gazebo** topics, not ROS 2 yet

### Step 3: The Bridge

The bridge file lists each topic to copy. One entry:

```yaml
- ros_topic_name: "scan_raw"
  gz_topic_name: "scan_raw"
  ros_type_name: "sensor_msgs/msg/LaserScan"
  gz_type_name: "gz.msgs.LaserScan"
  direction: GZ_TO_ROS
```

| Line | Meaning |
|---|---|
| `ros_topic_name` | The name on the ROS 2 side |
| `gz_topic_name` | The name on the Gazebo side |
| `ros_type_name` | The ROS 2 message type |
| `gz_type_name` | The Gazebo message type |
| `direction` | `GZ_TO_ROS` for sensor data. `ROS_TO_GZ` for commands like `cmd_vel` |

- Notice the names on the two sides can **differ**. Our color image is `camera/image` in Gazebo and `/ascamera/camera_publisher/rgb0/image` in ROS 2. We picked the ROS name to match the real robot's camera, so your RViz setup carries over
- Two small rules for YAML: spacing matters, and every entry's `-` starts at the **left edge**, with its keys indented two spaces

### Step 4: RViz

- RViz subscribes to the ROS 2 topic and draws it. For a `LaserScan` it draws dots at the measured distances. For `Image` it draws the picture. For `PointCloud2` it draws the 3D points
- RViz needs the **Fixed Frame** to be a frame that exists in TF (we use `odom`). It uses TF to place data from `lidar_frame` or the camera relative to the robot

> 📷 **[SCREENSHOT: RViz with Fixed Frame set to odom, a LaserScan on /scan_raw, and the point cloud]**

> 📷 **[SCREENSHOT: `gz topic -l` and `ros2 topic list` side by side, showing which topics exist on each side]**

---

## ✅ Checkpoint

**`gz topic -l` shows `/scan_raw`, but `ros2 topic list` does not. Which of the four steps failed?**

<details markdown="1">
<summary>Answer</summary>

**Step 3, the bridge.** Gazebo is making the data (steps 1 and 2 worked), but it's not being copied to ROS 2. Common causes: no entry for it in the bridge file, a typo in a topic or type name, the wrong `direction`, or the bridge itself crashed. Look at the bridge's own output.

</details>

---

## Commands for Looking at Sensor Data

| Command | What it shows |
|---|---|
| `gz topic -l` | The topics that exist inside **Gazebo** |
| `ros2 topic list` | The topics that exist in **ROS 2** |
| `ros2 topic info /scan_raw` | The message type and how many publishers and subscribers |
| `ros2 topic hz /scan_raw --use-sim-time` | How often messages arrive, measured in **simulation** time |
| `ros2 topic echo /scan_raw --once` | One full message |
| `ros2 topic echo /scan_raw --once --field range_max` | Just one field of the message |
| `ros2 interface show sensor_msgs/msg/LaserScan` | The definition of the message type |
| `ros2 run tf2_tools view_frames` | A picture of the TF tree |
| `ros2 run rviz2 rviz2 --ros-args -p use_sim_time:=true` | RViz, on simulation time |
| `ros2 topic echo /scan_raw --once --no-arr` | A scan's setup without printing every reading |
| `ros2 topic info -v /scan_raw` | The type, plus each publisher's and subscriber's **QoS settings** |
| `ros2 topic bw /ascamera/camera_publisher/rgb0/image` | How much data per second a topic moves |
| `ros2 run rqt_graph rqt_graph` | A picture of the nodes and topics and how they connect |
| `ros2 run rqt_image_view rqt_image_view` | A quick window for an image topic |
| `ros2 bag record -o bags/sensors /scan_raw /tf /tf_static` | Record sensor data to a bag |
| `ros2 bag play bags/sensors --clock` | Play a recording back, and publish its clock |

- Use `--use-sim-time` for `hz` in the simulation. Without it, the rate is measured against the **wall clock**, and if your simulation runs slower than real time you'll see a lower number than the sensor really produces

An echoed scan looks like this (shortened, and the numbers are only an example):

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">header:
  stamp:
    sec: 42
    nanosec: 300000000
  frame_id: lidar_frame
angle_min: -3.14159
angle_max: 3.14159
angle_increment: 0.01398
time_increment: 0.0
scan_time: 0.0
range_min: 0.12
range_max: 12.0
ranges:
- .inf
- .inf
- 2.41
- 2.39
...</pre>
</div>

- Find the `frame_id`, the angles, and the first few readings. `.inf` is "nothing seen"

---

## Tools That Show the Whole Picture

These don't need any code, and they're how ROS developers actually work.

### `rqt_graph`: See the Pipeline

```bash
ros2 run rqt_graph rqt_graph
```

- Draws every node as a box and every topic as an arrow. You'll see the bridge, `robot_state_publisher`, the safety gate, and RViz, with `/scan_raw` and the camera topics connecting them
- It turns the four-step pipeline from the last section into a picture you can check against reality
- **Tip:** set the dropdown to "Nodes/Topics (all)" so topics with no subscriber still show up

> 📷 **[SCREENSHOT: rqt_graph showing the bridge, scan_raw and camera topics, and RViz]**

### `ros2 topic bw`: Measure the Cost

```bash
ros2 topic bw /scan_raw
```

```bash
ros2 topic bw /ascamera/camera_publisher/rgb0/image
```

- Compare the two. The camera topic moves far more data than the scan. It matches the numbers we worked out by hand

### Record and Play Back: Interoperability, Proven

```bash
ros2 bag record -o bags/sensors /scan_raw /tf /tf_static /clock
```

- Drive for 10 seconds, stop the recording, then **close Gazebo and the bridge**. Play the bag back:

```bash
ros2 bag play bags/sensors --clock
```

- RViz (started with `use_sim_time:=true`) draws the scan as if the robot were still driving. **RViz can't tell a recording from a live robot.** It only sees topics with a type, a name, and a frame
- That is the contract in action. The same trick works with data from a real robot: record it on the robot, then work on it from your laptop with no robot present
- You've used `ros2 bag` since Module 9. Now you're using it for sensor data

### Saving Your RViz Setup

- Setting up RViz every time is slow, especially on lab machines where Deep Freeze wipes everything. **Save the setup:** File → Save Config As → `sensors.rviz`
- Open it later with:

```bash
ros2 run rviz2 rviz2 -d ~/ros2_ws/src/mentorpi_bringup/rviz/sensors.rviz --ros-args -p use_sim_time:=true
```

- Put the file in your project and commit it so it survives a restart

### What Uses This Next

- Everything you've seen this week is the input to bigger tools:
  - **SLAM** (Simultaneous Localization and Mapping) takes `LaserScan` and odometry, and builds a map while working out where the robot is. It's the fix for drift
  - **Nav2** takes the map and the scan to plan a path and drive it, avoiding obstacles
- Neither needs to know which lidar you have. They read `LaserScan`. That's why getting the contract right is worth the effort

> 📷 **[SCREENSHOT: an example SLAM map built from a LaserScan, for context]**

---

## Part 8 — "I See Nothing in RViz": A Troubleshooting Order

When a sensor shows nothing, don't guess. Walk the chain from the source to the screen and stop where the data stops.

| # | Question | How to check | If no |
|---|---|---|---|
| 1 | Is the world running with the **Sensors** system? | Does `gz topic -l` list the sensor's topic? | Add the Sensors plugin to the world |
| 2 | Is the sensor in the robot description? | Was it in the URDF, and did `sim_mode` include it? Rebuild and relaunch | Check `sensors.xacro` is included in the wrapper |
| 3 | Did the **bridge** start? | Look for a "process has died" line in the launch output | Read the bridge's last error |
| 4 | Is the topic in **ROS 2**? | `ros2 topic list` | Check the bridge entry names and types |
| 5 | Is it **publishing**? | `ros2 topic hz ... --use-sim-time` | Is the simulation paused or very slow? |
| 6 | Does RViz's **Fixed Frame** exist? | Set it to `odom` and look at the TF display | Pick a frame that's in the tree |
| 7 | Do the **QoS** settings match? | Try setting the display's Reliability to **Best Effort** | A "reliable" subscriber can't get data from a "best effort" publisher |
| 8 | Is RViz on **simulation time**? | Start it with `use_sim_time:=true` | Old timestamps can make data look stale and get dropped |

### Real Problems We Hit Building This Module

| Symptom | Cause | Fix |
|---|---|---|
| Walls missing from Gazebo, no sensor topics | The `world` launch argument was declared twice, and the old `empty.sdf` default won | Declare it once |
| `parameter_bridge ... process has died`, `yaml-cpp: error ... end of map not found` | Pasted YAML entries were indented unevenly | Every `-` at the left edge, keys indented two spaces |
| `gz topic -l` shows nothing for the sensors | Sensors system not in the world | Add the plugin to the `.sdf` |
| Scan arrives at 6 Hz, camera at 2 Hz | The simulation ran at 58 percent of real time | Lower camera size and rate. Check with `--use-sim-time` |
| Point cloud rotated 90 degrees | Data labeled with the optical frame, but not in that orientation | Fix the frame it's stamped with |
| `Warning ... gz_frame_id ... not defined in SDF` | Gazebo copies the tag through and still uses it | Harmless |
| Scan points swing more than the robot when it turns | Fixed Frame not what you thought, Decay Time above 0, or timing lag | Check the Fixed Frame, set Decay Time to 0, check the sim speed |

- Most of these have nothing to do with ROS. They're plain typing and wiring mistakes. The method works for all of them: find the **last step where the data exists**, and look at the step after it

---

## ⚠️ Common Pitfalls

- **Assuming the number of readings.** Always read the message fields
- **Ignoring `inf` and out-of-range values.** They are normal, not errors
- **Forgetting the lidar plane.** If an object isn't tall enough, the robot can't see it
- **Reading depth without checking `encoding`.** Meters and millimeters are both used
- **Mixing up body and optical frames.** If points come out rotated, check the frames first
- **Comparing rates with the wall clock.** In a simulation, use `--use-sim-time`
- **Searching for Classic answers.** `gazebo`, `libgazebo_ros_*`, and `GAZEBO_MODEL_PATH` are the old system
- **Assuming a topic that exists in Gazebo exists in ROS 2.** The bridge has to copy it

---

## From Simulation to the Real Robot

- The real MentorPi has an LD19 lidar and a depth camera, each with its **own driver** (a node written for that hardware)
- Those drivers publish the same kinds of messages we saw today. If the **names and frames agree**, the nodes you write against the simulator work on the real robot
- That agreement is a short list: topic names, message types, frame names, and units. We kept a sheet of them as we built the simulation so the switch is easy
- Real hardware brings extra work that the simulator doesn't: USB device names, permissions, and the driver software on the robot. Those get solved once, on the robot, and none of it changes your nodes

---

## Summary

- Review: **nodes** run, **topics** stream, **services** answer, **parameters** configure, **actions** run long jobs
- **Gazebo** makes the world and the sensor data. **RViz** displays data from ROS 2 topics. RViz never talks to Gazebo
- ROS 2's big benefit is **interoperability**: a sensor publishes a standard message on a topic, and the subscriber doesn't care which sensor it was. The topic is the **contract**
- A **lidar** measures distance from light's travel time. A `LaserScan` has a list of `ranges`, plus the angles and limits to interpret them. A 2D lidar only sees its own plane
- A **depth camera** adds a distance to each pixel. `Image`, `CameraInfo`, and `PointCloud2` carry it. Check `encoding`, and watch the body and optical frames
- In Gazebo Harmonic, a **world** needs the **Sensors** system for sensors to work, and objects are `<model>` elements with a collision and a visual
- A sensor travels: **URDF tag, Gazebo, bridge, ROS 2 topic, RViz**. When it fails, find the last step where the data exists

---

## Lab Preview: Exploring the Sensors

This lab is **exploration only**. There's no code to write. You'll run the simulation and look carefully.

- Run the simulation and compare `gz topic -l` with `ros2 topic list`
- Open RViz and add the LaserScan, the camera image, the depth image, and the point cloud
- Drive toward the wall and the obstacles, and watch the scan change
- Find the closest object by reading the scan, and check it against Gazebo's truth
- Find which obstacles the lidar sees, and which one the camera sees but the lidar does not
- Read one raw `LaserScan` message and identify its fields
- Open the world file and add your own object, then find it in the scan
- Compare your scan's start angle and resolution with the LD19's, and work out which index points straight ahead for each
- Watch the Fixed Frame change what you see while driving
- Draw the system with `rqt_graph`, and measure the bandwidth of each sensor
- Record a bag, close Gazebo, and play the sensors back into RViz
- Break something on purpose and use the troubleshooting order to find it

---

## Preview: Next Module

- You have a robot that can drive and see
- Next you'll write the node that connects the two: a **lidar safety-stop** that reads `/scan_raw` and stops the robot before it hits something
- It uses all five ideas from today's review: a **topic** (the scan), a **service** (`/enable_motion`), a **parameter** (the stop distance), a **node** (your code), and an **action** (a goal that gets stopped)

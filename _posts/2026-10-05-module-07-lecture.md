---
title: "Module 7 — Meet the MentorPi: URDF, MecanumDrive & Gazebo"
date: 2026-10-05 11:00:00 -0500
categories: [Module 07, MentorPi Simulation]
tags: [ros2, mentorpi, mecanum, gazebo, urdf]
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

## The MentorPi URDF

- Hiwonder publishes the MentorPi description at `github.com/Hiwonder/MentorPi`, inside `simulations/mentorpi_description`
- Real robots ship as **Xacro**, same as yours — the main file is `mentorpi.xacro`, which reads a configuration variable to decide whether to load the Mecanum or Ackermann chassis model

---

## 🔗 Show Online

Pull up Hiwonder's [MentorPi Github repo](https://github.com/Hiwonder/MentorPi), [URDF walkthrough](https://docs.hiwonder.com/projects/MentorPi/en/latest/docs/7.mapping_lesson.html#urdf-model), and their [Motion Control Lesson](https://docs.hiwonder.com/projects/MentorPi/en/latest/docs/4.motion_control_lesson.html). Those two pages are today's primary sources, read directly from the robot's actual files.
 


---
 
## Reading a Real Wheel Joint
 
<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;joint name="wheel_lf_Joint" type="continuous"&gt;
   &lt;origin rpy="0 0 0" xyz="0.067052 0.07591 -0.018408"/&gt;
   &lt;parent link="base_link"/&gt;
   &lt;child link="wheel_lf_Link"/&gt;
   &lt;axis xyz="0.00012228 1 -4.0642E-05"/&gt;
 &lt;/joint&gt;</pre>
</div>

- `wheel_lf_Joint` — left-front wheel, `continuous`, exactly as you'd expect for a drive wheel
- Notice the `axis` is not a clean `"0 1 0"` like you'd expect. Real CAD-exported values carry tiny numerical noise (`0.00012228`, `-4.0642E-05`) from the actual 3D model.
---
 
## ✅ Checkpoint
 
**Why `continuous` and not `revolute` for this joint? And why do you think the axis isn't a perfectly clean `"0 1 0"`?**
 
<details markdown="1">
<summary>Answer</summary>
`continuous` because it's a drive wheel with no rotational limit, same reasoning as your own robot's wheels. The slightly-off axis values come from the CAD model the URDF was exported from — small measurement/modeling tolerances in the real 3D design show up as small deviations from the "ideal" axis, rather than someone hand-typing a clean number.
 
</details>
---
 
## Callback: `base_footprint`
 
- The real MentorPi's URDF doesn't start at `base_link`. It starts at **`base_footprint`**, which sits on the ground, with `base_link` 0.07 m above it through a fixed joint
- In Module 5 you put `base_link` itself at ground level. Many robots do it this way instead: keep `base_link` wherever is convenient, and add a separate ground-level frame
- Hiwonder's `odom_publisher` reports odometry for `base_footprint`, not `base_link`
- Hold on to that. A frame can only have one parent in the TF tree, and it matters on Wednesday when a controller wants to publish `odom` → something
---
 
## What's Different: Four Wheels, Not Two
 
- Your Module 5 robot had two wheel joints. MentorPi's Mecanum chassis has four: front-left, front-right, back-left, back-right
- Each one is still a `continuous` joint, same as before — the *type* of joint doesn't change, just the count
- What's new is the **wheel itself**, and what it makes possible. That's the next few slides
---
 
## How a Mecanum Wheel Works
 
 ![MentorPi M1](/assets/mentorpi_mecanum.png)

- Each wheel has small rollers around its rim, mounted at **45°** to the wheel's axle
- Wheels come in two mirror-image types (Hiwonder calls them A and B). MentorPi uses an alternating **ABAB** layout, which is what lets it move in every direction. Some layouts, like AAAA, can't
- Each wheel pushes the robot along its roller direction, and the rollers let it slide freely sideways to that push. Add up the four pushes and you get forward, sideways, spinning, or any mix
- The simple math assumes **no wheel slip**, **enough friction with the ground**, and four wheels at the corners of a rectangle
---
 
 
## `cmd_vel` Just Grew a Dimension
 
- Back in Module 6: a differential-drive robot only ever used `linear.x` and `angular.z` — `linear.y` always sat at zero
- On MentorPi, `linear.y` is live. A `Twist` like these is now meaningful:
<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">linear: {x: 0.5, y: 0.5}
linear: {y: 0.5}, angular: {z: 0.2}</pre>
</div>
- The second one strafes sideways *while also* rotating — something a two-wheel robot can't do at all, at any combination of commands
---
 
## ✅ Checkpoint
 
**Predict: on MentorPi, what does `linear: {x: 0, y: 0.5}, angular: {z: 0}` actually do? What would that same command do on your Module 6 `DiffDrive` robot?**
 
<details markdown="1">
<summary>Answer</summary>
On MentorPi: the robot slides directly sideways (strafes) without turning or moving forward at all. On the Module 6 `DiffDrive` robot: nothing — `linear.y` is ignored entirely by a differential-drive robot, since it has no way to move sideways.
 
</details>
---
 
## How the Real MentorPi Turns `cmd_vel` Into Motion
 
- Hiwonder's `odom_publisher` node subscribes to `controller/cmd_vel`, a plain `geometry_msgs/Twist`
- It runs the Mecanum kinematics from the Motion Control Lesson, and publishes a `MotorsState` message (a motor ID and a speed in revolutions per second) on `ros_robot_controller/set_motor`
- A separate node, `ros_robot_controller`, is the hardware driver. It passes those commands to the RRC board over USB serial, and the board spins the motors
- So there are already two layers: kinematics in one node, board access in another, connected by a topic
---
 

## Odometry on the Real Robot
 
- `odom_publisher` publishes `/odom_raw` (`nav_msgs/Odometry`), computed from the Mecanum kinematic model
- An IMU node publishes `/imu` (`sensor_msgs/Imu`)
- Hiwonder's `controller.launch.py` runs `robot_localization`'s **EKF** to fuse the two, and republishes the result as `/odom`
- That's Method 4 from Module 6 (sensor fusion), running on a robot you'll be driving: wheel odometry for distance, the IMU for rotation
- Their stated reason: wheel odometry accumulates error and gets fooled when wheels spin without the robot actually moving, for example when it's lifted off the ground
---
 
## Calibration: Fixing Systematic Error
 
- Hiwonder ships robots pre-calibrated, but says hardware varies, and to recalibrate if the robot drifts or can't drive straight
- Two scale factors live in `calibrate_params.yaml`: `linear_correction_factor` and `angular_correction_factor`
- **Linear:** mark a 1 m course, run the test, adjust `odom_linear_scale_correction` in steps of 0.01 until the robot travels the right distance, then write the value into `linear_correction_factor`
- **Angular:** mark the robot's heading, spin one full 360°, adjust `odom_angle_scale_correction` the same way, then write it into `angular_correction_factor`
- **IMU:** a separate procedure that holds the robot in six orientations
- This is the "systematic error you can calibrate out" from Module 6's wheelbase exercise, done for real
---
 
## ✅ Checkpoint
 
**Your robot travels 0.93 m every time you command exactly 1.00 m. Is that a systematic or non-systematic error? Could you calibrate it out, and how?**
 
<details markdown="1">
<summary>Answer</summary>
Systematic — it's the same every run, which points to something repeatable like a wheel or motor mismatch rather than random slip. You can calibrate it out: run Hiwonder's linear calibration test and adjust the scale factor in 0.01 steps until the robot actually travels 1.00 m, then record that value as `linear_correction_factor`. A non-systematic error, like one run where a wheel slipped on dust, wouldn't repeat and couldn't be fixed this way.
 
</details>
---
 
## Driving It in Simulation: Gazebo's `MecanumDrive` Plugin
 
<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;plugin filename="gz-sim-mecanum-drive-system"
        name="gz::sim::systems::MecanumDrive"&gt;
  &lt;front_left_joint&gt;wheel_lf_Joint&lt;/front_left_joint&gt;
  &lt;front_right_joint&gt;wheel_rf_Joint&lt;/front_right_joint&gt;
  &lt;back_left_joint&gt;wheel_lb_Joint&lt;/back_left_joint&gt;
  &lt;back_right_joint&gt;wheel_rb_Joint&lt;/back_right_joint&gt;
  &lt;wheelbase&gt;0.1368&lt;/wheelbase&gt;
&lt;/plugin&gt;</pre>
</div>

- Same idea as `DiffDrive` from Module 6 — reads `/cmd_vel`, drives the wheels, publishes odometry — just built for four wheels and holonomic motion
- Each `<..._joint>` tag names one wheel's joint by exact name. Get a name wrong and that wheel simply won't move. Pull all four names straight from the URDF; only `wheel_lf_Joint` is confirmed above
- `0.1368` is Hiwonder's wheelbase from their code. The URDF's joint origins give a slightly different front-to-back distance (the left-front joint sits at `x = 0.067052`; check the rear ones). Two sources describing the same robot, and they disagree a little. That's part of why calibration exists
- The plugin has other geometry parameters too; check Gazebo's `MecanumDrive` API page for the exact names, and set them from the URDF
---
 
## ⚠️ Simulation Catch: Where Do the Rollers Go?
 
- Gazebo's physics sees only the wheel's collision shape, not its rollers
- Gazebo's own mecanum demo world gets strafing to work by giving the wheels *directional* friction: grip in one direction, slide in the other
- Expect to deal with this when you try `linear.y` on the MentorPi model. Hiwonder's kinematics assume wheels that don't slip; a simulator wheel with ordinary friction doesn't behave that way
---
 
## Same Robot, Two Message Types
 
- The real MentorPi takes a plain `geometry_msgs/Twist` on `/controller/cmd_vel`
- In Module 6's Gazebo setup, the bridge carried `TwistStamped`, and Wednesday's `mecanum_drive_controller` also takes a stamped Twist
- `teleop_twist_keyboard` can do either: `stamped:=true` for simulation, and a topic remap for the real robot
- Same three numbers (`vx`, `vy`, `ω`), different envelope. Mixing them up is a quiet failure: the robot just doesn't move
---
 
## ⚠️ Common Pitfall
 
Hiwonder's own documentation doesn't walk through a Gazebo simulation workflow at all — their tutorials go straight from URDF to real-hardware SLAM mapping over VNC. Today's Gazebo setup is something **we're assembling ourselves** on top of their official URDF, not a path they've documented for us. Don't go looking for a Hiwonder tutorial that matches Wednesday's lab step by step — it doesn't exist.
 
---

## The Plan: Two Packages
 
- **`mentorpi_description`** is Hiwonder's package, copied into your repo and edited in place (only the collision shapes). It's the robot model: meshes and Xacro. Sim and real robot share it
- **`mentorpi_bringup`** is a new package you create. It holds the launch files, the bridge config, and a wrapper xacro. It finds the model with `get_package_share_directory('mentorpi_description')`
- Both live inside **`mentorpi/`**, your git repo: a plain folder (no `package.xml`) that `colcon` looks inside
- Hiwonder's full repo gets cloned **outside** `src/`, as a read-only reference. Two packages with the same name in one workspace make `colcon` error out, Deep Freeze wipes the clone anyway, and you can't push to Hiwonder's repo. Your own GitHub repo is what survives
- Same split as the real stack: "what the robot is" lives in one place, "how we run it" in another
```
src/
└── mentorpi/                          # your git repo (a folder, not a package)
    ├── mentorpi_description/          # copy of Hiwonder's, shared by sim and real
    │   ├── urdf/
    │   │   ├── mentorpi.xacro         # untouched
    │   │   └── mecanum.xacro          # collision shapes edited
    │   └── meshes/mecanum/*.STL
    └── mentorpi_bringup/              # NEW, from ros2 pkg create
        ├── launch/  (rsp.launch.py, launch_sim.launch.py)
        ├── config/  (gz_bridge.yaml)
        └── urdf/
            ├── robot.urdf.xacro       # NEW: wrapper with a sim_mode argument
            └── gazebo_control.xacro   # NEW: MecanumDrive + JointStatePublisher (sim only)
```
 
- Module 8 adds `launch_real.launch.py` and real-robot config to `mentorpi_bringup`, next to the simulation files. No third package
---
 
## 🖥️ Live Demo: Set Up the Packages
 
<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">cd ~
git clone https://github.com/Hiwonder/MentorPi.git mentorpi_ref
mkdir -p ~/ros2_ws/src/mentorpi
cp -r ~/mentorpi_ref/simulations/mentorpi_description ~/ros2_ws/src/mentorpi/
cd ~/ros2_ws/src/mentorpi
ros2 pkg create --build-type ament_python mentorpi_bringup
mkdir -p mentorpi_bringup/launch mentorpi_bringup/config mentorpi_bringup/urdf</pre>
</div>

- The robot model is on Hiwonder's default branch, so a plain `git clone` works
- The copied folder keeps the name `mentorpi_description`. `colcon` goes by the name inside `package.xml`, and a folder with a different name is confusing even when it builds
- `ament_python` matches Hiwonder's own package, so the same `data_files` pattern in `setup.py` installs our folders
---
 
## 🖥️ Live Demo: Check the Robot Without Gazebo
 
<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
export MACHINE_TYPE=MentorPi_Mecanum
xacro src/mentorpi/mentorpi_bringup/urdf/robot.urdf.xacro sim_mode:=true &gt; /tmp/mentorpi.urdf
check_urdf /tmp/mentorpi.urdf</pre>
</div>

- `xacro` expands the file into plain URDF. This is exactly what `robot_state_publisher` will do inside the launch file
- `check_urdf` prints the link tree. A valid file shows `base_footprint` as the root, with one child, `base_link`
- Under `base_link`: the four wheels, `depth_cam`, `imu_link`, and `lidar_frame`
- `check_urdf` knows nothing about Gazebo. A pass means the model is valid, not that the simulation will work
---
 
## ✅ Checkpoint
 
**Why does the xacro command above need `MACHINE_TYPE` exported, when we never export it before `ros2 launch`?**
 
<details markdown="1">
<summary>Answer</summary>
`mentorpi.xacro` reads `$(env MACHINE_TYPE)` to decide between the Mecanum and Ackermann chassis. Run by hand, `xacro` inherits your terminal's environment, so you export it yourself. Our `rsp.launch.py` sets it in Python with `os.environ.setdefault('MACHINE_TYPE', 'MentorPi_Mecanum')`, so the launch file works without Hiwonder's `.typerc`.
 
</details>
---
 
## Add the Control Plugin: `gazebo_control.xacro`
 
A new file in `mentorpi_bringup/urdf/`:
 
```xml
<?xml version="1.0"?>
<robot xmlns:xacro="http://ros.org/wiki/xacro">
  <gazebo>
    <plugin filename="gz-sim-mecanum-drive-system"
            name="gz::sim::systems::MecanumDrive">
      <front_left_joint>wheel_lf_Joint</front_left_joint>
      <front_right_joint>wheel_rf_Joint</front_right_joint>
      <back_left_joint>wheel_lb_Joint</back_left_joint>
      <back_right_joint>wheel_rb_Joint</back_right_joint>
      <wheelbase>0.1347</wheelbase>
      <wheel_separation>0.1370</wheel_separation>
      <wheel_radius>0.0325</wheel_radius>
      <frame_id>odom</frame_id>
      <child_frame_id>base_footprint</child_frame_id>
      <topic>cmd_vel</topic>
      <odom_topic>odom</odom_topic>
      <tf_topic>tf</tf_topic>
    </plugin>
    <plugin filename="gz-sim-joint-state-publisher-system"
            name="gz::sim::systems::JointStatePublisher">
      <topic>joint_states</topic>
    </plugin>
  </gazebo>
</robot>
```
 
Then a small wrapper, `mentorpi_bringup/urdf/robot.urdf.xacro`, that loads the robot and adds the plugin only for simulation:
 
```xml
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro" name="mentorpi">
 
  <xacro:arg name="sim_mode" default="false"/>
 
  <xacro:include filename="$(find mentorpi_description)/urdf/mentorpi.xacro"/>
 
  <xacro:if value="$(arg sim_mode)">
    <xacro:include filename="$(find mentorpi_bringup)/urdf/gazebo_control.xacro"/>
  </xacro:if>
 
</robot>
```
 
- Hiwonder's `mentorpi.xacro` stays untouched. The real robot will load the same wrapper with `sim_mode:=false` and simply not get the Gazebo plugin
- Same idea as the `sim_mode` argument in the Articulated Robotics `robot.urdf.xacro`
- `MecanumDrive` reads the command topic, drives the four wheels, and publishes odometry. `JointStatePublisher` publishes the wheel joint angles
- A new file needs a rebuild even with `--symlink-install`, because symlinks only cover files that already existed
---
 
## The Launch Files
 
- **`rsp.launch.py`** runs `robot_state_publisher` on our wrapper, `robot.urdf.xacro`. It has `use_sim_time` and `sim_mode` arguments, and passes `sim_mode` into the xacro
- **`launch_sim.launch.py`** starts four things:
  1. `rsp.launch.py`, with `use_sim_time` and `sim_mode` both forced to `true`
  2. Gazebo, through `ros_gz_sim`'s own `gz_sim.launch.py`, with `-r` so the simulation starts running
  3. The `create` node, which spawns the robot from the `/robot_description` topic
  4. `parameter_bridge`, configured from `gz_bridge.yaml`
- Same structure as the Module 6 launch file and as the Articulated Robotics tutorial. The only MentorPi-specific parts are the package names and the plugin
---
 
## The Bridge
 
Gazebo has its own topics. The bridge copies selected ones to and from ROS:
 
| Topic | ROS type | Direction |
|---|---|---|
| `clock` | `rosgraph_msgs/msg/Clock` | Gazebo → ROS |
| `cmd_vel` | `geometry_msgs/msg/TwistStamped` | ROS → Gazebo |
| `odom` | `nav_msgs/msg/Odometry` | Gazebo → ROS |
| `tf` | `tf2_msgs/msg/TFMessage` | Gazebo → ROS |
| `joint_states` | `sensor_msgs/msg/JointState` | Gazebo → ROS |
 
- Only `cmd_vel` goes into Gazebo. Everything else is the simulator reporting back
- The command is stamped, so teleop needs `-p stamped:=true`. A plain `Twist` publisher would reach the bridge and the robot would quietly not move
---
 


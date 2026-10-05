---
title: "Module 7 — Meet the MentorPi: URDF, MecanumDrive & ros2_control"
date: 2026-10-05 11:00:00 -0500
categories: [Module 07, MentorPi Simulation]
tags: [ros2, mentorpi, mecanum, gazebo, ros2_control, urdf]
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

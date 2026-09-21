---
title: "Module 5 — URDF: Describing a Robot From Scratch"
date: 2026-02-02 13:00:00 -0600
categories: [Module 05, URDF]
tags: [ros2, urdf, xacro, links, joints, rviz]
pin: false
marp: true
theme: default
paginate: true
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
.term-body .cmt { color: #7C8AAE; }
</style>

# Module 5
## URDF: Describing a Robot From Scratch

RAS 212 — Introduction to ROS 2

---

## Learning Objectives

By the end of this module, you will be able to:
- Write a `<link>` tag with visual properties
- Write a `<joint>` tag with the correct type, parent/child, origin, and axis
- Explain what xacro properties and macros are for, and why they matter
- Follow standard ROS naming conventions for links and joints

---

## The Robot Description

- Many different pieces of software need to know a robot's physical characteristics and it's helpful to have this all in one location
- In ROS, that's the **URDF** (Unified Robot Description Format)
- URDF describes a robot as a **tree of links, connected by joints**

---

## When Do You Make a New Link?

Two reasons:
- A part of the robot **moves relative to another part** (each segment of an arm, a wheel)
- A part **doesn't move**, but it's convenient to give it its own reference point (a camera or a lidar sensor)

---

## Joint Types, in Full

| Type | Motion |
|---|---|
| `revolute` | rotational, with min/max angle limits |
| `continuous` | rotational, no limit (a wheel) |
| `prismatic` | linear sliding, with min/max position limits |
| `fixed` | rigidly connected, the "convenience" links use this |

---

## The XML Basics

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;?xml version="1.0"?&gt;
&lt;robot name="my_robot"&gt;
   ...
   all the rest of the tags
   ...
   
&lt;/robot&gt;</pre>
</div>

- One root tag, `<robot>`, holding everything else — set the `name` attribute once
- 🔗 Full spec: [wiki.ros.org/urdf/XML](http://wiki.ros.org/urdf/XML)

---

## Inside a `<link>` Tag, in Full

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;link name="arm_link"&gt;
  &lt;visual&gt;
    &lt;origin xyz="0 0 0" rpy="0 0 0"/&gt;
    &lt;geometry&gt;&lt;box size="1 1 1"/&gt;&lt;/geometry&gt;
    &lt;material name="Green"/&gt;
  &lt;/visual&gt;
    &lt;collision&gt;
    &lt;origin xyz="0 0 0" rpy="0 0 0"/&gt;
    &lt;geometry&gt;&lt;box size="1.01 1.01 1.01"/&gt;&lt;/geometry&gt;
  &lt;/collision&gt;
  &lt;inertial&gt;
    &lt;mass value="10"/&gt;
    &lt;origin xyz="0 0 0" rpy="0 0 0"/&gt;
    &lt;inertia ixx="1" ixy="0" ixz="0" iyy="1" iyz="0" izz="1"/&gt;
  &lt;/inertial&gt;
&lt;/link&gt;</pre>
</div>

- **Visual** — what you see in RViz/Gazebo: Visual — what you see in RViz/Gazebo: `<geometry>` (`box`/`cylinder`/`sphere`/`mesh`), an `<origin>` offset, a `<material>` (color)
- **Collision** — geometry used for physics collision checks; often copy-pasted from visual, sometimes simplified for computation ()
- **Inertial** — mass, center of mass (`origin`), and the rotational [inertia matrix](https://en.wikipedia.org/wiki/Moment_of_inertia#Inertia_tensor) used for physics, matters for Gazebo not RViz
- 🔗 [wiki.ros.org/urdf/XML/link](http://wiki.ros.org/urdf/XML/link) — every optional attribute, including `contact_coefficient` for advanced friction/restitution tuning

## Moment of Inertia: The Confusing Part

- The inertia matrix describes how a link's mass is distributed, which affects how hard it is to *rotate* (not just move) 
- For simple shapes (box, cylinder, sphere), the formula is known and fixed


## Collision Geometry: Why Simplify at All?

- Collision checking runs constantly during simulation, every physics timestep needs to ask "is anything touching?"
- A detailed mesh (say, a scanned wheel with tread pattern) is expensive to check against; a plain cylinder is nearly free
- Rule of thumb: visual geometry can be as detailed as you want, since RViz only draws it. Collision geometry should be the *simplest shape that's still roughly accurate* — that trade-off is a deliberate design choice, not laziness
![Simplified Calculations](/assets/cow_aerodynamics.jpg)


---

## RViz vs. Gazebo

- **RViz** — visualization only. Subscribes to topics (TF, sensor data, robot state) and renders them. No physics, no simulation, it just shows you what the robot *thinks* is happening (or what real sensors are reporting).
- **Gazebo** — physics simulation. Simulates the robot, sensors, and environment (gravity, collisions, motor dynamics) and publishes the resulting data as if it were a real robot.

> You can run RViz without Gazebo (visualizing a real robot), and you can run Gazebo without RViz (just simulating, no visualization) — they're independent tools that are commonly used together.

---

## ✅ Checkpoint

**A camera bolted rigidly to a chassis — does it need its own link? Why or why not?**

<details>
<summary>Answer</summary>

Yes — it needs both a `<link>` and a `<joint>`.

- **Link**: Even a rigidly mounted camera should get its own `<link>` if you want to reference its frame (e.g., `camera_link`/`camera_optical_frame` ). URDF has no way to attach visual/collision/sensor geometry "onto" another link without giving it its own link.
- **Joint**: Every link except the root must be connected to the tree by a joint, URDF requires it (no floating links). Since the camera doesn't move relative to the chassis, you use a `fixed` joint type:

```xml
<joint name="camera_joint" type="fixed">
  <parent link="chassis_link"/>
  <child link="camera_link"/>
  <origin xyz="0.1 0 0.2" rpy="0 0 0"/>
</joint>
```

`fixed` means zero degrees of freedom — it locks the camera's pose relative to the chassis permanently.

</details>

---

## Inside a `<joint>` Tag, in Full

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;joint name="arm_joint" type="revolute"&gt;
  &lt;origin xyz="0 0 0" rpy="0 0 0"/&gt;
  &lt;axis xyz="0 1 0"/&gt;
  &lt;parent link="chassis_link"/&gt;
  &lt;child link="arm_link"/&gt;
  &lt;limit lower="0.9" upper="${pi/2}" effort="100" velocity="1"/&gt;
&lt;/joint&gt;</pre>
</div>

Every joint needs:
- **Name** — always name your joints, not just your links
- **Type** — `fixed`, `prismatic`, `revolute`, or `continuous`
- **Parent** and **child** links
- **Origin** — the relationship between the two links, before any motion is applied
- 🔗 [wiki.ros.org/urdf/XML/joint](http://wiki.ros.org/urdf/XML/joint) — the full spec, including optional `dynamics` (damping/friction), `safety_controller`, `calibration`, and `mimic` tags for advanced use cases we won't need this semester

---

## Non-Fixed Joints Also Need

- **Axis** — which axis to move along or around
- **Limits** — upper/lower position limits (m or rad), velocity limits, effort limits (N or Nm)

---

## Extra Tags You'll See: `<material>`

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;material name="Green"&gt;
  &lt;color rgba="0 1 0 1"/&gt;
&lt;/material&gt;</pre>
</div>

- Name a color (or texture) once at the top of your file, reference it by name in any `<visual>` — same DRY idea as xacro properties, just for appearance instead of geometry

---

## Extra Tags You'll See: `<gazebo>`

- Simulation-specific parameters that don't belong in the plain URDF spec — friction coefficients, sensor plugins, and physics engine plugins
- Next module, you'll add a simple drive plugin here to actually simulate motion

---

## Extra Tags You'll See: `<transmission>`

- Links a joint to the actuator that physically drives it — required for `ros2_control` to know which joints it's allowed to command
- On a real robot, "actuator" means a motor. In simulation, it's how Gazebo knows to treat a joint as commandable rather than just decorative
- You won't need this one until `ros2_control` shows up later this semester, alongside real hardware

---

## Naming Conventions

- Pair your names: `arm_link` and `arm_joint`, not `arm` and `joint1`
- ROS has official conventions too — REP 120 for humanoid robots, REP 105 for mobile platforms
- Consistency matters more than which convention you pick — just pick one and stick to it
- 🔗 [ROS conventions for humanoid robots](https://www.ros.org/reps/rep-0120.html) 
- 🔗 [ROS conventions for mobile robots](https://www.ros.org/reps/rep-0105.html) 
- 🔗 [Standard Units of Measure and Coordinate Conventions](https://www.ros.org/reps/rep-0103.html) 

---

## ✅ Checkpoint

**Name one joint that should be `continuous` and one that should be `revolute`, from a robot you can picture in your head.**

<details>
<summary>Answer</summary>

- **Continuous**: a wheel joint on a mobile robot that spins freely with no rotational limits.
- **Revolute**: an elbow joint on a robot arm that rotates but only within a bounded range (e.g., 0–180°).

</details>

---

## Why Xacro Exists

- Full URDF files get long, repetitive, and easy to mess up by hand
- Xacro (XML macros) lets us split files up and avoid duplicate code
- Enable it by adding one thing to your `robot` tag:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;robot xmlns:xacro="http://www.ros.org/wiki/xacro"&gt;</pre>
</div>

---

## Xacro: Splitting Up Files

I like how Josh Newans ([Articulated Robotics](https://articulatedrobotics.xyz/)) splits the URDF into multiple files so that is the structure I have adopted here:

- Main robot file (robot.urdf.xacro)
- Core robot (links and joints)
- List of materials (colours) to use for display
- Sensor links/joints and their corresponding Gazebo tags
- Other macros

One main file holds the <robot name="..."> tag
Other files get pulled in with xacro:include, which effectively copy-pastes their contents into the main file:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;xacro:include filename="robot.urdf.xacro" /&gt;</pre>
</div>

- Typical split: core structure, a materials/colors file, sensor links, macros
- Main file is usually `.urdf.xacro`; included files vary (`.xacro` is common)

---
## Don't Repeat Yourself

Xacro helps enforce DRY (Don't Repeat Yourself) in URDF. Repeating the same values/logic in multiple places is risky because:

- More copies = more chances for a typo or mistake
- Changing a value later means hunting down every copy
- Miss one, and your system goes inconsistent — e.g., if "100% speed" means different things in different places, you could command a speed the robot didn't expect (real collision risk)

---

## Xacro: Properties

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;xacro:property name="arm_radius" value="0.5" /&gt;
...
&lt;cylinder radius="${arm_radius}" length="7" /&gt;</pre>
</div>

- Declare a constant once, reference it everywhere, change it in one place, not ten

---

## Xacro: Macros

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;xacro:macro name="inertial_box" params="mass x y z *origin"&gt;
    &lt;inertial&gt;
        &lt;xacro:insert_block name="origin"/&gt;
        &lt;mass value="${mass}" /&gt;
        &lt;inertia ixx="${(1/12) * mass * (y*y+z*z)}" ixy="0.0" ixz="0.0"
                iyy="${(1/12) * mass * (x*x+z*z)}" iyz="0.0"
                izz="${(1/12) * mass * (x*x+y*y)}" /&gt;
    &lt;/inertial&gt;
&lt;/xacro:macro&gt;</pre>
</div>

- A reusable template that varies based on parameters — this one computes inertia for any box, so you never hand-derive that formula again

---


## ⚠️ Common Pitfall

Don't chase perfect inertia values by hand. Unless you're designing a precision controller, a rough guess is fine — that's exactly why the inertia macro exists, so you're not doing tensor math for every link.

---


## Summary

- A URDF is a tree of links and joints
- Links carry visual/collision/inertial
- Joints carry type/parent/child/origin/axis/limits
- Xacro properties and macros exist so you write correct values once, not everywhere

---

## Preview: Wednesday

**Build a real robot from scratch, a differential-drive mobile robot.**

- `base_link`, a chassis, two driven wheels, a caster
- Then straight into lab — see the companion lab handout

---

# Wednesday — Building a Robot From Scratch

*Held in the lab space. Walk through each step live, then transition straight into lab time.*

---

## Recap: Monday

- `<link>` carries visual/collision/inertial; `<joint>` carries type/parent/child/origin/axis/limits
- Xacro properties and macros keep values correct in one place instead of scattered everywhere
- Today: write all of this for a real robot, not a toy example

---

## Differential-Drive Robots

- Two driven wheels (left and right) control all motion; other wheels just keep it stable and can spin freely (**caster wheels**)
- Popular because it's simple to build and control, and it can turn on the spot — no three-point turns
- The TurtleBot family (a common ROS education robot) comes in many shapes, but most are differential-drive underneath

---

## ROS Conventions for Mobile Robots

- The main coordinate frame is always called **`base_link`** (REP 105)
- Orientation is always **X-forward, Y-left, Z-up** (REP 103)
- These aren't optional style choices — other ROS packages (including ones you'll use later this semester) assume them

---

## Wait — Isn't Our Robot Mecanum, Not Differential-Drive?

- Yes. This exercise deliberately uses differential-drive anyway, because it's the simplest possible case to *learn the URDF-building process on* — two wheel joints, one clear kinematic story
- Everything about *structure* (base_link placement, fixed vs. continuous joints, the chassis/wheel/caster pattern) transfers directly to the MentorPi
- What changes for Mecanum: **four** wheel joints instead of two, and the wheels themselves are usually represented differently (mecanum rollers), which affects visual/collision geometry — but not the underlying tree-building process you're learning today

---

## Quick Pipeline Recap

- `xacro` combines your files into one complete URDF
- `robot_state_publisher` reads that and publishes `/robot_description` plus all the transforms
- `joint_state_publisher_gui` fakes joint motion for testing, same as last module

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">sudo apt install ros-jazzy-xacro ros-jazzy-joint-state-publisher-gui</pre>
</div>

---

## ⚠️ Common Pitfall

If you build with `colcon build --symlink-install`, URDF edits update automatically, **except** when you add a brand-new file — that one still needs a build. You'll also need to quit and relaunch `robot_state_publisher` after every change, and RViz sometimes needs its "Reset" button to pick up changes.

---

## The Key Design Decision: Where Is `base_link`?

- You might assume the chassis center — but for a differential-drive robot, the simplest choice is the **center of the two drive wheels**, since that's the point the robot actually rotates around
- Everything else (chassis, wheels, caster) gets positioned relative to that point

---

## 🖥️ Live Demo: `base_link`

- Start with an empty link called `base_link` — no geometry yet, just the root of the tree
- Relaunch `robot_state_publisher` and confirm it runs with no errors before adding anything else

---

## 🖥️ Live Demo: The Chassis

- A box, 0.3 × 0.3 × 0.15 m — connected to `base_link` by a **fixed** joint, set back from center
- The box's origin is at its bottom-rear-center, so the geometry needs to be shifted forward (X) by half the length and up (Z) by half the height from that origin

---

## Why a Separate Chassis Link at All?

- `robot_state_publisher` will warn you if the *root* link has inertia specified — so the root (`base_link`) should generally stay empty
- If a camera or lidar gets attached to the chassis later, you can move the wheels without touching those attachments — everything downstream of `chassis` moves together

---

## Your Dimensions Don't Have to Match Anyone Else's

- 0.3 × 0.3 × 0.15 m is just one example robot's chassis — there's no "correct" size
- What matters is internal consistency: whatever numbers you pick, the wheel spacing, caster height, and chassis offset all need to agree with each other geometrically, or the robot will look subtly wrong (floating, tilted, wheels not touching the ground)
- Treat today's build as a real design exercise, not a copy-typing exercise

---

## 🖥️ Live Demo: First Look in RViz2

- Set **Fixed Frame** to `base_link`
- Add a **TF** display (names enabled) and a **RobotModel** display (topic `/robot_description`)
- You should now see the chassis box, offset correctly from the origin

---

## 🖥️ Live Demo: Drive Wheels

- Cylinders, connected directly to **`base_link`** (not the chassis) via **continuous** joints — since `base_link` is the rotation center, wheels belong there
- Cylinders default to standing upright (Z-axis) — roll each one a quarter-turn around X so it lies along Y instead
- Keep the Z-axis pointing outward on each wheel: rotate the left wheel −π/2, the right wheel +π/2

---

## The Axis Detail That's Easy to Miss

- With the Z-axis pointing outward on each wheel, "drive forward" means rotating **positively around Z**
- Set each wheel joint's `axis` to `xyz="0 0 1"` accordingly — get this backwards and your robot will drive in reverse from what the code says

---

## 🖥️ Live Demo: Faking Wheel Rotation

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 run joint_state_publisher_gui joint_state_publisher_gui</pre>
</div>

- Without this, the wheels won't display correctly, since nothing is publishing their joint states yet

---

## 🖥️ Live Demo: The Caster Wheel

- A simple frictionless **sphere**, connected to the **chassis** with a **fixed** joint
- Positioned so its lowest point matches the bottom of the drive wheels — not physically realistic, but simple, and good enough for now

---

## ✅ Checkpoint

**Why `continuous` for the drive wheels instead of `revolute`? Why `fixed` for the caster instead of leaving it off the chassis link directly?**

---

## Adding Collision

- Simplest approach: copy the `geometry` and `origin` straight from each `<visual>` tag into a matching `<collision>` tag
- Toggle "Visual Enabled" off and "Collision Enabled" on in RViz's RobotModel display to check it looks right
- Not ideal long-term (now you have two places to update dimensions) — xacro properties fix this, but copy-paste is fine to get moving today

---

## Adding Inertia

- Don't hand-derive inertia tensors — copy the community `inertial_macros.xacro` file into your `description/` folder and include it
- Apply the matching macro (box/cylinder/sphere) to each link, with an `origin` matching that link's visual/collision origin
- This is the exact macro pattern from Monday's lecture, now actually saving you real work

---

## 🛠️ Troubleshooting Recap

**This week's reflexes:**
1. New file added → rebuild, even with `--symlink-install`
2. Relaunch `robot_state_publisher` after every URDF change
3. RViz not updating → "Reset" button, then toggling display items, then restart as a last resort

---

## Today's Lab

Hands-on, in the companion lab handout:
- Build `base_link` → chassis → drive wheels → caster, in that order
- Get it visualized in RViz2, confirm wheels spin correctly via `joint_state_publisher_gui`
- Add collision and inertia once the visual structure is solid

---

## Summary

- A real differential-drive robot, built link by link, joint by joint
- `base_link` at the wheel-rotation center was the one design decision that shaped everything else
- Collision and inertia came last, on purpose, once the visual structure was already right

---

## Preview: Next Module

**Gazebo — watching this robot actually drive.**

- `joint_state_publisher_gui` has been faking motion this whole time — next module, real physics
- Spawn your robot, add a simple drive plugin, and drive it with `teleop_twist_keyboard`
- `ros2_control` comes later still, once real hardware makes the "same code, sim and real" story worth the setup

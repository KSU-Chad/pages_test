---
title: "Module 4 — Launch Files, YAML, Parameters & the Math of Transforms"
date: 2026-09-14 13:00:00 -0500
categories: [Module 04, Transforms]
tags: [ros2, launch, yaml, parameters, tf2, transforms, matrices, rviz]
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

# Module 4
## Launch Files, YAML, Parameters & the Math of Transforms

RAS 212 — Introduction to ROS 2

---

## Today's Agenda

- **Monday (today):** a quick pass on launch files/YAML/parameters, then the real focus — the math behind coordinate transforms
- **Wednesday, in the lab space:** the same ideas, live, in RViz and `tf2`
- No midterm this semester — we keep rolling straight through into hands-on TF work, then URDF next module

---

## Recap: Last Week

- Colcon, workspaces, packages — your code has a home
- Your first publisher/subscriber pair, in both Python and C++

---

## Hook

> Everything a robot does — driving, sensing, planning — depends on it knowing exactly where its parts are relative to each other and to the world. That's what today is about.

---

## Learning Objectives

By the end of today, you will be able to:
- Declare and use a parameter inside a node, and load one from YAML
- Write a basic launch file that starts multiple nodes together
- Explain what a coordinate frame and a transform are, in plain language
- Explain why the *order* you combine rotation and translation changes the result

---

## Parameters: A Quick Recap

- A parameter is a named, typed value a node uses to configure itself
- Declare it in code, set it from the CLI or from a launch file, change it without restarting
- You've seen this from the CLI side already (Module 2) — today, briefly, from the code side

---

## 🖥️ Live Demo: Declaring a Parameter

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">self.declare_parameter('robot_name', 'mentorpi')
name = self.get_parameter('robot_name').get_parameter_value().string_value</pre>
</div>

- One line to declare it with a default, one line to read it back

---

## YAML: The Config File Format

- Keys and values, nested with indentation — **no tabs, ever**
- The single most common beginner error: mixing tabs and spaces, or inconsistent indentation

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">my_node:
  ros__parameters:
    robot_name: "mentorpi"
    max_speed: 1.5</pre>
</div>

---

## Launch Files: Why They Exist

- "Stop opening five terminals" — one command starts everything your system needs
- A launch file can start multiple nodes, load a YAML parameter file, remap topics, and set namespaces

---

## 🖥️ Live Demo: A Basic Launch File

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='my_pkg',
            executable='my_node',
            parameters=['config/params.yaml']
        ),
    ])</pre>
</div>

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 launch my_pkg my_launch.py</pre>
</div>

---

## ⚠️ Common Pitfall

YAML indentation errors fail silently or with a confusing error far from the actual mistake. If a launch file "does nothing," check YAML indentation before anything else.

---

## Now, the Real Focus: Transforms

> Everything a robot does depends on knowing where its parts are, relative to each other and to the world.

---

## Why Transforms Matter

- A robot arm's gripper position keeps changing relative to the base. How does the controller know where the gripper actually is in the world, not just relative to the joint above it?
- A camera mounted on the rover spots a rock sample, but it's the arm that has to reach it. How do we turn "camera saw it 30cm to the left" into "arm, move to this exact point"?
- Both problems need the same tool: a way to convert a position described from one point of view (camera, joint, sensor) into a different point of view (arm base, rover base, world)

---

## What Is a Frame?

- A **frame** is a coordinate system attached to something — the world, the robot's body, a wheel, a camera, a sensor
- Every part of a robot you might care about gets its own frame

## What Is a Transform?

- A **transform** describes the translation and rotation needed to turn one frame into another
- It can always be reversed to go the other way

---

## The Tree Structure Rule

- Every frame is defined relative to **exactly one** parent frame (base_link)
- Any frame can have any number of *children*
- This naturally forms a tree — and if every frame in the tree is connected, you can convert a point from any frame to any other frame

---

## The Rotation Matrix, Without the Scary Part

Forget matrix theory for a second. A rotation matrix answers one question:

**If I spin the x-axis and y-axis by angle theta, where do they end up pointing?**

- The x-axis, originally at (1, 0), ends up at (cos theta, sin theta)
- The y-axis, originally at (0, 1), ends up at (-sin theta, cos theta)

Stack those two new directions as columns, and that's the whole matrix:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">R(theta) = [ cos  -sin ]
           [ sin   cos ]</pre>
</div>

---

## 🖥️ Live Demo: The 2D Transform Tool — Rotation Only

- Set translation to zero, drag theta
- Watch the purple/teal lines — those are exactly the two columns of R(theta) from the last slide
- The matrix box below the visualization updates live — same numbers, same idea

<div class="tool-embed">
<iframe src="{{ '/assets/interactives/transforms_2d.html' | relative_url }}" style="width:100%; height:1450px; border:1px solid #D3D1C7; border-radius:10px;" loading="lazy" title="2D Homogeneous Transform Explorer"></iframe>
<p style="text-align:right; font-size:0.85em; margin-top:0.4em;"><a href="{{ '/assets/interactives/transforms_2d.html' | relative_url }}" target="_blank">Open full-screen ↗</a></p>
</div>

*(The same tool above is used for the next two demos too — rotation only, then translation, then the order toggle.)*

---

## The Homogeneous Matrix: Bolt On a Translation

- Take the rotation matrix, add a third column for how far you're sliding (x_t, y_t)
- Add a bottom row `[0 0 1]` — this row is just plumbing to make the matrix square, it has no meaning of its own

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">T = [ cos  -sin  x_t ]
    [ sin   cos  y_t ]
    [  0     0    1  ]</pre>
</div>

---

## 🖥️ Live Demo: The 2D Transform Tool — Adding Translation

- Now drag x_t and y_t too
- The transformed frame both rotates *and* slides

---

## The One Idea That Actually Matters: Order

**Rotating then translating is not the same as translating then rotating.**

- Start at (1, 0). Rotate 90 degrees: you're at (0, 1). Translate by (2, 0): you end at (2, 1).
- Start at (1, 0). Translate by (2, 0) first: you're at (3, 0). Rotate 90 degrees about the origin: you end at (0, 3).

(2, 1) is not (0, 3) — same two operations, different order, completely different result.

---

## 🖥️ Live Demo: Toggle the Order

- Set theta, x_t, y_t to whatever you like
- Predict out loud which way you think the frame will land
- Click the order toggle — watch it land somewhere else entirely

---

## 🖥️ Live Demo: One Dimension Up — the 3D Tool

- Same idea, now with a choice of rotation axis (X, Y, or Z)
- The matrix grows to 4x4, but the structure is identical: a 3x3 rotation block, a translation column, a dummy bottom row
- Same order-matters toggle, same lesson

<div class="tool-embed">
<iframe src="{{ '/assets/interactives/transforms_3d.html' | relative_url }}" style="width:100%; height:1650px; border:1px solid #D3D1C7; border-radius:10px;" loading="lazy" title="3D Homogeneous Transform Explorer"></iframe>
<p style="text-align:right; font-size:0.85em; margin-top:0.4em;"><a href="{{ '/assets/interactives/transforms_3d.html' | relative_url }}" target="_blank">Open full-screen ↗</a></p>
</div>

---

## Why ROS Needs Any of This

- A real robot has dozens of frames — wheels, sensors, joints, cameras
- Doing this trigonometry by hand for every pair of frames, every fraction of a second, doesn't scale
- `tf2` computes exactly these matrices automatically, and chains them together whenever you ask "where is frame A relative to frame B"

---

## Static vs. Dynamic Transforms

- **Static:** doesn't change over time — broadcast once, assumed correct until updated
- **Dynamic:** may change over time — the broadcaster is expected to keep publishing fresh values

---

## Summary

- Parameters, YAML, and launch files — quick today, but you'll use all three constantly from here on
- A rotation matrix is just "where do the axes end up"
- A homogeneous matrix bolts a translation onto that
- Order matters — rotate-then-translate and translate-then-rotate are genuinely different operations
- `tf2` is just this math, automated and chained across a whole robot

---

# Wednesday — Transforms, Live

## Recap: Monday

- A transform = rotation + translation, packed into one matrix
- Order matters — rotate-then-translate is not translate-then-rotate
- Every frame has exactly one parent — that's what makes the tree structure work

---

## Today: The Same Math, as Real ROS 2 Tools

- `static_transform_publisher` broadcasts one transform, once
- RViz2 lets us see the tree we're building
- `robot_state_publisher` + `joint_state_publisher_gui` broadcast a *moving* robot's transforms automatically
- `view_frames` (from `tf2_tools`) draws the whole tree as a diagram

---

## 🖥️ Live Demo: Broadcasting a Static Transform

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run tf2_ros static_transform_publisher x y z yaw pitch roll parent_frame child_frame</pre>
</div>

- Translation first (x, y, z), then rotation (yaw, pitch, roll) — in radians
- Example: a frame `robot_1`, 2m across and 1m up from `world`, rotated 45 degrees (0.785 rad):

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run tf2_ros static_transform_publisher 2 1 0 0.785 0 0 world robot_1</pre>
</div>

---

## 🖥️ Live Demo: A Second Frame, Chained

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run tf2_ros static_transform_publisher 1 0 0 0 0 0 robot_1 robot_2</pre>
</div>

- `robot_2` sits 1m over from `robot_1` — like a sidecar
- Notice: we defined `robot_2` relative to `robot_1`, not relative to `world` directly. That's the tree structure from Monday, for real.

---

## 🖥️ Live Demo: Viewing It in RViz2

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run rviz2 rviz2</pre>
</div>

- Click "Add" → select "TF"
- Set the **Fixed Frame** (top-left) to `world` — it defaults to `map`, which doesn't exist yet, so nothing will show up until you change this

---

## ⚠️ Common Pitfall

RViz draws the transform arrow from **child to parent** — the opposite direction from how we describe it in the command, and the opposite of what `view_frames` will show later today. Same transform, two different arrow conventions. Don't let it confuse you.

---

## 🖥️ Live Demo: Watch the Chain Move Together

Re-run the first command with a bigger rotation:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run tf2_ros static_transform_publisher 2 1 0 1.57 0 0 world robot_1</pre>
</div>

- `robot_1` rotates — and `robot_2` moves with it, because it's defined *relative to* `robot_1`, not to `world`
- This is the payoff of the tree structure: change one frame, everything downstream follows automatically

---

## ✅ Checkpoint

**If you changed the fixed frame in RViz from `world` to `robot_1`, what would look different on screen?**

---

## From Static to Moving: What's Missing?

- Everything so far has been **static** — broadcast once, never updates
- A real robot has **moving** parts — wheels turning, joints bending
- For that, we need `robot_state_publisher`, which reads a URDF file and automatically broadcasts every transform it describes

---

## 🖥️ Live Demo: Bringing Up a Moving Robot

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run robot_state_publisher robot_state_publisher --ros-args -p robot_description:="$(xacro path/to/file.urdf.xacro)"</pre>
</div>

- The `robot_description` parameter wants the full *contents* of the URDF, not a file path — that's what the `xacro ...` subshell is doing
- This command is painful to type by hand every time, which is exactly why we'll use a provided launch file to do it for us in lab

---

## 🖥️ Live Demo: Faking Joint Motion

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run joint_state_publisher_gui joint_state_publisher_gui</pre>
</div>

- This tool reads `/robot_description`, finds any joints that can move, and shows you a slider for each one
- It publishes to `/joint_states`, which `robot_state_publisher` is listening for
- On a real robot, actual encoders would publish here instead — today, we fake it with sliders

---

## 🖥️ Live Demo: Seeing It All Together in RViz2

- Add a "RobotModel" display, set its topic to `/robot_description`
- Move the sliders in `joint_state_publisher_gui` — watch the robot's joints move in RViz2, live

---

## ✅ Checkpoint

**If you closed `joint_state_publisher_gui`, what would happen to the robot's pose in RViz — would it disappear, or freeze in place?**

---

## 🖥️ Live Demo: `view_frames` — Seeing the Whole Tree

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 run tf2_tools view_frames.py</pre>
</div>

- Listens for a few seconds, then generates `frames.pdf` in your current directory
- Shows every frame, its parent, and how recently it was broadcast
- Arrow direction here matches the plain-language "parent → child" description from Monday — the opposite of RViz's convention

---

## 🛠️ Troubleshooting Recap

**This week's reflexes:**
1. Fixed Frame not set in RViz → nothing appears, even if everything else is correct
2. RViz's arrow direction is reversed from `view_frames` — don't let that trip you up
3. `view_frames` is your best tool when something in a complex tree looks wrong and you can't tell why just from RViz

---

## Today's Lab

Hands-on, in the companion lab handout:
- **Part 1:** broadcast a static transform chain, visualize it in RViz2
- **Part 2:** bring up a moving robot with `robot_state_publisher` + `joint_state_publisher_gui`, using your existing `ros2_transforms` example
- **Part 3:** generate and read a `view_frames` diagram of your own tree

---

## Summary

- You've now built a transform tree by hand, watched it move, and visualized it two different ways
- Everything today was the same math from Monday — just automated and made visual
- Next module: URDF, where the link/joint structure you'll write turns out to be the exact same tree pattern as today's frames

---

## Preview: Next Module

**URDF — describing a robot's physical structure.**

- Links and joints follow the same parent-child tree pattern as today's frames
- `robot_state_publisher` reads a URDF and broadcasts all its transforms automatically — you just watched this happen without building the URDF yourself yet

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
- Services, custom interfaces, and QoS are coming later this semester, right before hardware — not forgotten, just resequenced

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

## ✅ Checkpoint

**What's one thing a launch file lets you do that running `ros2 run` by hand doesn't?**

---

## Now, the Real Focus: Transforms

> Everything a robot does depends on knowing where its parts are, relative to each other and to the world.

---

## Why Transforms Matter

- Two robots exploring an area — one finds something interesting. How does the *other* robot know how to get there?
- A camera spots a target, but it's a robotic arm that has to move to it. How do we translate "camera saw it here" into "arm, move there"?
- Both problems need the same tool: a way to convert a position described from one point of view into a different point of view

---

## What Is a Frame?

- A **frame** is a coordinate system attached to something — the world, the robot's body, a wheel, a camera, a sensor
- Every part of a robot you might care about gets its own frame

## What Is a Transform?

- A **transform** describes the translation and rotation needed to turn one frame into another
- It can always be reversed to go the other way

---

## Points vs. Vectors — Not the Same Thing

- A **point** is a location. You cannot add two points together — "chair plus doorway" means nothing.
- A **vector** is a displacement — a "how to get from here to there." Vectors *can* be added, subtracted, scaled.
- The difference between two points is a vector. A point plus a vector gives you a new point.
- Why this matters: when tf2 gives you a transform, it's handing you something closer to a vector (a displacement) — applying it to a point is what actually moves that point somewhere new

---

## Right-Handed Coordinate Frames

- Draw the x-axis first. The y-axis is the x-axis swung 90 degrees **counterclockwise**. That's the whole rule.
- This is called a **right-handed** frame, and ROS assumes it everywhere, without exception
- You won't build frames the other way in this course, but the term will come up again — now you know what it means

---

## The Tree Structure Rule

- Every frame is defined relative to **exactly one** parent frame
- Any frame can have any number of *children*
- This naturally forms a tree — and if every frame in the tree is connected, you can convert a point from any frame to any other frame

---

## ✅ Checkpoint

**Name three frames a mobile robot might have.**

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

*(The same tool above is used for the next two demos too — rotation only, then translation, then the pivot-point toggle.)*

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

**Rotating around your own new location is not the same as rotating around the world origin.**

- Translate to (x_t, y_t), then spin in place: the origin stays exactly at (x_t, y_t) — rotating a frame about its own origin never moves that origin, only its orientation
- Translate to (x_t, y_t), then rotate the *whole thing* about the world origin instead: the point sweeps along an arc, like it's on the end of an arm pinned at (0, 0)
- Same rotation angle, same translation distance — genuinely different final position depending on which point the rotation pivots around
- "Rotate in place" is the convention `static_transform_publisher` and URDF both use

---

## 🖥️ Live Demo: Toggle the Pivot Point

- Set theta, x_t, y_t to whatever you like
- Predict out loud where the origin marker will land for each button
- Click between "rotate in place" and "rotate about world origin" — watch the origin itself either stay put or sweep along an arc
- **Heads up:** it's genuinely easy to get turned around here, even for people comfortable with matrices — don't worry if your first prediction is wrong

---

## ✅ Checkpoint

**Before I toggle the order button — which way do you think the frame moves?**

*(Ask this every time, before revealing. It's the whole lesson.)*

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

## ✅ Checkpoint

**When you rotate about the Z axis specifically, which coordinate stays unchanged? Why does that make sense?**

---

## Why ROS Needs Any of This

- A real robot has dozens of frames — wheels, sensors, joints, cameras
- Doing this trigonometry by hand for every pair of frames, every fraction of a second, doesn't scale
- `tf2` computes exactly these matrices automatically, and chains them together whenever you ask "where is frame A relative to frame B"

---

## Static vs. Dynamic Transforms

- **Static:** doesn't change over time — broadcast once, assumed correct until updated
- **Dynamic:** may change over time — the broadcaster is expected to keep publishing fresh values
- Why the distinction matters: a robust system can flag an error if a *dynamic* transform goes stale, but a static one is never expected to update

---

## One More Thing: This Isn't Just for Arms

- Wednesday's lab uses a manipulator arm as the moving-robot example — not because this is an arms course, but because an arm makes the idea easiest to *see*: each joint is one clean rotation, chained to the next
- The exact same idea (a chain of transforms, computed from moving parts) is what figures out a wheeled robot's position from how far its wheels have turned — that's called **odometry**, and you'll meet it for real on the MentorPi later this semester
- **Forward kinematics** (arm world): given the joint angles, where's the gripper? **The mobile-robot version:** given the wheel motion, where's the robot? Same underlying question, different hardware

---

## Summary

- Parameters, YAML, and launch files — quick today, but you'll use all three constantly from here on
- A rotation matrix is just "where do the axes end up"
- A homogeneous matrix bolts a translation onto that
- Order matters — rotate-then-translate and translate-then-rotate are genuinely different operations
- `tf2` is just this math, automated and chained across a whole robot

---

## Preview: Wednesday

**Same ideas, live, in ROS 2.**

- `static_transform_publisher`, RViz2, `robot_state_publisher`, `joint_state_publisher_gui`, `tf2_tools`
- Then straight into lab — see the companion lab handout

---

# Wednesday — Transforms, Live

*Held in the lab space. Walk through each demo live, then transition straight into lab time.*

---

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

## URDF: The Same Tree, Written Down

- You just spent an hour building a frame tree by hand with `static_transform_publisher` — parent, child, parent, child
- A **URDF** file is that exact same tree, written down once, for a whole robot: a `<link>` is a rigid piece, a `<joint>` connects two links and says how one can move relative to the other
- `robot_state_publisher` reads this file and does the `static_transform_publisher` work for you, automatically, for every link in the tree

---

## Inside a `<link>`

- **`visual`** — what it looks like in RViz (a box, cylinder, or mesh)
- **`collision`** — the (often simplified) shape used for collision checking
- **`inertial`** — mass and how it's distributed, used for physics — matters for Gazebo, not for RViz alone

---

## Joint Types

| Type | Motion |
|---|---|
| `fixed` | none — rigidly bolted together |
| `revolute` | rotates, with limited range (like an elbow) |
| `continuous` | rotates, unlimited (like a wheel) |
| `prismatic` | slides along a straight line |

---

## The `<origin>` Tag Is Monday's Matrix, For Real

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;origin xyz="0.5 0 0.1" rpy="0 0 0"/&gt;</pre>
</div>

- `xyz` first, then `rpy` — translate in the **parent's** axes, then rotate. Origin stays put, then spins in place.
- That's the exact convention from this morning's "rotate in place" button — you already know how to read this

---

## 🖥️ Live Demo: Reading the Actual File

Open `example_robot.urdf.xacro` from the repo you're about to use in lab. Walk through it together:

- **`base_link`** — a box, the root of the tree, no parent
- **`slider_link`** — another box, connected to `base_link` by `slider_joint`, a **prismatic** joint (slides along the top)
- **`arm_link`** — a cylinder, connected to `slider_link` by `arm_joint`, a **revolute** joint (rotates, limited range) — this is the one the sliders will move most obviously in lab
- **camera link** — connected by a **fixed** joint, just for organization (a separate frame is clearer than piling visuals onto the arm)

---

## A Preview, Not a Lesson: Xacro

- Notice this file is `.urdf.xacro`, not plain `.urdf` — it uses **properties** and **macros** (see `example_include.xacro`) so inertia math isn't retyped for every link
- Full Xacro authoring — writing your own macros, building a robot from scratch — is next module
- Today, just recognize that it exists and does some of the tedious math for you

---

## ✅ Checkpoint

**Looking at the file: which joint do you expect to move the *most* when you drag the sliders in lab — `slider_joint` or `arm_joint`? Why?**

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

## What You Just Generated Has a Name: a Pose Graph

- Each frame is a node. Each known transform is a directed edge between two nodes.
- If two frames aren't directly connected, `tf2` finds a **path** through the graph and chains the transforms along it — composing forward edges, and reversing (inverting) any edge it has to traverse backwards
- This is exactly what `lookupTransform` is doing every time you ask "where is frame A relative to frame B" — walking the graph you just generated

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

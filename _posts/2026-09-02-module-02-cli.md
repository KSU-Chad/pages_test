---
title: "Module 2 — ROS 2 CLI Tour: Nodes, Topics, Services, Parameters & Actions"
date: 2026-01-12 09:00:00 -0600
categories: [Module 02, ROS2 CLI]
tags: [ros2, topics, nodes, services, parameters, actions, turtlesim]
pin: false
marp: true
theme: default
paginate: true
---

# Module 2
## ROS 2 CLI Tour: Nodes, Topics, Services, Parameters & Actions

RAS 212 — Introduction to ROS 2

---

## Today's Agenda

- Everything today runs against `turtlesim` and pre-built demo nodes
- **No workspace. No package. No code written yet.**
- The goal: understand five core ROS 2 concepts by driving them from the CLI (and one GUI tool) first
- Today's lecture sets up two lab activities you'll run hands-on afterward

---

## Recap: Last Week

- Linux foundations: shell, permissions, filesystem structure
- ROS 2 architecture: nodes as ordinary Linux processes
- Middleware and DDS: how nodes find each other without a central server
- Environment variables: `ROS_DISTRO`, `ROS_VERSION`

---

## Hook

> You can understand an entire robot's software system without writing a single line of code.

Today, we prove it — using nothing but a cartoon turtle.

---

## Learning Objectives

By the end of today, you will be able to:
- Inspect any running ROS 2 system using CLI tools alone
- Explain what a node, topic, service, parameter, and action each are
- Read a topic's message type and structure using `topic info` and `interface show`
- Use `rqt_graph` and the RQT Service Caller to visualize and drive a system without writing code
- Understand what remapping does and why it matters for running multiple similar nodes

---

## `turtlesim`: The Class's Training Wheel

- A simple 2D simulator: a turtle you can drive around a window
- Deliberately simple — the point is the ROS 2 concepts, not the simulation
- Every concept today (nodes, topics, services, parameters, actions) already exists inside `turtlesim`
- You'll see these same five concepts again on a real MentorPi robot later in the semester

---

## 🖥️ Live Demo: Launch `turtlesim`

```bash
ros2 run turtlesim turtlesim_node
ros2 run turtlesim turtle_teleop_key
```

- Two terminals, two nodes, one turtle
- Drive it with arrow keys — notice: **you never touched a line of code**

---

## `rqt`: The Visual Toolbox

- `rqt` is a collection of GUI plugins for inspecting a running ROS 2 system
- `rqt_graph` is the one we'll use constantly — a live diagram of nodes and topics
- Later today, we'll also use RQT's **Service Caller** plugin — a GUI way to call services

```bash
rqt_graph
```

---

## Understanding Nodes

**A node is a single, focused program that does one job.**

- The turtlesim simulator is one node
- The teleop keyboard listener is a *separate* node
- A real robot might run dozens of nodes at once — each one small and single-purpose

---

## 🖥️ Live Demo: `ros2 node list`

```bash
ros2 node list
```

- Shows every node currently running
- With `turtlesim` + `teleop_key` running, you should see exactly two

---

## 🖥️ Live Demo: `ros2 node info`

```bash
ros2 node info /turtlesim
```

- Shows what a specific node publishes, subscribes to, and offers as services/actions
- Read the output field by field, live, as a class

---

## ✅ Checkpoint

**From `ros2 node info` alone, how would you know what a node publishes?**

*(Discuss in pairs, then share out.)*

---

## ⚠️ Common Pitfall: Node Name Collisions

- Two nodes with the same name can't coexist cleanly on the same system
- ROS 2 will warn you, but the symptom can look confusing the first time
- Rule of thumb: if something "isn't responding," check `ros2 node list` for duplicates first

---

## Understanding Topics

**A topic is a named stream of messages that nodes publish to and subscribe from.**

- Nobody talks to anybody directly — everything flows through a named topic
- Many nodes can publish to the same topic; many nodes can subscribe to it
- This is how `teleop_key` tells `turtlesim` to move, without either node knowing the other exists

---

## 🖥️ Live Demo: `ros2 topic list`

```bash
ros2 topic list
```

Add the `-t` flag to see each topic's message type in the same listing:

```bash
ros2 topic list -t
```

- Look for `/turtle1/pose` and `/turtle1/cmd_vel`

---

## 🖥️ Live Demo: `ros2 topic info`

```bash
ros2 topic info /turtle1/cmd_vel
```

- Confirms `/turtle1/cmd_vel` has type `geometry_msgs/msg/Twist`
- Reading that name: package `geometry_msgs` contains a message called `Twist`
- This is how you go from "I see a topic" to "I know exactly what data it carries"

---

## 🖥️ Live Demo: `ros2 interface show`

```bash
ros2 interface show geometry_msgs/msg/Twist
```

Returns:

```
This expresses velocity in free space broken into its linear and angular parts.

    Vector3  linear
    Vector3  angular
```

- Now you know exactly which fields to fill in before you ever publish to this topic

---

## 🖥️ Live Demo: `ros2 topic echo`

```bash
ros2 topic echo /turtle1/cmd_vel
```

- Streams live data as it's published
- Drive the turtle with the teleop node and watch `Twist` values appear in real time

---

## 🖥️ Live Demo: `ros2 topic pub` — `--once`

```bash
ros2 topic pub --once /turtle1/cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
```

- Publishes exactly one message, then stops
- The turtle moves once — a single nudge

---

## 🖥️ Live Demo: `ros2 topic pub` — `--rate`

```bash
ros2 topic pub --rate 1 /turtle1/cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
```

- Publishes continuously at 1 Hz until you Ctrl+C
- The turtle keeps moving in a steady arc — this is the same mechanism the teleop node uses under the hood, just automated

---

## ✅ Checkpoint

**What's the practical difference between `--once` and `--rate 1`, in terms of what the turtle actually does?**

---

## 🖥️ Live Demo: The Pose Topic

```bash
ros2 topic echo /turtle1/pose
```

- Same `echo` tool, different topic — confirms this pattern works everywhere, not just for `cmd_vel`

---

## 🖥️ Live Demo: `rqt_graph`, Reading the Diagram

- Nodes appear as ovals, topics as rectangles, arrows show data flow
- With your manual `topic pub` running, a *third* arrow appears into `turtlesim`
- This is the single most useful "what's actually connected" tool you'll use all semester

---

## ✅ Checkpoint

**What would `rqt_graph` look like if you spawned a second turtle?**

*(Think about it — we're about to find out for real.)*

---

## Understanding Services

**A service is a request/response pattern — you ask, you wait, you get an answer.**

- Different from a topic: services aren't a continuous stream, they're a single question-and-answer
- Full code-level treatment comes in Module 4 — today is "what is this, and what does it feel like"

---

## 🖥️ Live Demo: `ros2 service list`

```bash
ros2 service list
```

- Notice `/spawn`, `/kill`, and `/turtle1/set_pen` — turtlesim exposes all of these as services

---

## RQT's Service Caller: A GUI for Services

- Open `rqt`, then **Plugins → Services → Service Caller**
- Lets you pick a service, fill in its fields, and call it — no terminal typing required
- Great for exploring a service's fields before you'd ever write code against it

---

## 🖥️ Live Demo: Spawning a Turtle via RQT

In the Service Caller:
- Select `/spawn`
- Set `name` to `turtle2`
- Set `x = 1.0`, `y = 1.0`
- Click Call — a second turtle appears

---

## 🖥️ Live Demo: `set_pen` via RQT

- Select `/turtle2/set_pen` in the Service Caller
- Set `r = 81`, `g = 40`, `b = 136`
- Now driving `turtle2` draws a line in that color — a nice visible confirmation the service call actually did something

---

## ✅ Checkpoint

**Why use the RQT Service Caller here instead of `ros2 service call`? Is there a real difference?**

*(Same underlying mechanism — GUI vs. CLI is a convenience choice, not a different concept.)*

---

## ⚠️ Common Pitfall

Mistyping a service's request field names in the CLI produces a cryptic error — always double-check field names with:

```bash
ros2 service type /spawn
ros2 interface show turtlesim/srv/Spawn
```

The RQT Service Caller sidesteps this entirely by showing you the fields directly — one reason it's worth knowing both tools.

---

## Remapping: Running a Second Teleop Node

- You now have two turtles, but only one teleop node — it only controls `turtle1`
- **Remapping** lets you take an existing node and redirect which topic it actually uses, without touching its code

```bash
ros2 run turtlesim turtle_teleop_key --ros-args \
  --remap turtle1/cmd_vel:=turtle2/cmd_vel
```

---

## 🖥️ Live Demo: Two Turtles, Two Teleop Windows

- Terminal 2 (original teleop) still controls `turtle1`
- Terminal 4 (remapped teleop) now controls `turtle2`
- Switch focus between terminals and drive each turtle independently

---

## ✅ Checkpoint

**In plain language, what did `--remap turtle1/cmd_vel:=turtle2/cmd_vel` actually do to the node's code?**

*(Nothing — the node's code is unchanged. Remapping only changes which topic name it binds to at launch time.)*

---

## Understanding Parameters

**A parameter is a named, typed value a node uses to configure its own behavior.**

- Unlike topics (data flowing *between* nodes), parameters live *inside* one node
- Can often be changed live, without restarting the node

---

## 🖥️ Live Demo: `ros2 param list`

```bash
ros2 param list /turtlesim
```

---

## 🖥️ Live Demo: `ros2 param get` / `set`

```bash
ros2 param get /turtlesim background_r
ros2 param set /turtlesim background_r 255
```

- Change the turtlesim background color live, in front of the class
- No restart required — the node picks up the new value immediately

---

## ✅ Checkpoint

**What's one thing you just changed at runtime without restarting a node?**

---

## Understanding Actions

**An action is for long-running tasks where you want progress updates along the way.**

- Goal → Feedback (repeated) → Result
- Think of it as a service, but for tasks that take a while and you don't want to just sit there blind
- Full code-level treatment comes in Module 11 — today is a CLI-only preview

---

## 🖥️ Live Demo: `ros2 action list`

```bash
ros2 action list
```

- `turtlesim` exposes `/turtle1/rotate_absolute` as an action

---

## 🖥️ Live Demo: `ros2 action send_goal`

```bash
ros2 action send_goal /turtle1/rotate_absolute \
  turtlesim/action/RotateAbsolute "{theta: 1.57}" --feedback
```

- Watch the turtle rotate *and* watch feedback stream into the terminal as it turns
- That streaming feedback is the whole point of actions — a service could never do this

---

## ✅ Checkpoint

**How did that action differ from the service calls you made earlier?**

---

## `rqt_console`: Viewing Logs

```bash
ros2 run rqt_console rqt_console
```

- Every node logs info, warnings, and errors
- `rqt_console` gives you a searchable, filterable window into all of it at once
- You'll reach for this constantly once you're writing your own nodes

---

## 🖥️ Live Demo: Launching a Pre-Built Launch File

```bash
ros2 launch turtlesim multisim.launch.py
```

- Launch files start multiple nodes with one command — no five terminal windows
- Today we're only *using* one someone else wrote. Writing your own comes in Module 4.

---

## 🖥️ Live Demo: First Touch of `ros2 bag`

```bash
ros2 bag record /turtle1/cmd_vel /turtle1/pose
```

- Drive the turtle for 10-15 seconds, then Ctrl+C
- We'll play this back and use `rosbag2` properly much later in the semester — today is just "this exists"

---

## 🔗 Show Online

Pull up the docs.ros.org concept pages for **Nodes**, **Topics**, **Services**, **Parameters**, and **Actions** side by side.

*(Live browser tab — see placeholder slide.)*

---

## ⚠️ Common Pitfall

**"I need to write code to use ROS 2."**

You just spent an entire class period proving that's false. Everything today — CLI *and* the RQT Service Caller — required zero code. Keep that in mind whenever a real system feels overwhelming — you can always *inspect* before you *write*.

---

## Today's Lab

Two hands-on activities, in the companion lab handout:
- **Activity 1:** topic mechanics — `list`, `echo`, `info`, `interface show`, `pub --once`/`--rate`
- **Activity 2:** services via RQT (spawn, `set_pen`) and remapping a second teleop node

Everything in today's lecture is what you'll be doing yourself in a few minutes — no recording or write-up required, just work through both activities.

---

## 🛠️ Troubleshooting Recap

**This week's tools: `list` / `info` / `interface show` as your first reflex**

Whenever you encounter an unfamiliar ROS 2 system:
1. `ros2 node list` — what's running?
2. `ros2 topic list -t` / `ros2 service list` / `ros2 action list` — what's available, and what type is it?
3. `ros2 topic info` / `ros2 interface show` — what does the data actually look like?
4. `... info` on whatever looks relevant — what does it actually do?

---

## Summary

- Five core ROS 2 concepts, all understood without writing a single line of code
- Nodes, topics, services, parameters, actions — each has a distinct feel and a distinct CLI verb (and sometimes a GUI equivalent)
- Remapping let you reuse existing code for a second turtle without touching it
- `rqt_graph`, `topic info`/`interface show`, and the `list`/`info` pattern will be your reflexes for the rest of the semester

---

## Preview: Next Week

**You finally write your own code.**

- Git, workspaces, and your first package
- Everything today used code someone else already wrote — next week, you build the home for your own

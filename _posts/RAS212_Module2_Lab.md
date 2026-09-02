---
title: "Module 2 Lab — Topics, Services & Remapping with turtlesim"
date: 2026-01-12 11:00:00 -0600
categories: [Module 02, ROS2 CLI Lab]
tags: [ros2, topics, services, turtlesim, rqt, remapping, lab]
pin: false
---

# RAS 212 — Module 2 Lab
## ROS 2 CLI Tour: Topics, Services & Remapping with `turtlesim`

**Prerequisites:** Module 2 lecture (nodes, topics, services, parameters, actions overview)
**Format:** No code, no workspace — everything today runs against `turtlesim` using the CLI and RQT

---

## Activity 1 — Topic Mechanics

**Goal:** get comfortable inspecting and publishing to a topic without writing any code.

1. Open two terminals and launch `turtlesim`:

   ```bash
   ros2 run turtlesim turtlesim_node
   ros2 run turtlesim turtle_teleop_key
   ```

2. List active topics:

   ```bash
   ros2 topic list
   ```

   Now list them with their types included:

   ```bash
   ros2 topic list -t
   ```

3. Echo the velocity command topic:

   ```bash
   ros2 topic echo /turtle1/cmd_vel
   ```

4. Check the topic's type directly:

   ```bash
   ros2 topic info /turtle1/cmd_vel
   ```

   > Topic `/turtle1/cmd_vel` has type `geometry_msgs/msg/Twist`. This means that in the package `geometry_msgs` there is a message called `Twist`.

5. Look at the actual structure of that message type:

   ```bash
   ros2 interface show geometry_msgs/msg/Twist
   ```

   Expected output:

   ```
   This expresses velocity in free space broken into its linear and angular parts.

       Vector3  linear
       Vector3  angular
   ```

6. Re-run the echo to confirm you now know what you're looking at:

   ```bash
   ros2 topic echo /turtle1/cmd_vel
   ```

7. Publish a single command manually:

   ```bash
   ros2 topic pub --once /turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
   ```

   The turtle should move **once**.

8. Publish continuously at 1 Hz:

   ```bash
   ros2 topic pub --rate 1 /turtle1/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 2.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 1.8}}"
   ```

   The turtle should move **continuously** in an arc. Ctrl+C to stop.

9. Now view the pose topic instead:

   ```bash
   ros2 topic echo /turtle1/pose
   ```

**Check your understanding before moving on:** what's the practical difference between `--once` and `--rate 1`? What would `ros2 topic info -v` show that plain `ros2 topic info` doesn't? *(Hint: QoS — you'll use this again in Module 4.)*

---

## Activity 2 — Services via RQT & Remapping

**Goal:** explore the call/response nature of services using a GUI tool, then reuse an existing node for a second robot via remapping.

1. Open two terminals and launch `turtlesim` again (fresh instance is fine):

   - **Terminal 1:** `ros2 run turtlesim turtlesim_node`
   - **Terminal 2:** `ros2 run turtlesim turtle_teleop_key`

2. **Spawn a second turtle using RQT.**

   Nodes and topics are a continuous flow — services are different: a service only provides data when a client actually calls it. We'll use RQT to explore this.

   - **Terminal 3:** `rqt`
   - In RQT: **Plugins → Services → Service Caller**
   - In the Service dropdown, select `/spawn`
   - Enter a new turtle name in the `name` string field: `turtle2`
   - Set `x = 1.0` and `y = 1.0`
   - Click **Call** — confirm a second turtle appears

3. Click into the teleop terminal window (Terminal 2) and use the arrow keys — confirm you're moving `turtle1`.

4. **Change `turtle2`'s pen color** using the `set_pen` service, still in the Service Caller:

   - Select `/turtle2/set_pen`
   - Set `r = 81`, `g = 40`, `b = 136`
   - Call it

5. **Create a teleop node for `turtle2` using remapping.**

   Open a new terminal (Terminal 4):

   ```bash
   ros2 run turtlesim turtle_teleop_key --ros-args --remap turtle1/cmd_vel:=turtle2/cmd_vel
   ```

6. Control `turtle2` from this window (Terminal 4), then click back into Terminal 2 to confirm you can still independently control `turtle1`.

**Check your understanding before moving on:** in plain language, what did the `--remap` flag actually change about the teleop node's code? *(Nothing — the code is identical; only the topic name it binds to at launch changed.)*

---

## Completion Checklist

- [ ] Activity 1: successfully ran `topic list -t`, `topic info`, `interface show`, and both `--once` and `--rate` publishing
- [ ] Activity 2: spawned `turtle2` via RQT, changed its pen color with `set_pen`, and drove both turtles independently via remapping

## Troubleshooting Tips

- **`ros2 interface show` gives "package not found":** double check the exact type string, including the `msg`/`srv` segment (`geometry_msgs/msg/Twist`, not `geometry_msgs/Twist`)
- **RQT Service Caller doesn't show your service:** click the refresh icon next to the service dropdown — it doesn't always auto-update
- **Remapped teleop still controls `turtle1`:** check for typos in the remap argument; it's `old_name:=new_name`, order matters
- **Nothing happens on `topic pub --rate 1`:** confirm you didn't forget to press Ctrl+C from the previous command still running in that terminal

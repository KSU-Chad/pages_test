---
title: "Module 6 — Gazebo: Watching Your Robot Actually Drive"
date: 2026-09-28 13:00:00 -0500
categories: [Module 06, Gazebo Simulation]
tags: [ros2, gazebo, teleop, cmd_vel, odometry, rviz]
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

# Module 6
## Gazebo: Watching Your Robot Actually Drive

RAS 212 — Introduction to ROS 2

---

## Why Simulate At All?

- Testing on real hardware is slow, expensive, and sometimes genuinely risky — a bad command can damage a real robot or whatever's around it
- Early-stage bugs are usually in your code, not your hardware — a simulator lets you find and fix those without crashing into things
- Gazebo is a separate open-source project (also run by Open Robotics, the same group behind ROS) — it integrates tightly with ROS but isn't literally part of it

---

## From Sliders to Real Physics

- `joint_state_publisher_gui` never simulated anything — you moved a slider, and RViz just redrew the joint at a new angle
- Gazebo is a real physics engine: it simulates your robot's mass, friction, and motor limits, and responds to actual drive commands
- Nothing changes about your URDF's structure — you're adding to it, not replacing it

---

## `/cmd_vel`: The Universal Drive Command

- A drive command lives on a topic called `/cmd_vel` — a `Twist` (or `TwistStamped`), six numbers: linear velocity (x, y, z) and angular velocity (x, y, z)
- A differential-drive robot only ever uses two of those six: linear x (forward/back) and angular z (turning) — the rest stay zero

---

## Odometry and Dead Reckoning
 
- **Dead reckoning:** estimate where you are *now* from where you *started* plus how you've moved since — no outside reference, just bookkeeping
- **Odometry** is dead reckoning for robots: use motion sensors (wheel encoders, accelerometers, gyros) to keep a running estimate of pose
- The core idea in all of it: integrate small motions over tiny time steps and add them up
---
 
## Dead Reckoning vs. Absolute Positioning
 
- Dead reckoning is **relative** — every estimate builds on the previous one, so small errors get carried forward and stacked on top of each other
- **Absolute** methods (GPS, matching against a known map, recognizing a landmark) tell you where you are directly, so error doesn't pile up over time
- Dead reckoning is fast, cheap, and works anywhere, but its error grows without bound; absolute methods bound the error but need infrastructure or a map
- Real robots almost always combine both — dead reckoning to fill the gaps *between* absolute fixes
---
 
## Method 1: Wheel Odometry
 
- **Encoders** on the motors/wheels count rotation — ticks per revolution, converted to wheel angle
- Wheel angle × wheel radius = distance that wheel rolled
- Cheap, fast (updates hundreds of times a second), and works in the dark, in a open space, anywhere
- The weak point: it assumes the wheel rolled *without slipping* — any slip, bump, or wheel-size mismatch becomes an error the math can't see
---
 
## The Differential-Drive Math
 
Given how far each wheel rolled (`Δs`) in this unit of time (`Δs_left`, `Δs_right`) and the wheel separation `L`:
 
```
Δs = (Δs_right + Δs_left) / 2        distance the robot's center moved
Δθ = (Δs_right - Δs_left) / L        how much the heading changed
 
x_new = x + Δs * cos(θ + Δθ/2)
y_new = y + Δs * sin(θ + Δθ/2)
θ_new = θ + Δθ
```
 
- Both wheels equal → `Δθ = 0` → drives straight; wheels different → the difference is what turns the robot
- Using `θ + Δθ/2` (the *midpoint* heading) instead of just `θ` is a small refinement that noticeably reduces error, because the robot turned a bit during the step
---
 
## ✏️ Work It By Hand: One Odometry Update
 
Wheel radius `r = 0.05 m`, wheel separation `L = 0.35 m`. The robot starts at `x = 0`, `y = 0`, `θ = 0`. In one time step, the left wheel turns **2.0 rad** and the right wheel turns **2.4 rad**.
 
Calculate: `Δs_left`, `Δs_right`, `Δs`, `Δθ`, and the new `x`, `y`, `θ`.
 
<details markdown="1">
<summary>Answer</summary>
- `Δs_left = 0.05 × 2.0 = 0.10 m`
- `Δs_right = 0.05 × 2.4 = 0.12 m`
- `Δs = (0.12 + 0.10) / 2 = 0.11 m`
- `Δθ = (0.12 − 0.10) / 0.35 ≈ 0.0571 rad` (about 3.3°, a gentle left turn since the right wheel went farther)
- Midpoint heading = `0 + 0.0571/2 ≈ 0.0286 rad`
- `x_new = 0.11 × cos(0.0286) ≈ 0.1100 m`
- `y_new = 0.11 × sin(0.0286) ≈ 0.0031 m`
- `θ_new ≈ 0.0571 rad`
The robot moved almost straight ahead, but ended up a few millimeters to the left and slightly rotated — exactly the kind of tiny update that gets repeated hundreds of times a second.
 
</details>
---
 
## Odometry Is Just Transforms Again
 
- Every odometry update is a small motion composed onto the previous pose — rotate a little, move forward, rotate a little more
- That "move forward" is along the robot's *own* heading, not the world's — same "translate in the rotated axes" idea from the pivot-point tool in Module 4
- The `odom` → `base_link` transform in ROS is literally this running pose: every update multiplies one more small transform onto the last
- Same order-matters lesson too — apply these in the wrong order and you land somewhere different
---
 
## Method 2: IMU (Gyroscope + Accelerometer)
 
- An **IMU** has a gyroscope (rotation rate) and an accelerometer (acceleration)
- **Gyro → heading:** integrate rotation rate once to get angle. Works well short-term and doesn't care about wheel slip. Its weakness is bias: a tiny constant offset integrates into steady drift
- **Accelerometer → position:** you'd have to integrate *twice* (acceleration → velocity → position), and noise/bias errors blow up much faster — error grows roughly with the *square* of time
- That's why robots rarely dead-reckon position from an accelerometer alone; the gyro's heading is the useful part
---
 
## Method 3: Visual and Lidar Odometry
 
- **Visual odometry:** track features between successive camera frames and work out how the camera must have moved
- **Lidar odometry (scan matching):** line up each new scan against the previous one and see how far you'd have to shift/rotate to make them agree
- No wheels involved, so wheel slip stops being a problem
- New weak points instead: featureless hallways, glass, bright/dark lighting, fast motion blur — and they cost real computing power
- Still relative measurements, so they still drift — just for different reasons than wheels do
---
 
## Where the Errors Come From
 
**Systematic errors** — repeatable, the same every time:
- Wheel diameter slightly off, or two wheels not quite the same size
- Wheel separation `L` in your code not matching the real robot
- These can be measured and calibrated out
**Non-systematic errors** — unpredictable:
- Wheel slip, bumps, uneven floors, someone shoving the robot
- These can't be calibrated away, only detected or corrected by another sensor
**Heading errors are the worst kind** — a small angle error keeps pushing you sideways the farther you go: 1° off over 10 m is about 17 cm of sideways error, and it never shrinks on its own
 
---
 
## ✏️ Systematic Error: Wrong Wheelbase
 
Your code says `L = 0.35 m`, but the real robot's wheels are actually `0.36 m` apart. In each time step, the wheels roll `0.02 m` apart from each other (`Δs_right − Δs_left = 0.02`).
 
1. What heading change does your code compute per step, versus what really happened?
2. How far off is your heading estimate after 100 steps?
3. Is this a systematic or non-systematic error? Could you calibrate it out?
<details markdown="1">
<summary>Answer</summary>
1. Code: `0.02 / 0.35 ≈ 0.0571 rad`. Reality: `0.02 / 0.36 ≈ 0.0556 rad`. Your code overestimates by about `0.0016 rad` (~0.09°) every step.
2. After 100 steps: `0.0016 × 100 ≈ 0.159 rad`, roughly **9° of heading error** — from an error in a single number that looked tiny.
3. **Systematic** — it's the same every step. You can calibrate it out: command the robot to spin a known amount (say, one full rotation), measure how far it really turned, and adjust the wheel separation (or a correction factor) until they agree. This is exactly what MentorPi's `angular_correction_factor` is for.
</details>
---
 
## Method 4: Sensor Fusion
 
- No single sensor is best at everything — so blend them:
  - Wheel odometry is good at **distance**
  - A gyro is good at **rotation**
  - Fusing them uses each for what it's best at
- The usual tool is a **Kalman filter** (the Extended Kalman Filter, or EKF, for non-linear systems like robots): it blends estimates, weighting each by how much you trust it
- In ROS 2, the `robot_localization` package provides this — you'll see it again in later courses; the math underneath is a topic for another day
- Fusion improves dead reckoning but doesn't eliminate drift; only an absolute reference does that
---
 
## Methods at a Glance
 
| Method | Sensor | Good at | Weak at | Typical drift cause |
|---|---|---|---|---|
| Wheel odometry | Encoders | Distance, speed, works anywhere | Slip, uneven floors | Wheel slip, size/wheelbase error |
| IMU (gyro) | Gyroscope | Short-term heading | Long-term drift | Sensor bias |
| IMU (accel) | Accelerometer | Detecting sudden motion | Position (double integration) | Noise + bias, squared over time |
| Visual odometry | Camera | No wheels needed | Poor lighting/featureless scenes | Lost or mismatched features |
| Lidar odometry | Lidar | Structured environments | Long, featureless corridors | Scan-matching ambiguity |
| Fusion (EKF) | Several combined | Best of each | More complexity to tune | Whatever the inputs' errors are |
 
---
 
## ✅ Checkpoint
 
**A robot drives across a slippery floor. Which of the four methods would you trust *least* for distance, and which would you trust most for heading?**
 
<details markdown="1">
<summary>Answer</summary>
Trust wheel odometry least for distance — slippery floors mean the wheels spin without the robot actually moving that far, which is exactly the "assumes no slip" weakness. Trust a gyro (IMU) most for heading — it measures rotation directly and isn't fooled by wheel slip, though you'd still watch for slow bias drift over long runs.
 
</details>
---
 
## ✅ Checkpoint
 
**If your robot drives in a big circle and ends up back where it started, would odometry say the same thing? Why or why not?**
 
<details markdown="1">
<summary>Answer</summary>
Probably not exactly. Every small error — a bit of wheel slip, a slightly-off wheel size — gets added into the running estimate and never gets removed, so odometry's idea of "where I ended up" will usually be off from the true starting point. That gap between where odometry says you are and where you truly are is the drift, and it's exactly why real robots pair dead reckoning with an absolute reference.
 
</details>
---
 
## Where This Shows Up Next
 
- In Gazebo, the `DiffDrive` plugin publishes odometry computed from wheel motion using these same kinds of equations
- Later courses (Path Planning & Navigation) add the absolute references that finally keep drift in check
- For now: know what odometry is, where its error comes from, and why nobody trusts it alone
---

## How a Gazebo Plugin Fits In

- Gazebo has its own internal topics, separate from ROS's — so it needs help to talk to your ROS nodes
- A **plugin** is extra code that runs *inside* Gazebo and adds behavior to the simulation; we'll use two:
  - **`DiffDrive`** — the "driver." It reads velocity commands (`/cmd_vel`), turns them into wheel motion in the physics simulation, and reports back where the robot ended up (odometry)
  - **`JointStatePublisher`** — reports the real wheel joint positions, replacing the `joint_state_publisher_gui` slider that was faking them
- `DiffDrive` also broadcasts a new frame, `odom`, marking where the robot started — the transform from `odom` to `base_link` is your live position estimate
- A separate **bridge** (Wednesday) carries messages between Gazebo's topics and ROS's topics — the plugins live inside Gazebo, the bridge sits between the two worlds

---

## Same Plugin, More Wheels: Skid-Steer

- The `DiffDrive` plugin isn't limited to exactly two wheels — its `<left_joint>` and `<right_joint>` tags can each appear more than once
- A 4-wheel skid-steer robot (front-left, rear-left, front-right, rear-right) just lists every wheel on each side; every wheel on a side gets the same commanded speed
- Same plugin, same `/cmd_vel` math — differential drive and skid-steer are kinematically identical, they only differ in wheel count and how much the extra wheels scrub against the ground when turning

---

## Sim Hides Something Real

- The `DiffDrive` plugin computes odometry *kinematically* — from commanded/measured wheel velocity — not from actual wheel-ground contact physics
- That means a simulated skid-steer robot's odometry comes out just as clean as a simulated differential-drive robot's, because the plugin never actually simulates the scrubbing or sliding
- On a **real** skid-steer (or Mecanum) robot, that scrubbing is real, and it corrupts wheel-encoder-based odometry — the simulator is quietly lying to you about how accurate your odometry will be once you're on real hardware

---

## Coming Back to This: MentorPi's Real Correction Factors

- Your MentorPi has a documented `calibrate_params.yaml` with `linear_correction_factor` and `angular_correction_factor` — corrections for exactly this kind of real-world odometry drift
- It ships pre-calibrated, but Hiwonder's own docs note it may need retuning if you see the robot drifting or not driving/turning exactly as commanded
- We'll revisit this for real once we're driving the physical robot (or its accurate model in Gazebo) later this semester — today's plugin can't show you this problem, only real hardware can

---

## Gazebo-Specific URDF Tags

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">&lt;link name="my_link"&gt;
  &lt;!-- normal link content --&gt;
&lt;/link&gt;

&lt;gazebo reference="my_link"&gt;
  &lt;!-- Gazebo-specific parameters for that link --&gt;
&lt;/gazebo&gt;

&lt;gazebo&gt;
  &lt;!-- Gazebo parameters not tied to one link --&gt;
&lt;/gazebo&gt;</pre>
</div>

- `<gazebo reference="...">` targets one specific link or joint by name; a bare `<gazebo>` with no reference applies to the whole file
- 🔗 [Articulated Robotics: Gazebo Simulation](https://articulatedrobotics.xyz/tutorials/mobile-robot/concept-design/concept-gazebo) — today's anchor resource, with full plugin XML and troubleshooting notes

---

## Why Gazebo Needs Simulation Time

- Gazebo wants to control the clock, not just follow the wall clock — this lets simulations run faster or slower than real time and keeps everything synchronized
- That's what `use_sim_time:=true` actually does: it tells a node "get your idea of 'now' from Gazebo, not your own system clock"
- In ROS 2, this has to be set per-node (not globally), which is exactly why launch files are useful here — set it once at launch, pass it to everything

---

## Collision & Inertia, Properly

- Back in Module 5, you applied inertia macros without necessarily calculating anything by hand — today, let's actually do the math those macros are hiding from you
- Two reasons this matters more here than it did in RViz: Gazebo's physics engine genuinely *uses* these numbers (RViz just ignores them), and there's a real formula mix-up worth avoiding before you go pull numbers from a reference book

---

## ⚠️ A Real Mix-Up to Avoid

- **Area moment of inertia** (often just called "moment of inertia") — units of m⁴, used for bending stress and beam deflection calculations
- **Mass moment of inertia** — units of kg·m², used for rotational dynamics — this is what URDF's `<inertia>` tag actually wants
- They're related concepts with similar names and genuinely different formulas. 
---

## Mass Moment of Inertia: The Three Shapes You'll Actually Use

**Box** (mass `m`, dimensions `x`, `y`, `z`):
```
I_xx = (1/12) * m * (y² + z²)
I_yy = (1/12) * m * (x² + z²)
I_zz = (1/12) * m * (x² + y²)
```

**Cylinder** (mass `m`, radius `r`, height `h`, axis along Z):
```
I_xx = I_yy = (1/12) * m * (3r² + h²)
I_zz = (1/2) * m * r²
```

**Sphere** (mass `m`, radius `r`):
```
I_xx = I_yy = I_zz = (2/5) * m * r²
```

The sphere is the easy one — same value in every direction, since a sphere looks identical no matter which way you rotate it.

---

## ✅ Checkpoint

**Your caster is a sphere, mass 0.05 kg, radius 0.02 m. Calculate its moment of inertia.**

<details markdown="1">
<summary>Answer</summary>

I = (2/5) × 0.05 × (0.02)² = 0.4 × 0.05 × 0.0004 = **0.000008 kg·m²** (8 × 10⁻⁶)

Small mass, small radius — a tiny number, which makes sense for a lightweight caster that barely resists being spun.

</details>

---

## The Part That Actually Answers "Do I Need Inertia On Every Link?"

- Gazebo (via SDF) **merges any URDF links connected by `fixed` joints into a single SDF link**
- Because of that merge, SDF only requires *at least one* `<inertial>` tag per group of fixed-jointed links — not necessarily one on every single URDF link in that group
- Example: if your camera is `fixed` to your chassis, and your chassis already has inertia specified, Gazebo will treat them as one merged rigid body — the camera link technically doesn't need its own inertia
- **Best practice is still to give every meaningfully-massive link its own inertia anyway** — this rule explains why a missing inertial tag on a small fixed accessory doesn't break the simulation, not an excuse to skip it on things that actually matter

---

## Pulling Inertia From CAD Instead of Formulas

- If you've modeled your robot in CAD (Fusion 360 or similar) and assigned a material to each body, the software will calculate mass, center of mass, and the full inertia tensor for you
- In Fusion 360: **Inspect → Physical Properties**, or right-click a body/component → **Properties**
- **The catch:** CAD reports inertia about *its own* reference point and axes — not automatically your URDF link's origin. You still need to line up the reference frame, which is exactly what the `<origin>` tag inside `<inertial>` is for
- This doesn't save you from understanding the formulas above — it saves you from doing the arithmetic once you already understand what the numbers mean

---

## ⚠️ Common Pitfall: A Flopping Robot

If your robot looks unstable or jitters excessively once it's driving in Gazebo, try adding damping to your joints:

```xml
<dynamics damping="10.0" friction="10.0"/>
```

Placed inside the `<joint>` tag, alongside `<axis>` and `<limit>`. Higher values resist motion more — useful for taming a simulation that's technically correct but visually chaotic.

---


## Summary

- `/cmd_vel` and odometry are the same concepts you'll meet again on real hardware
- A simple Gazebo plugin gets you driving today; `ros2_control` earns its complexity later, once real hardware exists
- The `DiffDrive` plugin scales to skid-steer with more wheels, same math — but simulation hides the real-world scrubbing that corrupts odometry, which is exactly what MentorPi's correction factors exist to fix
- You now know the actual rule for when a link needs its own `<inertial>` tag (fixed-joint merging), can calculate mass moment of inertia by hand for the three shapes you'll actually use, and know where to pull the same numbers from CAD if you modeled your robot there
- Everything from last module (your URDF) carries forward unchanged — today only adds to it

---


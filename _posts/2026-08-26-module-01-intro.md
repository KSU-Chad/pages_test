---
title: "Module 1 — Introduction & ROS 2 Overview"
date: 2026-01-12 09:00:00 -0600
categories: [Module 1]
tags: [ros2, jazzy, docker, setup, ros-domain-id]
pin: false
---

## Welcome to RAS 212

This is the first stop on a semester-long build-up: by Module 15, you'll be
driving a real MentorPi M1 robot with lidar safety-stop and a live camera
feed. Everything between now and then adds one more piece. Today we lay the
foundation — what ROS 2 actually is, why robotics software is built this
way, and getting your development environment running.

## Why robots need a "middleware"

Imagine a robot's software as several separate specialists — one watching
the lidar, one deciding where to drive, one turning the wheels — who all
need to talk to each other constantly, in real time, without ever quite
knowing exactly when the others are going to speak. That's the core problem
ROS 2 exists to solve: it's a set of tools and conventions for many
independent programs (called **nodes**) to discover each other and pass
messages back and forth, without you having to hand-build a networking
system every single project.

## Learning Objectives

By the end of this module, you should be able to:

- Explain, in your own words, why robotics software is built as a network of
  communicating nodes rather than one large program
- Identify the current ROS 2 distribution (Jazzy Jalisco) and describe what
  a "distribution" means in this context
- Set up and verify a working ROS 2 Docker development environment
- Explain what `ROS_DOMAIN_ID` does and why it matters in a shared lab

## Concept: ROS 2 and the Jazzy Jalisco release

ROS 2 isn't a single piece of software you install once — it's released in
**distributions**, each a bundled, tested set of ROS 2 packages tied to a
specific Ubuntu LTS version. This course uses **Jazzy Jalisco**, running on
**Ubuntu 24.04**.

> Formal specifications for ROS 2 releases and supported platforms live in
> [**REP-2000**](https://ros.org/reps/rep-2000.html), the "Releases and
> Target Platforms" REP (ROS Enhancement Proposal). You won't need to read
> it deeply this semester, but it's worth knowing this kind of formal
> governance document exists — professional ROS 2 developers reference REPs
> the way web developers reference W3C specs.
{: .prompt-info }

## Concept: ROS_DOMAIN_ID — isolation in a shared lab

Every computer running ROS 2 broadcasts and listens for messages on the
network. In our lab, with everyone's Docker container active at once, that
means **your robot could accidentally "hear" someone else's commands** —
unless each of you is on a different `ROS_DOMAIN_ID`.

Think of it like Wi-Fi channels: everyone's routers are nearby, but each
operates on its own channel so they don't interfere. `ROS_DOMAIN_ID` is that
channel number for ROS 2 — an integer (0–232) that isolates groups of nodes
from each other, even on the same physical network.

> This isn't just a classroom workaround — `ROS_DOMAIN_ID` isolation is a
> real technique used in industrial and multi-robot deployments to keep
> separate robot fleets from cross-talking. You're learning a genuine
> production practice, not a toy simplification.
{: .prompt-tip }

**Your assigned domain ID for this course will be posted on Canvas** —
you'll set it as an environment variable in your container every session.

## 🔗 Live Demo

*(In-class: instructor demonstrates two Docker containers with different
`ROS_DOMAIN_ID` values, showing that `ros2 topic list` in one container
doesn't see topics published in the other — then sets them to the same ID
and shows the cross-talk.)*

## Checkpoint — Discuss with a neighbor

- If two robots in the same room use the *same* `ROS_DOMAIN_ID`, what do you
  predict would happen if both students drove their robots at the same time?
- Why might a company running 50 warehouse robots want more than one
  `ROS_DOMAIN_ID` in use across the building?

## Lab Briefing

1. Confirm Docker Desktop (or Docker Engine) is installed and running on
   your lab machine.
2. Pull the course's ROS 2 Jazzy image and start a container.
3. Set your assigned `ROS_DOMAIN_ID` as an environment variable inside the
   container.
4. Run `ros2 doctor` and confirm it reports no errors — this is
   **diagnostic tool #1** in your semester-long troubleshooting checklist.
5. Submit your terminal output (screenshot or copy-pasted text) via the
   `ras212-module-01` assignment repo.

```bash
docker pull osrf/ros:jazzy-desktop
docker run -it -e ROS_DOMAIN_ID=<your-assigned-id> osrf/ros:jazzy-desktop bash
ros2 --version
ros2 doctor
```

## 🔧 Troubleshooting Spotlight: `ros2 doctor`

`ros2 doctor` is a built-in health check — it inspects your ROS 2
installation and environment variables and flags common misconfigurations
before they cause confusing downstream errors. Add it to your personal
troubleshooting checklist now; you'll reach for it constantly as the
semester's setups get more complex.

> **Troubleshooting checklist so far:** `ros2 doctor`
{: .prompt-tip }

## Summary

- ROS 2 is middleware for coordinating many communicating nodes, not a
  single monolithic program
- We're using the Jazzy Jalisco distribution on Ubuntu 24.04, formally
  scoped by REP-2000
- `ROS_DOMAIN_ID` isolates your robot's communication from everyone else's
  in the same room — and the same technique scales to real industrial fleets
- Your Docker environment is now verified and ready for next week

## Next Week Preview

**Module 2 — Workspaces & Packages.** You'll create your first ROS 2
workspace and package, and write your first (very small) node. Bring your
working Docker setup from this week — we build directly on it.

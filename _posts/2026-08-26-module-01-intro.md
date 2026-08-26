---
title: "Module 1 — Introduction & ROS 2 Overview"
date: 2026-01-12 09:00:00 -0600
categories: [Module 01]
tags: [ros2, jazzy, docker, setup, ros-domain-id]
pin: false
---

## Welcome to RAS 212

This is the first stop on a semester-long build-up: by Module 15, you'll be
driving a real MentorPi M1 robot with lidar safety-stop and a live camera
feed. Everything between now and then adds one more piece. Today we lay the
foundation — what ROS 2 actually is, why robotics software is built this
way, and getting your development environment running.

# Module 1 — Linux & ROS 2 Foundations

---

## 1. Welcome to Module 1

Today has two halves. The first half is Linux — the operating system every robot in this room actually runs. The second half is ROS 2 — the layer that sits on top of Linux and makes robotics software possible. Neither half makes sense without the other, so we're doing them back to back.

---

## 2. Today's Agenda

- **Part A:** Linux history, the kernel, distributions, the shell, users, permissions, and editing files
- **Part B:** What ROS 2 is, why it exists, middleware, DDS, and robot architecture

By the end of today, you'll be able to navigate a Linux system and explain, in plain language, what ROS 2 actually is and why robotics needed it.

---

## 3. Hook: Why Does a Robot Need an Operating System?

A robot has sensors reading data, motors needing commands, and a battery that can die mid-task. Someone has to manage all of that — memory, processes, hardware access, timing — at the same time, reliably. That's what an operating system does. ROS 2 doesn't replace the operating system; it runs on top of one, using it to do all this coordination.

---

## 4. Learning Objectives

By the end of this module, you will be able to:
- Explain what a kernel is and how it relates to a distribution
- Navigate a Linux filesystem and use basic commands from the shell
- Explain file permissions, users/root, and the purpose of `sudo`
- Edit files using `nano` and `vim`
- Explain, in your own words, what ROS 2 is, why it exists, and what middleware and DDS do

---

## 5. Linux History

[Linux]([https://google.com](https://en.wikipedia.org/wiki/History_of_Linux) "The History of Linux") traces back to Unix, an operating system built in the 1970s at Bell Labs. In 1991, a Finnish student named Linus Torvalds wrote a free kernel as a personal project and released it to the world. Combined with tools from the GNU Project (started earlier by Richard Stallman), it became what we now call "Linux," though technically "GNU/Linux" is more accurate — the GNU tools provide the commands, Linux provides the kernel underneath them.

---

## 6. The Open-Source Philosophy

Linux is free and open source: anyone can read, modify, and redistribute its code. This matters directly for robotics — nearly every tool you'll use this semester (ROS 2, Docker, Git, the compilers, the drivers) exists because of this same philosophy. Robotics research moves fast partly *because* so much of its software stack is open and shareable rather than locked behind a vendor.

---

## 7. What Is a Kernel?

The **kernel** is the core program that talks directly to hardware — CPU, memory, disk, network — and decides which programs get access to what, and when. The **operating system** is the kernel plus everything built around it: the shell, the file utilities, the graphical interface. People often use "Linux" to mean the whole OS, but strictly, Linux *is* the kernel; everything else is added on top.

---

## 8. Kernel Versions vs. Distributions

One kernel, many distributions. A **distribution** ("distro") packages the Linux kernel together with system tools, package managers, and default software into something you can actually install and use. Ubuntu, Debian, Fedora, and Arch all use the same underlying kernel concept but differ in tooling, release philosophy, and defaults — the same way different car manufacturers all build on the same combustion-engine principles but package the rest of the car differently.

---

## 9. The Distro Landscape

Debian is one of the oldest and most stable distro families; Ubuntu is built on top of Debian and adds more polish and hardware support; Fedora tracks newer software more aggressively. We're using **Ubuntu 24.04 LTS** ("Long Term Support") specifically because ROS 2 Jazzy officially targets it — LTS releases get five years of security updates, which matters when a robot needs to keep running semester after semester without breaking.

---

## 10. Basic Linux Structure: The Filesystem Hierarchy

Everything on a Linux system lives under a single root directory, written `/`. From there: `/home` holds user files (your files live in `/home/yourname`), `/etc` holds system configuration, `/usr` holds installed programs, `/var` holds logs and variable data, and `/bin` holds essential commands. There's no "C: drive" — just one tree, starting at `/`.

---

## 11. "Everything Is a File"

A core Unix idea: as much as possible is represented as a file you can read, write, or list — regular documents, yes, but also devices, running processes, and system information. This is why so many Linux commands feel similar regardless of what they're touching: `cat`, `ls`, and `grep` all work the same way whether you're looking at a text file or a piece of hardware information.

---

## 12. Basic Commands, Part 1

```bash
pwd        # print working directory — where am I?
ls         # list contents of the current directory
cd folder  # change directory into "folder"
cd ..      # move up one directory
```

These four commands are how you'll spend most of your time navigating. `pwd` answers "where am I?", `ls` answers "what's here?", and `cd` moves you around. We'll run all of these live.

---

## 13. Basic Commands, Part 2

```bash
mkdir new_folder   # create a directory
touch file.txt     # create an empty file
cp file.txt copy.txt   # copy a file
mv file.txt new_name.txt  # move or rename a file
rm file.txt        # remove (delete) a file
```

**A caution about `rm`:** there is no Recycle Bin. `rm -rf` in particular deletes recursively and forcefully with no confirmation — a single misplaced space in that command has ended careers. Always double-check what directory you're in before running it.

---

## 14. What Is the Shell?

The **shell** is the program that reads the commands you type and tells the kernel what to do — `bash` is the shell we'll use all semester. The **terminal** (or terminal emulator) is the window you type into; it's just a wrapper around the shell. People often say "terminal" and "shell" interchangeably, but knowing the distinction helps when you're troubleshooting later — the shell is the interpreter, the terminal is the display.

---

## 15. Users and Root

Linux was built from the ground up as a **multi-user system** — the same machine can serve many people, each with their own account, files, and permissions. Every user has a username and belongs to one or more groups. This isn't just historical baggage; it's the same permission model that keeps one student's code from accidentally overwriting another's on a shared lab computer.

---

## 16. Root: The Superuser

**Root** is the one account with unrestricted power over the entire system — it can read, write, or delete anything, including things that would break the machine. This is deliberate: most of the time, you *don't* want that power available by accident. A typo executed as a normal user might fail safely; the same typo executed as root can take down the whole system.

---

## 17. `sudo`

Rather than logging in as root directly, Linux systems use `sudo` ("superuser do") to grant root-level power for a single command, temporarily:

```bash
sudo apt update
```

This is safer than staying logged in as root all the time, because you have to deliberately invoke elevated privileges each time, rather than having them active by default. If a command fails with "permission denied," `sudo` is often — but not always — the fix.

---

## 18. File Permissions: Owner, Group, Other

Every file has three permission categories: **owner** (the user who created it), **group** (a set of users), and **other** (everyone else). For each category, three permissions apply: **r**ead, **w**rite, and e**x**ecute. So a file can be readable by you, writable by you, but only readable (not writable) by everyone else — that's the model behind almost every "permission denied" error you'll hit this semester.

---

## 19. Reading Permissions Live

```bash
ls -l file.txt
# -rwxr--r-- 1 chad chad 220 Aug 26 file.txt
```

Reading left to right: the first character is the file type, then three groups of `rwx` for owner/group/other. Here, the owner can read/write/execute, but group and others can only read. We'll fix a broken permission live with `chmod`, and reassign file ownership with `chown`.

---

## 20. Checkpoint

**Discussion question:** What permission setting would let *only you* edit a script, but let anyone run it?

(Take a moment before moving on — this is a good one to talk through with a neighbor.)

---

## 21. Editing Files: `nano`

`nano` is a simple, beginner-friendly text editor that runs right in the terminal:

```bash
nano myfile.txt
```

The commands you need are listed at the bottom of the screen (`^O` to save, `^X` to exit) — there's no hidden mode to get stuck in. For most of this semester, `nano` is all you'll need.

---

## 22. Editing Files: `vim`

`vim` is a far more powerful — and far less forgiving — editor built around **modes**. In **normal mode**, keystrokes are commands (`dd` deletes a line, `x` deletes a character); in **insert mode** (entered with `i`), keystrokes type text like you'd expect. The infamous first lesson everyone learns is how to *exit* vim (`Esc`, then `:wq` to save and quit). You won't master vim today — the goal is just enough to survive if you ever land in it by accident (which happens more than you'd think).

---

## 23. Checkpoint

**Discussion question:** Given what you just saw, when would you reach for `vim` over `nano`?

---

## 24. Transition: From Linux to ROS 2

You can now navigate a Linux system, edit files, and understand the permission model underneath it. Everything from here forward — every ROS 2 command, every file we create — runs on top of exactly what you just learned. Now let's talk about what ROS 2 actually adds.

---

## 25. What Is ROS 2?

**ROS 2** (Robot Operating System 2) is not actually an operating system — it's a collection of software libraries and tools that make it dramatically easier to build robotics software. It gives you standardized ways for different pieces of a robot's software to talk to each other, reuse each other's code, and stay organized as the system grows in complexity.

---

## 26. A Brief History of ROS

ROS began in the mid-2000s at Willow Garage, a robotics research lab, as a way to stop reinventing the same infrastructure for every new robot project. It caught on because it solved a real, shared problem: robotics labs were constantly rebuilding the same low-level plumbing instead of focusing on what made their robot unique. ROS 1 became the standard research platform for over a decade.

---

## 27. Why ROS 2 Exists

ROS 1 had real limitations that eventually forced a full rewrite. It relied on a single central process (`roscore`) — if that died, the whole system died with it. It had no real support for real-time control, and multi-robot systems were awkward to build. ROS 2 was designed from the ground up to fix these: no single point of failure, real-time support, and native multi-robot capability.

---

## 28. Checkpoint

**Discussion question:** What problem was ROS 2 solving that ROS 1 genuinely couldn't?

---

## 29. ROS 2 Distribution Versions

Like Ubuntu, ROS 2 has named releases — Ubuntu-style, but with a letter-based naming convention (Foxy, Galactic, Humble, Iron, Jazzy...). Each distro is tied to a specific Ubuntu version and gets a defined support window. We're using **Jazzy Jalisco**, which pairs with Ubuntu 24.04 LTS — meaning both our OS and our ROS distro are on their long-support tracks together.

---

## 30. 🔗 Show Online: REP-2000

ROS isn't just tutorials and forum posts — it has formal specification documents called **REPs** (ROS Enhancement Proposals), the same way Python has PEPs. **REP-2000** defines exactly which ROS 2 distributions target which Ubuntu releases and for how long. *(Pull up ros.org/reps/rep-2000.html live and show the table.)* You won't need to memorize this, but knowing it exists — and where to find it — matters more than the specific dates.

---

## 31. Why ROS Is Needed at All

Robotics has always faced the same problem: nearly every robot needs sensors, control loops, and communication between components, but historically every lab rebuilt this from scratch, in incompatible ways. ROS's real contribution isn't any single algorithm — it's a shared standard that lets a sensor driver written by one team, and a navigation algorithm written by another, work together without either team knowing the other's code.

---

## 32. What Is Middleware?

**Middleware** is software that sits *between* other software, handling communication so individual programs don't have to manage it themselves. A useful analogy: think of a postal service. You don't personally deliver your mail across the country — you hand it to a system that knows how to find the recipient and get it there. ROS 2's middleware plays that same role between different parts of a robot's software.

---

## 33. What Is DDS?

ROS 2's middleware is built on **DDS** (Data Distribution Service), an existing industry standard for distributing data in real time — used well beyond robotics, including in aerospace and finance. ROS 1 used a custom, in-house transport system; ROS 2 deliberately adopted DDS instead, so ROS 2 benefits from decades of engineering already invested in solving this exact problem elsewhere.

---

## 34. DDS Discovery

One useful feature DDS provides: **automatic discovery**. Nodes don't need to be told in advance who they'll talk to — they broadcast what they offer and what they need, and DDS handles finding matching partners on the network. There's no central server to configure or keep alive. This is part of why ROS 1's single-point-of-failure problem doesn't exist in ROS 2.

---

## 35. Robot Software Architecture

Think of a robot's software as a pipeline: **sensors** produce raw data → some kind of **processing** happens on that data → **actuators** (motors, etc.) act on the result. ROS 2 organizes each piece of that pipeline into a **node** — a small, focused program that does one job and communicates with the others. We'll build our first real node next week; for now, just hold onto this picture.

---

## 36. 🔗 Show Online: ROS 2 Processes Are Just Linux Processes

```bash
ps aux | grep ros
```

*(Run this live against a running example.)* This is a genuinely useful reality check: ROS 2 "nodes" aren't some special magic construct — they're ordinary Linux processes, visible with the same tools you'd use to inspect anything else on the system. Everything you learned in Part A about processes and permissions still applies here.

---

## 37. Checkpoint

**Discussion question:** Why would a ROS 2 system show up as *many* separate processes instead of one big program?

---

## 38. Environment Variables

An **environment variable** is a named value that programs can read to change their behavior, without editing any code — think of it as a sticky note the whole system can see. ROS 2 relies on several of these; two you'll see constantly are `ROS_DISTRO` (which distribution is active) and `ROS_VERSION`. Check them with:

```bash
printenv | grep ROS
```

We'll come back to a more important ROS-specific environment variable, `ROS_DOMAIN_ID`, in a few weeks — once you're running multiple systems side by side, it'll matter a lot more than it would today.

---

## 39. Lab Briefing

Today's lab: practice the Linux commands from Part A directly on your assigned lab computer, then confirm your ROS 2 Docker environment is working correctly — check that Jazzy is installed and `ROS_DISTRO` reports what you expect. No physical robot yet; that's coming in Module 9. Focus today on getting comfortable moving around a Linux system without hesitation.

---

## 40. Summary & Next Week

Today, you went from "what even is a kernel" to being able to explain what ROS 2 is and why it exists — and everything in between: distros, the shell, permissions, and DDS. Next week, we start actually building things: Git, ROS 2 workspaces, and your first real running node.



## Next Week Preview

**Module 2 — Workspaces & Packages.** You'll create your first ROS 2
workspace and package, and write your first (very small) node. Bring your
working Docker setup from this week — we build directly on it.

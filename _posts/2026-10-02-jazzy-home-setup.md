---
title: "Set Up the ROS2 Jazzy Simulation Environment at Home"
date: 2026-10-02 17:00:00 -0600
categories: [Getting Started, At-Home Setup]
tags: [docker, docker-desktop, ros2, jazzy, gazebo, kasmvnc, setup, home]
pin: true
---

Want to keep working on labs outside of class, or just prefer testing your
code on your own machine? This is the same environment used on the lab
computers, packaged so you can run it at home — on Windows, with Docker.

**Note:** unlike the lab computers, your home machine won't reset itself
between sessions — so once this is set up, you generally only need to
rebuild it after you download an updated version, not every single time.

## 1. Download and unzip

[Download jazzy-lab-home.zip](/downloads/jazzy-lab.zip)

Unzip it anywhere on your computer (Documents, Desktop — wherever you'll
remember). Inside you'll find:

```
jazzy-lab/
├── Dockerfile
├── docker-compose.yml
├── README.md
├── start-lab.bat
├── supervisor/
│   └── supervisord.conf
└── xfce-config/
    ├── xfce4-panel.xml
    ├── xfce4-desktop.xml
    ├── backgrounds/
    └── panel/
```

Keep this whole folder structure intact — `start-lab.bat` and `docker compose`
both expect everything to stay where it is relative to each other.

## 2. Install Docker Desktop

If you don't already have it:

1. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/) — get the **AMD64** version
   (correct even on Intel CPUs — "AMD64" is just the generic name for 64-bit
   PCs, not AMD-specific). Check Windows Settings → System → About →
   "System type" if you're not sure.
2. During install, make sure the **WSL2 backend** is selected (default).
3. If Docker Desktop asks to enable WSL2 as part of setup, allow it — this
   is required, not optional, for running Linux containers on Windows.
4. Once installed, open Docker Desktop, accept the Docker Subscription Service Agreement and skip signing in if asked — no
   Docker account needed for this.

## 3. Allocate resources

Docker Desktop → Settings → Resources → Advanced. Give it at least
**4 CPUs / 8GB RAM** if your machine has it to spare — this environment runs
Gazebo without a dedicated GPU, so it leans more on CPU than usual.

## 4. Start it

Double-click **start-lab.bat** inside the unzipped folder. A window opens
and handles everything automatically — no commands to type.

First run takes a while (multi-GB base image, plus the full desktop
environment) — grab a coffee. Leave the window open (minimized is fine)
while you work; don't close it, though see the note at the bottom about
what closing it does and doesn't do.

## 5. Open it in your browser

Once the text settles down and stops scrolling, go to:

```
http://localhost:6080
```

It should load straight in — no waiting, no page refresh needed. Log in with:

- **Username:** `student`
- **Password:** `student`

You'll land on a full desktop (XFCE — normal title bars, drag-to-resize
windows, an Applications menu, a taskbar) with VS Code and a terminal
already open. Firefox, a PDF viewer, and a text editor are also available
from the Applications menu or the taskbar.

## Next time you want to use it

Since your home computer doesn't reset itself, you don't strictly need to
rebuild every time. You can edit `start-lab.bat` and remove `--build` from
the command for a faster plain `docker compose up` once you've built it at
least once — or just leave `--build` in; it's slower but always safe, since
Docker skips rebuilding anything that hasn't changed.

**When you're done:** closing the window `start-lab.bat` opened does **not**
fully stop the environment — it keeps running in the background under
Docker Desktop. To actually stop it, go to Docker Desktop's **Containers**
tab and click **Stop** on `jazzy-lab`.

## Saving your work

Anything you save inside the `ros2_ws/src` folder (visible in VS Code's file
explorer on the left) automatically appears in a `student-workspace` folder
that'll be created next to your unzipped project files — that's how your
code survives between sessions. Save your actual lab work there, not just
anywhere else on the desktop inside the environment, or it won't persist.

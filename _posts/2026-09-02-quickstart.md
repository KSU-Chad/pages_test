---
title: "Getting Started — Launching Your RAS 212 Simulation Environment"
date: 2026-09-02 09:00:00 -0600
categories: [Getting Started, Lab Setup]
tags: [docker, docker-desktop, ros2, gazebo, simulation, kasmvnc, setup]
pin: true
---

# RAS 212 — Starting Your Simulation Environment

Follow these steps every time you sit down to work on a lab.

## 1. Open Docker Desktop

Find **Docker Desktop** on the Start Menu or Desktop and open it.

## 2. Wait for Docker Desktop to fully start

Look for the whale icon in the bottom-right system tray. Give it a minute —
it needs a short amount of time to finish starting up in the background
before it's ready to use.

## 3. Open the course folder

Open File Explorer and go to:

```
C:\Public\RAS212\jazzy-lab
```

## 4. Double-click start-lab.bat

Find **start-lab.bat** in that folder and double-click it. A black window
will open and start building/launching the environment automatically — you
don't need to type any commands yourself.

## 5. Wait for it to finish starting

You'll see a lot of text scroll by — this is normal. Wait until the text
stops scrolling and settles down to just a few lines repeating occasionally.
**Minimize this window rather than closing it.** Closing it won't stop the
environment (see note at the bottom), but if you close it and then double-click
start-lab.bat again without stopping the old one first, you may get a "port
already in use" error — minimizing avoids that entirely.

## 6. Open the simulation in your browser

Switch to **Docker Desktop** and click the **Containers** tab on the left.
Find and expand **jazzy-lab** in the list. Click the port link shown next to
it (something like **6080:6080**) — this opens your default browser to the
simulation environment automatically.

## 7. Log in

When the page loads, enter:

- **Username:** `student`
- **Password:** `student`

You're in. You should see a desktop with VS Code, a terminal, and everything
you need for the lab.

---

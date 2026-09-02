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

## 3. Open Command Prompt

Click the Start Menu, type **cmd**, and open **Command Prompt**.

## 4. Go to the course folder

Type this exactly, then press Enter:

```
cd C:\Public\RAS212\sim-pilot
```

## 5. Start the environment

Type this, then press Enter:

```
docker compose up
```

## 6. Wait for it to finish starting

You'll see a lot of text scroll by — this is normal. Wait until the text
stops scrolling and settles down to just a few lines repeating occasionally.
**Minimize this Command Prompt window rather than closing it.** Closing it
won't stop the environment (see note at the bottom), but if you close it and
then try to start a new one without stopping the old one first, you may get
a "port already in use" error — minimizing avoids that entirely.

## 7. Open the simulation in your browser

Switch to **Docker Desktop** and click the **Containers** tab on the left.
Find and expand **sim-pilot** in the list. Click the port link shown next to
it (something like **6080:6080**) — this opens your default browser to the
simulation environment automatically.

## 8. Log in

When the page loads, enter:

- **Username:** `student`
- **Password:** `student`

You're in. You should see a desktop with VS Code, a terminal, and everything
you need for the lab.

---

## When you're done for the day

**Closing the Command Prompt window does *not* stop the environment** — the
container keeps running in the background either way, managed by Docker
Desktop itself rather than by that window. To actually stop it:

1. Switch to **Docker Desktop** → **Containers** tab
2. Find **sim-pilot** in the list
3. Click the **Stop** (⏹) button next to it

That's the only reliable way to shut it down. Simply closing the Command
Prompt window leaves it running, using up resources on the machine even
though you've walked away — please stop it properly before you leave.

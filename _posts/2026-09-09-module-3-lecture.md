---
title: "Module 3 — Git, Workspaces & Packages"
date: 2026-09-09 13:00:00 -0500
categories: [Module 03, Git & Workspaces]
tags: [ros2, git, github, colcon, workspace, package]
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

# Module 3
## Git, Workspaces & Packages

RAS 212 — Introduction to ROS 2

---

## Today's Agenda

- **This is where you first write and run your own code**
- Everything in Module 2 used code someone else already wrote
- Today: give that code a home (Git) and a place to run (workspace + package)

---

## Recap: Last Week

- Nodes, topics, services, parameters, actions — all understood via `turtlesim` and the CLI
- Zero code written, zero workspace touched
- `rqt_graph`, `topic info`, `interface show`, remapping — your growing toolkit

---

## Learning Objectives

By the end of today, you will be able to:
- Explain what version control is and why robotics code specifically needs it
- Use Git's core commands: `init`, `clone`, `add`, `commit`, `push`, `pull`
- Explain the anatomy of a ROS 2 workspace and a ROS 2 package
- Create your own package and confirm it builds

---

## What Is Version Control, Conceptually?

- A system that tracks every change to your files over time
- Lets you go back to any previous version, see exactly what changed, and by whom
- Not just a backup — a full history, with the ability to branch off and merge changes back

![Typical_final_doc](assets/final_doc.png)

---

## Why Robotics Code Especially Needs This

- Packages are multi-file (source, config, message definitions, launch files) — easy to lose track of what changed where
- Team review matters: a bad change to a node that drives a real robot is not just an inconvenience
- Reproducibility: "it worked on my machine" isn't good enough when the "machine" is a robot in a hallway

---

## Git Vocabulary

- **Repository (repo):** a folder Git is tracking the full history of
- **Commit:** a saved snapshot of your files at a point in time, with a message describing what changed
- **Branch:** a parallel line of development — lets you experiment without touching the main history

---

## 🖥️ Live Demo: `git init` / `git clone`

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git init my_project
<span class="cmt"># starts tracking a brand-new folder</span>

$ git clone https://github.com/your-org/some-repo.git
<span class="cmt"># copies down a repo that already exists somewhere else</span></pre>
</div>

---

## 🖥️ Live Demo: `git add` / `git commit`

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git add my_file.py
$ git commit -m "Add first draft of publisher node"</pre>
</div>

- `add` stages a change — tells Git "this is part of the next snapshot"
- `commit` actually takes the snapshot, permanently, with a message

---

## ✅ Checkpoint

**What's the difference between `git add` and `git commit`?**

*(Staging vs. actually saving the snapshot.)*

---

## 🖥️ Live Demo: `git push` / `git pull`

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git push origin main
$ git pull origin main</pre>
</div>

- `push` sends your local commits up to a remote (like GitHub)
- `pull` brings down commits made elsewhere since you last checked

---

## `.gitignore`: What Not to Track

- Not every file belongs in version control
- ROS 2 workspaces generate `build/`, `install/`, and `log/` directories every time you build — these are **regenerated automatically** and don't belong in Git
- A `.gitignore` file tells Git to skip them

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">build/
install/
log/</pre>
</div>

---

## GitHub Template-Repo Workflow

- Rather than starting from a blank repo, this course uses **template repos**
- Click **"Use this template"** on GitHub → you get your own private copy, pre-loaded with starter files
- No manual forking, no shared-repo conflicts between students

---

## 🖥️ Live Demo: Using the Template Repo

1. Click "Use this template" on the provided repo
2. Clone your new copy locally:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git clone https://github.com/your-username/ras212-module3.git</pre>
</div>

3. Make a small edit (e.g., add your name to `README.md`)
4. Commit and push it

---

## ✅ Checkpoint

**What's the difference between commit and push, in terms of who can see your changes?**

*(Commit is local-only until you push.)*

---

## ⚠️ Common Pitfall: Committing Build Artifacts

- Forgetting `.gitignore` means `build/`/`install/`/`log/` end up in your repo
- Bloats the repo, causes merge conflicts on files nobody actually wrote
- If it happens:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git rm -r --cached build/ install/ log/
<span class="cmt"># then commit the .gitignore fix</span></pre>
</div>

---

## ⚠️ Common Pitfall: Forgetting to `git pull`

- Starting new work without pulling first means you're building on a stale copy
- Leads to painful merge conflicts later
- Habit to build now:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ git pull
<span class="cmt"># at the start of every work session</span></pre>
</div>

---

## Transition: Your Code Needs a Place to Run

- Git gives your code a *history*
- A **workspace** gives your code a *place to actually build and run*
- These are two separate concepts that beginners often conflate

---

## ROS 2 Workspace Anatomy

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2_ws/
├── src/       <span class="cmt">← your source code lives here</span>
├── build/     <span class="cmt">← intermediate build files (auto-generated)</span>
├── install/   <span class="cmt">← the actual runnable output (auto-generated)</span>
└── log/       <span class="cmt">← build/run logs (auto-generated)</span></pre>
</div>

- You only ever hand-edit files inside `src/`

---

## Overlay vs. Underlay

- Your **underlay** is the base ROS 2 installation (Jazzy itself)
- Your **workspace** is an **overlay** on top of it — your own packages layered over the base system
- We'll revisit this more precisely once you're working with multiple workspaces later in the semester

---

## `colcon build`: What Happens Under the Hood

- `colcon` is the build tool that compiles/prepares everything in `src/`
- For each package it finds, it produces the matching output in `build/` and `install/`
- Conceptually: "take my source code and turn it into something ROS 2 can actually run"

---

## 🖥️ Live Demo: Creating a Workspace From Scratch

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ mkdir -p ~/ros2_ws/src
$ cd ~/ros2_ws
$ colcon build</pre>
</div>

- Notice: this works even with an **empty** `src/` — `colcon` just produces empty `build/`/`install/`/`log/` folders

---

## ⚠️ Common Pitfall: Forgetting to Source

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ source install/setup.bash</pre>
</div>

- Building a workspace doesn't automatically make it *active* in your terminal
- Forgetting this step is the single most common "why can't ROS 2 find my package" cause
- Habit to build: source it every new terminal, every time you rebuild

---

## Package Anatomy

- **`package.xml`** — metadata: name, version, dependencies (every package needs this)
- **`CMakeLists.txt`** — build instructions, for C++ packages
- **`setup.py`** — build instructions, for Python packages

---

## Python Package vs. C++ Package

| | Python | C++ |
|---|---|---|
| Build file | `setup.py` | `CMakeLists.txt` |
| Build type | `ament_python` | `ament_cmake` |
| Source location | `<pkg_name>/` | `src/` |

---

## 🖥️ Live Demo: `ros2 pkg create` — Python

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ cd ~/ros2_ws/src
$ ros2 pkg create --build-type ament_python my_first_pkg</pre>
</div>

- Explore the generated folder structure together

---

## 🖥️ Live Demo: `ros2 pkg create` — C++

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ ros2 pkg create --build-type ament_cmake my_first_cpp_pkg</pre>
</div>

- Same idea, different build system — compare the two folder structures side by side

---

## ✅ Checkpoint

**What single file tells `colcon` that a folder is a package at all?**

*(`package.xml` — present in both Python and C++ packages.)*

---

## 🖥️ Live Demo: Build and Confirm

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">$ cd ~/ros2_ws
$ colcon build
$ source install/setup.bash
$ ros2 pkg list | grep my_first_pkg</pre>
</div>

- If it shows up in `ros2 pkg list`, ROS 2 knows about it — you're done

---

## ⚠️ Common Pitfall: Package Name Mismatches

- The folder name and the `<name>` tag inside `package.xml` must match
- A mismatch causes confusing "package not found" errors even though the folder clearly exists
- Always double-check both when something isn't showing up

---

## 🔗 Show Online

Pull up a real, well-organized open-source ROS 2 package on GitHub — walk through its folder structure together.

*(Live browser tab — see placeholder slide.)*

---

## ✅ Checkpoint

**Looking at that real package's structure — where would a brand-new node's source file go?**

---

## Today's Lab

Hands-on, in the companion lab handout:
- **Part 1:** set up your Git repo from the template, make your first commit
- **Part 2:** create your first workspace from scratch
- **Part 3:** create your first package (Python, and optionally C++), confirm it builds and is recognized by ROS 2

---

## 🛠️ Troubleshooting Recap

**This week's reflexes:**
1. "Did you source it?" — the first question for almost any "ROS 2 can't find X" problem
2. Reading a `colcon build` error: which package failed, and what's the actual error underneath the noise?
3. Package name mismatch check: folder name vs. `package.xml`'s `<name>` tag

---

## Summary

- Your code now has a history (Git) and a place to run (workspace + package)
- `colcon build` + `source install/setup.bash` is a rhythm you'll repeat constantly from here on
- Everything is currently empty — that changes next week

---

## Preview: Next Week

**Filling that empty package with real code — all at once.**

- Writing your own publisher/subscriber pair
- Writing your own service/client pair
- Custom message and service types
- Parameters, YAML config, and launch files

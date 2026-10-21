---
title: "Module 9 — Actions, Loops & Recording Your Robot"
date: 2026-10-19 12:00:00 -0500
categories: [Module 09, Actions & rosbag2]
tags: [ros2, actions, rosbag2, python]
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



# Actions, Loops & rosbag2 (ros2 bag)

## What Is an Action?

- Actions are one of the communication types in ROS 2, built for **long-running tasks**
- An action has three parts: a **goal**, **feedback**, and a **result**
- Actions are built on **topics and services**. They work like a service, with two big differences:
  - An action can be **canceled** while it's running
  - An action gives **steady feedback**, where a service returns a single response
- Actions use a **client-server model**, like the publisher-subscriber model from the topics lesson:
  - An **action client** node sends a goal
  - An **action server** node acknowledges the goal, then returns a stream of feedback and a final result
- In our case, `ros2 action send_goal` is the client, and `drive_distance` is the server

*Source: [ROS 2 Jazzy docs, Understanding actions](https://docs.ros.org/en/jazzy/Tutorials/Beginner-CLI-Tools/Understanding-ROS2-Actions/Understanding-ROS2-Actions.html)*

## The Plan

```
ros2 action send_goal  --->  [ drive_distance ]  --->  cmd_vel_raw  --->  [ safety_gate ]  --->  cmd_vel  --->  Gazebo
                                    ^                                                                            |
                                    |______________________________  /odom  _____________________________________|
                                           (how far have we gone?)
```

- The action server **drives** by publishing to `cmd_vel_raw`, the same input teleop used
- It **measures** by listening to `/odom`, the robot's own estimate of where it is
- It keeps driving until it has gone far enough, run out of time, or been told to stop

---

## Why Not a Service?

Imagine we made "drive 1 meter" a service:

| What you'd want | What a service does |
|---|---|
| Know how far it has gone | Nothing until the very end. One request, one response |
| Stop it halfway | No way to. The caller is stuck waiting |
| Do something else meanwhile | The caller is frozen until the answer arrives |
| Know **why** it ended | Just `success` and a `message` |

- A service is a **phone call with one question and one answer**. It works when the answer is quick
- A topic doesn't help either. A topic has no "request": nobody asked for the job, and nobody gets a result
- An **action** is a service plus a topic, wrapped in one pattern: **request, progress updates, final result, and a way to cancel**

| | Topic | Service | Action |
|---|---|---|---|
| **Pattern** | Broadcast | Ask, wait, answer | Ask, get updates, get a final answer |
| **Takes time?** | Streams forever | Should be quick | Seconds to minutes |
| **Progress?** | It's all progress | No | Yes, **feedback** |
| **Cancel?** | Just stop publishing | No | Yes |
| **Example** | `/odom` | `/stop` | "Drive 1 meter" |

---

## ✅ Checkpoint

**For each job, pick topic, service, or action: (a) the camera image stream, (b) "set the headlight on or off," (c) "drive to the doorway," (d) "what's your battery level right now?"**

<details markdown="1">
<summary>Answer</summary>

(a) **Topic.** It's a continuous stream. (b) **Service.** It's a quick one-time request with a yes/no result. (c) **Action.** It takes a while, you want progress, and you might cancel. (d) **Service** (or a topic if you always want it). It's a quick ask-and-answer, like the Mars rover status lesson.

</details>

---

## The Three Parts of an Action

An action has three kinds of messages:

- **Goal:** what the client wants. Sent once, at the start
- **Feedback:** progress reports. Sent over and over while the job runs
- **Result:** the final answer. Sent once, at the end

The action's type is a `.action` file. It looks like a `.srv` file, but with **two** `---` lines:

```
# goal
...
---
# result
...
---
# feedback
...
```

Here's the one we'll use. It comes from the Nav2 package, so we don't have to invent anything:

```
# nav2_msgs/action/DriveOnHeading

#Goal definition
geometry_msgs/Point target
float32 speed
builtin_interfaces/Duration time_allowance
---

#Error codes
uint16 NONE=0
uint16 UNKNOWN=720
uint16 TIMEOUT=721
uint16 TF_ERROR=722
uint16 COLLISION_AHEAD=723
uint16 INVALID_INPUT=724

#Results definition
builtin_interfaces/Duration total_elapsed_time
uint16 error_code
string error_msg
---

#Feedback definition
float32 distance_traveled
```

| Part | Field | Meaning |
|---|---|---|
| **Goal** | `target` | A point. We'll use `target.x` as **how far to drive, in meters** |
| **Goal** | `speed` | How fast to drive, in meters per second |
| **Goal** | `time_allowance` | The most time we're allowed to take (a `Duration`: seconds and nanoseconds) |
| **Result** | `error_code` | A number: `0` is no error, `721` is `TIMEOUT`, `724` is `INVALID_INPUT` |
| **Result** | `total_elapsed_time` | How long the job took |
| **Result** | `error_msg` | A message in words |
| **Feedback** | `distance_traveled` | How far we've gone so far, in meters |

- Those lines like `uint16 TIMEOUT=721` are **named constants**. They give the number a name, so the code can say `TIMEOUT` instead of `721`
- The Nav2 package defines a larger robot behavior around this action. We're borrowing only the **message type** and writing our own server
- You can look at any action type yourself with `ros2 interface show nav2_msgs/action/DriveOnHeading`

---

## The Life of a Goal

A goal gets **two separate responses**. They arrive at very different times.

**Step 1: The goal response (immediate)**

- The client sends the goal
- The server's **goal callback** decides: accept or reject
- The client hears back right away
  - `Goal accepted with ID: ...`
  - or `Goal was rejected.`
- A rejected goal stops here. It never starts and never gets a result

**Step 2: The work (while it runs)**

- An accepted goal is **ACCEPTED**, then **EXECUTING** once the server starts `execute`
- The server publishes **feedback** over and over
- The client can ask to **cancel**. The goal goes to **CANCELING** while the server wraps up

**Step 3: The result response (at the end)**

- The client asks for the result with the get_result service. The server answers **only when the goal is finished**, so the client seems to wait
- The goal ends in exactly one of three states:
  - `Result: ...`
  - `Goal finished with status: SUCCEEDED`

```
 sent --> goal callback --+--> REJECTED   (stop here, no result)
                          |
                          +--> ACCEPTED --> EXECUTING --+--> SUCCEEDED
                                                  |     +--> ABORTED
                                                  |     +--> CANCELED
                                              (CANCELING, if a cancel was requested)

   |<--- goal response --->|<--------------- work + feedback --------------->|<- result response ->|
         (immediate)                                                              (at the end)
```

| State | Who decides | Example in our server |
|---|---|---|
| **Rejected** | The server, in the goal callback | A negative distance, or no `/odom` yet |
| **Succeeded** | The server | We drove far enough |
| **Aborted** | The server | We ran out of `time_allowance` |
| **Canceled** | The client asks, the server agrees | You cancel halfway |

- The server **always** ends an accepted goal in exactly one of **succeeded, aborted, or canceled**. If it forgets to say which, the client waits forever. We'll see that bug in a moment

---

## ✅ Checkpoint

**A client sends the goal "drive 0.5 m at 0.2 m/s with a 10 s allowance." What are the possible ways it could end, and what's the likely one?**

<details markdown="1">
<summary>Answer</summary>

It could be **rejected** (if `/odom` isn't running), **canceled** (if someone cancels), **aborted** (if it can't finish in 10 s, for example if the gate has motion disabled), or **succeeded**. The likely one is **succeeded**: 0.5 m at 0.2 m/s takes about 2.5 s, well inside the 10 s allowance.

</details>

---

## What an Action Is Made Of

You don't need this to use actions, but it helps when debugging:

- An action is built from **three services and two topics** that ROS 2 sets up for you:
  - A service to **send the goal**
  - A service to **ask for the result**
  - A service to **cancel**
  - A topic for **feedback**
  - A topic for **status**
- Run `ros2 service list -t` while the action server is running, and you'll see them, named like `/drive_distance/_action/send_goal`
- That's why cancel can be done with an ordinary service call, and why `ros2 node info` shows an action server as a bundle of services and topics

---

## Actions From the Command Line

| Command | What it does |
|---|---|
| `ros2 action list` | Lists the running action servers |
| `ros2 action list -t` | Same, with each action's type |
| `ros2 action info /drive_distance` | Shows who is the server and who is a client |
| `ros2 interface show nav2_msgs/action/DriveOnHeading` | Shows goal, result, and feedback fields |
| `ros2 action send_goal /drive_distance nav2_msgs/action/DriveOnHeading "{target: {x: 1.0}, speed: 0.2, time_allowance: {sec: 10}}" --feedback` | Sends a goal and prints the feedback |
| `ros2 service call /drive_distance/_action/cancel_goal action_msgs/srv/CancelGoal "{}"` | Cancels the goal(s) on that server |

- `send_goal` is the action's version of `service call`. The goal is written in YAML, like a service request
- The `--feedback` flag prints each feedback message as it arrives. Without it, you only see the final result
- You'll see something like this:

```
Waiting for an action server to become available...
Sending goal:
     target:
  x: 1.0
...
Goal accepted with ID: 8f4e...

Feedback:
    distance_traveled: 0.04

Feedback:
    distance_traveled: 0.08
...
Result:
    total_elapsed_time:
      sec: 5
      nanosec: 120000000
    error_code: 0
    error_msg: ''

Goal finished with status: SUCCEEDED
```

- A rejected goal prints `Goal was rejected.`
- The **cancel** command is a plain service call, because that's what the cancel part of an action is
- Without `{}` filled in, the cancel request means "cancel everything on this server." That's fine for us, because we only run one goal at a time

---

## 🖥️ Demo: Actions in Turtlesim

Turtlesim has an action server that rotates the turtle.

**Terminal 1** (the server):

```bash
ros2 run turtlesim turtlesim_node
```

**Terminal 2** (look at the action):

```bash
ros2 action list -t
```

- The action is `/turtle1/rotate_absolute`, with type `turtlesim/action/RotateAbsolute`

```bash
ros2 action info /turtle1/rotate_absolute
```

- `info` shows who is the client and who is the server
- Right now there's a server (`/turtlesim`) and no client

```bash
ros2 interface show turtlesim/action/RotateAbsolute
```

- The interface has the usual three parts, split by `---`:
  - The **goal** (`theta`, the heading we want)
  - The **result** (`delta`, how far it turned)
  - The **feedback** (`remaining`, radians left to go)

### Watch Both Responses

Send a goal and look at **Terminal 2** (the client side):

```bash
ros2 action send_goal /turtle1/rotate_absolute turtlesim/action/RotateAbsolute "{theta: 3.0}" --feedback
```

The output has the two responses from earlier:

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">Goal accepted with ID: e6092c...        &lt;-- goal response (immediate)

Feedback:                               &lt;-- work, while EXECUTING
&nbsp;&nbsp;&nbsp;&nbsp;remaining: 3.12
...

Result:                                 &lt;-- result response (at the end)
&nbsp;&nbsp;&nbsp;&nbsp;delta: -3.12
Goal finished with status: SUCCEEDED</pre>
</div>

- `Goal accepted` prints **right away**
- `Result:` and `Goal finished` print only **after the turtle stops**
- The server terminal (Terminal 1) shows just one line: `Rotation goal completed successfully`. Goal response, feedback, and result print where the **client** runs. The server only logs its own outcome

If the turtle doesn't move, it's already facing that heading. Send `{theta: -3.0}`.

### Watch the Status

Open a **third** terminal and run this *before* you send a goal:

```bash
ros2 topic echo /turtle1/rotate_absolute/_action/status
```

- Send the goal again from Terminal 2. The `status` number changes as the goal moves along
- Status numbers: **1** accepted, **2** executing, **3** canceling, **4** succeeded, **5** canceled, **6** aborted
- This is the "action is built on topics" idea from earlier. Status is a topic you can listen to

### Cancel and Abort

Cancel from the command line while a goal is running:

```bash
ros2 service call /turtle1/rotate_absolute/_action/cancel_goal action_msgs/srv/CancelGoal "{}"
```

- The server terminal shows `Rotation goal canceled`. The status topic shows **5**
- This is the cancel service from "What an Action Is Made Of". It's an ordinary service call

For **abort**, run the teleop node in another terminal:

```bash
ros2 run turtlesim turtle_teleop_key
```

- Press **D**, then **G** before the first rotation finishes
- The server aborts the first goal because a new one arrived: `Rotation goal received before a previous goal finished. Aborting previous goal`
- **The server chose that.** It could have rejected the new goal or queued it. Don't assume every action server aborts
- Press **F** during a rotation to cancel it from the client side

### ✅ Checkpoint

**You press D and then G quickly. Who decided to stop the first goal, and is it "canceled" or "aborted"?**

<details markdown="1">
<summary>Answer</summary>

The **server** decided, so it's **aborted**. A cancel is something the *client* asks for (like pressing F). An abort is the server giving up on a goal on its own.

</details>

---



# Reading Python: Loops and Long Callbacks

## Same Four Parts, Plus a Few New Things

Everything from Module 8 still applies: **imports, class, callbacks, `main`**. Here is the action server, with the new pieces marked.

**Imports (what's new):**

```python
import math
import time

import rclpy
from rclpy.action import ActionServer, CancelResponse, GoalResponse
from rclpy.callback_groups import ReentrantCallbackGroup
from rclpy.executors import MultiThreadedExecutor
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped
from nav_msgs.msg import Odometry
from nav2_msgs.action import DriveOnHeading
```

- `math` and `time` are **built into Python**. No install needed
- `from nav2_msgs.action import DriveOnHeading`: the same pattern as `from std_srvs.srv import Trigger`, but `.action` instead of `.srv`
- `from nav_msgs.msg import Odometry`: the type of the `/odom` topic
- Because we import from `nav2_msgs` and `nav_msgs`, they must be listed in `package.xml`

---

## The Setup in `__init__`

```python
class DriveDistance(Node):

    def __init__(self):
        super().__init__('drive_distance')

        self.x = None
        self.y = None

        group = ReentrantCallbackGroup()

        self.create_subscription(
            Odometry, 'odom', self.on_odom, 10, callback_group=group)
        self.pub = self.create_publisher(TwistStamped, 'cmd_vel_raw', 10)

        self.action_server = ActionServer(
            self,
            DriveOnHeading,
            'drive_distance',
            execute_callback=self.execute,
            goal_callback=self.on_goal,
            cancel_callback=self.on_cancel,
            callback_group=group)
```

| Line | What it does |
|---|---|
| `self.x = None` | A variable on the node's notebook with **no value yet**. `None` is Python's word for "nothing here". We fill it in when the first `/odom` message arrives |
| `create_subscription(Odometry, 'odom', self.on_odom, 10, ...)` | The same as Module 8: type, name, callback, queue size |
| `create_publisher(TwistStamped, 'cmd_vel_raw', 10)` | We publish where **teleop used to**, so the gate sees us |
| `ActionServer(self, DriveOnHeading, 'drive_distance', ...)` | The action's version of `create_service`: type, name, and **three callbacks** |
| `callback_group=group` | Explained in a moment. Hold that thought |

- Compare to `create_service(Trigger, 'stop', self.on_stop)`. An action needs three callbacks because it has three decisions to make: **accept this goal? cancel it? and do the work**

---

## Three Callbacks, Three Jobs

| Callback | When ROS calls it | Its job | Returns |
|---|---|---|---|
| `on_goal` | A goal arrives | Decide: accept or reject | `GoalResponse.ACCEPT` or `.REJECT` |
| `on_cancel` | A client asks to cancel | Decide: allow it or not | `CancelResponse.ACCEPT` |
| `execute` | After a goal is accepted | **Do the job**, report progress, finish | The result |

```python
    def on_goal(self, goal_request):
        if goal_request.target.x <= 0.0 or goal_request.speed <= 0.0:
            self.get_logger().warn('Rejected: distance and speed must be positive')
            return GoalResponse.REJECT
        if self.x is None:
            self.get_logger().warn('Rejected: no odometry yet')
            return GoalResponse.REJECT
        return GoalResponse.ACCEPT

    def on_cancel(self, goal_handle):
        self.get_logger().info('Cancel requested')
        return CancelResponse.ACCEPT
```

- `on_goal` is a **gatekeeper.** It rejects nonsense before any driving starts. `<=` means "less than or equal to"
- `or` means either condition being true is enough
- `self.x is None` asks: "has `/odom` arrived yet?" If not, we don't know where we started, so we can't measure distance
- Each `return` ends the function right there, so the last line only runs if nothing above rejected
- `on_cancel` just says yes. A real robot might refuse to cancel in the middle of something dangerous

---

## The Helper Methods

```python
    def on_odom(self, msg):
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y

    def send_speed(self, speed):
        msg = TwistStamped()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'base_link'
        msg.twist.linear.x = speed
        self.pub.publish(msg)
```

- `on_odom` is a normal topic callback. It copies the robot's position onto `self`, so the `execute` loop can read it
- `msg.pose.pose.position.x` looks like a lot. An `Odometry` message nests: a pose, with covariance, inside which is the position. `ros2 interface show nav_msgs/msg/Odometry` shows the nesting
- `send_speed(0.0)` publishes a stop. `send_speed(0.2)` drives at 0.2 m/s. Writing it once means we never copy-paste the message-building code

---

## The Loop: `execute`

This is the longest callback you've seen. It uses a **loop**, so read it slowly.

```python
    def execute(self, goal_handle):
        goal = goal_handle.request
        target = goal.target.x
        speed = goal.speed

        allowance = goal.time_allowance.sec + goal.time_allowance.nanosec * 1e-9
        if allowance <= 0.0:
            allowance = 10.0

        start_x = self.x
        start_y = self.y
        start_time = self.get_clock().now()

        feedback = DriveOnHeading.Feedback()
        result = DriveOnHeading.Result()

        while rclpy.ok():
            elapsed = (self.get_clock().now() - start_time).nanoseconds / 1e9
            traveled = math.hypot(self.x - start_x, self.y - start_y)

            if goal_handle.is_cancel_requested:
                self.send_speed(0.0)
                goal_handle.canceled()
                result.error_code = DriveOnHeading.Result.NONE
                result.error_msg = 'Canceled'
                break

            if elapsed > allowance:
                self.send_speed(0.0)
                goal_handle.abort()
                result.error_code = DriveOnHeading.Result.TIMEOUT
                result.error_msg = 'Ran out of time'
                break

            if traveled >= target:
                self.send_speed(0.0)
                goal_handle.succeed()
                result.error_code = DriveOnHeading.Result.NONE
                result.error_msg = ''
                break

            self.send_speed(speed)
            feedback.distance_traveled = float(traveled)
            goal_handle.publish_feedback(feedback)
            time.sleep(0.1)

        elapsed = (self.get_clock().now() - start_time).nanoseconds / 1e9
        result.total_elapsed_time.sec = int(elapsed)
        result.total_elapsed_time.nanosec = int((elapsed % 1.0) * 1e9)
        return result
```

**Setup (before the loop):**
- `goal_handle.request` is the goal the client sent. `goal.target.x` is the distance and `goal.speed` is the speed
- `time_allowance` is a `Duration` with `.sec` and `.nanosec`. We combine them into one number of seconds. `1e-9` means 0.000000001
- If the client sent no allowance (0), we pick 10 s. A job with no time limit is a bad idea
- We save the **starting position and time**, so we can measure how far and how long since then
- We make empty `Feedback` and `Result` messages to fill in

**The loop:**
- `while rclpy.ok():` means "keep repeating this block as long as ROS is still running." The indented block below it is the loop body
- **One trip through the body = one 0.1 s tick:**
  1. Work out how much time has passed (`elapsed`) and how far we've gone (`traveled`)
  2. Check the three reasons to stop: **canceled? out of time? arrived?** If any is true, stop the robot, tell ROS the outcome, fill in the result, and `break` (leave the loop)
  3. If none are true, drive: publish the speed, send feedback, and `time.sleep(0.1)` (wait a tenth of a second)
- `math.hypot(a, b)` is the straight-line distance: the square root of a² + b². Our distance comes from `/odom`, so it's real measured motion, not a guess
- **The order of the checks matters.** Cancel comes first because a human's request beats everything. Timeout comes before arrived, as written above, so a goal that is exactly on the line is judged by the clock

**After the loop:**
- We work out the final elapsed time, put it in the result, and `return result`. ROS sends it back to the client
- Every path through the loop ends with exactly one of `succeed()`, `abort()`, or `canceled()`

---

## Python in Five More Minutes

| Idea | What it looks like | What it means |
|---|---|---|
| **while loop** | `while rclpy.ok():` | Repeat the indented block until the condition is false, or until `break` |
| **break** | `break` | Leave the loop right now |
| **None** | `self.x = None` | "No value yet" |
| **is None** | `if self.x is None:` | Is there a value yet? |
| **and / or / not** | `a <= 0.0 or b <= 0.0` | Combine true/false tests |
| **Comparison** | `<  <=  >  >=  ==  !=` | `==` asks "equal?", a single `=` stores a value |
| **Named constant** | `DriveOnHeading.Result.TIMEOUT` | A number with a name, defined inside the message type |
| **float()** | `float(traveled)` | Convert to a decimal number, because the message field needs one |
| **f-string** | `f'Driving {target:.2f} m'` | Put a value in text. `:.2f` means two decimal places |
| **sleep** | `time.sleep(0.1)` | Pause this code for 0.1 s |

- `==` versus `=` is the most common beginner bug. `=` **stores**, `==` **asks**
- A loop that never reaches a `break` or a false condition never stops. That's why every branch above ends the job

---

## ✅ Checkpoint

**In the loop, why does the code call `self.send_speed(0.0)` before `goal_handle.canceled()` and the other outcomes?**

<details markdown="1">
<summary>Answer</summary>

Because the robot keeps moving at the last command it was given. Nothing else will stop it. If the server just reported "canceled" and returned, the last `send_speed(speed)` would still be in effect. This is the latch problem from Module 7 again: ending the job is not the same as stopping the robot.

</details>

---

## Why `MultiThreadedExecutor` and `ReentrantCallbackGroup`?

This is the part that surprises people, so here's the story:

- Normally, `rclpy.spin(node)` is like **one worker** at a counter. It handles one callback at a time, then the next
- Our `execute` callback is **long.** It sits in a loop for seconds
- While that one worker is busy inside `execute`, it can't run `on_odom`. So `self.x` never updates, `traveled` stays at 0, and the goal can only end by timing out
- The fix is **more than one worker.** `MultiThreadedExecutor` provides several, and a `ReentrantCallbackGroup` says "these callbacks are allowed to run at the same time"

```python
def main(args=None):
    rclpy.init(args=args)
    node = DriveDistance()
    executor = MultiThreadedExecutor()
    executor.add_node(node)
    try:
        executor.spin()
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()
```

- It's the same `main()` as Module 8, except `executor.spin()` replaces `rclpy.spin(node)`
- A good rule: **callbacks should finish quickly.** An action's `execute` is the exception, so it needs help
- Don't memorize this. When you write another action server, copy this pattern. The Wednesday demo shows what the failure looks like

---

## Two Kinds of Timeout

| | `time_allowance` | Watchdog |
|---|---|---|
| **Question it answers** | "Is this job taking too long?" | "Did the commands stop coming?" |
| **Lives in** | The action server | The gate |
| **Fires when** | The job runs past its time | No command arrives for a while |
| **Protects against** | A stuck robot, a blocked path | A dead teleop, a crashed node |

- `time_allowance` protects against a **job** that won't finish. It does nothing if the thing sending commands just disappears
- Remember the latch problem from Module 7: kill the publisher and the robot keeps going. A **watchdog** is the real fix. It's a timer that checks how long it's been since the last command, and sends zero if the gap is too long
- The watchdog uses the same two ingredients you've now seen: **a timer** and **a saved timestamp** on `self`
- You'll build one in the lab, as a challenge

---

# rosbag2: Recording Your Robot

## Why Record?

- Your robot is only in front of you some of the time. Gazebo takes a minute to start. Something fails once and never again
- A **bag** is a recording of topics, with timestamps. You can play it back later, as if the robot were running, without the robot or the simulator
- Uses:
  - **Debugging:** record when it fails, then study it calmly
  - **Sharing:** send a classmate or instructor the bag instead of describing the problem
  - **Testing:** run your code against the same data over and over
  - **Evidence:** show what the robot actually did

---

## The Commands

| Command | What it does |
|---|---|
| `ros2 bag record -o drive_test /odom /cmd_vel_raw /cmd_vel` | Records those three topics into a folder called `drive_test` |
| `ros2 bag record -a -o everything` | Records **all** topics (big!) |
| `ros2 bag info drive_test` | Shows what's in the bag: duration, topics, message counts |
| `ros2 bag play drive_test` | Replays the messages, with the original timing |
| `ros2 bag play drive_test --clock` | Also publishes `/clock`, for nodes using simulation time |

- Press **Ctrl+C** to stop recording. The bag is complete once the command exits
- `-o` sets the name of the output folder. If a folder with that name already exists, the command refuses to overwrite it
- You list the topics you care about. Recording everything works, but images and scans make bags huge
- `ros2 bag info` tells you the **storage format** and the **message count** for each topic. The file inside the folder may end in `.db3` or `.mcap`, depending on your install. It doesn't matter for us

```
Files:             drive_test_0.mcap
Bag size:          180.5 KiB
Storage id:        mcap
Duration:          8.4s
Start:             Oct 19 2026 14:02:11.123 (1792436531.123)
Messages:          1180
Topic information: Topic: /odom | Type: nav_msgs/msg/Odometry | Count: 420 | ...
                   Topic: /cmd_vel_raw | Type: geometry_msgs/msg/TwistStamped | Count: 84 | ...
```

---

## Playing a Bag Back

- When you `play` a bag, ROS publishes those recorded messages as if the robot were running now
- That means **you don't need Gazebo.** Start `ros2 bag play`, and in another terminal run `ros2 topic echo /odom`. The odometry values flow, from a robot that isn't running
- Anything that listens can use it: `ros2 topic echo`, `rqt_graph`, your own nodes
- Careful: if Gazebo **is** running, don't replay `/cmd_vel` or `/odom`. You'd have two publishers on the same topic, one live and one recorded, and they'd fight
- Bags are **data, not code.** They are big, and they change every time you record. They don't belong in git. We tell git to ignore them with a `.gitignore` file. The lab shows how

---

## ✅ Checkpoint

**You recorded a bag of a drive, closed Gazebo, and ran `ros2 bag play`. In another terminal, `ros2 topic echo /odom` prints values. Where are those values coming from? What would `ros2 node list` show?**

<details markdown="1">
<summary>Answer</summary>

The values are coming from the **bag player**, which is publishing the recorded `/odom` messages. `ros2 node list` shows the player node (something like `/rosbag2_player`), and no Gazebo, no gate, no action server. The robot isn't running. The data is.

</details>

---

## ⚠️ Common Pitfalls

- **Goal rejected:** the server rejects goals with no `/odom` yet, or a distance or speed that isn't positive. Check the server's terminal for the `Rejected:` message
- **Goal times out with 0 m traveled:** the gate may have motion disabled (`/enable_motion false`), or the gate isn't running, or the server publishes to a different topic than the gate listens on
- **Distance stuck at 0.0 in feedback:** `/odom` isn't updating. Either the simulation isn't running, or the executor is single-threaded and `execute` is blocking `on_odom`
- **Client waits forever:** the server forgot `succeed()`, `abort()`, or `canceled()`, or forgot `return result`
- **Goal speed ignored:** the gate limits speed to `max_speed`. The action asked for 0.5 m/s and the gate said 0.3
- **YAML typo in `send_goal`:** use `{target: {x: 1.0}, speed: 0.2, time_allowance: {sec: 10}}`, with a space after each colon. Wrap it in quotes
- **Bag recording refuses to start:** the output folder already exists. Choose a new name or delete the old folder
- **Bag player does nothing in your node:** if your node uses `use_sim_time:=true`, it waits for `/clock`. Replay with `--clock`

---


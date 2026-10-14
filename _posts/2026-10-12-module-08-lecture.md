---
title: "Module 8 — Services & Your First Real Python Node"
date: 2026-10-12 11:00:00 -0500
categories: [Module 08, Services & Python Nodes]
tags: [ros2, services, parameters, python, rclpy, mentorpi]
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

## The Plan: A Gate Between Teleop and the Robot

```
teleop  --->  cmd_vel_raw  --->  [ safety_gate ]  --->  cmd_vel  --->  Gazebo (MecanumDrive)
                                       ^
                          /stop   /enable_motion   max_speed
                         (service)    (service)    (parameter)
```

- Teleop used to publish straight to `/cmd_vel`. We will remap this to publish to `/cmd_vel_raw`, and then only our node will publish to `/cmd_vel`
- `safety_gate` is the only thing the robot listens to, so the gate decides what gets through
- Three ways to talk to the gate while it runs:
  - A **service** called `/stop` that sends one zero command right now
  - A **service** called `/enable_motion` that turns motion on or off
  - A **parameter** called `max_speed` that sets the speed limit

---

## Three Ways to Talk to a Node

- **Topic:** a radio broadcast. The sender doesn't know who's listening
- **Service:** a phone call with one question and one answer. The caller waits for the answer
- **Parameter:** a configuration setting for a node

| | Topic | Service | Parameter |
|---|---|---|---|
| **Pattern** | Publish and subscribe | Ask and answer | A setting the node holds |
| **Who starts it** | The publisher, whenever it wants | The client, once, when it wants something | Anyone, anytime |
| **Data flows** | One way, continuous | Request, then one response | Read or write a value |
| **Many listeners?** | Yes | One server answers each call | Anyone can read it |
| **Good for** | Sensor data, velocity commands, anything that streams | "Do this now and tell me how it went" | Tuning: speeds, limits, names, thresholds |
| **Example here** | `/cmd_vel`, `/odom` | `/stop`, `/enable_motion` | `max_speed` |

Decision rules:
- Does it stream continuously? **Topic**
- Is it a one-time request that needs an answer? **Service**
- Is it a setting you'd want to change without editing code? **Parameter**
- Does it take a long time and need progress updates? **Neither. That's an action, and it's in the next module**

---

## ✅ Checkpoint

**For each job, pick topic, service, or parameter: (a) the robot's current wheel speeds, (b) "reset the odometry to zero now," (c) the maximum speed allowed, (d) the lidar scans.**

<details markdown="1">
<summary>Answer</summary>

(a) **Topic.** It streams continuously and anyone can listen. (b) **Service.** It's a one-time request, and you want to know it worked. (c) **Parameter.** It's a setting you want to change without rewriting the node. (d) **Topic.** Same reason as (a).

</details>

---

## Anatomy of a Service

A service has two sides:
- The **server** is a node that offers the service. It waits for requests and sends back responses
- The **client** is a node (or you, from the command line) that sends one request and waits for the reply

![Service - Single Client](assets/Service-SingleServiceClient.gif)

![Service - Multiple Clients](assets/Service-MultipleServiceClient.gif)

A service has a **type**, just like a topic. The type is a file that lists what goes in the request and what comes back. A `.srv` file has two halves split by `---`:

- Above the `---` is the **request** the client sends
- Below the `---` is the **response** the server returns
- `Trigger` takes nothing in and returns whether it worked, plus a message


```
# Trigger.srv  (from std_srvs)
# request: nothing, just "do it"
---
bool success
string message
```

- `SetBool` takes one true/false value in and returns the same two things back

```
# SetBool.srv  (from std_srvs)
bool data
---
bool success
string message
```


- These types already exist in a package called `std_srvs`. We don't need to invent our own. We just use them

| Type | Request | Response | Good for |
|---|---|---|---|
| `std_srvs/srv/Trigger` | (empty) | `success`, `message` | "Do it now": stop, reset, save |
| `std_srvs/srv/SetBool` | `data` (true/false) | `success`, `message` | On/off switches: enable, disable |
| `std_srvs/srv/Empty` | (empty) | (empty) | "Do it now" with no feedback at all |

- You've seen this tool already: `ros2 interface show` works on services the same way it does on topic types

---

## Calling a Service From the Command Line

You did this in Module 2 with `turtlesim`. The commands are the same here:

| Command | What it does |
|---|---|
| `ros2 service list` | Lists every service that's running |
| `ros2 service list -t` | Same, with each service's type |
| `ros2 service type /stop` | Prints the type of one service |
| `ros2 interface show std_srvs/srv/Trigger` | Shows the request and response fields |
| `ros2 service call /stop std_srvs/srv/Trigger "{}"` | Calls the service with an empty request |
| `ros2 service call /enable_motion std_srvs/srv/SetBool "{data: false}"` | Calls it with a value |

- The `"{}"` is an empty request written in YAML. For `SetBool`, the request is `{data: false}`
- A service call prints the request it sent, then waits and prints the response:

```
response:
std_srvs.srv.SetBool_Response(success=True, message='Motion disabled')
```

- If the server isn't running, the call just waits. You'll see `waiting for service to become available...`

---

## Parameters, Again

You used parameters in Module 4 with launch files and YAML. Here's the idea from the node's side:

- A node **declares** a parameter with a default value: "I have a setting called `max_speed`, and it starts at 0.3"
- Anyone can then read or change it while the node runs

| Command | What it does |
|---|---|
| `ros2 param list` | Lists parameters for every node |
| `ros2 param get /safety_gate max_speed` | Reads one value |
| `ros2 param set /safety_gate max_speed 0.1` | Changes it while the node runs |

- The node reads the parameter **every time a message arrives**, so a change takes effect on the next command
- Parameters have a **type.** `max_speed` was declared as a decimal number (`0.3`), so `ros2 param set /safety_gate max_speed 1` fails because `1` is a whole number. Write `1.0`
- The word **"parameter"** means two things in this class, and they're unrelated:
  - A **ROS parameter** is a setting on a node, like `max_speed`
  - A **function parameter** is a name in the parentheses of a Python function, like `value` in `clamp(value, low, high)`
  - Same word, different idea. We'll say "ROS parameter" and "function argument" to keep them apart

---

## ✅ Checkpoint

**You call `ros2 service call /enable_motion std_srvs/srv/SetBool "{data: false}"` and the terminal prints `waiting for service to become available...` and sits there. What does that tell you?**

<details markdown="1">
<summary>Answer</summary>

The server isn't there, or it isn't named `/enable_motion`. Check `ros2 service list` to see what's actually running. The usual causes are that the gate node isn't started, or you're in a terminal where you forgot `source install/setup.bash`, so ROS can't see it.

</details>

---

## ✏️ Work It By Hand: What Does the Gate Do?

The gate works like this:
- If motion is **disabled**, it sends zero speed, always
- If motion is **enabled**, it limits `linear.x` and `linear.y` to between `-max_speed` and `+max_speed`. Turning (`angular.z`) passes through unchanged

Fill in the output for each incoming command:

| # | Gate state | `max_speed` | Incoming `x` | Incoming `y` | Incoming `angular.z` | Output `x` | Output `y` | Output `angular.z` |
|---|---|---|---|---|---|---|---|---|
| 1 | enabled | 0.3 | 0.5 | 0.0 | 0.0 | ? | ? | ? |
| 2 | enabled | 0.3 | -0.5 | 0.5 | 1.0 | ? | ? | ? |
| 3 | enabled | 0.1 | 0.2 | -0.05 | 0.0 | ? | ? | ? |
| 4 | disabled | 0.3 | 0.5 | 0.5 | 1.0 | ? | ? | ? |
| 5 | enabled | 0.6 | 0.5 | 0.0 | 0.0 | ? | ? | ? |

<details markdown="1">
<summary>Answers</summary>

| # | Output `x` | Output `y` | Output `angular.z` | Why |
|---|---|---|---|---|
| 1 | 0.3 | 0.0 | 0.0 | 0.5 is over the limit, so it's cut to 0.3 |
| 2 | -0.3 | 0.3 | 1.0 | Both limited, turning passes through |
| 3 | 0.1 | -0.05 | 0.0 | 0.2 is cut to 0.1; -0.05 is already inside ±0.1 |
| 4 | 0.0 | 0.0 | 0.0 | Disabled means all zero, including turning |
| 5 | 0.5 | 0.0 | 0.0 | 0.5 is already under the 0.6 limit |

The operation is called **clamping.** Written with `max` and `min`, it's one line: `max(low, min(value, high))`.

</details>

- Notice that row 4 sets turning to zero too. That's a design choice. What would you change if you wanted the robot to still be able to turn in place when disabled?

---

## Why Services and Not Just Another Topic?

- You *could* make `/stop` a topic and publish to it. But then:
  - You'd never know if the gate got the message
  - There's no response, so you can't tell "stopped" from "node isn't even running"
  - Anyone publishing to it would need to know to publish exactly once
- A service gives you the answer. `success=True` means the node received the request and did something
- For a safety feature, "did it work?" matters. That's the reason to use a service here

---

## ⚠️ A Service Call Waits

- When a client calls a service, it **waits** for the response. If the server never answers, the client is stuck
- That's why well-written clients check first: "Is the service even there?" We'll do this in the client code
- It's also why a service shouldn't do something that takes seconds. The caller would be frozen the whole time
- If the job takes a long time, or you want progress updates along the way, it's an **action.** That's Module 9

---

# Reading Python: The Parts of a ROS 2 Node

## Why Now

- In Module 3 you copied a publisher and subscriber and ran them. They worked, and you may have wondered what half the lines did
- Now we're going to read code on purpose. Reading it is how you learn to write it
- You don't need to memorize anything. You need to be able to look at a node and say "this part does that"

---

## The Familiar Starting Point

You've seen this one. It's the publisher from Module 3:

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class MinimalPublisher(Node):

    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(String, 'topic', 10)
        self.timer = self.create_timer(0.5, self.timer_callback)
        self.i = 0

    def timer_callback(self):
        msg = String()
        msg.data = 'Hello World: %d' % self.i
        self.publisher_.publish(msg)
        self.get_logger().info('Publishing: "%s"' % msg.data)
        self.i += 1


def main(args=None):
    rclpy.init(args=args)
    minimal_publisher = MinimalPublisher()
    rclpy.spin(minimal_publisher)
    minimal_publisher.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## The Four Parts

Every ROS 2 Python node in this course has the same four parts:

| # | Part | In the example above | What it does |
|---|---|---|---|
| 1 | **Imports** | `import rclpy`, `from std_msgs.msg import String` | Borrows tools and message types from other files |
| 2 | **The class** | `class MinimalPublisher(Node):` | Defines your node: what it is and what it does |
| 3 | **Callbacks** | `timer_callback` | Functions that run when something happens |
| 4 | **`main()`** | `def main(args=None):` | Starts ROS, creates your node, keeps it running |

Inside the class there's one more thing to see:
- **`__init__`** runs once, when the node is created. Its job is to **set up the connections**: publishers, subscribers, timers, services
- After `__init__`, the node just waits. Callbacks do the work

Here's the whole file as a picture:

```
IMPORTS      Borrow tools and message types
   |
CLASS        class MyNode(Node):
   |           __init__   -> set up connections, once
   |           callback 1 -> runs when message #1 arrives
   |           callback 2 -> runs when message #2 arrives
   |
MAIN         start ROS -> make the node -> spin -> shut down
```

---

## Part 1: Imports

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped
from std_srvs.srv import Trigger, SetBool
```

- `import rclpy` loads the ROS 2 Python library. Everything from it is used as `rclpy.something`
- `from rclpy.node import Node` pulls out just one piece, `Node`, so you can write `Node` instead of `rclpy.node.Node`
- The **message and service types** are imported the same way. The pattern is `from <package>.<kind> import <Type>`:
  - `geometry_msgs.msg` means "the message types in `geometry_msgs`" and `TwistStamped` is the one we want
  - `std_srvs.srv` means "the service types in `std_srvs`" and we take two: `Trigger` and `SetBool`
- This is why a package has to be listed as a dependency in `package.xml`. If it isn't installed, the import fails

---

## Part 2: The Class

```python
class SafetyGate(Node):

    def __init__(self):
        super().__init__('safety_gate')
```

- A **class** is a blueprint. `SafetyGate` is the blueprint for our node
- `(Node)` after the name means **"a SafetyGate is a Node, plus extras."** It inherits everything a ROS node can do (publish, subscribe, log) and we add what's special
- `def __init__(self):` is the setup function. Python runs it once when the node is created
- `super().__init__('safety_gate')` runs the parent `Node`'s setup and gives the node its name. The name `'safety_gate'` is what shows up in `ros2 node list`
- **`self`** means "this node." Everything a node owns, such as its publishers, its settings, and its on/off state, is stored on `self`, like the node's own notebook. A callback can read it later because it's written on `self`

```python
        self.enabled = True
```

- This creates a variable on the node's notebook. `self.enabled` starts as `True` and stays until something changes it

---

## Python in Five Minutes

Just enough to read the node. You'll pick up the rest as we go.

| Idea | What it looks like | What it means |
|---|---|---|
| **Comment** | `# meters per second` | The computer ignores it. It's a note to humans |
| **Variable** | `limit = 0.3` | A name that holds a value |
| **Types** | `0.3` (decimal), `5` (whole), `True`/`False`, `'text'` | Python figures out the type; you don't declare it |
| **Function** | `def clamp(value, low, high):` | A named block of code you can run again |
| **Return** | `return max(low, min(value, high))` | Hands a value back to whoever called the function |
| **If / else** | `if self.enabled:` ... `else:` | Do one thing or the other |
| **Method** | `self.publish_zero()` | A function that belongs to a class. You call it on `self` |
| **Indentation** | 4 spaces in from the line above | **Python uses it to know what's inside what** |

- **Indentation is not decoration.** Everything indented under `def` is inside that function. Everything indented under `class` is inside that class. Move a line one step left or right and the program changes meaning
- Use 4 spaces. Don't mix tabs and spaces. Most editors will do this for you
- A colon `:` at the end of a line (`def ...:`, `if ...:`, `class ...:`) means "the indented block that follows belongs to this line"

---

## A Small Function: `clamp`

```python
def clamp(value, low, high):
    """Keep value between low and high."""
    return max(low, min(value, high))
```

- `clamp` takes three **arguments** and hands back one value
- Read it from the inside out: `min(value, high)` picks the smaller of `value` and `high`, so nothing goes over `high`. Then `max(low, ...)` picks the larger, so nothing goes under `low`
- The text in triple quotes is a **docstring.** It describes what the function does, and tools can show it to you
- Try three calls in your head:
  - `clamp(0.5, -0.3, 0.3)` returns `0.3`
  - `clamp(-0.5, -0.3, 0.3)` returns `-0.3`
  - `clamp(0.1, -0.3, 0.3)` returns `0.1`

---

## Setting Up the Connections in `__init__`

Back inside `__init__`, the gate sets up everything it needs:

```python
        self.declare_parameter('max_speed', 0.3)

        self.sub = self.create_subscription(
            TwistStamped, 'cmd_vel_raw', self.on_cmd_vel_raw, 10)
        self.pub = self.create_publisher(TwistStamped, 'cmd_vel', 10)

        self.create_service(Trigger, 'stop', self.on_stop)
        self.create_service(SetBool, 'enable_motion', self.on_enable_motion)
```

| Line | What it sets up |
|---|---|
| `declare_parameter('max_speed', 0.3)` | A ROS parameter with a default value |
| `create_subscription(TwistStamped, 'cmd_vel_raw', self.on_cmd_vel_raw, 10)` | "Listen on `cmd_vel_raw` for `TwistStamped` messages. When one arrives, run `self.on_cmd_vel_raw`" |
| `create_publisher(TwistStamped, 'cmd_vel', 10)` | "I'll publish `TwistStamped` messages on `cmd_vel`" |
| `create_service(Trigger, 'stop', self.on_stop)` | "I offer a service called `stop`. When someone calls it, run `self.on_stop`" |
| `create_service(SetBool, 'enable_motion', self.on_enable_motion)` | The same for the on/off switch |

- Every `create_...` line follows the same pattern: **what type, what name, which function to call**
- The `10` on topics is the queue size: how many messages to hold if they arrive faster than we handle them. Ten is fine here
- Notice `self.on_cmd_vel_raw` has **no parentheses.** We're handing ROS the function itself, not running it now

---

## What Is a Callback?

- A **callback** is a function you hand to ROS and say: "call this one when the thing happens"
- You never call it yourself. ROS does
- Think of leaving your phone number at a shop: "Call me when my order's in." You don't stand by the phone. The shop calls you
- `rclpy.spin(node)` is the node standing by. It waits for messages and requests, and calls the right callback when one shows up
- That's why `__init__` finishes so quickly and nothing seems to happen: the work is all in the callbacks

---

## ✅ Checkpoint

**In `self.create_service(Trigger, 'stop', self.on_stop)`, what's the difference between writing `self.on_stop` and `self.on_stop()`?**

<details markdown="1">
<summary>Answer</summary>

`self.on_stop` is the function itself. We're handing it to ROS so ROS can call it later, when someone calls the service. `self.on_stop()` with parentheses would run the function right now, during setup, and hand ROS whatever it returned. The callback would never be connected. Callbacks are always passed without parentheses.

</details>

---

## Part 3: The Callbacks

The topic callback runs every time a message arrives on `cmd_vel_raw`:

```python
    def on_cmd_vel_raw(self, msg):
        if not self.enabled:
            self.publish_zero()
            return

        limit = self.get_parameter('max_speed').value

        out = TwistStamped()
        out.header = msg.header
        out.twist.linear.x = clamp(msg.twist.linear.x, -limit, limit)
        out.twist.linear.y = clamp(msg.twist.linear.y, -limit, limit)
        out.twist.angular.z = msg.twist.angular.z
        self.pub.publish(out)
```

- `msg` is the message that just arrived. ROS fills it in and hands it to us
- `if not self.enabled:` checks the on/off state from the notebook. If motion is off, send zeros and stop (`return` ends the function early)
- `self.get_parameter('max_speed').value` reads the ROS parameter **fresh each time.** That's why `ros2 param set` takes effect right away
- `out = TwistStamped()` makes a new, empty message. Everything in it starts at zero
- We fill in the fields we care about with `clamp(...)`, copy the turning rate over, and publish

A helper method that other methods use:

```python
    def publish_zero(self):
        out = TwistStamped()
        out.header.stamp = self.get_clock().now().to_msg()
        self.pub.publish(out)
```

- A fresh `TwistStamped` is all zeros, so publishing one **is** a stop command
- `self.get_clock().now().to_msg()` puts the current time in the header. Stamped messages need a timestamp
- Both `on_cmd_vel_raw` and the service callbacks use this, so we write it once

The two service callbacks:

```python
    def on_stop(self, request, response):
        self.publish_zero()
        response.success = True
        response.message = 'Sent a zero velocity command'
        return response

    def on_enable_motion(self, request, response):
        self.enabled = request.data
        if not self.enabled:
            self.publish_zero()
        response.success = True
        if self.enabled:
            response.message = 'Motion enabled'
        else:
            response.message = 'Motion disabled'
        return response
```

- A service callback always gets **two** things: the `request` from the client and an empty `response` for us to fill in
- **We must `return response`.** If we forget, the client never gets an answer and waits forever
- `/stop` doesn't need anything from the request (`Trigger` is empty), so it ignores `request`
- `/enable_motion` reads `request.data`, the true/false the client sent, and stores it in `self.enabled`
- When motion is turned off, it also sends one zero command right away. Otherwise the robot would keep moving until the next key press, which could be never

---

## Part 4: `main()`

```python
def main(args=None):
    rclpy.init(args=args)
    node = SafetyGate()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()
```

| Line | What it does |
|---|---|
| `rclpy.init(args=args)` | Starts ROS in this program |
| `node = SafetyGate()` | Creates our node. This runs `__init__` |
| `rclpy.spin(node)` | Waits, and runs callbacks as things happen. It doesn't return until the node is stopped |
| `except KeyboardInterrupt: pass` | When you press Ctrl+C, quit quietly instead of printing a big error |
| `finally:` | Runs no matter how we got here |
| `node.destroy_node()`, `rclpy.try_shutdown()` | Clean up and shut ROS down |

- The tutorial version you saw earlier has no `try`. It works, but Ctrl+C prints an error trace. Ours handles it
---

## ✅ Checkpoint

**A teleop message arrives on `cmd_vel_raw` while the gate is enabled. List, in order, what code runs and what ends up on `/cmd_vel`. Which part of the node (imports, class, callbacks, `main`) is each step in?**

<details markdown="1">
<summary>Answer</summary>

1. `main()` already started the node and is sitting in `rclpy.spin(node)`, waiting. (**main**)
2. The message arrives. ROS calls `self.on_cmd_vel_raw(msg)`, which we registered in `__init__`. (**class, callback**)
3. The callback checks `self.enabled`, reads `max_speed`, clamps `x` and `y`, copies `angular.z`, and calls `self.pub.publish(out)`. (**callback**)
4. The robot (Gazebo, via the bridge) receives the clamped message on `/cmd_vel`.

The publisher itself was set up in `__init__`; the types we used came from the imports.

</details>

---

## 🐛 Spot the Bugs

This code has three bugs. Find them on paper.

```python
class SafetyGate(Node):

    def __init__(self):
        super().__init__('safety_gate')
        self.pub = self.create_publisher(TwistStamped, 'cmd_vel', 10)
        self.create_service(Trigger, 'stop', self.on_stop)

    def on_stop(self, request, response):
    self.publish_zero()
        response.success = True
        response.message = 'Stopped'

    def publish_zero(self):
        out = TwistStamped()
        pub.publish(out)
```

<details markdown="1">
<summary>Answers</summary>

1. **Indentation.** `self.publish_zero()` in `on_stop` is not indented under the `def`, so Python stops with an `IndentationError` before anything runs.
2. **Missing `return response`** at the end of `on_stop`. The node would run, but anyone calling `/stop` would wait forever for an answer.
3. **`pub.publish(out)`** in `publish_zero` should be `self.pub.publish(out)`. `pub` by itself doesn't exist inside the function. Python reports `NameError: name 'pub' is not defined` the first time it runs.

Notice when each one shows up: bug 1 stops the program before it starts, bug 2 gives no error at all, and bug 3 only appears when the function actually runs.

</details>

---

## Reading an Error Message

When Python hits a problem it prints a **traceback.** It looks scary, but it's a trail you can follow:

```
Traceback (most recent call last):
  File "/home/student/ros2_ws/install/mentorpi_nodes/lib/mentorpi_nodes/safety_gate", line 33, in <module>
    sys.exit(load_entry_point('mentorpi-nodes==0.0.0', 'console_scripts', 'safety_gate')())
  File ".../mentorpi_nodes/safety_gate.py", line 74, in main
    node = SafetyGate()
  File ".../mentorpi_nodes/safety_gate.py", line 27, in __init__
    self.pub = self.create_publisher(TwistStamped, 'cmd_vel', 10)
NameError: name 'TwistStamped' is not defined
```

How to read it:
1. **Start at the bottom.** The last line says what went wrong: `NameError: name 'TwistStamped' is not defined`
2. **The line above it** is the exact code that failed: `self.create_publisher(TwistStamped, ...)`
3. **Just above that** is the file name and line number: `safety_gate.py`, line 27
4. The lines above that are the **trail of calls** that led there. Usually you don't need them. The bottom of the trail is where the problem is

| Error | What it usually means |
|---|---|
| `NameError: name 'X' is not defined` | A typo, a missing `import`, or a missing `self.` |
| `IndentationError` / `SyntaxError` | A line is out of place, or a `:`, `)` or quote is missing |
| `AttributeError: 'SafetyGate' object has no attribute 'X'` | You used `self.X` somewhere you never created it |
| `ModuleNotFoundError: No module named 'X'` | The package isn't installed, or you forgot to `source install/setup.bash` |
| `TypeError: ... takes 2 positional arguments but 3 were given` | A function's arguments don't match how it's called (often a missing `self`) |

- Read the last line first, then the line above it. You'll fix most errors from those two
- Copy the **last line** into a search or ask for help with it. "It doesn't work" can't be debugged. `NameError: name 'TwistStamped' is not defined` can

---

## ✅ Checkpoint

**You run your node and see `AttributeError: 'SafetyGate' object has no attribute 'enabled'`. Where would you look first?**

<details markdown="1">
<summary>Answer</summary>

Look for where `self.enabled` is created: it should be a line like `self.enabled = True` in `__init__`. Either that line is missing, it has a typo (`self.enable = True`), or it's written as `enabled = True` without `self.`, which makes a variable that disappears when `__init__` ends. A callback can only read `self.enabled` if `__init__` wrote it to the node's notebook.

</details>

---

## A Client That Calls the Service

So far the gate is the **server.** Here's a small **client** that calls `/stop` once and reports what came back:

```python
import rclpy
from std_srvs.srv import Trigger


def main(args=None):
    rclpy.init(args=args)
    node = rclpy.create_node('stop_client')

    client = node.create_client(Trigger, 'stop')
    if not client.wait_for_service(timeout_sec=3.0):
        node.get_logger().error('The /stop service is not available')
    else:
        future = client.call_async(Trigger.Request())
        rclpy.spin_until_future_complete(node, future)
        node.get_logger().info(f'Response: {future.result().message}')

    node.destroy_node()
    rclpy.try_shutdown()
```

- It follows the same parts, but it's **shorter and has no class.** It does one job and exits. Not every node has to be a class
- `client.wait_for_service(timeout_sec=3.0)` checks the service exists, for up to three seconds. If it doesn't, we log an error and quit instead of freezing
- `Trigger.Request()` builds the (empty) request. For `SetBool`, you'd write `request = SetBool.Request()` and then `request.data = False`
- `call_async` sends the request and returns a **future**, which is a promise that an answer will arrive. `spin_until_future_complete` waits for it
- `f'Response: {future.result().message}'` is an **f-string** (formatted string). The `f` before the quote lets you put values inside `{ }` and they're filled in

---

## Python Words, Collected

| Word | In plain terms |
|---|---|
| **import** | Borrow code from another file or package |
| **class** | A blueprint for a thing, such as our node |
| **inheritance** | `class SafetyGate(Node)`: a SafetyGate *is a* Node, with extras |
| **`__init__`** | Setup code that runs once when the thing is created |
| **`self`** | "This node." Where it keeps its own data |
| **method** | A function that belongs to a class |
| **function argument** | A value you hand a function: `clamp(0.5, -0.3, 0.3)` |
| **return** | Hand a value back to the caller |
| **callback** | A function ROS calls for you when something happens |
| **spin** | Wait around and run callbacks as they come up |
| **traceback** | The trail Python prints when something breaks. Read from the bottom |
| **ROS parameter** | A setting on a node. Not the same as a function argument |

- Keep this table nearby for the lab. A one-page cheat sheet with all of this goes out with the lab handout

---

## Debugging Tools for Services and Parameters

When a node doesn't behave, these tell you what's really running:

| What you want to know | Command |
|---|---|
| Is my node running? | `ros2 node list` |
| What does it publish, subscribe to, and offer? | `ros2 node info /safety_gate` |
| What topics exist and who's on them? | `ros2 topic list`, `ros2 topic info /cmd_vel_raw -v` |
| What message is actually flowing? | `ros2 topic echo /cmd_vel` |
| Is my service there? | `ros2 service list -t` |
| What are my parameter values? | `ros2 param list`, `ros2 param get /safety_gate max_speed` |
| Show me how it's all connected | `rqt_graph` |

- `ros2 node info` is the one to reach for first. It lists everything the node has set up. If a subscriber or service is missing from that list, `__init__` never created it
- `rqt_graph` shows the chain: teleop → `/cmd_vel_raw` → `safety_gate` → `/cmd_vel`. If there's a gap in the chain, a topic name doesn't match

---

## ⚠️ Common Pitfalls

- **Topic name typo.** `cmd_vel_raw` in one place and `cmd_vel_row` in another. ROS doesn't complain. Nothing connects, and nothing moves
- **Wrong message type.** The bridge carries `TwistStamped`. A plain `Twist` publisher won't connect, and you may see a warning about an incompatible type. Teleop needs `-p stamped:=true`
- **Forgetting `return response`** in a service callback. The client waits forever
- **Forgetting `self.`** when you mean something the node owns
- **Parameter type.** `ros2 param set /safety_gate max_speed 1` fails because `1` is a whole number and the parameter was declared as a decimal. Use `1.0`
- **Editing the file and not seeing a change.** With a Python node, `colcon build --symlink-install` links your source, so saved edits show up when you re-run the node. A **new** file or a **new entry point** needs a rebuild

---

## Summary

- **Topic** for streams, **service** for ask-and-answer, **parameter** for settings. Long jobs with progress are actions, next module
- A `.srv` type has a request and a response, split by `---`. `std_srvs` has `Trigger`, `SetBool`, and `Empty`
- Every Python node has four parts: **imports, class, callbacks, `main`.** `__init__` sets up the connections, and callbacks do the work
- A **callback** is a function you hand to ROS so it can call you back
- **`self`** is the node's notebook. **Indentation** is how Python knows what's inside what
- Read a traceback from the **bottom**
- The `safety_gate` is a node with one subscriber, one publisher, two services, and one ROS parameter

---

# Wednesday — Building the Gate

## Today's Plan

- Create a second package that holds our own nodes, separate from the launch files in `mentorpi_bringup`
- Walk through the files `ros2 pkg create` makes, and see how a Python file becomes a ROS command
- Run the finished gate in the simulation and call it from the command line
- Break it on purpose and read each error
- Then straight into lab, where you build it yourself from a skeleton

---

## The Repo, Updated

```
~/ros2_ws/src/mentorpi/               # your git repo
├── mentorpi_description/             # Hiwonder's robot model (Module 7)
├── mentorpi_bringup/                 # launch files, config, xacro wrapper (Module 7)
└── mentorpi_nodes/                   # NEW: our own nodes
    ├── mentorpi_nodes/
    │   ├── __init__.py
    │   └── safety_gate.py            # the node
    ├── package.xml
    ├── setup.py
    └── setup.cfg
```

- `mentorpi_description` is the robot. `mentorpi_bringup` is how we start it. `mentorpi_nodes` is the code that runs on top
- **Not the same as Hiwonder's `controller` package.** Their `controller` and `ros_robot_controller` talk to the motors on the real robot. Ours sits above that, working with `cmd_vel`, and works the same in the simulation or on hardware

---

## 🖥️ Live Demo: Create the Package

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">cd ~/ros2_ws/src/mentorpi
ros2 pkg create --build-type ament_python mentorpi_nodes --dependencies rclpy geometry_msgs std_srvs --node-name safety_gate</pre>
</div>

- `--build-type ament_python` makes it a Python package, like `mentorpi_bringup`
- `--dependencies rclpy geometry_msgs std_srvs` writes those packages into `package.xml` for us. They match the imports in the node
- `--node-name safety_gate` also creates a starter file, `mentorpi_nodes/safety_gate.py`, and the line in `setup.py` that makes it runnable
- The starter file just prints a greeting. We'll replace its contents with the real node

---

## Package Files: `package.xml`, `setup.py`, `CMakeLists.txt`

Every ROS 2 package has a `package.xml`. Then it has **one** build file, depending on the build type you picked in `ros2 pkg create`:

| File | Job | In which packages |
|---|---|---|
| `package.xml` | Says what the package **is** and what it **needs**: name, version, dependencies, build type. `colcon` reads it to find packages and decide the build order | All of them |
| `setup.py` | Says how to **build and install** a Python package: what code to install, what extra files to copy, and which commands to create | `--build-type ament_python` |
| `CMakeLists.txt` | Says how to **build and install** a CMake package: what to compile, what to copy, which dependencies to find | `--build-type ament_cmake` (the default if you leave the option off) |

- `ros2 pkg create --build-type ament_python` makes `setup.py` and **no** `CMakeLists.txt`. `--build-type ament_cmake` does the reverse
- **`CMakeLists.txt` isn't only for C++.** Hiwonder's `mentorpi_description` has no code at all, only URDF, meshes, and launch files, and it still uses `CMakeLists.txt`. Look inside and you'll find one job: an `install(DIRECTORY ...)` line that copies those folders into the install space
- Packages that **define messages, services, or actions** must also be `ament_cmake`, because the definitions get compiled into code. That's why `mentorpi_interfaces` (Module 12) will be a CMake package
- A rule of thumb: if the package holds your Python nodes, use `ament_python`. If it only holds files or defines interfaces, use `ament_cmake`
- In our repo: `mentorpi_description` is CMake (files only), `mentorpi_bringup` and `mentorpi_nodes` are Python


## `setup.py` and `entry_points`

Open `mentorpi_nodes/setup.py` and find this:

```python
    entry_points={
        'console_scripts': [
            'safety_gate = mentorpi_nodes.safety_gate:main',
        ],
    },
```

Read the line from left to right:

```
'safety_gate = mentorpi_nodes.safety_gate:main'
   |               |              |        |
   |               |              |        +-- the function to run
   |               |              +----------- the file (safety_gate.py)
   |               +-------------------------- the folder (the Python package)
   +------------------------------------------ the command name you type
```

- This is why `ros2 run mentorpi_nodes safety_gate` works. ROS looks up the **command name** and finds the **file** and **function** to run
- The function is `main`, the same `main()` as Part 4
- Each new node you write needs its own line here. Next module's action server will get a line of its own
- Change the file but not the entry point: no rebuild needed. Add a **new** entry point: rebuild
- `setup.py` also has a `data_files` list. That's how the launch, config, and URDF files in `mentorpi_bringup` get copied to the install space. It does the same job as the `install(DIRECTORY ...)` line in `mentorpi_description`'s `CMakeLists.txt`

---

## ✅ Checkpoint

**You write a second node in a file called `drive_action.py`, with a `main()` function, in the same package. You build, source, and run `ros2 run mentorpi_nodes drive_action`. What do you get, and what's the fix?**

<details markdown="1">
<summary>Answer</summary>

`No executable found`. ROS has no command called `drive_action` because we never added it to `entry_points`. Add the line `'drive_action = mentorpi_nodes.drive_action:main',` to the list, then rebuild with `colcon build --symlink-install`, and `source install/setup.bash` again.

</details>

---

## 🖥️ Live Demo: The Finished Gate in the Simulation

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash</pre>
</div>

- Build both new and changed packages, then source so the terminal can see them

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 launch mentorpi_bringup launch_sim.launch.py</pre>
</div>

- The simulation from Module 7. The robot is in Gazebo. In a new terminal, source again before every command (every new terminal needs it)

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 run mentorpi_nodes safety_gate --ros-args -p use_sim_time:=true</pre>
</div>

- The gate is now running. It's listening on `cmd_vel_raw`, but nothing is publishing there yet

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p stamped:=true -p use_sim_time:=true -r cmd_vel:=cmd_vel_raw</pre>
</div>

- Teleop as before, but with one new piece: `-r cmd_vel:=cmd_vel_raw`. That **remaps** teleop's output to the gate's input
- Drive. The robot moves, but now through the gate
- The teleop default speed is 0.5 m/s. The gate limits it to 0.3

---

## 🖥️ Live Demo: Talk to the Gate

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 node info /safety_gate</pre>
</div>

- Shows the gate's subscriber, publisher, and service servers. Everything we set up in `__init__` is on this list

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 service list -t
ros2 param get /safety_gate max_speed</pre>
</div>

- The two services appear with their types. The parameter reads `0.3`

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 param set /safety_gate max_speed 0.1</pre>
</div>

- Drive again. The top speed is now about a third of what it was. No restart, no code change

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 service call /stop std_srvs/srv/Trigger "{}"</pre>
</div>

- Press and hold a forward key, then call `/stop` from another terminal. The robot halts
- This is the fix for the latch problem from Module 7

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">ros2 service call /enable_motion std_srvs/srv/SetBool "{data: false}"</pre>
</div>

- Teleop keys do nothing now. The gate blocks everything. Call it again with `{data: true}` to turn motion back on

<div class="term">
<div class="term-dots"><span></span><span></span><span></span></div>
<pre class="term-body">rqt_graph</pre>
</div>

- Teleop → `/cmd_vel_raw` → `safety_gate` → `/cmd_vel` → the bridge. This is the diagram from Monday, drawn by ROS

---

## 🖥️ Live Demo: Break It on Purpose

We'll introduce four mistakes, one at a time. For each: what do we see, and where do we look?

| # | The mistake | What we see | Where to look |
|---|---|---|---|
| 1 | Skip `source install/setup.bash` in a new terminal | `Package 'mentorpi_nodes' not found` | The terminal: it never sourced |
| 2 | Add a new node's file, but not its `entry_points` line | `No executable found` | `setup.py`, then rebuild |
| 3 | Type `cmd_vel_row` instead of `cmd_vel_raw` in the node | The gate runs fine. Nothing moves | `rqt_graph`: the chain has a gap. `ros2 node info` shows the wrong name |
| 4 | Indent a line wrong in the callback | A traceback with `IndentationError` | The last line of the traceback, then the line number above it |

- #3 is the hardest, because there's no error. Nothing crashed and nothing worked. The tools (`rqt_graph`, `node info`, `topic info -v`) are how you find out
- For #4, read the traceback together from the bottom up, the way we did on Monday

---

## ✅ Checkpoint

**The gate is running, teleop is running, you press keys, and the robot doesn't move. `ros2 node list` shows `/safety_gate`. Give three things to check, in order.**

<details markdown="1">
<summary>Answer</summary>

1. `ros2 topic echo /cmd_vel_raw`: is teleop actually publishing? If not, check the remap and `stamped:=true`.
2. `ros2 topic echo /cmd_vel`: is the gate publishing? If not, check `ros2 node info /safety_gate` for its subscriber's topic name, and check whether motion was left disabled by an earlier `/enable_motion` call.
3. `ros2 topic info /cmd_vel -v`: is the bridge subscribed, and is the type `TwistStamped`? If the robot still doesn't move, the problem is on the Gazebo side, which was Module 7.

Work through the chain from where the data starts, and stop where it stops arriving.

</details>

---

## Feature Branches

- **The idea:** `main` always holds code that works. New work happens on its own branch. When it works, you merge it back
- Why: if the new work breaks something, `main` is untouched. And a branch named `add-safety-gate` tells anyone looking at your repo what that work was

The flow for today's lab:

| Step | Command |
|---|---|
| Start from a clean `main` | `git switch main` |
| Make a branch for the new work | `git switch -c add-safety-gate` |
| Do the work, then save it | `git add .`, `git commit -m "..."` |
| Upload the branch | `git push -u origin add-safety-gate` |
| Bring it into `main` | `git switch main`, `git merge add-safety-gate` |
| Upload `main` | `git push` |

- Commit **small and often** on the branch, for example once the package builds, once the gate node runs, and once the services work
- A good commit message says what changed: "Add safety_gate node with stop and enable services." Not "stuff"
- You can also do the merge on GitHub with a **pull request,** where someone reviews the change before it goes in. On real teams, that's the normal way. We'll try it later

---

## 🛠️ Troubleshooting Recap

1. `Package 'mentorpi_nodes' not found` → `source install/setup.bash` in that terminal
2. `No executable found` → missing `entry_points` line, or you didn't rebuild
3. Robot doesn't move through the gate → work the chain: `/cmd_vel_raw`, then `/cmd_vel`, then the bridge
4. `waiting for service to become available...` → the gate isn't running, or you didn't source
5. Service call hangs → the callback is missing `return response`
6. `ros2 param set` fails → type mismatch: use `1.0`, not `1`
7. `IndentationError` → a line is out of place. Read the last line of the traceback
8. `NameError` → typo, missing import, or missing `self.`
9. Teleop moves the robot but the gate has no effect → teleop is still publishing to `/cmd_vel`. Check the remap `-r cmd_vel:=cmd_vel_raw`
10. Robot ignores teleop after `/enable_motion false` → call it with `{data: true}`

---


## Summary

- A gate node gives us a way to limit speed, block motion, and stop on request
- Services and parameters are two of the ways to control a running node. Topics carry the stream
- `ros2 pkg create` builds a package skeleton. `entry_points` is what makes a file runnable with `ros2 run`
- Errors are information. Read tracebacks from the bottom, and use `ros2 node info` and `rqt_graph` when nothing errors but nothing works
- Feature branches keep `main` working while new work happens

---

## Preview: Next Module

- The gate stops the robot when asked. But what about a job that takes a few seconds, such as "drive forward one meter," where you want progress along the way and the ability to cancel? That's a service's weakness and an **action's** strength
- Next module: write an action server that drives the simulated MentorPi a set distance, with feedback and cancel
- We'll also learn `rosbag2`, so we can record a driving session and play it back

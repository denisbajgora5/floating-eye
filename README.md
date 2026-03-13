# 👁️ Floating Eye

## Project Description

The game is set in a **space environment** featuring a floating island on a desolate planet named **EB-2**.

The main autonomous agent (boid) is a **floating eyeball with wings and legs**.

### Eyeball Behavior

- Floats around the environment
- Follows predefined paths
- Avoids obstacles such as:
  - Trees
  - Rocks
- Lands and transitions into crawling behavior
- Crawls along:
  - Ground
  - Walls
  - Environmental objects

### Audio Interaction

- Various sounds and audio effects play depending on the player's position relative to the eyeball.
- An audio clip is triggered when the player gets close to the eyeball.

### Additional Background Behavior

There will be:

- A **leader Space Bee**
- Smaller follower eyeballs that follow the leader

- A **Predator Space Bee and Prey Space Bee**
- If Predator is near prey it will start to chase the prey, the prey will then flee, if the prey flees too far the predator will give up and change using state machines to the wander behaviour.

This behavior exists in the background and is separate from the main autonomous eyeball agent.

---

## 👥 Team Members

### Denis

- **Student ID:** C22503876
- **Course:** TU857 (4)
- **GitHub:** [denisbajgora5](https://github.com/denisbajgora5)

### Jason

- **Student ID:** C22400796
- **Course:** TU856 (4)
- **GitHub:** [JasonOS03](https://github.com/JasonOS03)

---

## 🎥 Video

## link

## 🖼️ Screenshots

![screenshot1](./images/screenshot1.png)

abc

![screnshot2](./images/screenshot2.png)

abc2

---

## 🎮 Instructions for Use

### First Person Mode

1. Open the project in **Godot 4.x**
2. Load the main scene:
3. You can use WASD or Arrow Keys to move around.
4. ` Key can be used to fly around in freeform.
5. G Key will be used to turn on and off Gizmos and the Path for the Eye.

---

## ⚙️ How It Works

- **`scripts/main.gd`**  
  does x y z

---

## 📦 Classes & Assets

| Class / Asset           | Source                          |
| ----------------------- | ------------------------------- |
| `scripts/main.gd` (x y) | Self written (ChatGPT assisted) |

---

## 📚 References

### AI Prompts

- How to make the boid follow a path.
- How to set s color for a mesh.
- How does avoidance work?
- Can you suggest a design for the background boids.
- Whats a good particle effect for a boid?
- Should the floating eye boid have a cool particle effect?
- How to make a floating eye follow a path.
- How to set ponits around the map using path follow 3d
- why does my floating boid go around in a circle.
- Why does my floating boid go into the air and never come back.
- Why does the floor model look glitchy.
- How do i fix the predator and prey keep bashing into walls.
- So how to make the leader boid not go into the tree.

---

## 🧊 Models

- **KayKit Asset Packs BlockBits:** https://kaylousberg.itch.io/block-bits

- **Floating Eye:**
  https://sketchfab.com/3d-models/kraken-eyeball-blender-file-9af20edc176c460391d1948356c339b7

- **Map SkyBox:**  
  https://jettelly.com/blog/some-space-skyboxes-why-not

- **First Person Controller:**  
  https://github.com/Brackeys/brackeys-proto-controller

---

## 🔊 Sound Effects

- **Background Music:**  
  https://freesound.org/people/ZHR%C3%98/sounds/572358/

- **Background SFX for Floating Eye:**  
  https://freesound.org/people/DylanTheFish/sounds/442181/

---

## ⭐ What We’re Most Proud Of

- **Denis:**  
  I am most proud of the following features:
  background boids the way they avoid obsucles.
  The way the wonder around and do their own thing using Wander was really cool to implement.
  I am really proud of the way the map turned out it fits really nicely with the sky box.
  The way the boids are neon like and have particles i am super proud of as it makes them glow really nicely in the sky.
  I Am also proud of the way i designed the colors of the map and boids the way it looks like an alien planet.
  The music aswell i am super proud of as it fits the game very nicely espically the background music and floating eye SFX.

- **Jason:**  
  goes here

---

## 📖 What We Learned

- **Denis:**  
  I learnt more about Gridmap how to use it how to use mesh library importing models from a online source. How to use buses to control different sound enviorments. I learnt about wandering, seek, how to animate wingss for the eye. I learnt how seperation, cohension and alignement work along with avoidance. Also, i learnt how the weights work together if a weight is too small it could lead to it other weights taking proiorty.

- **Jason:**  
  goes here

---

_Thank you for exploring the Floating Eye!_ 👁️🌑

**Autonomous Agent Assignment Proposal (OG Proposal)**

# Games Engines 2 — Autonomous Agent

## Project Proposal

## Project Title

**Wandering Eye: A Walking Floating Autonomous Eyeball**

---

## Team Members

- Jason O’Sullivan (C22400796)
- Denis Bajgora (C22503876)

---

## Development Environment

- Local development
- Godot Engine (Godot Editor used for running the game)
- No XR used

---

## GitHub Repository

https://github.com/denisbajgora5/floating-eye

---

## GitHub Branches

- `main`
- `denis-branch`
- `jason-branch`

---

## Player

The player is represented as a **first-person character**.

### Controls

- **Keyboard:** WASD or Arrow Keys
- **Controller:** Supported

### Abilities

- Move
- Jump
- Fly
- Run

The player’s purpose is to observe the floating eye and its autonomous behaviors within the environment.

---

## Project Description

The game is set in a **space environment** featuring floating islands on a desolate planet named **EB-2**.

The main autonomous agent (boid) is a **floating eyeball with wings and legs**.

### Eyeball Behavior

- Floats around the environment
- Follows predefined paths
- Avoids obstacles such as:
  - Trees
  - Space base structures
- Lands and transitions into crawling behavior
- Crawls along:
  - Ground
  - Walls
  - Environmental objects
- Interacts with environmental objects

### Audio Interaction

- Various sounds and audio effects play depending on the player's position relative to the eyeball.
- An audio clip is triggered when the player gets close to the eyeball.

### Additional Background Behavior

There will be:

- A **leader eyeball**
- Smaller follower eyeballs that follow the leader

This behavior exists in the background and is separate from the main autonomous eyeball agent.

---

## Components Used

The following Godot nodes and systems will be used:

- **Path3D** and **PathFollow3D**  
  → For path-following behavior

- **CharacterBody3D**  
  → Used for both the player and the eyeball

- **CollisionShape3D**  
  → For physics and collision detection

- **MeshInstance3D**  
  → For visual representation

- **Node3D** and **Node**  
  → For grouping and scene structure

- **AnimationPlayer**  
  → For animations such as:
  - Crawling
  - Wing fluttering

---

## Steering Behaviors

The eyeball's movement will be controlled using steering behaviors.

### Implemented Behaviors

- Seek
- Arrive
- Pursue
- Offset Pursue
- Wander

### State Machines

State Machines will manage behavior transitions.

For example:

- If the eyeball gets close to the space base, it will switch to an avoidance behavior.
- Behaviors can dynamically change depending on environmental triggers.

---

## Signals

Godot **signals** will be used to:

- Trigger behavior changes
- Detect environmental interactions
- Switch states when encountering specific objects

---

## Summary

_Wandering Eye_ is an autonomous agent project showcasing steering behaviors, state machines, and interactive environmental AI within a 3D Godot space environment. The player observes the emergent behavior of the floating eyeball and its interactions with the world.

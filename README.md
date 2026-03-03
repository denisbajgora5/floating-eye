# Games Engines 2 — Autonomous Agent

## Project Proposal

---

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

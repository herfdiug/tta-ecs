# TTA — ECS design for a combat AI

A whiteboard before the code: one diagram that fixes what the AI's states are, which systems run, what data each system is allowed to read, and the order they must run in.

![TTA ECS architecture](TTA_ECS.png)

**Why this exists:** a behaviour tree gets rewritten every time a new behaviour appears. With ECS, a behaviour is a set of components plus a system that reads them — so adding "patrol" means adding a system and a tag, not editing an `if` chain. The diagram is the contract that makes that true.

Files: `TTA_ECS.png` (what you're looking at), `TTA_ECS.svg` (same thing, sharp at any zoom), `TTA_ECS.drawio` (the editable source — open it in [diagrams.net](https://app.diagrams.net) or the VS Code Draw.io extension).

Read it at full size: bands stack top to bottom, boxes read left to right.

## Layers in the diagram

| Band | What it holds |
|---|---|
| **Required system order** | The order that must hold, left to right: `Get Position`, `Get LookVector`, `Scanning`, `Attacking`, `Pathfind Target Once`, `Continuous Target Pathfinding`, `Moving`, then `Rid ×4` and `Apply ×4` behaviour boxes. Wrong order reads last frame's data. |
| **States** | `Idle`, `Patrol`, `Chase`, `Attack`, and `All` at the join. |
| **Systems** | `Get Position`, `Get LookVector`, `Scanning`, `Pathfind Target Once`, `Continuous Target Pathfinding`, `Continuous Move to Target`, `Move to Target Once`, `Moving`, `Attacking`, `Cooldown`. |
| **Tags / Components** | `CanMove`, `CanScan`, `CanDamage`, `CanPathfind`, `CanPathfindContinuously`, `CanLogPosition`, `CanLogLookVector`, `Cooldown`, `pair(Cooldown, any)`. |
| **Queries** | `Twisted query` (`Position`, `LookVector`, `CanScan`) and `Player query` (`Position`, `IsPlaying`). A system only sees what its query returns. |
| **Data written by systems** | `Position : Vector3`, `LookVector : Vector3`, `Waypoints : {Vector3}`, `NextWaypoint : Vector3`, `EndPosition : Vector3`, `AgentParams : Dict`, `Damage : number`. |
| **Events** | `Blocked Path`, `CanPathfind` — what a system emits instead of calling another system directly. |
| **Conditions** | `if player is detected`, `if number > 0`, `if number <= 0` — the guards that sit between a query and an action. |
| **State changes** | `pair(State, Idle / Patrol / Chase / Attack)` written by a query, and `pair(ChangeState, Idle / Patrol / Chase / Attack / any)` applied in one place. |

`AgentParams` is the dictionary you hand to `PathfindingService:CreatePath` — `AgentRadius`, `AgentHeight`, `AgentCanJump`, `WaypointSpacing`. The first version of the diagram called it `AgentRadius`, which was wrong: that's one key inside it, not the whole thing.

## The three decisions worth reading

1. **Cooldowns are data, not a system.** `pair(Cooldown, any)` is charged on the entity, and the `Cooldown` system only decrements. That keeps "can I attack" out of the attack branch.
2. **State transitions are events, not mutations.** Systems emit `pair(ChangeState, …)`; one system applies it. Nothing writes `State` from three places.
3. **Behaviour is attached and removed, not branched.** `Apply X Behavior` / `Rid X Behavior` are explicit enters and exits, so a state change cannot leave a stale behaviour running.

## Status

Prototype, not a finished game. The diagram is the design; a slice of it runs in a test place:

- **Implemented:** `Idle`, `Patrol`, `Chase`. The agent idles, patrols, notices a player and chases.
- **Still design only:** `Attack`, the cooldown pair, and the events band.

### Running slice

![Test place: two agents, vision rays and a patrol path](media/tta-prototype-poster.jpg)

**[Watch the clip — 45 s, no audio](media/tta-prototype.mp4)**

Filmed in the test place with `Idle`, `Patrol` and `Chase` live. The cyan lines are the agent's debug drawing, still switched on: they are how you can see what it thinks it can see, and the dotted markers are its waypoints.

What is not there yet is also the honest part: the place around it is half-built (placeholder objective text, no attack), and the debug output prints a value every frame instead of on a timer.

The value of the diagram is the ordering and the query boundaries — the parts that are expensive to change later.

The first version stacked three copies of the same table — present, added/changed, removed — which made the same label appear three times and left section headers sitting inside each other's rows. This version keeps one copy of each concept, puts the bands in reading order, and folds the per-state deltas into the tags and state-change bands. The per-state "what gets added, what gets removed" detail is not shown here; that is the next diagram.

## Next

- One system per column, with the query as its signature.
- A test place with two agents sharing the same systems and different component sets, to prove behaviour is data.
# TTA — ECS design for a combat AI

A whiteboard before the code: one diagram that fixes what the AI's states are, which systems run, what data each system is allowed to read, and the order they must run in.

![TTA ECS architecture](TTA_ECS.png)

**Why this exists:** a behaviour tree gets rewritten every time a new behaviour appears. With ECS, a behaviour is a set of components plus a system that reads them — so adding "patrol" means adding a system and a tag, not editing an `if` chain. The diagram is the contract that makes that true.

Files: `TTA_ECS.png` (what you're looking at), `TTA_ECS.svg` (same thing, sharp at any zoom), `TTA_ECS.drawio` (the editable source — open it in [diagrams.net](https://app.diagrams.net) or the VS Code Draw.io extension).

Read it at full size: the bands run left to right, one column per concern.

## Layers in the diagram

| Band | What it holds |
|---|---|
| **States** | `Idle`, `Patrol`, `Chase`, `Attack`, plus `Scanning`, `Pathfinding Once`, `Continuous Pathfinding`, `Moving`, `Attacking` as sub-states. `All` sits at the join. |
| **Systems** | `Get Position`, `Get LookVector`, `Scanning`, `Pathfind Target Once`, `Continuous Target Pathfinding`, `Continuous Move to Target`, `Moving`, `Attacking`, `Cooldown`. |
| **Tags / Components** | `CanMove`, `CanScan`, `CanDamage`, `CanPathfind`, `CanPathfindContinuously`, `CanLogPosition`, `CanLogLookVector`, `Cooldown`. |
| **Data** | `Position : Vector3`, `LookVector : Vector3`, `Waypoints : {Vector3}`, `NextWaypoint : Vector3`, `EndPosition : Vector3`, `AgentRadius : Dict`, `Damage : number`, `pair(Cooldown, any) : number`. |
| **Events** | `Blocked Path`, `CanPathfind` — what a system emits instead of calling another system directly. |
| **Required System Order** | The read order that must hold: position and look vector first, then scan, attack, pathfind, move. Wrong order reads last frame's data. |
| **Queries** | `Twisted query` (component set that crosses states) and `Player query` (`Position`, `IsPlaying`). A system only sees what its query returns. |

## The three decisions worth reading

1. **Cooldowns are data, not a system.** `pair(Cooldown, any)` is charged on the entity, and the `Cooldown` system only decrements. That keeps "can I attack" out of the attack branch.
2. **State transitions are events, not mutations.** Systems emit `pair(ChangeState, …)`; one system applies it. Nothing writes `State` from three places.
3. **Behaviour is attached and removed, not branched.** `Apply X Behavior` / `Rid X Behavior` are explicit enters and exits, so a state change cannot leave a stale behaviour running.

## Status

Design only. This repository holds the diagram; it does not claim a finished implementation. The value is the ordering and the query boundaries — those are the parts that are expensive to change later.

## Next

- One system per column, with the query as its signature.
- A test place with two agents sharing the same systems and different component sets, to prove behaviour is data.
# Grey Valley — Milestone 1: Playable Exploration Prototype

A 2D top-down, semi-open-world RPG built in **Godot 4.3 + GDScript**. The design
takes RimWorld only as a *high-level* reference (top-down tile world, small
readable characters, systemic simulation) — all art, names, world and code here
are original placeholders.

> This is **Milestone 1** of the development plan: a small, genuinely runnable
> exploration prototype. Combat, inventory, factions, quests, schedules and save
> systems are **later phases** and are intentionally not implemented yet.

---

## How to run

Open the project in Godot 4.3 (or newer 4.x) and press **F5**, or from a shell:

```bash
godot --path .
```

### Controls

| Input | Action |
|-------|--------|
| `W A S D` / Arrows | Move |
| `Shift` | Run |
| `Ctrl` | Sneak (slower) |
| `E` | Interact / talk (also closes dialogue) |
| Mouse wheel | Zoom camera |
| Left click (debug on) | Inspect the NPC under the cursor |
| `F1` | Toggle debug overlay |
| `Esc` | Close dialogue |

You start in the middle of Grey Valley Town. Walk up to any villager — a prompt
`[E] Talk to <name>` appears — and press **E** to open a branching conversation.
NPCs wander the town on their own using navigation that routes around buildings.

---

## What Milestone 1 delivers

- Project structure + autoloads (`GameState`, `TimeManager`)
- `Player` (CharacterBody2D): WASD movement, run, sneak, camera with zoom
- A procedurally-built tile ground (`TileMapLayer`, no imported art needed)
- `NavigationRegion2D` baked at runtime, carved around building footprints
- `Npc` (CharacterBody2D + `NavigationAgent2D`): Idle / Wander / Talk AI
- Unified `InteractableComponent` (the UI asks it for actions; it never
  hard-codes "is this an NPC?")
- Press-E interaction that opens a **data-driven branching `DialoguePanel`**
- `Hud` (day/clock + interaction prompt) and an `F1` `DebugOverlay`
- A headless integration test (`tests/Smoke.tscn`)

---

## Architecture & key classes

```
res://
├── project.godot            Input map, autoloads, main scene, window
├── autoload/
│   ├── GameState.gd         Global refs + a small dialogue event bus
│   └── TimeManager.gd       In-game clock (day / hour / minute), time scale
├── characters/
│   ├── components/
│   │   └── InteractableComponent.gd   Area2D; get_interactions()/interact()
│   ├── player/
│   │   ├── Player.gd / .tscn           Movement, camera, focus detection
│   └── npc/
│       ├── Npc.gd / .tscn              Wander + Talk state machine
├── world/
│   ├── WorldMap.gd          Builds the placeholder TileMapLayer + TileSet
│   ├── Region.gd            Builds ground, buildings, baked navigation
│   └── Main.tscn            The playable scene (world + entities + UI)
├── ui/
│   ├── hud/Hud.gd           Clock + contextual interaction prompt
│   ├── hud/DebugOverlay.gd  F1 diagnostics + NPC inspector
│   └── dialogue/DialoguePanel.gd  Data-driven branching dialogue
├── data/dialogue/*.json     Dialogue trees (one per speaker)
└── tests/Smoke.gd / .tscn   Headless integration test
```

Design rules already honoured, so later phases slot in cleanly:

- **No monolithic manager.** `GameState` only holds shared refs + an event bus.
- **Component-based, shared between Player and NPC.** Both are `CharacterBody2D`;
  interaction lives in a reusable `InteractableComponent`.
- **Data-driven.** Dialogue is JSON; building layout is a data array that feeds
  both the visuals and the navigation carving from one source.
- **Decoupled UI.** NPCs request dialogue over a signal bus; they never reference
  UI nodes. The HUD/overlay read state, they don't drive gameplay.
- **Performance-aware AI.** NPCs only re-decide when idle on a randomised timer,
  never every frame.

### Verifying it runs

```bash
# Import + parse check
godot --headless --editor --quit

# Play the scene headless for a few seconds (no errors expected)
godot --headless --path . --quit-after 300

# Integration smoke test (prints PASS/FAIL, exit code = failure count)
godot --headless --path . tests/Smoke.tscn
```

All three pass with no script or runtime errors.

---

## Suggested next milestone

**Milestone 2 — Core RPG layer** (per the development plan, Phase 2):

1. `InventoryComponent` + `ItemData` (Resource) — pick-up items in the world.
2. `EquipmentComponent` — equip a weapon/tool, reflected on the character.
3. `SkillComponent` — the 0–20 use-based skills (Shooting, Melee, Medicine…).
4. Extend `DialoguePanel` nodes/choices with `conditions` and `effects`
   (give/remove item, set world flag) — the data shape already tolerates them.
5. A first `Shop` interaction reusing `InteractableComponent` + money on
   `GameState`.

Combat, health/body-parts and Tactical Pause remain **Phase 3** and should not
be started until the RPG layer above is playable.

# Design source registry

This directory records the canonical design material supplied for **Kiro: Dream of the
Observer**. Design documents are inputs to implementation, not evidence that a gameplay
system has already been built.

## Available sources

| Source | Supplied material | Completeness in repository |
| --- | --- | --- |
| [v4.0 design brief](kiro_design_brief_v4.md) | Document metadata, core cosmology, five treasures, the Sea of Consciousness, Observers/Dao Masters, and detailed excerpts for universes 1–3 | Partial excerpt |
| [v4.0 balance workbook](../../data/balance/v4/manifest.json) | Eleven supplied balance sheets covering skills, items, relationships, world deviation, property, reincarnation, organizations, combat, economy, achievements, and difficulty | Structured source data |

The supplied v4.0 text says that the complete external document contains roughly 75,000
Chinese characters and thirteen or more major chapters, but that complete body was not
included in the repository input. Missing chapters must not be invented or treated as
approved canon. Add future material as versioned source documents and update this registry.

## Implementation boundary

- `Grey Valley`, its route-walking NPC, and its current dialogue are Milestone 1 technical
  placeholders rather than canonical Kiro lore.
- Names, locations, factions, abilities, and story events should be promoted into gameplay
  data only after their relevant source section is present.
- The current milestone remains an exploration prototype. This documentation update does
  not authorize work on combat, cultivation, reincarnation, quests, or universe travel.
- Balance CSV files preserve designer input. They are not imported into runtime gameplay
  until the corresponding milestone supplies typed Resources and validation rules.

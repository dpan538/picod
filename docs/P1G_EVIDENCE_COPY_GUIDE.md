# P1G Evidence Copy Guide

Date: 2026-07-03

## Purpose

Evidence copy is the user-facing layer between memory records and world traces.
It should help the user feel that a day, story, album, cycle, or rare memory
touched the world without exposing mechanics.

## Tone

- quiet
- short
- concrete
- first-glance understandable
- suggestive rather than explanatory

Pico should not sound like it knows the whole truth. The world can imply more
than Pico understands.

## Allowed Normal UI Terms

- World trace
- trace
- path
- rain
- stones
- lamp
- shrine
- marker
- echo
- cycle
- quiet

## Forbidden Normal UI Terms

- evidenceID
- projectedElementID
- catalogElementID
- WorldStateProjection
- resolver
- validator
- audit
- debug
- JSON
- store
- confidence score
- raw seed ID
- anchor coordinate

## Surface Rules

DailyLifeRecord:

- Show one or two lines.
- Captured day: prefer photo mood, path, rain, light, or Pico change.
- Missed/future day: quiet placeholder, never punitive.

StoryCard:

- Locked: ambiguous, no visible world anchor.
- traceSeen: partial and fragmentary.
- encountered/recurring/remembered: may show stronger trace language.
- Up to three evidence fragments, no lore dump.

LifeAlbum:

- Seven-day retrospective object.
- Mention rhythm, final trace, or repeated story hint.
- Do not make it feel like a database row.

CycleRecord:

- World-level memory, not Pico biography.
- Mention marker, visitor/weather/time rhythm, or route/world trace.

EraMemory:

- Hidden/quiet before unlock.
- One rare echo line after unlock.
- Do not explain reset directly.

## Current English Examples

- A trace was left near the path.
- The lamp remembered this night.
- The rain stayed on the stones.
- Something by the shrine looked back.
- One marker stayed after the cycle ended.
- A rare echo stayed after the long turn.
- This day stayed quiet, and the map kept the empty space.

## Current Chinese Examples

- 一条小痕迹落在路边。
- 那盏灯记住了这个夜晚。
- 雨停在石路边。
- 神社旁边有一点东西看了回来。
- 周期结束后，一个标记留了下来。
- 很久以后，有一点回声还在。
- 这一天很安静，地图也把空白留住了。

## Fallback Rules

- Missing anchor: use a soft fallback, not an error.
- Missing projection: use text-only fallback and keep the app calm.
- Missing diary: use deterministic diary/mood fallback.
- Locked EraMemory: "Not visible yet." / "还没有显现。"
- Low participation: describe quietness as preserved space, never punishment.

## DEBUG Boundary

DEBUG preview may show anchor IDs, projected element IDs, catalog IDs, source
types, and validation states. Normal Memory Drawer text must not.

Projection rendering remains gated. P1G only promotes text evidence, not map
highlighting.

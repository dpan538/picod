# P1H Evidence Copy Review

Date: 2026-07-03

## Scope

Reviewed normal-user copy produced by:

- `PicodWorldTraceText`
- Memory Drawer detail surfaces
- `PicodEvidenceCopyDebugValidator`

DEBUG-only labels were not treated as normal UI copy.

## Validation Result

- Evidence-copy audit: `evidence copy checked 10 / failed 0`
- No raw IDs in accepted normal copy.
- No coordinates in accepted normal copy.
- No `projection`, `anchor`, `validator`, `audit`, `evidenceID`, debug term, or confidence score in accepted normal copy.
- No explicit horror explanation or lore dump.

## Accepted English Lines

- `The lamp remembered this night.`
- `The rain stayed on the stones.`
- `Something by the shrine looked back.`
- `One marker stayed after the cycle ended.`
- `A rare echo stayed after the long turn.`
- `This day stayed quiet, and the map kept the empty space.`
- `A seven-day trace rests quietly in the world.`
- `This cycle left a quiet rhythm.`
- `Not visible yet.`

## Accepted Chinese Lines

- `那盏灯记住了这个夜晚。`
- `雨停在石路边。`
- `神社旁边有一点东西看了回来。`
- `周期结束后，一个标记留了下来。`
- `很久以后，有一点回声还在。`
- `这一天很安静，地图也把空白留住了。`
- `七天的痕迹安静地放在世界里。`
- `这个周期留下了很轻的节奏。`
- `还没有显现。`

## Lines To Revisit Later

No P1H blocker copy rewrite is required.

Polish candidates:

| Current Line | Concern | Possible Rewrite |
| --- | --- | --- |
| `It has returned more than once.` | Clear, but slightly direct for a subtle story card. | `It has come close more than once.` |
| `This trace has not stepped into the world yet.` | Understandable, but a little abstract. | `This trace is still waiting at the edge.` |
| `它已经不止一次靠近。` | Natural enough, but could be softer. | `它已经靠近过不止一次。` |
| `这条痕迹还没有走进世界。` | Slightly poetic but a bit stiff. | `这条痕迹还停在边上。` |

These should be considered copy polish, not blockers.

## Forbidden Vocabulary

Normal user UI should not show:

- `evidenceID`
- `projectedElementID`
- `catalogElementID`
- `WorldStateProjection`
- `projection`
- `anchor`
- `resolver`
- `validator`
- `audit`
- `debug`
- `JSON`
- `store`
- `confidence score`
- raw seed IDs
- anchor coordinates

## Tone Notes

- Keep copy short, calm, and concrete.
- Prefer physical traces: lamp, rain, stones, shrine, marker, echo.
- Avoid explaining who the visitor is.
- Avoid explaining the 49-day reset.
- Low participation copy should preserve quietness, not imply failure.
- StoryCard copy should feel like fragments, not encyclopedia entries.

## Story-Specific Copy Review

night_lamplighter:

- Pass.
- The lamp line connects night and path memory without identifying the visitor.

umbrella_woman:

- Pass.
- Rain/stones language feels quiet and uneasy without revealing identity.

mirror_miko:

- Pass.
- Shrine/looking-back language suggests ritual reflection without explaining the reset.

CycleRecord:

- Pass.
- Marker/rhythm language reads as world-level memory rather than Pico biography.

EraMemory:

- Pass.
- Locked state remains quiet; unlocked state uses one rare echo line.

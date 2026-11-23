# Reef Dive

An underwater Roblox game. You spawn on a raft in a sunny lagoon, dive down to a coral reef, grab glowing pearls from clams and try not to get eaten.

## What's in it

- A walled lagoon of real swimmable terrain water, with the sun overhead
- Coral reefs: branching coral, brain coral, sea fans, tube coral, anemones and starfish
- Kelp forests that sway and reach up towards the surface
- Fish schools that scatter when you or a shark swims through them, plus jellyfish, sea turtles, manta rays and crabs
- Sharks that patrol and chase you if you get close. They bite, back off, then come round again
- An oxygen bar. Go back up for air or you start drowning
- Pearls as score, shown on the leaderboard and saved between sessions once the game's published

## Running it

```
git clone https://github.com/ockeslam/-Roblox-game-1-.git
cd -Roblox-game-1-
rojo build -o ReefDive.rbxl
open ReefDive.rbxl
```

That opens it in Roblox Studio. Hit **Play**.

To keep Studio in sync while code changes:

```
rojo serve
```

Then in Studio open the Rojo plugin and click **Connect**.

## Getting updates

```
git pull
```

With `rojo serve` running and connected, Studio updates by itself.

## Tweaking

Most numbers are in `src/shared/Config.luau`: shark speed, bite damage, how long your oxygen lasts, number of clams, and more. Change `Seed` for a different map layout.

## Where things live

| File | What it does |
| --- | --- |
| `src/server/World.luau` | Builds the terrain, lighting, raft, reefs, kelp and clams |
| `src/server/Sharks.luau` | Shark models and AI |
| `src/server/PlayerStats.luau` | Pearls, oxygen, saving |
| `src/client/MarineLife.luau` | Fish, jellyfish, turtles, rays, crabs |
| `src/client/Kelp.luau` | Kelp swaying |
| `src/client/Effects.luau` | Underwater tint and bubbles |
| `src/client/Hud.luau` | Oxygen bar, pop-ups, damage flash |

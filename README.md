# Reef Dive

An underwater Roblox game. You spawn on a raft in a lagoon in the middle of a tropical island. Dive down, hunt fish with your harpoon for cash, buy better harpoons from the vending machine, and try not to get eaten.

## What's in it

- **The island:** a ring of sandy beaches and jungle hills with palm trees around the lagoon, little sandy islets inside it, a smoking volcano behind, and open ocean with more islands on the horizon
- **The reef:** branching coral, brain coral, sea fans, tube coral, anemones, starfish, and kelp forests that sway
- **Hunting:** snapper, mackerel, parrotfish, grouper and tuna you can shoot. They flee when you get close and drop gold coins when they die. Swim near the coins to pick them up. Harpoons have a slight aim assist
- **Jellyfish:** glowing and drifting. Swim into one and you get stung. Shoot one and the shock comes back down the line, so you get stung too
- **Sharks:** patrol and chase you if you get close, or if you shoot them. Worth a lot of cash
- **The Giant Squid:** lurks deep down. Every so often it picks a diver, follows them from behind, then charges. You'll get a warning when it's watching you. It inks and runs when badly hurt. While it hunts, a thunderstorm rolls in: dark sky, rain, lightning and choppy water. It's worth a fortune if you can kill it
- **Harpoon shop:** the vending machine on the raft sells five harpoons, from Basic (free) up to the Legendary Kraken Slayer with splash damage
- **Ambient life:** fish schools that scatter, manta rays, crabs, seagulls, and sea turtles swimming or resting on the beaches
- **Beach hut:** a hut on stilts with a balcony, deck chairs and string lights looking out over the lagoon
- **Oxygen:** go back up for air or you start drowning
- **Saving:** money, pearls and owned harpoons save between sessions once the game's published

## Controls

- **1** equips your harpoon. **Click** (or tap) to shoot where you're aiming
- **E** at the vending machine opens the shop

## Running it

```
git clone https://github.com/ockeslam/-Roblox-game-1-.git
cd -- -Roblox-game-1-
rojo build -o ReefDive.rbxl
open ReefDive.rbxl
```

That opens it in Roblox Studio. Hit **Play**.

To keep Studio in sync while code changes, run `rojo serve`, then in Studio open the Rojo plugin and click **Connect**.

## Getting updates

```
git pull
rojo build -o ReefDive.rbxl
```

Or, with `rojo serve` running and connected, just `git pull` and Studio updates by itself.

## Sounds

The thunder, squid sting and storm drone use built-in placeholder sounds. To swap in better ones, open `src/shared/Config.luau` and fill in `Config.Sounds`. Find sounds in Studio under Toolbox > Creator Store > Audio, right-click one, choose Copy Asset ID, and paste it as `"rbxassetid://123456"`. Rain and seagulls are silent until you add an ID.

## Tweaking

Most numbers are in `src/shared/Config.luau`: creature health and rewards, shark and squid behaviour, harpoon stats and prices, oxygen, and more. Change `Seed` for a different map layout.

## Where things live

| File | What it does |
| --- | --- |
| `src/server/World.luau` | Island, lagoon, volcano, palms, raft, vending machine, reefs, kelp, clams |
| `src/server/Creatures.luau` | Huntable fish, sharks and the giant squid: models, AI, health |
| `src/server/Harpoons.luau` | Harpoon guns, shooting, buying |
| `src/server/Coins.luau` | Coin drops and pickup |
| `src/server/PlayerStats.luau` | Money, pearls, oxygen, saving |
| `src/client/Weapons.luau` | Aiming, shot effects, damage numbers |
| `src/client/Shop.luau` | The shop menu |
| `src/client/CreatureAnim.luau` | Tail and tentacle wiggles, spinning coins |
| `src/client/MarineLife.luau` | Ambient fish, jellyfish, turtles, rays, crabs |
| `src/client/Kelp.luau` | Kelp swaying |
| `src/client/Effects.luau` | Underwater tint and bubbles |
| `src/client/Hud.luau` | Oxygen bar, pop-ups, squid warning, announcements |
| `src/client/Weather.luau` | The squid storm: sky, clouds, waves, rain, lightning |
| `src/client/Birds.luau` | Seagulls |
| `src/client/Sounds.luau` | Sound loading and placeholders |

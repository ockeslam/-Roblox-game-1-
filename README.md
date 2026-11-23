# Reef Dive

An online underwater Roblox game with PvP. You spawn on a raft in a lagoon in the middle of a tropical island. Dive down, hunt 40 species for cash and XP, buy better guns from the vending machine, level up, brave The Deep, and watch out for other players.

## What's in it

- **The island:** a ring of sandy beaches and jungle hills with palm trees around the lagoon, little sandy islets inside it, a smoking volcano behind, and open ocean with more islands on the horizon
- **The reef:** branching coral, brain coral, sea fans, tube coral, anemones, starfish, and kelp forests that sway
- **Hunting:** 30 species you can shoot, each with a rarity from 1 (Common) to 5 (Legendary). Rarer catches are scarcer and slower to respawn, have more health, and drop more coins and XP. Their name and stars show above them when hit. Harpoons have a slight aim assist
  - Common (8 of each, back in 10s): sardine, snapper, mackerel, damselfish, blue chromis, goby, crab, jellyfish
  - Uncommon (6 of each, 20s): clownfish, parrotfish, butterflyfish, angelfish, pufferfish, blue tang, wrasse, moorish idol
  - Rare (4 of each, 45s): grouper, tuna, barracuda, triggerfish, lionfish, moray eel, stingray, king crab
  - Epic (2 of each, 90s): mahi-mahi (rarely dashes at you at huge speed), swordfish, hammerhead, marlin. Plus 4 sharks
  - Legendary (1 of each, 4 minutes): ocean sunfish, golden fish, coelacanth, giant squid
  - The Deep (level 10+): lanternfish, hatchetfish, giant isopod, glow jelly, anglerfish, viperfish, gulper eel, frilled shark, chimaera, oarfish
- **Levels:** up to level 100. Earn XP from kills, pearls and PvP kills. Each level makes creatures tougher and hit harder for you, but they pay more. Better guns need higher levels. Every 3 levels another shark joins the lagoon, and the squid hunts more often
- **The Deep:** a dark trench through the channel on the east side of the island, past the red buoy. It's pitch black (your head torch switches on), oxygen runs out faster, and below level 10 the pressure hurts you
- **PvP:** guns hurt other players everywhere except on the raft. You get 5 seconds of spawn protection. A PvP kill gives XP and adds to your Kills, and the victim drops 10% of their cash (up to $500) as coins. Kills show in the top-right feed
- **Jellyfish:** glowing and drifting. Swim into one and you get stung. Shoot one and the shock comes back down the line, so you get stung too
- **Sharks:** patrol and chase you if you get close, or if you shoot them. Worth a lot of cash
- **The Giant Squid:** lurks deep down. Every so often it picks a diver, follows them from behind, then charges. You'll get a warning when it's watching you. It inks and runs when badly hurt. While it hunts, a thunderstorm rolls in: dark sky, rain, lightning and choppy water. It's worth a fortune if you can kill it
- **Gun shop:** the vending machine on the raft sells 11 guns:
  - Basic Harpoon (free)
  - Reef Harpoon
  - Tide Harpoon
  - Triple Spear (3-shot spread)
  - Abyss Harpoon
  - Sonic Blaster (full-auto)
  - Torpedo Launcher (slow, big splash)
  - Kraken Slayer (splash)
  - Storm Trident (chain lightning)
  - Leviathan Cannon (5-shot spread with splash)
  - Poseidon's Wrath (chain and splash, level 50)
- **Ambient life:** decorative fish schools that scatter, manta rays, crabs, seagulls, and sea turtles swimming or resting on the beaches
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

## Playing online with other people

1. In Studio: **File → Publish to Roblox**
2. On create.roblox.com, open the game, go to **Settings**, set it to **Public**, and set the max players (e.g. 20)
3. For saving to work: in Studio, **Game Settings → Security → Enable Studio Access to API Services**

To test PvP on your own: in Studio's **Test** tab, choose **Clients and Servers** with 2 players and press **Start**. Two game windows open and you can shoot each other.

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

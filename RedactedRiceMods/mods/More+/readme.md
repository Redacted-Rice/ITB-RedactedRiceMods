# More Pilot Level Up Skills
Have you ever wished there was even more variety for Pilot Level Up Skills than in AE?
Well this is the mod for you! This mod currently adds 35 more Pilot Level Up Skills to
the game in 5 different categorical groups. Enable and disable groups or individual
skills in the CPLUS+ Modify Pilot Abilities Menu.

Customize and enhance your game like never before!

Join the Redacted Rice discord for support, more mods, discussion and other projects: https://discord.gg/CNjTVrpN4v

Please enjoy and contact us if you run into any issues.
* RedactedRice Discord Server: https://discord.gg/CNjTVrpN4v
* ItB Discord: Das Keifer
* Email: RedactedRice@gmail.com

## Known Issues
* On death effects don't trigger with +/x damage effects. This will be a difficult one to fix

## Custom Skills Added

### Defensive
Skills related to grid and mech defense and hampering enemy power

* Cheap Plating - The first attack each mission that would damage the piloted mech does -3 damage.
* Covering Fire - Targeted enemies lose half their movement for a turn (rounded down).
* Defiant - +3 grid defense per enemy on the board.
* Foolhardy - +12 grid defense if no buildings are damaged.
* Impervious - Piloted mech is immune to self and friendly, non-instakill damage (direct damage from attack only).
* Resilient - Gain a shield each time the piloted mech is damaged after the attack completes.
* Streetwise - Prevents (not-instakill) damage to buildings from piloted mech's attacks.

### Movement
Skills related to mechs moving around the board in any way

* Accelerator - +1 Move at the end of each turn.
* Guarded - Piloted Mech is stable and cannot be moved by weapon effects.
* Jump Jets - Piloted Mech can jump with -1 move as its movement.
* Nimble - Piloted mech can move onto and through buildings and mountains.
* Pontoons - Piloted mech floats on top of liquid tiles without being affected by them.
* Supporter - Piloted mech can teleport to tiles adjacent to allies.

### Offensive
Skills related to dealing damage to enemies

* Anger - Gain boosted when piloted mech is directly damaged by an enemy.
* Big Game Hunter - Doubles damage to boss vek.
* Calculated Shot - +1 damage to enemies with movement <= to half (rounded up) the piloted mech's movement.
* First Blood - +1 damage to undamaged enemies with 4+ health.
* Focused Strike - Doubles damage to enemies if the piloted mech has not used its movement.
* Kill Shot - +1 damage to enemies that would be killed by the extra damage.
* Momentum - Gain boosted after moving at least 4 tiles.
* Trophy Hunter - +1 damage to "unique" (non-common) enemies.
* Vampire - Repair (regardless of pilot repair skill) piloted mech when you kill a vek.
* Vigor - Gain Boost when piloted mech is healed (even if already at full health).

### Positioning
Skills based on where the piloted mech or enemies are positioned on the board

* Alert - Reduce damage taken from enemies by 1 while adjacent to an enemy (stacks with armor, not cancelled by acid).
* Ambusher - +1 damage to enemies if piloted mech is not on a road, liquid, or hole tile.
* Escort - Shield adjacent allies when you move next to them or they move next to you.
* Militia - +1 damage to enemies adjacent to buildings.
* Rally - Boost adjacent allies when you move next to them or they move next to you.
* Urban - Gain a shield when moving adjacent to a building.

### Trade Offs
These are skills that have a stronger than typical positive effect but also include a negative effect

* Hot Headed - Gain Boost every other turn but loses 2 XP per kill (can't level down from this).
* Hyper - +2 movement for the first 2 turns, +1 movement for the 3rd turn, then +0 movement.
* Malevolent - If piloted mech has a negative status, apply it to attacks that damage enemies.
* Reflect - If damaged by an enemy, deals half (rounded up) damage back to the attacker.
* Shatterstep - When moving, cracks the tile moved from.
* Vindictive - +1 damage to enemies for each negative status effect on piloted mech.

# Releases
Latest release: 2.2.0

## 2.2.0
Released: XX/XX/2026

compatible with:
* ItB AE 	1.2.93
* ModLoader 2.9.5
* memhack	1.2.0
* CPLUS+ Ex	1.2.0

### Notes
* Reworked for new weapon preview groups concepts
* Added option to reset the weapon preview tool tips
* Updating working on ambusher from road to ground to be consistent with vanilla displayed text

## 2.1.0
Released: 05/07/2026

compatible with:
* ItB AE 	1.2.93
* ModLoader 2.9.5
* memhack	1.1.0
* CPLUS+ Ex	1.1.0

### Notes
* Created a default enabled/disabled skills list
* Updated for fixes in weapon preview mod
* Fixed resiliant triggering on undoing heal mine moves
* Fixed rally not working when moving the pawn with the skill
* Fixed first blood not triggering on enemies with more than their typical max health
* Fixed momentum, rally, urban, and escort removing boost/shield from other pawns on undo move
* Added a number of additional exclusions for Zoltan/Mafan
* Added broken stateful icon for cheap plating
* Updated icon for streetwise


Latest release: 2.0.0

## 2.0.0
Released: 05/01/2026

compatible with:
* ItB AE 	1.2.93
* ModLoader 2.9.5
* memhack	1.1.0
* CPLUS+ Ex	1.1.0

### Notes
Major 2.0 release with 16 new skills!

Moved skill base classes into CPLUS+

New Skills:
* Defensive (2) - Cheap Plating, Impervious
* Movement (1) - Supporter
* Offensive (3) - Anger, Vampire, Vigor
* Positioning (6) - Alert, Ambusher, Escort, Militia, Rally, Urban (entire new category!)
* Trade Offs (4) - Hot Headed, Malevolent, Reflect, Vindictive

Other improvements:
* Integrated Status Library for malevolent and vindictive
* Many bug fixes and balance improvements
* Enhanced visual feedback and icons
* Improved skill compatibility and constraints via pools

Full skill list:
* Defensive (7) - Cheap Plating, Covering Fire, Defiant, Foolhardy, Impervious, Resilient, Streetwise
* Movement (6) - Accelerator, Guarded, Jump Jets, Nimble, Pontoons, Supporter
* Offensive (10) - Anger, Big Game Hunter, Calculated Shot, First Blood, Focused Strike, Kill Shot, Momentum, Trophy Hunter, Vampire, Vigor
* Positioning (6) - Alert, Ambusher, Escort, Militia, Rally, Urban
* Trade Offs (6) - Hot Headed, Hyper, Malevolent, Reflect, Shatterstep, Vindictive

## 1.0.0
Released: 04/10/2026

compatible with:
* ItB AE 	1.2.93
* ModLoader 2.9.5
* memhack	1.0.0
* CPLUS+ Ex	1.0.2

### Notes
Initial release with 19 pilot level up skills across 4 categories:
* Defensive (5) - Covering Fire, Defiant, Foolhardy, Resilient, Streetwise
* Movement (5) - Accelerator, Guarded, Jump Jets, Nimble, Pontoons
* Offensive (7) - Big Game Hunter, Calculated Shot, First Blood, Focused Strike, Kill Shot, Momentum, Trophy Hunter
* Trade Offs (2) - Hyper, Shatterstep

# Overview
Various Libraries to support Into the Breach mod development.

Each library has a short description of how to use it in the file.

Join the Redacted Rice discord for support, more mods, discussion and other projects: https://discord.gg/CNjTVrpN4v

Please enjoy and contact us if you run into any issues!
* RedactedRice Discord Server: https://discord.gg/CNjTVrpN4v
* ItB Discord: Das Keifer
* Email: RedactedRice@gmail.com

# Releases:

## ArtilleryArc
Current Release: 2.0.0

### 2.0.0
Released: 05/04/2026

* Brought in from Lemonymous' repo and enhanced to support two click weapons and mutli shot effects

## BoardUtils
Current Release: 1.5.0

### 1.5.0
Released: 05/04/2026

* Added functions for forcing a single move and canceling an attack

### 1.4.0
Released: 05/01/2026

* Added functions for tracking pawns
* Add functions to support additive checks for allowing pawns on buildings and mountains
* Fixes to some edge cases of all terrain movement

### 1.3.0
Released: 03/30/2026

Updated to handle multiple instances/versions actually correctly

### 1.2.0
Released: 03/28/2026

* Enhanced forced movement to be more generic and work without killing the whole effect
* Added support for hijacked flying for things like amphibious skills
* Added last computed forced path for modifying & referencing for skills like momentum

### 1.1.0
Released: 01/10/2026

Initial release to keep in sync with other libs

## PassiveEffect
Current Release: 1.4.0

### 1.4.0
Released: 03/30/2026

Updated to handle multiple instances/versions actually correctly

### 1.3.0
Released: 03/28/2026

Added a function to check if a passive is active

### 1.2.0
Released: 01/13/2026

Fixed some passive effect issues specifically with not being added correctly to the second part of the final mission

### 1.1.0
Released: 12/19/2025

Made it support multiple instances correctly

### 1.0.0
Released: ?

Initial Release.

## PawnTypeUtils
Current Release: 1.1.0

### 1.1.0
Released: 03/30/2026
Made it support multiple instances correctly

### 1.0.0
Released: 03/28/2026

Initial release

## PredictableRandom
Current Release: 1.2.0

### 1.2.0
Released: 03/30/2026

Updated to handle multiple instances/versions actually correctly

### 1.1.0
Released: 12/19/2025
Made it support multiple instances correctly

### 1.0.0
Released: ?
Initial Release.

## Trait
Current Release: 3.0.1

### 3.0.1
Released: 04/10/2026

Fixed issue with animations not playing in preview

### 3.0.0
Released: 02/14/2026

Copied from Lemonymous and updated to handle multiple traits by appending text together and cycling through images

## TraitReplace
Current Release: 0.9.1

### 0.9.1
Released: XX/XX/2026

Fixing case where Board could be nil causing a failure

### 0.9.0
Released: 05/07/2026

Adding support for stateful icons - e.g. cheap plating - icons that change if the corresponding skill has been used or not

### 0.8.2
Released: 05/01/2026

Optimizations to redraw less and recreate less to remove some cases where I was seeing noticable lag

### 0.8.1
Released: 04/10/2026

Fixing some issues with timing when adding icons and displaying vanilla icons in deployment phase

### 0.8.0
Released: 03/28/2026

Initial release. Works for massive but has some issue with exta UIs some icons like flying are use in

## TutorialTips
Current Release: 1.2.0

### 1.2.0
Released: XX/XX/2026

* Included to support WeaponPreview and updated to allow specifying a rootId instead of always using mod.id to support weaponPreview using it

## WeaponArmed
Current Release: 2.1.0

### 2.1.0
Brough in from Lemonymous' repo in support of ArtilleryArc. No changes

## WeaponPreview
Current Release: 4.1.0

### 4.1.0
Released: XX/XX/2026

* Switched to using tutortialtips lib for group icons and tool tips for weapon preview
* Fixed issues with dynamically changing target area skill effects

### 4.0.2
Released: 05/07/2026

* Fixed issues with queued icons not getting cleared out on skill execution and being added without associated pawns

### 4.0.1
Released: 03/30/2026

Fixed issue with animations not playing in preview

### 4.0.0
Released: 03/28/2026

Copied from Lemonymous and updated to handle multiple traits by appending text together and cycling through images
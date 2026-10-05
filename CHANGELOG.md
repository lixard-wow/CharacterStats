# Changelog

## Version 2.1.4

### Fixed

- Fixed the main stats display sometimes appearing as a plain white box with no visible text or border color, caused by a background texture load issue.

## Version 2.1.3

### Improved

- Item Level now shows the exact number of decimal places you've chosen in the settings, instead of always rounding to a whole number.
- Versatility stays accurate more reliably while in Mythic+ dungeons and Delves.
- General behind-the-scenes cleanup for better performance and stability.

### Changed

- Slider handles in the settings panel are now round instead of square, for a cleaner look.

## Version 2.1.2

### Updated

- Updated for **World of Warcraft Patch 12.0.7**.
- Added compatibility for **Patch 12.1.0**.
- Improved game version detection to ensure the addon recognizes supported WoW versions correctly.

## Version 2.1.1

### Improved

- Stats now update faster and stay in sync across the floating stats window and Character panel.
- Improved responsiveness when changing gear, talents, specialization, forms, and buffs.
- Movement Speed tracking is more reliable during combat and Mythic+.
- Raw rating values (Critical Strike, Haste, Mastery, and Versatility) remain more consistent during combat.
- Improved Character panel integration for better compatibility with Blizzard's default UI.
- Increased space for Movement Speed values to prevent clipping at very high speeds.

### Fixed

- Fixed Versatility displaying incorrect values during combat and Mythic+.
- Fixed stats disappearing during combat or other restricted situations.
- Fixed raw rating values disappearing in combat.
- Fixed some stats becoming stuck on outdated values.
- Fixed Character panel stats not updating consistently with the floating stats window.
- Fixed some Blizzard Character panel elements not restoring correctly after closing the panel.
- Fixed Mana Regen, Attack Power, and Spell Power occasionally disappearing.
- Removed outdated caching that could cause stale stat values to be displayed.

## Version 2.1.0

### Improved

- Updated the addon for the changes introduced in WoW 12.0.x.
- Improved stat reliability during combat and Mythic+.
- Improved Movement Speed tracking, including better support for Skyriding.
- Fixed Movement Speed occasionally displaying incorrect values after changing zones.

## Version 2.0.4

### Improved

- Character panel stat tooltips now use Blizzard's native tooltips.

## Version 2.0.3

### Fixed

- Fixed several profile management issues.
- Corrected Item Level colors for Epic and Legendary items.
- Improved performance by optimizing stat updates.

## Version 2.0.2

### New

- Added an optional horizontal layout.
- Added optional separators between stats in horizontal mode.
- Added an option to display a colon after each stat label.
- Added custom color support for the Item Level stat.

### Fixed

- Fixed buff and debuff stat updates.
- Fixed profile management issues.
- Improved spacing for percentage-based stats in horizontal mode.

## Version 2.0.1

### Fixed

- Fixed Movement Speed alignment.
- Fixed Minimap button dragging.
- Fixed the **Clamp to Screen** option not being applied when the addon loads.

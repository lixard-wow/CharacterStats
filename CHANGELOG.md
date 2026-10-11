# Changelog

## Version 2.2.0

### Added

- Four looks for the stats panel and the character window: Original, Ledger, Meters and Companion. Original stays the default; pick another under Appearance or with `/cs style`, which opens a picker with a live preview.
- Three window themes for the options window and popups: Classic (the default), Workbench and Artisan Ledger. Pick one from the gear button in the options window's title bar or cycle with `/cs theme`.
- A new options window with a sidebar of pages. Its title bar has a gear button for the window's own settings (theme, accent color, scale) and a minimize button.
- Frame Scale setting for the stats panel, and Font Size now goes down to 4.
- Gear slot details on the character window (off by default, turn on under Character Frame): item level colored by upgrade track, upgrade level (4/6, or 4/6 Hero), enchant and gem icons (hover for names), and a "Missing enchant" note on slots that should be enchanted. Choose where each part sits, on the icon or beside it at the top, middle or bottom. MoP Classic upgrade levels are shown too.
- A drawer beside the character window with Stats, Gear and Ratings tabs.
- An options button on the character window (off by default).
- The character window is 50 px wider to give the gear slot details room next to your character. Change it under Character Frame > Extra Character Frame Width (0 restores the original size).
- Diminishing returns:
  - In the Meters look, crit, haste, mastery and versatility bars fill up to the point where the penalty starts; past it, a darker shade fills back in to show how far over you are. Leech, avoidance and speed use their own, earlier start point.
  - Hovering those stats (stats panel or character window) shows your current penalty, the rating until the next penalty, and your effective rating.
  - Item tooltips show what each stat on an item is worth after diminishing returns, and how much the penalty takes away (off by default, turn on under General).
  - The drawer's Ratings tab shows the rating needed for 1% more at your current penalty.
- Bar thickness settings for the stats panel and the character window (Meters look).
- Detection of other addons that restyle the character window (ElvUI, EllesmereUI, Chonky Character Sheet and others), with a popup that offers to turn off the conflicting part or the other addon (off by default, turn on under Character Frame).
- WoW Classic Forever support: Blizzard's own stat list on the character window, resistances colored by school, the ranged slot, and a Ratings tab with the combat ratings that client uses. The drawer sits clear of the character window's side tabs.
- MoP Classic: the character window lists Blizzard's own stat categories (General, Attributes, Melee, Ranged, Spell, Defense, Resistance) in a scrolling list, showing only what matters for your class and spec, with every stat in its own color. Health, Power, weapon damage, Spell Healing, Spell Penetration and resistances are now in the Stats list too. Supports MoP Classic 5.5.4.
- Addon language: show CharacterStats in any of its languages, independent of your game language, from General > Language or with `/cs locale`.

### Changed

- Versatility now always shows the value from your versatility rating, live in combat. Flat bonuses such as Mark of the Wild are not included, because the game hides them from addons in combat. The Real-Time Versatility option is gone.
- Minimap button: left-click opens the options, right-click shows or hides the stats panel.
- Profiles for your own class's specs show just the spec name (for example Protection instead of Protection Warrior).
- Buff colors from the game (green/red numbers) no longer override stat colors on the character window.
- The `/csdebug` command has been removed.

### Fixed

- An error from the character window's stat tooltips (secret values, taint) no longer appears.
- The character window no longer takes several seconds to show its stats when opened.
- Switching profiles no longer carries settings over from the previous profile, and "Reset Colors" no longer comes back after a reload.
- Block chance now shows on non-English game clients.
- Specialization profiles no longer get shared between classes with the same spec name (for example Holy Priest and Holy Paladin). Existing profiles are copied over automatically.
- Confirmation popups no longer block movement and other keys while open, and Escape now closes the Share menu.
- The Share menu no longer errors after a friend comes online, skips values the game currently hides, and tells you when chat is restricted instead of failing silently.
- The options window now remembers its size.
- The "UI Scale" slider is now labeled "Options Window Scale", since it only ever scaled the options window.
- The stats panel no longer briefly shows stats you disabled while the character window is open.
- On Classic, the addon no longer replaces game functions that other addons and the default UI rely on.

### Improved

- Movement speed updates only run while you are moving or in the air, instead of all the time.
- Buff and debuff changes in combat are grouped into fewer refreshes.
- Less work done on every refresh.
- All new text is translated into German, Spanish, French, Italian, Brazilian Portuguese, Russian, Korean and Chinese.

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

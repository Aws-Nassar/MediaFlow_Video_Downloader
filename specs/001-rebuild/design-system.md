# Studio Dark Design System

## 1. Direction

Studio Dark is a calm, high-contrast workspace for media: deep neutral surfaces,
one strong violet accent, cyan for live/in-progress signals, and restrained color
everywhere else. It should feel like a professional tool, not a consumer video
site.

The UI is content-first. Thumbnails, titles, and progress are the visual anchors;
chrome stays quiet. One primary action per screen. Advanced controls expand only
when needed.

## 2. Design tokens

### Color

| Token | Hex | Use |
|---|---|---|
| `bg` | `#0B0D12` | App background |
| `surface` | `#12151D` | Cards, sheets |
| `surfaceRaised` | `#1A1F2B` | Menus, hover, selected rows |
| `border` | `#262C3A` | Dividers, card outlines |
| `text` | `#E6E9F2` | Primary text |
| `textMuted` | `#8B93A7` | Secondary text, metadata |
| `textFaint` | `#5C6478` | Disabled, placeholders |
| `accent` | `#7C5CFF` | Primary actions, focus |
| `accentHover` | `#927AFF` | Hover/pressed |
| `accentSoft` | `#241F45` | Accent-tinted surfaces |
| `cyan` | `#22D3EE` | Live, active progress |
| `success` | `#34D399` | Completed |
| `warning` | `#FBBF24` | Auth needed, quota |
| `danger` | `#F87171` | Errors, destructive actions |
| `dangerSoft` | `#3A1D24` | Destructive tint |

Light theme: invert surfaces to `#F7F8FB` / `#FFFFFF`, text to `#12151D`,
borders to `#DDE2EC`, keep accent violet and semantic colors adjusted for
contrast. OLED theme: `bg` and `surface` become `#000000` and `#08090D`; borders
stay visible.

Source badges use muted brand tints, not full brand colors:
YouTube red, TikTok cyan/pink, Facebook blue, Instagram magenta, Kick green,
Twitch purple, SoundCloud orange, Drive blue. Badges are small and never compete
with the primary accent.

### Type

Use the platform UI font (Segoe UI Variable on Windows, Roboto on Android) unless
a bundled Inter is approved. Arabic uses Noto Sans Arabic or the platform Arabic
font. Do not mix fonts per string.

| Role | Size / weight | Use |
|---|---|---|
| Display | 28 / 700 | Empty-state headline |
| H1 | 22 / 700 | Screen title |
| H2 | 18 / 600 | Section title |
| Body | 14 / 400 | Default |
| BodyStrong | 14 / 600 | Titles in lists |
| Caption | 12 / 400 | Metadata |
| Overline | 11 / 600, +0.6 tracking | Section eyebrows |
| Mono | 12 / 400 | Diagnostics only |

Line height: 1.4 for body, 1.2 for headings. Avoid all-caps except overlines.

### Spacing, radius, elevation

- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40.
- Radii: 8 (inputs), 12 (cards), 16 (sheets/dialogs), 999 (pills).
- Elevation: use borders first, shadows second. Dark theme shadows are subtle:
  `0 8 24 rgba(0,0,0,0.35)`.
- Focus ring: 2px accent, 2px offset.
- Touch target: minimum 48x48dp.

## 3. Layout

### Windows (>= 1000px)

```
┌────────────┬──────────────────────────────┬──────────────────┐
│ Nav rail   │ Main content                 │ Details panel    │
│ 220px      │ flexible                     │ 320px, optional  │
│            │                              │                  │
│ Analyze    │ URL input                    │ Thumbnail        │
│ Queue      │ Media card                   │ Title/metadata   │
│ Library    │ Format/quality               │ Advanced options │
│ Settings   │ Recent activity              │ Download action  │
└────────────┴──────────────────────────────┴──────────────────┘
```

- Nav rail collapses to icons below 1100px.
- Details panel collapses into an expandable section below 900px.
- Minimum window: 900x600. Remember size/position.
- Keyboard: `Ctrl+V` paste, `Ctrl+Enter` analyze/download, `Esc` close dialog,
  `Delete` remove selected queue item.

### Android (compact)

- Bottom navigation: Analyze, Queue, Library, Settings.
- Analyze is the default tab and shows a large paste/share target.
- A floating "New download" action is unnecessary on the Analyze tab; use a
  persistent URL field at the top.
- Details open as a bottom sheet, not a side panel.
- Queue rows are cards with a progress bar, source badge, and overflow menu.
- Respect system insets and predictive back.

Breakpoints:
- `< 600dp`: compact phone.
- `600–839dp`: large phone / small tablet; two-column queue/library.
- `>= 840dp`: tablet/desktop; side navigation.

## 4. Screens

### Analyze

- Overline: `NEW DOWNLOAD`.
- Headline: "Paste a link" / "الصق رابطًا".
- Large input with paste icon and a source hint.
- Multi-line mode toggle: "Add multiple links."
- After probe: media card with 16:9 thumbnail, duration pill, source badge,
  title, author.
- Format row: type (Video/Audio), quality dropdown, container dropdown.
- Batch-level Video/Audio segmented control when multiple links are queued.
- Advanced disclosure: subtitles, thumbnail, playlist, cookies, live-from-start.
- Drive folder: a selection sheet with file/subfolder checkboxes, total size,
  "Download all," and "Download as ZIP."
- Primary button: "Download" or "Add to queue."
- Empty/error states explain supported sources and next actions.

### Queue

- Header: active count, global speed, "Pause queue" (stops new jobs).
- Tabs/filters: Active, Waiting, Completed, Failed.
- Row: thumbnail, title, source, status, progress bar, speed/ETA, cancel/retry.
- Collection groups: parent row with `3 of 12 completed`, expandable items.
- Completed rows: Open, Share, Show in folder.
- Failure rows: thumbnail/fallback name, original link, short localized reason,
  and actions. Expand for Details, Retry, Open in browser, Copy link, Skip.
- When the batch settles, show a "Batch finished" summary sheet (see below).
- Empty state: "Nothing downloading" + "Paste a link."

### Library

- Search field, source filter, status filter.
- Grid/list toggle; default list on phone, grid on desktop.
- Tile: thumbnail, title, source, duration, size, date, missing-file badge.
- Detail sheet: metadata, file path, open/share/delete, re-download.
- Delete flow: "Remove from history" vs "Delete file from disk" with explicit
  confirmation.

### Settings

Sections: General, Downloads, Sources & cookies, Appearance, Storage, About.

- General: language, theme, start screen.
- Downloads: output folder, concurrency, retries, timeout, proxy, rate limit,
  filename template.
- Sources & cookies: cookie file import, browser cookies (Windows), clear
  cookies. Google Drive is link-shared only; do not show a Google sign-in or
  account-connect control.
- Appearance: theme, reduced motion, compact density.
- Storage: free space, default folder, clear cache/temp.
- About: version, engine versions, licenses, privacy, legal notice, export
  diagnostics.

Android hides desktop-only controls (browser cookie import, engine path,
FFmpeg). Do not show a toggle for a capability that does not exist.

### Source catalog

A searchable list of engine-supported hosts and adapter-supported sources.
Show "Powered by yt-dlp" with the engine version. Do not hardcode a "268+"
claim; show the count reported by the engine. Each row can show a capability
badge (Video, Audio, Live, Playlist, Cookies). Do not show a Google sign-in
badge for Drive; it is link-shared only.

## 5. Components

### URL field
- 56dp height, 12dp radius, leading link icon, trailing paste/clear.
- Accepts multi-line in batch mode; each line becomes a chip.
- Inline validation: red border + message, no modal for a single bad URL.

### Source badge
- 20dp icon + 12sp label; tinted background; max width 120dp.
- Unknown source: neutral globe icon + host name.

### Media card
- 16:9 thumbnail with 12dp radius; skeleton while loading; fallback icon.
- Duration pill bottom-right; LIVE pill uses cyan and pulses subtly (reduce
  motion aware).
- Title max 2 lines; author muted; source badge top-left.

### Progress
- 6dp linear bar, rounded; accent for downloading, cyan for live, success for
  completed, danger for failed.
- Indeterminate shimmer only when the engine cannot report progress.
- Text: `42% · 12.4 MB/s · 0:18 left` (hide unknown parts).
- Do not show 0% before the first event; show "Starting…".

### Buttons
- Primary: accent fill, white text, 48dp height, 12dp radius.
- Secondary: transparent with border.
- Destructive: danger text on danger-soft surface; confirm before file deletion.
- Icon buttons: 40dp visual, 48dp hit area.

### Dialogs and sheets
- Title, one-sentence body, clear primary and secondary actions.
- Destructive action is never the default focus.
- Bottom sheets have a drag handle and safe-area padding.

### Failure card
- Appears in the queue and in the batch summary.
- Shows the fallback/real title, source badge, original link (truncated with
  Copy), and a one-line localized reason.
- Primary action is the most useful recovery: Retry, Add cookies, Open in
  browser, or Change folder.
- Secondary actions: Copy link, Skip, Remove.
- "Details" expands redacted technical text. Never show cookies, tokens, or
  signed media URLs.
- Use danger tint for terminal errors; warning tint for auth/rate-limit.

### Batch summary
- A bottom sheet on compact screens, a dialog/card on desktop.
- Header: "Batch finished" or "12 items finished."
- Counts: downloaded, failed, skipped; total size; elapsed time.
- Failed list: title, original link, reason, Retry per item.
- Actions: Retry failed, Copy failed links, Open folder, View report.
- Dismissing the sheet keeps the summary in History.
- If everything succeeded, show a compact success summary, not a long dialog.

### Drive selection sheet
- Header: folder name and item count.
- Rows: checkbox, file/folder icon, name, size.
- Subfolders can be expanded; recursion is on by default with a guard.
- Footer: selected count, total size, "Download all," "Download as ZIP."
- Blocked files are shown with a lock/alert icon and reason; they cannot be
  selected.

### Toasts/snackbars
- Use for non-blocking confirmations ("Added to queue", "Link copied").
- Errors that need a decision belong in a card/dialog, not a toast.

## 6. States

- **Empty:** icon, one-line explanation, primary action.
- **Loading:** skeleton for cards; progress for probes; no full-screen spinner
  for list content.
- **Error:** error icon, plain-language cause, one primary action, details behind
  "Technical details."
- **Offline:** banner with retry; queued jobs remain.
- **Auth needed:** warning card with "Add cookies" and "Open in browser." Do not
  show a Google sign-in option for Drive.
- **Restricted:** explain the owner/admin restriction; no retry-as-bypass.
- **Partial batch:** show a persistent summary chip ("9 downloaded · 2 failed")
  that opens the batch summary.

## 7. Motion

- 150–200ms ease-out for state changes; 250ms for sheets.
- Progress bar animates value changes but never loops.
- LIVE indicator pulses at 2s intervals; disable with reduced motion.
- No parallax or decorative animation.

## 8. Arabic and RTL

- Full mirroring: nav, rows, chevrons, progress direction, sheet handles.
- Do not mirror media thumbnails, play icons, or brand logos.
- Use Western digits in Arabic prose and metrics (1, 2, 3; 42%; 12.4 MB/s).
- Use Arabic-Indic digits only if the user explicitly selects them (not v1).
- Arabic strings live in ARB; no concatenated sentences. Use placeholders.
- Test long Arabic titles with 2-line ellipsis and RTL alignment.
- Ensure filenames with Arabic characters render correctly in lists and dialogs.
- Font fallback: Noto Sans Arabic; avoid faux bold.

## 9. Accessibility

- Contrast: text on `bg`/`surface` meets WCAG AA; muted text is for secondary
  information only.
- Focus order follows visual order; visible focus ring.
- Screen-reader labels for icon-only buttons, progress values, and source
  badges.
- Announce download completion and failures.
- 48dp targets; no hover-only actions.
- Support 200% text scale without clipping primary actions.
- Reduced motion respected.

## 10. Content and tone

- Short, direct, human. "Link needs cookies" not "Extractor authentication
  failure."
- No blame. "This file's owner disabled downloads" not "You can't download."
- No fake progress or fake speeds.
- Use "Download" for the action; "Rip" is the reference site's brand, not ours.
- Legal note in About: download only content you have rights to; respect site
  terms and copyright.

## 11. Golden test matrix

| Screen | Themes | Locales | Sizes |
|---|---|---|---|
| Analyze empty | Dark, Light | en, ar | 360x800, 1280x800 |
| Analyze with media | Dark, OLED | en, ar | 360x800, 1280x800 |
| Queue active | Dark | en, ar | 360x800, 1280x800 |
| Queue failed | Dark | en, ar | 360x800 |
| Failure card | Dark, Light | en, ar | 360x800, 1280x800 |
| Batch summary | Dark | en, ar | 360x800, 1280x800 |
| Library grid | Dark, Light | en, ar | 360x800, 1280x800 |
| Settings | Dark | en, ar | 360x800, 1280x800 |
| Drive selection sheet | Dark | en, ar | 360x800 |

## 12. Do / don't

Do:
- Keep one accent and use it for the primary action.
- Use borders and spacing before shadows.
- Make the URL field the visual anchor on Analyze.
- Show real metadata and real progress.
- Show the item name, original link, and reason on every failure.
- Keep the batch moving and summarize at the end.
- Explain restrictions without offering bypasses.

Don't:
- Use pure black as the default background.
- Use brand colors as large fills.
- Show a settings toggle for an unavailable capability.
- Hide errors behind a generic "Something went wrong."
- Stop the whole batch because one item failed (unless the user opted in).
- Show a Google sign-in control for link-shared Drive.
- Put destructive file deletion behind a single tap.

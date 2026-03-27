# Shared Gratitudes & Gratitude Wall

## Features

### 1. Share Prompt After Gratitude Check-In (Give Tab)
- After completing your Daily Gratitude (after the golden pulse and scripture verse), a subtle "Share with your circle?" row fades in below the verse
- Only appears if you belong to at least one Prayer Circle
- Tapping opens a share bottom sheet:
  - **One circle**: Choose "Share with your name" or "Share anonymously", see a preview, then tap Share
  - **Multiple circles**: Select one or more circles via pill selectors, then choose named/anonymous, then Share
  - Tap-only gratitudes ("Thank you, God") become "[Name] gave thanks to God today"
- Confirmation: "Shared ✓" appears in sage green for 2 seconds, then fades — no pop-ups or navigation changes
- Ignoring the prompt is fine — it disappears when you scroll or navigate away

### 2. Gratitude Wall (Inside Each Circle's Detail Page)
- A new "Gratitude Wall" section at the top of each circle's detail page, above SOS and actions
- Shows this week's shared gratitudes in a scrollable list, newest first
- Each gratitude card shows: name (or "Someone in your circle" for anonymous), relative time, and the gratitude text
- Cards are read-only — no likes, replies, or reactions
- "Previous weeks" link at the bottom loads older entries one week at a time
- Empty state: "No gratitudes shared this week yet" centered in the section
- You can delete your own gratitudes by long-pressing your card → "Delete"

### 3. Golden Badge Dot on Circles Tab
- A small golden dot appears on the Circles tab icon when there are new shared gratitudes since your last visit
- At the top of the Gratitude Wall, a "3 new gratitudes" count in golden text appears briefly (fades after 5 seconds or after scrolling)
- Both indicators clear once you've seen the wall

### 4. Circle Summary Integration
- The Sunday Circle Summary sheet now includes shared gratitude count: "…and shared 6 gratitudes"
- The Week Look Back screen also mentions circle gratitude counts when available
- If zero gratitudes were shared, the message stays unchanged
- Deleting a gratitude does NOT reduce the summary count (original count preserved)

### 5. Multi-Circle Handling
- If you have one circle, the wall shows directly
- If you have multiple circles, each circle's detail page has its own independent Gratitude Wall

### 6. Free for Everyone
- No paywall gating — free and premium users share and view gratitudes equally

### 7. What's NOT Included
- No push notifications for shared gratitudes
- No likes, hearts, reactions, or comments
- No external sharing (social media)
- No feed algorithm — strictly newest-first
- No read receipts or "seen by"

---

## Design

- **Share prompt row**: Subtle fade-in below scripture verse. Left text "Share with your circle?" in muted secondary color, golden share icon on the right
- **Share bottom sheet**: Dark themed, circle selector pills in golden, name/anonymous toggle, preview text, golden "Share →" button
- **Gratitude cards**: Charcoal-light background (#2A2A3C), subtle border (#353548), 12px rounded corners. Name + timestamp on top row, gratitude text below. 8px spacing between cards
- **Section header**: "GRATITUDE WALL" in uppercase, small muted text with letter-spacing
- **Badge dot**: Small golden circle on the Circles tab icon
- **New gratitude count**: Golden text "3 new gratitudes" at top of wall, fades out gracefully
- **Confirmation**: "Shared ✓" in sage green (#7A9E7E), inline, 2-second display
- **All styling** matches the existing Tribute dark theme with golden accents

---

## Backend Changes (Migrate to Supabase)

### Database Migration
- Migrate the existing backend storage from in-memory KV (dbGet/dbSet) to Supabase (PostgreSQL)
- Create a new `shared_gratitudes` table for the gratitude wall data
- Store user display names on the backend during sign-in for robust name handling across features

### New API Endpoints
- **Share a gratitude** — post a gratitude to one or more circles (named or anonymous)
- **Get gratitude wall** — fetch shared gratitudes for a circle, paginated by week
- **Delete a gratitude** — remove your own shared gratitude
- **Get new gratitude count** — check how many new gratitudes since your last visit
- **Mark gratitudes seen** — clear the "new" indicator when you visit a circle's wall
- **Updated Sunday Summary** — now includes shared gratitude count for the week

### Display Name Storage
- When users sign in with Apple, their display name is now saved to the backend
- Shared gratitudes reference the stored name so circle members see the correct first name

---

## Screens / Views Affected

- **Give Tab (TodayView / GratitudeCheckInView)** — share prompt appears after gratitude completion
- **Share Gratitude Sheet** — new bottom sheet for circle selection, name/anonymous toggle, and sharing
- **Circle Detail Page** — new Gratitude Wall section at top
- **Circles Tab** — golden badge dot for unseen gratitudes
- **Circle Sunday Summary** — updated to include gratitude count
- **Week Look Back** — updated to mention circle gratitude counts

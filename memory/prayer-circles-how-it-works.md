---
name: Prayer Circles — How It Works
description: Comprehensive reference for all Prayer Circle features, data flows, and business logic
type: project
---

# Prayer Circles — How It Works

This document covers the complete behaviour of the Prayer Circles feature as implemented. It is written for product, design, and support use — not as end-user documentation.

---

## 1. Creating and Joining a Circle

### Creating a Circle
- Any signed-in user can create a circle from the Circles tab ("+" button → New Circle).
- Required: a **Circle Name**. Optional: a **Description**.
- On creation the backend (`circleCreate` callable) does three things atomically:
  1. Creates the circle document in `circles/{circleId}` with name, description, memberCount: 1, and a randomly generated invite code.
  2. Writes the invite code to `inviteCodes/{code}` (publicly readable — used for join validation).
  3. Adds the creator as the first member in `circles/{circleId}/members/{userId}` with role: **admin**.
- The creator is always the only admin.

### Joining a Circle
- A user joins by entering an **invite code** (8-character uppercase alphanumeric, e.g. `KA7CR3S3`).
- The backend (`circleJoin` callable) validates that the code exists in `inviteCodes`, then:
  1. Writes a member document for the joining user with role: **member**.
  2. Increments `memberCount` on the circle document.
- If the user is already a member the join is rejected with "You're already a member of this circle."
- Anyone who has the invite code can join — there is no invite-only approval step.

### Leaving a Circle
- Available from the circle detail view.
- The backend (`circleLeave` callable) deletes the member document and decrements `memberCount`.
- Admins can leave — there is currently no restriction preventing the last admin from leaving.

---

## 2. Members

### Who Can See Whom
- All members of a circle can see the **member list** for that circle.
- The member list shows: role (Admin / Member) and the date they joined.
- **Display names are not currently stored in the member document.** The Firestore member document contains only `userId`, `role`, and `joinedAt`. The UI therefore shows a generic "Member" label next to the role. This is a known gap — a future improvement would be to write `displayName` into the member document at join time.

### Roles
- **Admin** — the circle creator. There is currently one admin per circle.
- **Member** — everyone else.
- Admins can update the circle's name and description. Members cannot.

### Removing Members
- There is no client-side remove-member flow. Member removal would require an Admin SDK operation (not currently implemented).

---

## 3. Circle Activity (Collaborative Heatmap)

### What It Shows
The heatmap on the circle detail screen shows **collective faithfulness** — not any individual member's data. Each cell represents a day, coloured by how many members had a strong day.

### How Intensity Is Calculated
- Each member submits their daily habit score via `circleSubmitHeatmapData` (called when they log habits).
- Data is stored in `circles/{circleId}/heatmapEntries/{userId}` as an array of `{date, score}` objects.
- For each day, the app counts:
  - **seenCount** — how many members have any data for that day.
  - **strongCount** — how many of those had a score ≥ 0.5 (i.e. completed at least half their habits).
- **Intensity = strongCount ÷ totalMembers** (where totalMembers is the total member count of the circle, not just those who logged data).
- A day where all members logged a strong score shows full intensity (gold). A day where nobody logged anything shows no intensity.

### Access by Tier
- **Free users**: current week only.
- **Premium users**: full 52-week history.

### Individual Privacy
The heatmap is deliberately aggregated. No member can see another member's individual daily scores — only the collective result.

---

## 4. Gratitude Wall

### How Gratitudes Appear on the Wall
Gratitudes come from **Daily Gratitude check-ins** in the Today view. After a user completes their Daily Gratitude habit, the app shows a prompt: *"Share with your circle?"*

The user can then:
1. Choose which circle(s) to share to (if they're in multiple circles, they pick one or more from a horizontal chip selector).
2. Choose to share **with their name** or **anonymously**.
3. Tap Share.

The `circleShareGratitude` callable then writes a gratitude document to each selected circle's `gratitudes` subcollection.

### What Is Shown on the Wall
- The gratitude text the user wrote during their check-in.
- If sharing with name: their display name (e.g. "Lance: Grateful for my family today").
- If sharing anonymously: "Someone in your circle gave thanks to God today" (or their text prefixed with "Someone in your circle:").
- The time it was shared.
- Posts are ordered newest first.
- Only posts from the past 7 days are shown by default (configurable with `weeksBack` parameter for older history).

### Deleted Gratitudes
- A user can **soft-delete** their own gratitude by tapping a delete option. This sets `deleted: true` on the document — it does not physically remove it.
- Only the author can delete their own gratitude, and only by flipping `deleted` to `true` (Firestore security rules prevent any other field changes).
- Deleted posts are filtered out on read and never shown on the wall.
- Other members cannot delete anyone else's posts.

### What Is NOT on the Gratitude Wall
- No likes, reactions, or comments of any kind.
- No ability for members to respond to a gratitude.

### New Gratitude Badge
- The Circles tab shows a notification dot when there are unread gratitudes in any of the user's circles.
- "Unread" means: gratitudes shared after the user's last `lastSeenAt` timestamp (stored in `circles/{circleId}/userSeenGratitude/{userId}`).
- The badge clears automatically when the user opens the Gratitude Wall (which calls `markGratitudesSeen`).

---

## 5. Circle Milestones

### What They Are
Collective milestones celebrate the circle's shared effort. They are achievements earned as a group, not individually.

### What Is Tracked
The backend maintains a running aggregate in `circles/{circleId}/meta/totals`:
- **totalGivingDays** — total number of member-days where habit data was submitted.
- **totalHours** — total time given across all timed habits across all members.
- **totalGratitudeDays** — total number of member-days where a gratitude was shared to the circle.

These are incremented by the backend callables (`circleSubmitHeatmapData` increments giving days and hours; `circleShareGratitude` increments gratitude days).

### How Milestones Are Triggered
- When a cumulative total crosses a threshold, the backend writes a milestone document to `circles/{circleId}/milestones/{milestoneId}`.
- Milestone thresholds are defined in the backend and evaluated each time new data is submitted.
- Examples: "500 hours given to God together", "100 days of gratitude shared".

### Who Sets the Milestones
**The backend only.** Clients cannot create or modify milestone documents (Firestore security rules block client writes to `/milestones`). They are entirely server-generated.

### Where They Appear
- In the **Circle Milestones** section of the circle detail screen.
- Shows title, message, and the date achieved.
- Also surfaced in the **Weekly Summary** context.

---

## 6. Weekly Summary

### How to Access It
From the circle detail view, tap the "Weekly Summary" row in the Actions section.

### What It Shows
| Field | How It Is Determined |
|---|---|
| **Active members** | Number of circle members who submitted any heatmap data this week |
| **Total members** | The `memberCount` field on the circle document |
| **Average score** | Each active member's weekly average daily score, then averaged across all active members |
| **Gratitude count** | Number of non-deleted gratitudes shared to the circle in the past 7 days |
| **Summary message** | A grace-based phrase based on the average score (see thresholds below) |
| **Scripture** | 1 Thessalonians 5:11 — fixed, always shown |

### Score Message Thresholds
| Average Score | Message |
|---|---|
| ≥ 90% | "Outstanding! Your circle walked in near-perfect faithfulness this week." |
| ≥ 70% | "Strong week! Your circle showed up with consistency and dedication." |
| ≥ 50% | "Good effort! More than half the circle stayed faithful this week." |
| ≥ 30% | "A start! Every small step counts. Encourage each other." |
| < 30% | "A quiet week. Rally together — you're stronger in community." |

### What It Doesn't Show
- Individual member scores or rankings.
- Which members were active vs. inactive.
- Streak or cumulative history — this view is this week only.

---

## 7. SOS Prayer Request

### Access Control
- SOS is a **Premium-only** feature.
- Free users see a paywall when they try to use SOS from the Today view or an abstain card.

### The SOS Flow (Before Sending a Request)
When a user taps the SOS button, the app first shows the **SOS View** — a private, calming screen designed to help in the moment before any prayer request is sent. It contains:

1. **Your Why** — the habit's purpose statement the user wrote, plus the anchor verse for that habit category.
2. **Your Plan for Moments Like This** — the user's coping plan (if they wrote one during habit setup). Sub-header: *"You wrote this when you were strong. Trust that version of yourself."*
3. **A Small Step Right Now** — a category-specific micro-action (e.g. "Pray for 60 seconds. Tell God what you're feeling." for abstain habits). Rotates daily. User can tap "Did it" to mark it complete.
4. **What You're Protecting** — the milestone shield: shows the user's lifetime stat for that habit (consecutive clean days, total hours, total check-ins, etc.) with a personalised grace statement. For abstain habits this shows current streak, total clean days, and how far they are from the next milestone.
5. **Send SOS prayer request** button (if authenticated and in a circle).

### Sending the Prayer Request
- If the user is in **multiple circles**, they first see a circle picker to choose which circle to send to.
- On the **SOS Prayer Request screen**:
  - Optionally write a message (default if blank: "Please pray for me").
  - Select up to **20 recipients** from the circle's member list (excluding yourself).
  - "Select All" option available.
  - Tap "Send SOS Prayer Request".
- The `circleSendSOS` callable writes a request to `circles/{circleId}/sosRequests/{sosId}` and sends an FCM push notification to each selected recipient's device.
- Recipients see the notification on their lock screen/notification tray.

### If Not in a Circle
- If authenticated but not in any circle, the app shows: *"Join or create a Prayer Circle first to send SOS requests."*
- If not signed in, the app prompts sign-in.

---

## 8. Invite

### How Invite Codes Work
- Each circle has one invite code, generated at creation time (8-character uppercase alphanumeric).
- The code is permanent for the lifetime of the circle — there is no code rotation.
- Codes are stored in the public `inviteCodes` collection so the join flow can validate them without authentication.

### Sharing an Invite
From the circle detail view, tap "Share Invite Link". This opens the Invite sheet, which provides two options:

1. **Share Invite** (gold button) — opens the **system share sheet** (native Android/iOS share modal) with the message:
   > *Join my Prayer Circle "[Circle Name]" on Tribute!*
   > *Use invite code: [CODE]*
   > *Download Tribute: https://tribute.app*

   This lets the user share via WhatsApp, iMessage, email, Instagram, etc.

2. **Copy Code** (secondary button) — copies just the raw invite code to the clipboard for pasting manually.

### Who Can Share
Any member of the circle can access the Invite sheet and share the code — not just admins.

---

## 9. Data Access Summary

| Data | Who Can Read | Who Can Write |
|---|---|---|
| Circle document | Members only | Admin (name/description updates) |
| Member list | Members only | Backend only (join/leave) |
| Heatmap entries | All members | Owner of the entry only (and must be a member) |
| Gratitude wall posts | All members | Backend callable (`circleShareGratitude`); owner can soft-delete |
| SOS requests | All members | Backend only (`circleSendSOS`) |
| Milestones | All members | Backend only |
| meta/totals aggregate | All members | Backend only |
| userSeenGratitude | Owner only | Owner only |
| sosContacts | All members | Owner only |
| inviteCodes | Public (anyone) | Backend only |

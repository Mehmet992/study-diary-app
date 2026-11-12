# Study Diary App — Feature Roadmap & UI To-Do List (`TODO.md`)

> These features are queued to be designed and implemented right after we finish integrating the remaining core tech stack (Firebase Auth, Firestore Delta Sync, Crashlytics, and SharedPreferences).

---

## 1. Tech Stack Completion (Current Priority)
- [x] **SharedPreferences Integration:** Persist `lastSyncedAt` timestamp, user preferences (timer style, theme/focus settings).
- [ ] **Firebase Core & Authentication:** Optional user sign-in (Google / Email) so users can back up and restore their study history across devices or reinstalls.
- [ ] **Firebase Cloud Firestore (Cost-Safe Delta Sync):** Connect `RemoteStudyDataSource` to Firestore so only `pendingSync` / `pendingDelete` rows are pushed and only records newer than `lastSyncedAt` are pulled.
- [ ] **Firebase Crashlytics:** Real-time production crash and error reporting.

---

## 2. Upcoming UI & Experience Features (Post-Stack Integration)

### A. Focus Mode While Studying (Deep Concentration Mode)
- [ ] **Dimmed / Low-Light Study Environment:** When a study session starts, dim the screen brightness / transition UI to a deep dark low-glare backdrop.
- [ ] **Minimalist Focus View:** Hide navigation bars, cards, and extra UI elements while the timer is actively running so only the timer (and minimal tap-to-reveal pause/finish controls) is visible, eliminating anything that could break the student's concentration.

### B. Upgraded & Customizable Timer UI
- [ ] **Large Digital Timer Style:** Bold, high-contrast full-width digital clock display.
- [ ] **Circular Ring + Sub-Timer Style:** Large animated circular progress ring (`CustomPainter`) showing remaining/elapsed progress with a secondary small timer underneath (e.g., current Pomodoro set time vs. total session time).
- [ ] **Multiple Timer Skins/Modes:** Allow the user to switch between timer visual styles (Digital vs. Circular Ring).

### C. UI Animations & Custom Brand Mascot
- [ ] **Signature Brand Mascot (Duolingo-style Character):** Design and animate our custom mascot for `CompanionMood` states (`idle`, `studying`, `breakRest`, `finalSetCheer`, `proudCelebration`).
- [ ] **Session End & Transition Animations:** Smooth celebratory animations when a study session completes or when transitioning into/out of a 5-minute Pomodoro break.

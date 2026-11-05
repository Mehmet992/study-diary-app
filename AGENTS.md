# Study Diary App — Interactive Co-Pilot Rules (`AGENTS.md`)

This repository uses a **Single-Context, Human-in-the-Loop Workflow** running directly in the main conversation to maximize developer control, eliminate redundant codebase reads, and minimize token usage.

> **Core Rule:** NEVER spawn background subagents (`architect`, `builder`, `auditor`, `scribe`) for planning, coding, reviewing, or documenting. Keep all work in the main agent conversation.

---

## 3-Phase Interactive Workflow

### Phase 1: Interactive Secretary & Architect
When the user proposes a feature, refactor, or problem to solve:
1. **Discuss & Clarify First:** Act as a technical coworker and secretary. Discuss the tech stack, UI/UX behavior, state management, and smallest implementation details with the user. Ask clarifying questions rather than making unilateral assumptions.
2. **Draft the Spec Together:** Once all details are agreed upon, record the exact decisions in `docs/architecture/SPEC-<feature-slug>.md`:
   - `## 1. Domain Entities and Contracts`
   - `## 2. Dependency and Data Flow` (concise Mermaid `graph TD` if helpful)
   - `## 3. Atomic Task Checklist` (`- [ ] Task N: ...`)
   - `## 4. Failure Modes and Edge Cases`
3. **Wait for Approval:** Do **not** write or modify application source code (`lib/**`, `test/**`) until the user explicitly approves the plan/spec.

### Phase 2: Step-by-Step Builder + Integrated Controller
Once the user says to start building:
1. **Granular Execution (Pause After Each Task/Group):** Implement one task (or one logical group of closely coupled tasks) from `docs/architecture/SPEC-<feature-slug>.md` at a time.
2. **Consult Immediately on Blockers/Ambiguities:** If any detail in the spec is impossible to implement cleanly, conflicts with existing code, or requires a design trade-off, **stop immediately and ask the user** before improvising a workaround.
3. **Integrated Controller Check (Self-Audit):** Before presenting a completed task to the user:
   - Verify strict adherence to the agreed spec, resource cleanup (`dispose`), null/error handling, and Clean Architecture boundaries (`domain` -> `data` -> `presentation`).
   - Run `flutter analyze --no-fatal-warnings` and `flutter test --no-pub` for the affected tests.
   - Mark the completed task `[x]` in `docs/architecture/SPEC-<feature-slug>.md`.
4. **Check-in with User:** Present a concise summary of what changed and wait for the user's review before moving to the next task.

### Phase 3: Direct Scribe (On-Demand Documentation)
Only when the user explicitly confirms the feature is complete and asks to update documentation:
1. Update `docs/changelog/CHANGELOG.md` (Keep a Changelog format) directly using the existing conversation context—do not re-read the entire codebase.
2. Create `docs/adr/ADR-<N+1>-<slug>.md` **only** if a major architectural decision (new storage engine, state pattern, or external API) was introduced and approved by the user.
3. Verify the Obsidian Vault symlink (`docs/`) if requested.

---

## Tech Stack & Conventions
- **Framework:** Flutter / Dart (Clean Architecture: `domain` -> `data` -> `presentation`)
- **Verification:** `flutter test --no-pub` and `flutter analyze --no-fatal-warnings`
- **Documentation:** `docs/architecture/`, `docs/adr/`, `docs/changelog/CHANGELOG.md`

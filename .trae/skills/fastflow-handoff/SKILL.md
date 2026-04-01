---
name: "fastflow-handoff"
description: "Loads FastFlow project handoff context and keeps the handoff doc updated. Invoke when working on the FastFlow iOS app or when project state materially changes."
---

# FastFlow Handoff

Use this skill when the task is about the FastFlow iOS project at:

`/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis`

## Purpose

This skill helps new threads get productive quickly by loading the maintained project handoff doc first, then using it as the baseline for product direction, architecture, and current feature state.

It also adds a close-out habit: before finishing meaningful work, check whether the handoff doc should be updated.

## Required first read

Read this file first:

`/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/project_docs/share_card_growth/worklog.md`

Treat it as the primary project context unless the current code clearly disagrees.

If the code and the doc conflict:
- trust the current code
- then update the handoff doc before you finish the task if the difference matters

## What the handoff doc is expected to cover

The handoff doc should stay useful for a fresh Codex thread. It must keep at least:
- product background and positioning
- current feature state
- free vs Pro boundary
- core product decisions already settled
- major architecture and data-model boundaries
- iCloud sync status and risks
- important growth/share-card context
- key iteration history
- high-priority open issues or risks

## Working routine

### At the start of a task

1. Read the handoff doc.
2. Build a minimal working model of the task from the doc.
3. Open the relevant source files to confirm the current code still matches the documented state.
4. If the task touches user-facing copy, product behavior, monetization, sync, or analytics, assume the handoff doc may need an update at the end.

### During the task

Use the handoff doc to avoid re-litigating settled decisions, especially around:
- lightweight fasting companion positioning
- 5:2 removal
- session-first analytics rules
- free full history
- Pro = ads removal + advanced tools
- local-first architecture with cautious cloud rollout
- avoiding AI-sounding Chinese copy
- never shipping developer-facing or internal process copy in user-visible pages, cards, or websites

### Before finishing a task

Always ask:

`Did this work materially change project background, feature state, product decisions, architecture, sync status, growth direction, or known risks?`

If yes, update the handoff doc.

## When to update the handoff doc

Update the handoff doc when work changes any of these:
- product positioning or scope
- new feature shipped or major feature removed
- free/Pro boundary changed
- analytics or data-model rules changed
- new architecture or storage path introduced
- iCloud or sync status changed
- growth/share-card strategy materially changed
- an important bug/risk was discovered or resolved

Do not update it for tiny UI nits, one-off fixes, or purely mechanical refactors unless they change the practical project state.

## How to update the handoff doc

- Keep it concise and high-signal.
- Prefer durable truths over chronological chatter.
- Fold new knowledge into the existing structure.
- Remove stale statements when they are no longer true.
- Do not turn it into a raw journal.

## Recommended files to inspect after the handoff doc

Open only what the task needs, but these are the common anchors:
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowApp.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowTimerView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowTimerViewModel.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowModels.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/HistoryView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/StatsView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/zh-Hans.lproj/Localizable.strings`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/en.lproj/Localizable.strings`

## Output style guidance

When explaining the project to the user or summarizing work:
- prefer concrete product language over abstract PM jargon
- avoid AI-sounding Chinese phrasing
- assume the user values stability, continuity, and practical product judgment
- be explicit when something is implemented vs only planned
- keep developer reminders, rollout notes, and integration placeholders out of user-facing copy; put them in code comments or handoff docs instead

# Claude (orchestrator) status, 2026-11-25 late evening

Main is pushed at the batch-2 merge + credits (`53714b9`). Orchestration runs through Relay
(`C:\Users\batha\agent-orchestrator`, GitHub `Apoorvabatham/relay-agent-orchestrator`, branch master).
Godot only via `C:\Users\batha\.local\bin\godot-q.cmd` (2 slots, mutex-based since the semaphore deadlock).

## Gate for every branch (do not skip)
1. Read the diff (`git diff main...<branch>`); scope as briefed; no hand-edited data/ (re-run generators,
   expect no diff); no `assets/stage_props/mensa/**.import` churn; no logs/temp files.
2. Look at its renders (visual work).
3. Integrate several branches on `integrate/<batch>` from main, then ONE godot-q run: import,
   build_movesets + build_showdown_roster (expect no data diff), sim_test (`0 failure(s)`),
   capture_screens.gd for a visual check.
4. Merge into main (`--no-ff`), push to origin (owner wants pushes after every green batch).

## Ready for batch 3 (committed, reviewed)
- `relay/xi-banner`: Xi victory lanterns no longer cover the banner (5 lines).
- `relay/story-proof`: story text proofreading (7 files, small).
- `relay/g-hotspot`: Server Farm light 2.8 -> 1.4 (judge on a fight capture).
- `relay/jaw-test` (4120b38): deterministic jaw test via set_voice_frame() hook (inactive in play); suite 0 failure(s) x2.

## In progress (worktree -> what's left)
- `relay/g-style` (agent-worktrees/.../relay_g-style): style clips Jensen/Zuckerbot/Xi, UNCOMMITTED.
  Determinism verified by reading (visual-only). Needs: generators (no diff), balance_sim (40-60%),
  sim_test, commit "[O6] Wire style clips for Jensen, Zuckerbot, Xi". Some startups +4..+6 frames.
- `relay/g-xi-likeness`: Xi round 2 (Opus continuing Gemini's work). MUST revert other fighters' hair
  changes (Jensen approved at 1505752). Needs owner approval of docs/review/likeness/xi_round2.png.
  Branch also carries Jensen's approved likeness: merge after Xi is approved (or cherry-pick 1505752).
- Yann `word_tokens` missing clip `fight/overhead_smash` (Sonnet, worktree under .claude/worktrees).
- Alt-outfit shoes (Sonnet, .claude/worktrees). Dario's red alt outfit is barefoot.
- Relay jobs: docs-refresh (OpenCode), stage-thumbs (OpenCode HY4), senate-desks (OpenCode),
  select-tiles (OpenCode), sound-test (Cline Lightning), title-overlap (Kilo).
- Haiku: read-only balance/smoke/determinism check of main.

## Backlog (next tasks for whichever agent is free)
B1 NPC shoes (build_npcs.gd). B4 normalise new super sound loudness. B5 in-game credits screen.
B6 options menu sanity + tests. B7 first-launch "How to play" screen. B8 beginner-friendly default CPU
difficulty. B9 README screenshots final refresh (after likeness). B10 Windows release build:
`python tools/build_release.py windows` with `GODOT=C:\Users\batha\.local\bin\godot_base_console.exe`
(templates 4.7.2 installed; export allowed 45 min), smoke + determinism.

## Quotas (Relay ~/.relay/quota.json)
Gemini Hydrogen+Flash exhausted until ~00:30; Cline Super VL limited 15 h (Lightning works);
Kilo anonymous quota small; OpenCode free models: up to 4 parallel.

## Owner decisions
Keep real logos/brands. Jensen likeness approved; Xi "more like him" (3D pipeline only, no photoreal
images of real people). No combos. Voices credited as Gemini TTS. Push main after green merges.

# Animation & State Roadmap

## 1. Interaction polish (current focus)
- Goal: head/body taps, long presses, and rapid chase-tail feel consistent in the debug panel.
- Status: turn/dizzy pacing and region detection are in; long press will be repurposed to drag, legacy jaw long-press to be retired.
- Next steps:
  1. Log timing parameters (timePerFrame, max loop duration, cooldowns).
  2. Swap long-press handling for drag-to-move; keep tap head/body interactions.
  3. Document the final gesture timings in PRD/README.

## 2. Idle randomiser
- Goal: cycle light animations (idle, relax, walk, look around) while the pet is idle for long periods.
- Upcoming additions: patrol across full ground area, drag-to-move interaction.
- Plan:
  1. Finalise the action pool: idle (breathing), relax (sway), walk (frames coming tomorrow), optional lookaround.
  2. Define weights and cooldowns, e.g. idle 30%, relax 40%, lookaround 20%, walk 10%, 30 s minimum cooldown per clip.
  3. Add an IdleRandomiser in the ViewModel; trigger every 10-15 s and publish via manualAnimationRequest.
  4. Ensure the manual panel and automation share the same dispatch path so they do not clash.
  5. Add a patrol behavior: free-walk across the ground area of the background, pause at random spots, then blend into other idle clips.

## 3. Data-driven state machine
- Goal: switch the base state (happy / tired / sleep) based on readiness, time of day, and external events.
- Ideas:
  - readiness < 50 -> tired; sleep flag or late night -> sleep.
  - Priority stack: sleep > tired > idle/random; after a forced state finishes, fall back to the idle system.
  - Cooldown low-frequency randoms (grooming, look left/right) to avoid spam.
  - Route every manual trigger (turn/dizzy, head/body touch) through the same event pipeline.
- Steps:
  1. Extract a StateController to track active state and priorities.
  2. Prototype with mock inputs (sliders/buttons).
  3. Hook in the real API once the state machine is stable.

## 4. Day/night timeline (draft)
- Night rules:
  - After 22:00 the pet drifts into tired; 23:00 forces sleep. Taps wake it for about 1 min, then it dozes again.
  - Morning (about 07:00): high readiness -> happy greeting; low readiness -> starts the day tired.
- Daily fatigue:
  - After 18:00 gradually bias towards tired.
  - Training/step gains temporarily boost readiness and refresh mood.

## 5. Events & achievements
- Goal: unify task complete, level up, accessory unlock, etc.
- Plan: create a GameEvent interface; events pipe into the ViewModel -> manualAnimationRequest (e.g. hurray + overlay); ensure compatibility with the state machine so animations return to baseline afterwards.

## 6. watchOS / other targets
- Reuse the model above and strip interactions for watchOS once the iOS flow is proven.

---

## Immediate priorities
1. Fix the long-press -> idle race and capture final gesture timings.
2. Implement the idle random pool (after walk frames are ready).
3. Build the time/state prototype (night fatigue, sleep, morning wake-up with readiness).
4. Consolidate random cooldowns and event handling.

## Notes & open items
- Night rules: 22:00 tired drift; 23:00 forced sleep; interactions wake the pet for about 1 min before it dozes again.
- Morning readiness sets the day mood: good -> happy, poor -> tired baseline.
- Evening fatigue: after 18:00 bias towards tired unless activity lifts readiness.
- Idle pool requires walk frames (pending art update).
- Long-press idle flash bug is high priority.
- Mobile layout: top metrics (readiness/HRV/sleep score circles), middle free-roam pet area, bottom reminder banner.
- Theme system: backgrounds/skins/accessories should be swappable; keep hooks for future room decor.
- Daily mission system: one mission per day, generated from current readiness. If readiness is low next day, pet stays tired unless the user finishes the matching recovery task (e.g., 1 minute mindfulness), which clears fatigue.

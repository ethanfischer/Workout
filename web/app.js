// ----- Tiffin Workout (vanilla JS PWA) -----

const REST_SECONDS = 60;
const RESISTANCE_LEVELS = [
  { value: 1, name: "Extra Light" },
  { value: 2, name: "Light" },
  { value: 3, name: "Medium" },
  { value: 4, name: "Hard" },
  { value: 5, name: "Extra Hard" },
];

const PICK_GUIDANCE = {
  push: { compound: "Pick 2", accessory: "Pick 3" },
  pull: { compound: "Pick 2", accessory: "Pick 3" },
  legs: { compound: "Pick 1-2", unilateral: "Pick 1-2", accessory: "Pick 2" },
  core: { accessory: "Pick 2-3" },
};

const REPS_DISPLAY = {
  push: { compound: "3-4 x 10", accessory: "3 x 10-12" },
  pull: { compound: "3-4 x 10", accessory: "3 x 10-12" },
  legs: { compound: "4 x 10", unilateral: "3 x 10-12", accessory: "3 x 12-15" },
  core: { accessory: "3 x 30s" },
};

const CATEGORY_SUBTITLE = {
  push: "Upper body day - Push (shoulders + chest + triceps)",
  pull: "Upper body day - Pull (back + biceps)",
  legs: "Lower body day",
  core: "Core stability",
};

const TYPE_ORDER = {
  push: ["compound", "accessory"],
  pull: ["compound", "accessory"],
  legs: ["compound", "unilateral", "accessory"],
  core: ["accessory"],
};

const TYPE_NAMES = {
  compound: "Compound",
  unilateral: "Unilateral",
  accessory: "Accessory/Isolation",
};

const DIFFICULTY_EMOJI = ["", "😫", "😕", "😐", "🙂", "😄"];

// ----- Exercise catalog -----

let EXERCISES = { push: [], pull: [], legs: [], core: [] };

async function loadExercises() {
  const res = await fetch("exercises.json");
  EXERCISES = await res.json();
}

function mediaFilename(name) {
  return name.toLowerCase().replace(/ /g, "_").replace(/\//g, "_");
}

const MEDIA_EXTENSIONS = ["gif", "png", "jpg", "jpeg", "webp"];

function exerciseImg(name) {
  const base = `gifs/${mediaFilename(name)}`;
  const img = el("img", {
    src: `${base}.${MEDIA_EXTENSIONS[0]}`,
    onerror: function () {
      const next = (parseInt(this.dataset.extIdx || "0", 10)) + 1;
      if (next < MEDIA_EXTENSIONS.length) {
        this.dataset.extIdx = String(next);
        this.src = `${base}.${MEDIA_EXTENSIONS[next]}`;
      } else {
        this.style.visibility = "hidden";
      }
    },
  });
  return img;
}

function isBanded(name) {
  const n = name.toLowerCase();
  return n.includes("banded") || n.includes("resistance band");
}

function defaultRepsInt(reps) {
  const m = reps.match(/\d+/);
  return m ? parseInt(m[0], 10) : 10;
}

// ----- Storage (localStorage) -----

const STORAGE = {
  WORKOUTS: "tiffin.workouts.v1",
  IN_PROGRESS: "tiffin.inprogress.v1",
};

function loadWorkouts() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE.WORKOUTS) || "[]");
  } catch {
    return [];
  }
}

function saveWorkouts(workouts) {
  localStorage.setItem(STORAGE.WORKOUTS, JSON.stringify(workouts));
}

function addWorkout(workout) {
  const all = loadWorkouts();
  all.unshift(workout);
  saveWorkouts(all);
}

function loadInProgress() {
  try {
    const raw = localStorage.getItem(STORAGE.IN_PROGRESS);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function saveInProgress(state) {
  localStorage.setItem(STORAGE.IN_PROGRESS, JSON.stringify(state));
}

function clearInProgress() {
  localStorage.removeItem(STORAGE.IN_PROGRESS);
}

// ----- Audio (Web Audio API beep) -----

let audioCtx = null;
let beepBuffer = null;

function ensureAudio() {
  if (audioCtx) return audioCtx;
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return null;
  audioCtx = new AC();
  return audioCtx;
}

async function preloadBeep() {
  const ctx = ensureAudio();
  if (!ctx || beepBuffer) return;
  try {
    const res = await fetch("beep.wav");
    const arr = await res.arrayBuffer();
    beepBuffer = await ctx.decodeAudioData(arr);
  } catch {
    // Fall back to synthesized beep
  }
}

function playBeep() {
  const ctx = ensureAudio();
  if (!ctx) return;
  if (ctx.state === "suspended") ctx.resume();

  if (beepBuffer) {
    const src = ctx.createBufferSource();
    src.buffer = beepBuffer;
    src.connect(ctx.destination);
    src.start();
    return;
  }

  // Synthesized fallback: short sine beep
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.frequency.value = 880;
  osc.type = "sine";
  gain.gain.setValueAtTime(0, ctx.currentTime);
  gain.gain.linearRampToValueAtTime(0.3, ctx.currentTime + 0.01);
  gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.15);
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start();
  osc.stop(ctx.currentTime + 0.16);
}

function playTripleBeep() {
  playBeep();
  setTimeout(playBeep, 200);
  setTimeout(playBeep, 400);
}

// ----- Wake Lock -----

let wakeLockSentinel = null;

async function requestWakeLock() {
  if (!("wakeLock" in navigator)) return;
  try {
    wakeLockSentinel = await navigator.wakeLock.request("screen");
    wakeLockSentinel.addEventListener("release", () => {
      wakeLockSentinel = null;
    });
  } catch {
    /* not available */
  }
}

async function releaseWakeLock() {
  if (wakeLockSentinel) {
    try { await wakeLockSentinel.release(); } catch {}
    wakeLockSentinel = null;
  }
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible" && state.screen === "active") {
    requestWakeLock();
    onResumeFromBackground();
  }
});

// ----- Notifications -----

async function requestNotificationPermission() {
  if (!("Notification" in window)) return;
  if (Notification.permission === "default") {
    try { await Notification.requestPermission(); } catch {}
  }
}

let restNotifTimeoutId = null;

function scheduleRestNotification(endTimeMs) {
  cancelRestNotification();
  if (!("Notification" in window) || Notification.permission !== "granted") return;
  const delay = endTimeMs - Date.now();
  if (delay <= 0) return;
  restNotifTimeoutId = setTimeout(() => {
    try {
      new Notification("Rest Complete", { body: "Time for your next set!" });
    } catch {}
    restNotifTimeoutId = null;
  }, delay);
}

function cancelRestNotification() {
  if (restNotifTimeoutId) {
    clearTimeout(restNotifTimeoutId);
    restNotifTimeoutId = null;
  }
}

// ----- App state -----

const state = {
  screen: "home", // home | category | exercises | active | history | detail
  category: null,
  selected: [], // ExerciseDefinition[]

  // active workout
  phase: "warmup", // warmup | exercise | rest | paused | difficulty | complete
  currentExerciseIndex: 0,
  currentSetIndex: 0,
  weight: 0,
  reps: 0,
  completedSets: [], // [[{setNumber, weight, reps}]]
  exerciseDifficulties: {}, // {index: 1..5}

  // timers
  workoutStartTime: null, // ms epoch (excluding paused time)
  pausedAccumulated: 0, // ms accumulated while paused
  pausedAt: null, // ms epoch when pause began
  warmupStartTime: null,

  restEndTime: null, // ms epoch
  pausedRestRemaining: null, // ms remaining when paused

  // detail
  detailWorkout: null,
  showEdit: false,
  editingSet: null, // {ex, set, weight, reps}
  endConfirm: false,

  lastBeepedSecond: null,
};

let tickInterval = null;
const root = document.getElementById("app");

// ----- Helpers -----

function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === "class") node.className = v;
    else if (k === "html") node.innerHTML = v;
    else if (k.startsWith("on") && typeof v === "function") {
      node.addEventListener(k.slice(2).toLowerCase(), v);
    } else if (k === "style" && typeof v === "object") {
      Object.assign(node.style, v);
    } else if (v === true) {
      node.setAttribute(k, "");
    } else if (v !== false && v != null) {
      node.setAttribute(k, v);
    }
  }
  for (const c of children) {
    if (c == null || c === false) continue;
    if (Array.isArray(c)) c.forEach(cc => node.appendChild(typeof cc === "string" ? document.createTextNode(cc) : cc));
    else node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
  }
  return node;
}

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

function formatWeight(weight, banded) {
  if (banded) {
    const lvl = RESISTANCE_LEVELS.find(l => l.value === weight) || RESISTANCE_LEVELS[2];
    return lvl.name;
  }
  return `${Math.round(weight)} lbs`;
}

function elapsedSeconds() {
  if (!state.workoutStartTime) return 0;
  const now = state.pausedAt ?? Date.now();
  return Math.floor((now - state.workoutStartTime - state.pausedAccumulated) / 1000);
}

function warmupSeconds() {
  if (!state.warmupStartTime) return 0;
  return Math.floor((Date.now() - state.warmupStartTime) / 1000);
}

function restSecondsRemaining() {
  if (state.pausedRestRemaining != null) {
    return Math.ceil(state.pausedRestRemaining / 1000);
  }
  if (!state.restEndTime) return 0;
  return Math.max(0, Math.ceil((state.restEndTime - Date.now()) / 1000));
}

function currentExerciseDef() {
  return state.selected[state.currentExerciseIndex] || null;
}

function totalSetsForCurrent() {
  return currentExerciseDef()?.defaultSets ?? 3;
}

// ----- Render -----

function render() {
  root.innerHTML = "";
  const screen = el("div", { class: "screen" });
  switch (state.screen) {
    case "home": renderHome(screen); break;
    case "category": renderCategory(screen); break;
    case "exercises": renderExercises(screen); break;
    case "active": renderActive(screen); break;
    case "history": renderHistory(screen); break;
    case "detail": renderDetail(screen); break;
  }
  root.appendChild(screen);

  if (state.showEdit) renderEditModal();
  if (state.editingSet) renderEditSetModal();
  if (state.endConfirm) renderEndConfirm();
}

// ----- Home -----

function renderHome(container) {
  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "home-title" },
      el("h1", {}, "TIFFIN"),
      el("h2", {}, "WORKOUT")
    ),
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px", display: "flex", flexDirection: "column", gap: "16px", alignItems: "center" } },
      el("button", { class: "btn-primary", onclick: () => navigate("category") }, "START WORKOUT"),
      el("button", { class: "nav-button", style: { color: "var(--pink)", fontSize: "15px", padding: "8px" }, onclick: () => navigate("history") }, "History")
    ),
    el("div", { class: "spacer" })
  );

  // Offer resume if there's an in-progress workout
  const ip = loadInProgress();
  if (ip) {
    container.appendChild(
      el("div", { style: { padding: "16px" } },
        el("button", { class: "btn-secondary", onclick: () => resumeWorkout(ip) }, "Resume in-progress workout")
      )
    );
  }
}

// ----- Category -----

function renderCategory(container) {
  container.append(
    navBar({ left: backButton(() => navigate("home")) }),
    el("div", { class: "section-title" }, "SELECT CATEGORY"),
    el("div", { class: "spacer" }),
    ...["push", "pull", "legs", "core"].map(cat =>
      el("button", { class: "category-button", onclick: () => { state.category = cat; navigate("exercises"); } },
        cat.toUpperCase())
    ),
    el("div", { class: "spacer" })
  );
}

// ----- Exercise selection -----

function renderExercises(container) {
  const cat = state.category;
  const types = TYPE_ORDER[cat];

  container.append(
    navBar({ left: backButton(() => { state.selected = []; navigate("category"); }) }),
    el("div", { class: "section-title" }, "WORKOUT BUILDER"),
    el("div", { class: "subtitle" }, CATEGORY_SUBTITLE[cat]),
  );

  const scroll = el("div", { style: { flex: "1", overflowY: "auto", padding: "0 4px" } });
  for (const type of types) {
    const list = EXERCISES[cat].filter(e => e.type === type);
    if (list.length === 0) continue;
    scroll.appendChild(typeSection(type, cat, list));
  }
  container.appendChild(scroll);

  const startDisabled = state.selected.length === 0;
  container.appendChild(
    el("div", { style: { padding: "12px 0 0" } },
      el("button", {
        class: "btn-primary" + (startDisabled ? " disabled" : ""),
        disabled: startDisabled,
        onclick: () => { if (!startDisabled) startWorkout(); }
      }, `START WORKOUT (${state.selected.length})`)
    )
  );
}

function typeSection(type, cat, list) {
  return el("div", { class: "type-section" },
    el("div", { class: "type-header" },
      el("div", {}, "TYPE"),
      el("div", {}, "EXERCISE"),
      el("div", { style: { textAlign: "right" } }, "REPS")
    ),
    el("div", { class: "type-body" },
      el("div", { class: "type-label" },
        el("div", { class: "type-name" }, TYPE_NAMES[type]),
        el("div", { class: "type-hint" }, PICK_GUIDANCE[cat][type] || "")
      ),
      el("div", { class: "exercise-list" },
        ...list.map(ex => {
          const idx = state.selected.findIndex(s => s.name === ex.name);
          const selected = idx >= 0;
          return el("button", {
            class: "exercise-row" + (selected ? " selected" : ""),
            onclick: () => toggleSelected(ex)
          },
            el("span", { class: "check-box" }, selected ? String(idx + 1) : ""),
            exerciseImg(ex.name),
            el("span", { class: "name" }, ex.name)
          );
        })
      ),
      el("div", { class: "reps-display" }, REPS_DISPLAY[cat][type] || "")
    )
  );
}

function toggleSelected(ex) {
  const i = state.selected.findIndex(s => s.name === ex.name);
  if (i >= 0) state.selected.splice(i, 1);
  else state.selected.push({ ...ex });
  render();
}

// ----- Active workout -----

function startWorkout() {
  state.phase = "warmup";
  state.currentExerciseIndex = 0;
  state.currentSetIndex = 0;
  state.completedSets = state.selected.map(() => []);
  state.exerciseDifficulties = {};
  state.workoutStartTime = null;
  state.pausedAccumulated = 0;
  state.pausedAt = null;
  state.warmupStartTime = Date.now();
  state.restEndTime = null;
  state.pausedRestRemaining = null;
  requestNotificationPermission();
  preloadBeep();
  requestWakeLock();
  navigate("active");
  startTick();
}

function startTick() {
  if (tickInterval) clearInterval(tickInterval);
  tickInterval = setInterval(onTick, 250);
}

function stopTick() {
  if (tickInterval) clearInterval(tickInterval);
  tickInterval = null;
}

function onTick() {
  if (state.screen !== "active") return;
  if (state.phase === "rest") {
    const remaining = restSecondsRemaining();
    if (remaining <= 3 && remaining > 0 && state.lastBeepedSecond !== remaining) {
      state.lastBeepedSecond = remaining;
      playBeep();
    }
    if (remaining <= 0) {
      state.lastBeepedSecond = null;
      playTripleBeep();
      endRest();
      return;
    }
  }
  render();
}

function onResumeFromBackground() {
  // When tab returns to foreground, recompute and possibly end rest immediately
  if (state.phase === "rest" && restSecondsRemaining() <= 0) {
    playTripleBeep();
    endRest();
  } else {
    render();
  }
}

function renderActive(container) {
  if (state.phase === "complete") { renderComplete(container); return; }
  if (state.phase === "warmup") { renderWarmup(container); return; }

  container.appendChild(navBar({
    left: state.phase === "paused" ? null : el("button", {
      class: "nav-button", onclick: togglePause
    }, pauseIcon()),
    title: el("span", { class: "timer-medium" }, formatTime(elapsedSeconds())),
    right: el("span", { class: "nav-button", style: { fontSize: "13px", color: "var(--text-secondary)" } },
      `${state.currentExerciseIndex + 1} of ${state.selected.length}`)
  }));

  if (state.phase === "paused") return renderPaused(container);
  if (state.phase === "difficulty") return renderDifficulty(container);
  if (state.phase === "rest") return renderRest(container);
  renderExerciseSet(container);
}

function renderWarmup(container) {
  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "label-big" }, "WARMUP"),
    el("div", { class: "timer-large" }, formatTime(warmupSeconds())),
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px 24px" } },
      el("button", { class: "btn-primary", onclick: endWarmup }, "END WARMUP")
    )
  );
}

function endWarmup() {
  state.warmupStartTime = null;
  state.workoutStartTime = Date.now();
  state.phase = "exercise";
  initializeExerciseDefaults();
  render();
}

function renderExerciseSet(container) {
  const ex = currentExerciseDef();
  if (!ex) return;
  const banded = isBanded(ex.name);
  const lastSets = getLastWorkoutSets(ex.name);
  const completedThis = state.completedSets[state.currentExerciseIndex] || [];

  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "media-container" },
      exerciseImg(ex.name)
    ),
    el("div", { style: { display: "flex", flexDirection: "column", gap: "4px" } },
      el("div", { class: "exercise-name" }, ex.name),
      el("div", { class: "set-info" }, `Set ${state.currentSetIndex + 1} of ${totalSetsForCurrent()}`)
    ),
  );

  if (lastSets && lastSets.length > 0) {
    container.appendChild(lastTimeBox(lastSets, completedThis, banded));
  }

  container.append(
    el("div", { class: "spacer" }),
    weightStepper(ex, banded),
    repsStepper(),
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px 24px" } },
      el("button", { class: "btn-primary", onclick: completeSet }, "COMPLETE SET")
    )
  );
}

function lastTimeBox(lastSets, completedThis, banded) {
  const rows = lastSets.map(set => {
    const setIdx = set.setNumber - 1;
    const isCurrent = state.currentSetIndex === setIdx;
    const done = setIdx < completedThis.length;
    const children = [
      el("span", { class: isCurrent ? "" : "muted" }, `Set ${set.setNumber}:`),
      el("span", {}, `${formatWeight(set.weight, banded)} x ${set.reps}`),
    ];
    if (done) {
      const cd = completedThis[setIdx];
      children.push(
        el("span", { class: "muted" }, "→"),
        el("span", { class: "done" }, `${formatWeight(cd.weight, banded)} x ${cd.reps}`),
        el("span", { class: "done" }, "✓")
      );
    }
    return el("div", { class: "row" + (isCurrent ? " current" : " muted") }, ...children);
  });
  return el("div", { class: "last-time" },
    el("div", { class: "label" }, "LAST TIME"),
    ...rows
  );
}

function weightStepper(ex, banded) {
  return el("div", { class: "stepper-block" },
    el("div", { class: "label" }, banded ? "RESISTANCE" : "WEIGHT"),
    el("div", { class: "stepper" },
      stepperButton(false, () => adjustWeight(-1, banded)),
      el("div", { class: "value" }, formatWeight(state.weight, banded)),
      stepperButton(true, () => adjustWeight(+1, banded))
    )
  );
}

function repsStepper() {
  return el("div", { class: "stepper-block" },
    el("div", { class: "label" }, "REPS"),
    el("div", { class: "stepper" },
      stepperButton(false, () => { if (state.reps > 0) { state.reps--; render(); } }),
      el("div", { class: "value" }, String(state.reps)),
      stepperButton(true, () => { state.reps++; render(); })
    )
  );
}

function stepperButton(plus, onclick) {
  const svg = plus
    ? `<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="11"/><path d="M12 7v10M7 12h10" stroke="black" stroke-width="2" stroke-linecap="round"/></svg>`
    : `<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="11"/><path d="M7 12h10" stroke="black" stroke-width="2" stroke-linecap="round"/></svg>`;
  return el("button", { onclick, html: svg });
}

function adjustWeight(dir, banded) {
  if (banded) {
    const idx = RESISTANCE_LEVELS.findIndex(l => l.value === state.weight);
    const cur = idx >= 0 ? idx : 2;
    const next = Math.min(RESISTANCE_LEVELS.length - 1, Math.max(0, cur + dir));
    state.weight = RESISTANCE_LEVELS[next].value;
  } else {
    state.weight = Math.max(0, state.weight + dir * 5);
  }
  render();
}

function initializeExerciseDefaults() {
  const ex = currentExerciseDef();
  if (!ex) return;
  const banded = isBanded(ex.name);
  const last = getLastSetData(ex.name, state.currentSetIndex);
  if (last) {
    state.weight = last.weight;
    state.reps = last.reps;
  } else {
    state.weight = banded ? 3 : 0;
    state.reps = defaultRepsInt(ex.defaultReps);
  }
}

function getLastWorkoutSets(exerciseName) {
  const all = loadWorkouts();
  for (const w of all) {
    const ex = (w.exercises || []).find(e => e.name === exerciseName);
    if (ex) return [...ex.sets].sort((a, b) => a.setNumber - b.setNumber);
  }
  return null;
}

function getLastSetData(exerciseName, setIndex) {
  const last = getLastWorkoutSets(exerciseName);
  if (!last) return null;
  return last[setIndex] || last[last.length - 1] || null;
}

function completeSet() {
  const set = { setNumber: state.currentSetIndex + 1, weight: state.weight, reps: state.reps };
  state.completedSets[state.currentExerciseIndex].push(set);

  if (state.currentSetIndex + 1 >= totalSetsForCurrent()) {
    state.phase = "difficulty";
    render();
  } else {
    startRest();
  }
  persistInProgress();
}

function startRest() {
  state.phase = "rest";
  state.restEndTime = Date.now() + REST_SECONDS * 1000;
  state.pausedRestRemaining = null;
  state.lastBeepedSecond = null;
  scheduleRestNotification(state.restEndTime);
  render();
}

function endRest() {
  cancelRestNotification();
  state.restEndTime = null;
  state.pausedRestRemaining = null;

  if (state.currentSetIndex + 1 >= totalSetsForCurrent()) {
    state.currentExerciseIndex++;
    state.currentSetIndex = 0;
    initializeExerciseDefaults();
  } else {
    state.currentSetIndex++;
    const ex = currentExerciseDef();
    const last = getLastSetData(ex.name, state.currentSetIndex);
    if (last) { state.weight = last.weight; state.reps = last.reps; }
  }
  state.phase = "exercise";
  persistInProgress();
  render();
}

function renderRest(container) {
  const remaining = restSecondsRemaining();
  const nextName = getNextLabel();
  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "label-big" }, "REST"),
    el("div", { class: "timer-large" }, formatTime(remaining)),
    nextName ? el("div", { class: "set-info" }, `Next: ${nextName}`) : null,
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px 24px" } },
      el("button", { class: "btn-secondary", onclick: () => {
        cancelRestNotification();
        endRest();
      } }, "SKIP REST")
    )
  );
}

function getNextLabel() {
  if (state.currentSetIndex + 1 >= totalSetsForCurrent()) {
    const nx = state.selected[state.currentExerciseIndex + 1];
    return nx ? nx.name : null;
  }
  const ex = currentExerciseDef();
  return `${ex.name} - Set ${state.currentSetIndex + 2}`;
}

function renderPaused(container) {
  const hasAny = state.completedSets.some(s => s.length > 0);
  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "label-big" }, "PAUSED"),
    el("div", { class: "timer-large", style: { color: "var(--text-secondary)" } }, formatTime(elapsedSeconds())),
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px 24px", display: "flex", flexDirection: "column", gap: "16px" } },
      el("button", {
        class: "btn-secondary" + (hasAny ? "" : " disabled"),
        disabled: !hasAny,
        onclick: () => { if (hasAny) { state.showEdit = true; render(); } }
      }, "EDIT WORKOUT"),
      el("button", { class: "btn-primary", onclick: togglePause }, "RESUME"),
      el("button", { class: "btn-danger", onclick: () => { state.endConfirm = true; render(); } }, "End Workout")
    )
  );
}

function togglePause() {
  if (state.phase === "paused") {
    // Resume
    if (state.pausedAt) {
      state.pausedAccumulated += Date.now() - state.pausedAt;
      state.pausedAt = null;
    }
    if (state.pausedRestRemaining != null) {
      state.restEndTime = Date.now() + state.pausedRestRemaining;
      state.pausedRestRemaining = null;
      scheduleRestNotification(state.restEndTime);
      state.phase = "rest";
    } else {
      state.phase = "exercise";
    }
  } else {
    // Pause
    state.pausedAt = Date.now();
    if (state.phase === "rest") {
      state.pausedRestRemaining = Math.max(0, state.restEndTime - Date.now());
      state.restEndTime = null;
      cancelRestNotification();
    }
    state.phase = "paused";
  }
  persistInProgress();
  render();
}

function renderDifficulty(container) {
  const ex = currentExerciseDef();
  container.append(
    el("div", { class: "spacer" }),
    el("div", { style: { textAlign: "center" } },
      el("div", { class: "label-big" }, "HOW DID THAT FEEL?"),
      el("div", { class: "set-info", style: { marginTop: "8px" } }, ex?.name || "")
    ),
    el("div", { class: "difficulty-row" },
      ...[1,2,3,4,5].map(r =>
        el("button", { onclick: () => submitDifficulty(r) }, DIFFICULTY_EMOJI[r])
      )
    ),
    el("div", { class: "spacer" })
  );
}

function submitDifficulty(rating) {
  state.exerciseDifficulties[state.currentExerciseIndex] = rating;
  if (state.currentExerciseIndex + 1 >= state.selected.length) {
    finishWorkout();
  } else {
    startRest();
  }
  persistInProgress();
}

function renderComplete(container) {
  const duration = elapsedSeconds();
  container.append(
    el("div", { class: "spacer" }),
    el("div", { class: "label-big" }, "WORKOUT COMPLETE"),
    el("div", { style: { textAlign: "center", marginTop: "8px" } },
      el("div", { style: { fontSize: "17px", fontWeight: "600" } }, `${capitalize(state.category)} Day`),
      el("div", { class: "set-info" }, `${state.selected.length} exercises`),
      el("div", { class: "set-info" }, `${Math.floor(duration / 60)} min`)
    ),
    el("div", { style: { background: "var(--surface)", borderRadius: "12px", padding: "16px", margin: "16px" } },
      ...state.selected.map((ex, i) => el("div", { style: { marginBottom: "12px" } },
        el("div", { style: { fontWeight: "600", marginBottom: "4px" } }, ex.name),
        ...(state.completedSets[i] || []).map(s =>
          el("div", { style: { fontSize: "12px", color: "var(--text-secondary)" } },
            `Set ${s.setNumber}: ${formatWeight(s.weight, isBanded(ex.name))} x ${s.reps}`)
        )
      ))
    ),
    el("div", { class: "spacer" }),
    el("div", { style: { padding: "0 24px 24px" } },
      el("button", { class: "btn-primary", onclick: () => navigate("history") }, "DONE")
    )
  );
}

function finishWorkout() {
  const workout = {
    id: uuid(),
    date: new Date().toISOString(),
    category: state.category,
    durationSeconds: elapsedSeconds(),
    exercises: state.selected.map((ex, i) => ({
      name: ex.name,
      order: i,
      difficultyRating: state.exerciseDifficulties[i] ?? null,
      sets: state.completedSets[i] || [],
    })),
  };
  addWorkout(workout);
  clearInProgress();
  releaseWakeLock();
  stopTick();
  state.phase = "complete";
  render();
}

function savePartialWorkout() {
  const hasAny = state.completedSets.some(s => s.length > 0);
  if (!hasAny) return;
  const workout = {
    id: uuid(),
    date: new Date().toISOString(),
    category: state.category,
    durationSeconds: elapsedSeconds(),
    exercises: state.selected.map((ex, i) => ({
      name: ex.name,
      order: i,
      difficultyRating: state.exerciseDifficulties[i] ?? null,
      sets: state.completedSets[i] || [],
    })).filter(e => e.sets.length > 0),
  };
  addWorkout(workout);
}

function endWorkoutAfterConfirm(save) {
  if (save) savePartialWorkout();
  clearInProgress();
  releaseWakeLock();
  cancelRestNotification();
  stopTick();
  state.endConfirm = false;
  navigate("history");
}

// ----- History -----

function renderHistory(container) {
  container.append(navBar({
    left: backButton(() => navigate("home")),
    title: el("span", {}, "History"),
  }));
  const all = loadWorkouts();
  if (all.length === 0) {
    container.appendChild(
      el("div", { class: "history-empty" },
        el("div", { style: { fontWeight: "600", color: "var(--text)" } }, "No workouts yet"),
        el("div", {}, "Complete a workout to see it here")
      )
    );
    return;
  }
  const scroll = el("div", { style: { flex: "1", overflowY: "auto" } });
  for (const w of all) {
    scroll.appendChild(
      el("button", {
        class: "history-card",
        onclick: () => { state.detailWorkout = w; navigate("detail"); }
      },
        el("div", { class: "date" }, formatDateShort(w.date)),
        el("div", { class: "meta" }, `${capitalize(w.category)} Day • ${w.exercises.length} exercises`),
        el("div", { class: "duration" }, `${Math.floor(w.durationSeconds / 60)} min`)
      )
    );
  }
  container.appendChild(scroll);
}

function renderDetail(container) {
  const w = state.detailWorkout;
  if (!w) { navigate("history"); return; }
  container.append(
    navBar({ left: backButton(() => navigate("history")) }),
    el("div", { class: "detail-header" },
      el("div", { class: "date" }, formatDateShort(w.date)),
      el("div", { class: "cat" }, `${capitalize(w.category)} Day`),
      el("div", { class: "dur" }, `${Math.floor(w.durationSeconds / 60)} min`)
    )
  );
  const scroll = el("div", { style: { flex: "1", overflowY: "auto" } });
  const sorted = [...w.exercises].sort((a, b) => a.order - b.order);
  for (const ex of sorted) {
    const banded = isBanded(ex.name);
    const setsSorted = [...ex.sets].sort((a, b) => a.setNumber - b.setNumber);
    scroll.appendChild(
      el("div", { class: "detail-exercise" },
        el("div", { class: "name" },
          ex.name,
          ex.difficultyRating ? el("span", {}, DIFFICULTY_EMOJI[ex.difficultyRating]) : null
        ),
        ...setsSorted.map(s =>
          el("div", { class: "set" },
            el("span", { class: "set-label" }, `Set ${s.setNumber}:`),
            `${formatWeight(s.weight, banded)} x ${s.reps}`
          )
        )
      )
    );
  }
  container.appendChild(scroll);
}

// ----- Modals -----

function renderEditModal() {
  const overlay = el("div", { class: "modal-backdrop", onclick: (e) => {
    if (e.target === overlay) { state.showEdit = false; render(); }
  } });
  const sheet = el("div", { class: "modal-sheet" });
  sheet.appendChild(el("div", { style: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" } },
    el("div", { style: { fontWeight: "600", fontSize: "17px" } }, "Edit Workout"),
    el("button", { class: "nav-button", style: { color: "var(--pink)" }, onclick: () => { state.showEdit = false; render(); } }, "Done")
  ));
  state.selected.forEach((ex, ei) => {
    const sets = state.completedSets[ei] || [];
    if (sets.length === 0) return;
    sheet.appendChild(el("div", { class: "section-label-list" }, ex.name.toUpperCase()));
    sets.forEach((set, si) => {
      sheet.appendChild(
        el("button", {
          class: "set-edit-row",
          onclick: () => {
            state.editingSet = { ex: ei, set: si, weight: set.weight, reps: set.reps };
            render();
          }
        },
          el("span", {}, `Set ${set.setNumber}`),
          el("span", { class: "meta" }, `${formatWeight(set.weight, isBanded(ex.name))} x ${set.reps}`),
          el("span", { class: "chev" }, "›")
        )
      );
    });
  });
  overlay.appendChild(sheet);
  document.body.appendChild(overlay);
}

function renderEditSetModal() {
  const { ex: ei, set: si } = state.editingSet;
  const ex = state.selected[ei];
  const banded = isBanded(ex.name);

  const overlay = el("div", { class: "modal-backdrop", onclick: (e) => {
    if (e.target === overlay) { state.editingSet = null; render(); }
  } });
  const sheet = el("div", { class: "modal-sheet" });

  function adjustEditWeight(dir) {
    if (banded) {
      const idx = RESISTANCE_LEVELS.findIndex(l => l.value === state.editingSet.weight);
      const cur = idx >= 0 ? idx : 2;
      const next = Math.min(RESISTANCE_LEVELS.length - 1, Math.max(0, cur + dir));
      state.editingSet.weight = RESISTANCE_LEVELS[next].value;
    } else {
      state.editingSet.weight = Math.max(0, state.editingSet.weight + dir * 5);
    }
    render();
  }

  sheet.append(
    el("div", { style: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" } },
      el("button", { class: "nav-button", style: { color: "var(--pink)" }, onclick: () => { state.editingSet = null; render(); } }, "Cancel"),
      el("div", { style: { fontWeight: "600", fontSize: "17px" } }, `Edit Set ${si + 1}`),
      el("div", { style: { width: "60px" } })
    ),
    el("div", { class: "stepper-block", style: { marginTop: "24px" } },
      el("div", { class: "label" }, banded ? "RESISTANCE" : "WEIGHT"),
      el("div", { class: "stepper" },
        stepperButton(false, () => adjustEditWeight(-1)),
        el("div", { class: "value" }, formatWeight(state.editingSet.weight, banded)),
        stepperButton(true, () => adjustEditWeight(+1))
      )
    ),
    el("div", { class: "stepper-block", style: { marginTop: "24px" } },
      el("div", { class: "label" }, "REPS"),
      el("div", { class: "stepper" },
        stepperButton(false, () => { if (state.editingSet.reps > 0) { state.editingSet.reps--; render(); } }),
        el("div", { class: "value" }, String(state.editingSet.reps)),
        stepperButton(true, () => { state.editingSet.reps++; render(); })
      )
    ),
    el("div", { style: { marginTop: "32px" } },
      el("button", { class: "btn-primary", onclick: () => {
        state.completedSets[ei][si].weight = state.editingSet.weight;
        state.completedSets[ei][si].reps = state.editingSet.reps;
        state.editingSet = null;
        persistInProgress();
        render();
      } }, "SAVE")
    )
  );
  overlay.appendChild(sheet);
  document.body.appendChild(overlay);
}

function renderEndConfirm() {
  const overlay = el("div", { class: "alert-backdrop" });
  overlay.appendChild(
    el("div", { class: "alert" },
      el("div", { class: "alert-body" },
        el("div", { class: "title" }, "End Workout?"),
        el("div", { class: "msg" }, "Would you like to save your progress so far?")
      ),
      el("div", { class: "alert-buttons" },
        el("button", { onclick: () => endWorkoutAfterConfirm(true) }, "Save & Exit"),
        el("button", { class: "destructive", onclick: () => endWorkoutAfterConfirm(false) }, "Discard"),
        el("button", { onclick: () => { state.endConfirm = false; render(); } }, "Cancel")
      )
    )
  );
  document.body.appendChild(overlay);
}

// ----- Nav helpers -----

function navBar({ left, title, right } = {}) {
  return el("div", { class: "nav-bar" },
    el("div", { class: "nav-left" }, left || ""),
    el("div", { class: "nav-title" }, title || ""),
    el("div", { class: "nav-right" }, right || "")
  );
}

function backButton(onclick) {
  return el("button", { class: "nav-button", onclick }, "‹ Back");
}

function pauseIcon() {
  return "❚❚";
}

function navigate(screen) {
  if (state.screen === "active" && screen !== "active") {
    stopTick();
    releaseWakeLock();
  }
  state.screen = screen;
  render();
}

// ----- In-progress persistence -----

function persistInProgress() {
  if (state.screen !== "active") return;
  if (state.phase === "complete") return;
  saveInProgress({
    category: state.category,
    exerciseNames: state.selected.map(e => e.name),
    phase: state.phase,
    currentExerciseIndex: state.currentExerciseIndex,
    currentSetIndex: state.currentSetIndex,
    weight: state.weight,
    reps: state.reps,
    completedSets: state.completedSets,
    exerciseDifficulties: state.exerciseDifficulties,
    workoutStartTime: state.workoutStartTime,
    pausedAccumulated: state.pausedAccumulated,
    pausedAt: state.pausedAt,
    restEndTime: state.restEndTime,
    pausedRestRemaining: state.pausedRestRemaining,
    savedAt: Date.now(),
  });
}

function resumeWorkout(ip) {
  const cat = ip.category;
  const allForCat = EXERCISES[cat] || [];
  state.category = cat;
  state.selected = ip.exerciseNames
    .map(n => allForCat.find(e => e.name === n))
    .filter(Boolean);
  state.completedSets = ip.completedSets || state.selected.map(() => []);
  state.exerciseDifficulties = ip.exerciseDifficulties || {};
  state.currentExerciseIndex = ip.currentExerciseIndex;
  state.currentSetIndex = ip.currentSetIndex;
  state.weight = ip.weight;
  state.reps = ip.reps;
  state.workoutStartTime = ip.workoutStartTime;
  state.pausedAccumulated = ip.pausedAccumulated || 0;
  state.pausedAt = ip.pausedAt;
  state.phase = ip.phase;

  // Adjust rest timer for elapsed time
  if (ip.phase === "rest" && ip.restEndTime) {
    if (Date.now() >= ip.restEndTime) {
      // Rest already done
      state.restEndTime = null;
      endRestImmediate();
    } else {
      state.restEndTime = ip.restEndTime;
      state.pausedRestRemaining = null;
      scheduleRestNotification(ip.restEndTime);
    }
  } else if (ip.pausedRestRemaining != null) {
    state.pausedRestRemaining = ip.pausedRestRemaining;
  }

  requestWakeLock();
  preloadBeep();
  navigate("active");
  startTick();
}

function endRestImmediate() {
  cancelRestNotification();
  state.restEndTime = null;
  state.pausedRestRemaining = null;
  if (state.currentSetIndex + 1 >= totalSetsForCurrent()) {
    state.currentExerciseIndex++;
    state.currentSetIndex = 0;
    initializeExerciseDefaults();
  } else {
    state.currentSetIndex++;
    initializeExerciseDefaults();
  }
  state.phase = "exercise";
}

// ----- Utilities -----

function uuid() {
  if (crypto.randomUUID) return crypto.randomUUID();
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, c => {
    const r = Math.random() * 16 | 0;
    return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
  });
}

function formatDateShort(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

function capitalize(s) {
  return s ? s[0].toUpperCase() + s.slice(1) : "";
}

// ----- Bootstrap -----

(async function init() {
  await loadExercises();
  if ("serviceWorker" in navigator) {
    try { await navigator.serviceWorker.register("service-worker.js"); } catch {}
  }
  render();
})();

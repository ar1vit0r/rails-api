"use strict";

// API origin: localhost when opened locally, production when hosted. Override with ?api=<url>
// ponytail: no config file, add one if more settings appear.
const LOCAL = ["localhost", "127.0.0.1", ""].includes(location.hostname);
const API = new URLSearchParams(location.search).get("api") ?? (LOCAL ? "http://localhost:3000" : "https://rails-api-zm3n.onrender.com");
const TOKEN_KEY = "rack.token";

const STATUSES = [
  { key: "todo", empty: "Nothing waiting. Add a task above." },
  { key: "in_progress", empty: "Nothing in progress. Start a task from To do." },
  { key: "done", empty: "Finished tasks land here." },
];
const PRIORITIES = ["Low", "Normal", "High", "Urgent"];
const MOVES = {
  todo: [{ to: "in_progress", label: "Start" }],
  in_progress: [{ to: "done", label: "Finish" }, { to: "todo", label: "Put back" }],
  done: [{ to: "todo", label: "Reopen" }],
};
const statusIndex = (key) => STATUSES.findIndex((s) => s.key === key);

const state = { token: null, user: null, tasks: [], categories: [], q: "", cat: "", tab: "in_progress", arrived: null };

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);
const isMobile = () => matchMedia("(max-width: 959px)").matches;

const storage = {
  get: (k) => { try { return localStorage.getItem(k); } catch { return null; } },
  set: (k, v) => { try { localStorage.setItem(k, v); } catch { /* private mode: stay signed in for this page only */ } },
  remove: (k) => { try { localStorage.removeItem(k); } catch { /* see above */ } },
};

// Builds an element. All text goes through textContent, never innerHTML.
function h(tag, props = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === "role" || k.startsWith("aria-") || k.startsWith("data-")) el.setAttribute(k, v);
    else el[k] = v;
  }
  el.append(...kids);
  return el;
}

async function api(path, { method = "GET", body } = {}) {
  let res;
  try {
    res = await fetch(`${API}/api/v1${path}`, {
      method,
      headers: { "Content-Type": "application/json", ...(state.token && { Authorization: `Bearer ${state.token}` }) },
      body: body && JSON.stringify(body),
    });
  } catch {
    throw new Error(`Can't reach the API at ${API}. Check that the server is running.`);
  }
  if (res.status === 401 && state.token) {
    signOut("Session expired. Sign in again.");
    throw new Error("Session expired.");
  }
  const data = res.status === 204 ? null : await res.json().catch(() => null);
  if (!res.ok) throw new Error(data?.errors?.join(", ") || data?.error || `Request failed (${res.status}).`);
  return data;
}

const flash = (msg) => { $("#notice").textContent = msg; };
async function run(fn) {
  flash("");
  try { await fn(); } catch (e) { flash(e.message); }
}

/* Auth */

async function auth(kind) {
  const f = $("#login-form");
  if (!f.reportValidity()) return;
  $("#login-error").textContent = "";
  try {
    const body = { email: f.elements.email.value, password: f.elements.password.value };
    if (kind === "register") body.password_confirmation = body.password;
    const { token, user } = await api(`/${kind}`, { method: "POST", body });
    Object.assign(state, { token, user });
    storage.set(TOKEN_KEY, token);
    f.reset();
    enter();
  } catch (e) {
    $("#login-error").textContent = e.message;
  }
}

function signOut(message = "") {
  Object.assign(state, { token: null, user: null, tasks: [], arrived: null });
  storage.remove(TOKEN_KEY);
  $("#board").hidden = true;
  $("#login").hidden = false;
  $("#login-error").textContent = message;
}

async function enter() {
  $("#login").hidden = true;
  $("#board").hidden = false;
  await run(async () => {
    state.user ??= await api("/me");
    $("#who").textContent = state.user.email;
    [state.tasks, state.categories] = await Promise.all([api("/tasks"), api("/categories")]);
    fillCategories();
    render();
  });
}

/* Board */

function fillCategories() {
  const form = $("#new-form");
  $("#filter-cat").replaceChildren(
    h("option", { value: "", textContent: "All categories" }),
    ...state.categories.map((c) => h("option", { value: c.name, textContent: c.name })),
  );
  $("#filter-cat").value = state.cat;
  form.elements.category.replaceChildren(...state.categories.map((c) => h("option", { value: c.id, textContent: c.name })));
  const none = state.categories.length === 0;
  for (const el of form.elements) el.disabled = none;
  $("#new-hint").textContent = none ? "No categories yet. Run bin/rails db:seed to create them." : "";
}

const byPriority = (a, b) => b.priority - a.priority || new Date(b.updated_at) - new Date(a.updated_at);

// ponytail: filtering runs client-side over the full task list, move to the ?q= API filter if lists get large.
function matches(t) {
  const q = state.q.trim().toLowerCase();
  return (!state.cat || t.category === state.cat) && (!q || `${t.title} ${t.description ?? ""}`.toLowerCase().includes(q));
}

function render() {
  const filtering = state.cat || state.q.trim();
  for (const { key, empty } of STATUSES) {
    const tasks = state.tasks.filter((t) => t.status === key && matches(t)).sort(byPriority);
    $(`#list-${key}`).replaceChildren(
      ...(tasks.length ? tasks.map(strip) : [h("li", { className: "empty", textContent: filtering ? "No matching tasks." : empty })]),
    );
    $$(`[data-count="${key}"]`).forEach((el) => { el.textContent = tasks.length; });
    $(`#bay-${key}`).dataset.active = String(key === state.tab);
    $(`[data-tab="${key}"]`).setAttribute("aria-pressed", String(key === state.tab));
  }
  state.arrived = null;
}

function strip(t) {
  const arrived = state.arrived?.id === t.id;
  const li = h("li", { className: `strip${arrived ? " arrived" : ""}` });
  li.dataset.status = t.status;
  li.dataset.priority = t.priority;
  if (arrived) li.style.setProperty("--from", `${-state.arrived.dir * 40}px`);

  const bars = h("div", { role: "group", "aria-label": "Priority", className: "bars" });
  PRIORITIES.forEach((label, i) => bars.append(h("button", {
    type: "button",
    className: `bar${i <= t.priority ? " on" : ""}`,
    title: label,
    "aria-label": `Set priority to ${label}`,
    "aria-pressed": String(i === t.priority),
    onclick: () => setPriority(t, i),
  })));

  const del = h("button", { type: "button", className: "del", textContent: "Delete" });
  del.onclick = () => {
    if (del.classList.contains("armed")) return remove(t);
    del.classList.add("armed");
    del.textContent = "Confirm delete";
    setTimeout(() => { del.classList.remove("armed"); del.textContent = "Delete"; }, 3000);
  };

  li.append(
    ...(t.status === "done" ? [h("span", { className: "check", "aria-hidden": "true" })] : []),
    h("h3", { className: "title", textContent: t.title }),
    bars,
    h("p", { className: "meta", textContent: `${t.category}, ${PRIORITIES[t.priority]} priority` }),
    ...(t.description ? [h("p", { className: "desc", textContent: t.description, title: t.description })] : []),
    h("div", { className: "actions" },
      ...MOVES[t.status].map((m, i) => h("button", {
        type: "button",
        className: i ? "btn" : "btn primary",
        textContent: m.label,
        onclick: () => move(t, m.to),
      })),
      del),
  );
  return li;
}

const replaceTask = (next) => {
  state.tasks = state.tasks.map((x) => (x.id === next.id ? next : x));
  render();
};

const move = (t, to) => run(async () => {
  const next = await api(`/tasks/${t.id}`, { method: "PATCH", body: { status: to } });
  state.arrived = { id: t.id, dir: statusIndex(to) - statusIndex(t.status) };
  if (isMobile()) state.tab = to;
  replaceTask(next);
});

const setPriority = (t, priority) => priority === t.priority || run(async () => {
  replaceTask(await api(`/tasks/${t.id}`, { method: "PATCH", body: { priority } }));
});

const remove = (t) => run(async () => {
  await api(`/tasks/${t.id}`, { method: "DELETE" });
  state.tasks = state.tasks.filter((x) => x.id !== t.id);
  render();
});

/* Wiring */

$("#new-form").elements.priority.replaceChildren(
  ...PRIORITIES.map((p, i) => h("option", { value: i, textContent: p, selected: i === 1 })),
);

$("#login-form").addEventListener("submit", (e) => { e.preventDefault(); auth("login"); });
$("#register").addEventListener("click", () => auth("register"));
$("#signout").addEventListener("click", () => signOut());
$("#search").addEventListener("input", (e) => { state.q = e.target.value; render(); });
$("#filter-cat").addEventListener("change", (e) => { state.cat = e.target.value; render(); });
$$("[data-tab]").forEach((b) => b.addEventListener("click", () => { state.tab = b.dataset.tab; render(); }));

$("#new-form").addEventListener("submit", (e) => {
  e.preventDefault();
  const f = e.target;
  const title = f.elements.title.value.trim();
  if (!title) return flash("Enter a task title.");
  run(async () => {
    const task = await api("/tasks", {
      method: "POST",
      body: { title, category_id: f.elements.category.value, priority: Number(f.elements.priority.value), status: "todo" },
    });
    state.tasks.push(task);
    state.tab = "todo";
    f.elements.title.value = "";
    render();
    f.elements.title.focus();
  });
});

state.token = storage.get(TOKEN_KEY);
if (state.token) enter(); else signOut();

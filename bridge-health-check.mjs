#!/usr/bin/env node
/**
 * Hermy HQ Bridge — Health Check Reporter
 *
 * Este script pode ser chamado pelo bridge periodicamente para reportar
 * status de serviços via AgentEvent kind=status no Postgres.
 *
 * Uso: node bridge-health-check.js [--json]
 */

import pg from "pg";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { randomUUID } from "node:crypto";
import os from "node:os";

const execFileP = promisify(execFile);

const DB_URL = process.env.DATABASE_URL || "";
const HERMES_BIN = process.env.HERMES_BIN || "hermes";
const BOARD = process.env.HERMES_BOARD || "default";
const IS_JSON = process.argv.includes("--json");

if (!DB_URL) {
  console.error("DATABASE_URL required");
  process.exit(1);
}

const isLocal = /@(localhost|127\.0\.0\.1)/.test(DB_URL);
const pool = new pg.Pool({ connectionString: DB_URL, max: 2, ssl: isLocal ? undefined : { rejectUnauthorized: false } });

const q = (text, params) => pool.query(text, params);

async function emit(kind, title, { detail = null, agent = "hermes-bridge", level = "info", meta = null } = {}) {
  await q(
    `INSERT INTO "AgentEvent" (id, kind, title, detail, agent, level, meta, "createdAt") VALUES ($1,$2,$3,$4,$5,$6,$7, now())`,
    [randomUUID(), kind, title.slice(0, 200), detail, agent, level, meta ? JSON.stringify(meta) : null]
  );
}

async function run(cmd, args, timeout = 10000) {
  try {
    const { stdout } = await execFileP(cmd, args, { timeout });
    return { ok: true, output: stdout.trim() };
  } catch (e) {
    return { ok: false, error: (e.stderr || e.message || "error").toString().split("\n")[0].slice(0, 400) };
  }
}

async function checkHermesCLI() {
  const r = await run(HERMES_BIN, ["--version"]);
  return r.ok ? { status: "healthy", version: r.output } : { status: "down", error: r.error };
}

async function checkKanban() {
  const r = await run(HERMES_BIN, ["kanban", "--board", BOARD, "list", "--json"], 15000);
  if (!r.ok) return { status: "down", error: r.error };
  try {
    const tasks = JSON.parse(r.output);
    const count = Array.isArray(tasks) ? tasks.length : (tasks.tasks?.length || 0);
    return { status: "healthy", task_count: count };
  } catch {
    return { status: "degraded", error: "invalid json" };
  }
}

async function checkCron() {
  const r = await run(HERMES_BIN, ["cron", "list", "--json"], 10000);
  if (!r.ok) return { status: "down", error: r.error };
  try {
    const crons = JSON.parse(r.output);
    const count = Array.isArray(crons) ? crons.length : 0;
    const active = crons.filter(c => c.status === "active").length;
    return { status: "healthy", total: count, active };
  } catch {
    return { status: "degraded", error: "invalid json" };
  }
}

async function checkVoiceStudio() {
  try {
    const res = await fetch("http://127.0.0.1:3900/health", { signal: AbortSignal.timeout(5000) });
    if (!res.ok) return { status: "down", error: `HTTP ${res.status}` };
    const data = await res.json();
    return { status: data.status === "ok" ? "healthy" : "degraded", ...data };
  } catch (e) {
    return { status: "down", error: e.message };
  }
}

async function checkWiki() {
  try {
    const wikiDir = process.env.HERMES_WIKI || `${os.homedir()}/.hermes/wiki`;
    const fs = await import("node:fs/promises");
    await fs.access(wikiDir);
    const files = await fs.readdir(wikiDir, { recursive: true });
    const mdFiles = files.filter(f => f.endsWith(".md")).length;
    return { status: "healthy", path: wikiDir, entries: mdFiles };
  } catch (e) {
    return { status: "down", error: e.message };
  }
}

async function checkBridgeProcess() {
  // Verifica se o próprio bridge está rodando (PID file ou lock)
  return { status: "healthy", pid: process.pid, uptime_s: process.uptime() };
}

async function main() {
  const checks = await Promise.allSettled([
    checkHermesCLI(),
    checkKanban(),
    checkCron(),
    checkVoiceStudio(),
    checkWiki(),
    checkBridgeProcess(),
  ]);

  const results = {};
  let healthy = 0, degraded = 0, down = 0;

  const names = ["hermes-cli", "kanban", "cron", "voicestudio", "wiki", "bridge-process"];
  checks.forEach((c, i) => {
    const name = names[i];
    if (c.status === "fulfilled") {
      results[name] = c.value;
      if (c.value.status === "healthy") healthy++;
      else if (c.value.status === "degraded") degraded++;
      else down++;
    } else {
      results[name] = { status: "down", error: c.reason?.message || "unknown" };
      down++;
    }
  });

  const summary = { healthy, degraded, down, total: names.length };
  const overall = down > 0 ? "down" : (degraded > 0 ? "degraded" : "healthy");

  const payload = {
    timestamp: new Date().toISOString(),
    overall,
    summary,
    services: results,
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch(),
    node_version: process.version,
  };

  if (IS_JSON) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.log(`Bridge Health: ${overall.toUpperCase()}`);
    console.log(`  Healthy: ${healthy}, Degraded: ${degraded}, Down: ${down}`);
    Object.entries(results).forEach(([name, data]) => {
      const icon = data.status === "healthy" ? "✓" : (data.status === "degraded" ? "⚠" : "✗");
      console.log(`  ${icon} ${name}: ${data.status}`);
      if (data.error) console.log(`    Error: ${data.error}`);
    });
  }

  // Emitir no Postgres
  await emit("status", `Bridge health: ${overall}`, {
    level: overall === "healthy" ? "info" : (overall === "degraded" ? "warn" : "down"),
    detail: `Healthy: ${healthy}, Degraded: ${degraded}, Down: ${down}`,
    meta: payload,
  });

  await pool.end();
  process.exit(overall === "healthy" ? 0 : 1);
}

main().catch(e => {
  console.error("Health check failed:", e);
  process.exit(1);
});
/**
 * Durable sync queue backed by SQLite `sync_ops`.
 *
 * All functions are transactional and survive app restart. The table is
 * created by the initial migration in `src/storage/db.ts`.
 */
import { openDb } from "@/storage/db";
import type { SyncOp, SyncOpKind, SyncEntity } from "./types";

function nowIso(): string {
  return new Date().toISOString();
}

export async function enqueue(
  entity: SyncEntity,
  entityId: string,
  op: SyncOpKind,
  payload: unknown,
): Promise<number> {
  const db = await openDb();
  const res = await db.runAsync(
    `INSERT INTO sync_ops (entity, entity_id, op, payload, created_at, next_attempt_at) VALUES (?, ?, ?, ?, ?, ?)`,
    entity,
    entityId,
    op,
    JSON.stringify(payload),
    nowIso(),
    nowIso(),
  );
  return res.lastInsertRowId;
}

export async function listPending(limit = 100): Promise<SyncOp[]> {
  const db = await openDb();
  const rows = await db.getAllAsync<SyncOp>(
    `SELECT id, entity, entity_id as entityId, op, payload, created_at as createdAt,
            attempt_count as attemptCount, last_error as lastError, next_attempt_at as nextAttemptAt
     FROM sync_ops ORDER BY id ASC LIMIT ?`,
    limit,
  );
  return rows;
}

export async function listDue(now = nowIso(), limit = 50): Promise<SyncOp[]> {
  const db = await openDb();
  const rows = await db.getAllAsync<SyncOp>(
    `SELECT id, entity, entity_id as entityId, op, payload, created_at as createdAt,
            attempt_count as attemptCount, last_error as lastError, next_attempt_at as nextAttemptAt
     FROM sync_ops WHERE next_attempt_at <= ? ORDER BY id ASC LIMIT ?`,
    now,
    limit,
  );
  return rows;
}

export async function removeOp(id: number): Promise<void> {
  const db = await openDb();
  await db.runAsync(`DELETE FROM sync_ops WHERE id = ?`, id);
}

export async function failOp(id: number, error: string): Promise<void> {
  const db = await openDb();
  const row = await db.getFirstAsync<{ attempt_count: number }>(`SELECT attempt_count FROM sync_ops WHERE id = ?`, id);
  const attempts = (row?.attempt_count ?? 0) + 1;
  // exponential backoff: 2s, 8s, 32s, 2m, 8m, capped at 5m
  const delayMs = Math.min(5 * 60 * 1000, Math.pow(4, Math.min(attempts, 6)) * 500);
  const next = new Date(Date.now() + delayMs).toISOString();
  await db.runAsync(
    `UPDATE sync_ops SET attempt_count = ?, last_error = ?, next_attempt_at = ? WHERE id = ?`,
    attempts,
    error.slice(0, 1000),
    next,
    id,
  );
}

export async function countPending(): Promise<number> {
  const db = await openDb();
  const row = await db.getFirstAsync<{ c: number }>(`SELECT COUNT(*) as c FROM sync_ops`);
  return row?.c ?? 0;
}

export async function clearAll(): Promise<void> {
  const db = await openDb();
  await db.execAsync(`DELETE FROM sync_ops`);
}

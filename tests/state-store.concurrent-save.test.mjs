import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'

import { StateStore } from '../lib/state-store.mjs'

test('StateStore.save supports concurrent calls without ENOENT races', async (t) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'openfox-state-race-'))
  t.after(async () => {
    await fs.rm(dir, { recursive: true, force: true }).catch(() => {})
  })

  const stateFile = path.join(dir, 'state.json')
  const store = new StateStore(stateFile)
  const baseState = {
    offset: null,
    chats: {},
    settings: { model: null },
    usage: { total: 0, input: 0, output: 0, reasoning: 0 }
  }

  const writes = Array.from({ length: 100 }, (_, index) => {
    const state = {
      ...baseState,
      offset: index,
      chats: {
        [String(index)]: {
          sessionId: `session-${index}`,
          updatedAt: new Date().toISOString(),
          usage: { total: index, input: index, output: index, reasoning: index }
        }
      }
    }
    return store.save(state)
  })

  const results = await Promise.allSettled(writes)
  const rejected = results.filter((result) => result.status === 'rejected')
  assert.equal(rejected.length, 0, `expected no save failures, got ${rejected.length}`)
})

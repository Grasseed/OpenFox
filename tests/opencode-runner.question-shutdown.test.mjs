import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'

import { OpencodeRunner } from '../lib/opencode-runner.mjs'

function isProcessAlive(pid) {
  try {
    process.kill(pid, 0)
    return true
  } catch {
    return false
  }
}

async function sleep(ms) {
  await new Promise((resolve) => setTimeout(resolve, ms))
}

test('OpencodeRunner force-kills question flow child process if SIGTERM is ignored', async (t) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'openfox-question-stop-'))
  const fakeOpencode = path.join(dir, 'fake-opencode.mjs')
  const pidFile = path.join(dir, 'pid.txt')

  t.after(async () => {
    await fs.rm(dir, { recursive: true, force: true }).catch(() => {})
  })

  await fs.writeFile(
    fakeOpencode,
    `#!/usr/bin/env node
import fs from 'node:fs'
const args = process.argv.slice(2)

if (args[0] === 'run') {
  fs.writeFileSync(${JSON.stringify(pidFile)}, String(process.pid))
  process.on('SIGTERM', () => {})
  console.log(JSON.stringify({
    type: 'question',
    part: { questions: [{ question: 'Pick one', options: [{ label: 'A' }] }] }
  }))
  setInterval(() => {}, 1000)
}
`
  )
  await fs.chmod(fakeOpencode, 0o755)

  const runner = new OpencodeRunner({
    opencodeBin: fakeOpencode,
    opencodeWorkdir: process.cwd(),
    opencodeTimeoutMs: 5_000,
    opencodeModel: '',
    opencodeVariant: '',
    opencodeAgent: '',
    projectRoot: process.cwd()
  })

  const result = await runner.run({ message: 'hello', sessionId: null, chatId: 1 })
  assert.ok(result.question)

  const pid = Number((await fs.readFile(pidFile, 'utf8')).trim())
  assert.ok(Number.isFinite(pid) && pid > 0)

  let terminated = false
  for (let i = 0; i < 30; i += 1) {
    if (!isProcessAlive(pid)) {
      terminated = true
      break
    }
    await sleep(100)
  }

  if (!terminated && isProcessAlive(pid)) {
    process.kill(pid, 'SIGKILL')
  }

  assert.equal(terminated, true, `expected child process ${pid} to be terminated`)
})

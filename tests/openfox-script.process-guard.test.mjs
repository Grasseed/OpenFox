import test from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { spawn } from 'node:child_process'
import { promisify } from 'node:util'
import { execFile as execFileCb } from 'node:child_process'

const execFile = promisify(execFileCb)

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

function isRunning(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return false
  try {
    process.kill(pid, 0)
    return true
  } catch {
    return false
  }
}

async function waitForExit(pid, timeoutMs = 4000) {
  const started = Date.now()
  while (Date.now() - started < timeoutMs) {
    if (!isRunning(pid)) return true
    await new Promise((resolve) => setTimeout(resolve, 100))
  }
  return !isRunning(pid)
}

async function setupTempProject() {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'openfox-script-'))
  const scriptsDir = path.join(root, 'scripts')
  const openfoxPath = path.join(scriptsDir, 'openfox.sh')

  await fs.mkdir(scriptsDir, { recursive: true })
  await fs.copyFile(path.resolve('scripts/openfox.sh'), openfoxPath)
  await fs.chmod(openfoxPath, 0o755)

  await fs.writeFile(path.join(root, 'telegram-bot.mjs'), 'setInterval(() => {}, 1000)\n')
  await fs.writeFile(path.join(root, 'telegram-webhook-handler.mjs'), 'setInterval(() => {}, 1000)\n')
  await fs.writeFile(
    path.join(root, 'package.json'),
    JSON.stringify({ name: 'openfox-script-test', private: true, scripts: { start: 'node telegram-bot.mjs' } }),
  )

  return { root, openfoxPath }
}

function spawnDetachedBot(cwd) {
  const child = spawn(process.execPath, ['telegram-bot.mjs'], {
    cwd,
    stdio: 'ignore',
    detached: true,
  })
  child.unref()
  return child.pid
}

async function runOpenfox(projectRoot, ...args) {
  const { stdout, stderr } = await execFile('bash', [path.join(projectRoot, 'scripts', 'openfox.sh'), ...args], {
    cwd: projectRoot,
    env: {
      ...process.env,
      PATH: process.env.PATH || '/usr/bin:/bin:/usr/sbin:/sbin',
    },
    maxBuffer: 10 * 1024 * 1024,
  })
  return { stdout, stderr }
}

test('start -d blocks duplicate launch when a bot process already runs in same project', async (t) => {
  const { root } = await setupTempProject()
  const pid = spawnDetachedBot(root)

  t.after(async () => {
    if (isRunning(pid)) process.kill(pid, 'SIGKILL')
    await fs.rm(root, { recursive: true, force: true })
  })

  assert.equal(isRunning(pid), true)

  const { stdout } = await runOpenfox(root, 'start', '-d')
  assert.match(stdout, /OpenFox is already running/) 

  const pidFile = path.join(root, 'openfox.pid')
  assert.equal(await exists(pidFile), false, 'expected start guard to avoid creating pid file')
  assert.equal(isRunning(pid), true, 'existing process should still be running')
})

test('stop terminates pid-file process and orphan bot processes from the same project', async (t) => {
  const { root } = await setupTempProject()
  const pid1 = spawnDetachedBot(root)
  const pid2 = spawnDetachedBot(root)
  const pidFile = path.join(root, 'openfox.pid')

  t.after(async () => {
    if (isRunning(pid1)) process.kill(pid1, 'SIGKILL')
    if (isRunning(pid2)) process.kill(pid2, 'SIGKILL')
    await fs.rm(root, { recursive: true, force: true })
  })

  await fs.writeFile(pidFile, `${pid1}\n`)
  assert.equal(isRunning(pid1), true)
  assert.equal(isRunning(pid2), true)

  await runOpenfox(root, 'stop')

  assert.equal(await waitForExit(pid1), true, 'pid file process should be stopped')
  assert.equal(await waitForExit(pid2), true, 'orphan process should be stopped')
  assert.equal(await exists(pidFile), false, 'pid file should be removed')
})

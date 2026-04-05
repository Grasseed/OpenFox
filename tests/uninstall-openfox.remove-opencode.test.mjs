import test from 'node:test'
import assert from 'node:assert/strict'
import os from 'node:os'
import path from 'node:path'
import { promisify } from 'node:util'
import { execFile as execFileCb } from 'node:child_process'
import fs from 'node:fs/promises'

const execFile = promisify(execFileCb)

async function exists(filePath) {
  try {
    await fs.access(filePath)
    return true
  } catch {
    return false
  }
}

test('uninstall script removes remaining opencode binary left by self-uninstall', async () => {
  const tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'openfox-uninstall-'))
  const homeDir = path.join(tempRoot, 'home')
  const targetDir = path.join(homeDir, 'OpenFox')
  const launcherPath = path.join(homeDir, '.local', 'bin', 'openfox')
  const opencodeBinDir = path.join(homeDir, '.opencode', 'bin')
  const opencodeBinPath = path.join(opencodeBinDir, 'opencode')
  const scriptPath = path.resolve('scripts/uninstall-openfox.sh')

  await fs.mkdir(path.join(targetDir, 'scripts'), { recursive: true })
  await fs.mkdir(path.dirname(launcherPath), { recursive: true })
  await fs.mkdir(opencodeBinDir, { recursive: true })
  await fs.writeFile(path.join(homeDir, '.zshrc'), '')
  await fs.writeFile(path.join(homeDir, '.bash_profile'), '')
  await fs.writeFile(path.join(homeDir, '.bashrc'), '')

  await fs.writeFile(path.join(targetDir, 'scripts', 'openfox.sh'), '#!/usr/bin/env bash\n')
  await fs.writeFile(
    launcherPath,
    `#!/usr/bin/env bash\nexec \"${targetDir}/scripts/openfox.sh\" \"$@\"\n`,
  )

  await fs.writeFile(
    opencodeBinPath,
    '#!/usr/bin/env bash\nif [[ "${1:-}" == "uninstall" ]]; then\n  echo "mock opencode uninstall"\n  exit 0\nfi\nexit 0\n',
  )
  await fs.chmod(opencodeBinPath, 0o755)

  const env = {
    ...process.env,
    HOME: homeDir,
    OPENFOX_UNINSTALL_YES: 'yes',
    OPENFOX_UNINSTALL_REMOVE_OPENCODE: 'yes',
    OPENFOX_UNINSTALL_LANG: 'en',
    PATH: `${opencodeBinDir}:/usr/bin:/bin`,
  }

  await execFile('bash', [scriptPath, targetDir], {
    cwd: path.resolve('.'),
    env,
    maxBuffer: 10 * 1024 * 1024,
  })

  assert.equal(await exists(opencodeBinPath), false, 'expected opencode binary to be removed')
})

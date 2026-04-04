import { execSync } from 'node:child_process'
import { loadConfig } from './lib/config.mjs'
import { TelegramOpencodeBot } from './lib/bot-service.mjs'

async function main() {
  try {
    execSync('pkill -f "opencode run.*--format json"', { stdio: 'ignore' })
    console.log('[startup] killed orphaned opencode processes')
  } catch {
    // pkill exits 1 when no matching processes — that's fine
  }

  const config = loadConfig()
  const bot = new TelegramOpencodeBot(config)

  const shutdown = () => {
    bot.opencode.kill()
    process.exit(0)
  }
  process.on('SIGTERM', shutdown)
  process.on('SIGINT', shutdown)

  const info = await bot.init()

  console.log(`[startup] bot @${info.username} (${info.first_name})`)
  console.log(`[startup] state file: ${config.stateFile}`)
  console.log(`[startup] opencode workdir: ${config.opencodeWorkdir}`)
  console.log('[startup] polling Telegram for updates')

  await bot.startPolling()
}

main().catch((error) => {
  console.error('[fatal]', error)
  process.exitCode = 1
})

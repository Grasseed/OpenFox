import assert from 'node:assert/strict'
import test from 'node:test'

import { TelegramOpencodeBot } from '../lib/bot-service.mjs'

function createBotForHandleUpdateTests() {
  const bot = new TelegramOpencodeBot({
    stateFile: '/tmp/openfox-unused-state.json',
    botToken: 'dummy',
    opencodeBin: 'opencode',
    opencodeWorkdir: process.cwd(),
    opencodeTimeoutMs: 1000,
    pollTimeoutSeconds: 1,
    pollRetryDelayMs: 1,
    runOnce: true,
    deleteWebhookOnStart: false,
    skipPendingUpdatesOnStart: false,
    allowGroups: true,
    opencodeModel: '',
    opencodeVariant: 'medium',
    opencodeAgent: '',
    projectRoot: process.cwd()
  })

  bot.state = {
    offset: null,
    chats: {},
    settings: { model: null },
    usage: { total: 0, input: 0, output: 0, reasoning: 0 }
  }

  const savedOffsets = []
  bot.stateStore = {
    save: async (state) => {
      savedOffsets.push(state.offset)
    }
  }
  bot.enqueueChat = async (_chatId, task) => task()
  bot.telegram = { sendText: async () => {}, sendChatAction: async () => {} }

  return { bot, savedOffsets }
}

const update = {
  update_id: 10,
  message: { chat: { id: 42, type: 'private' }, from: { is_bot: false }, text: 'hello' }
}

test('handleUpdate does not advance offset when message processing fails', async () => {
  const { bot, savedOffsets } = createBotForHandleUpdateTests()
  bot.processMessage = async () => {
    throw new Error('simulated processing failure')
  }

  await assert.rejects(() => bot.handleUpdate(update), /simulated processing failure/)
  assert.equal(bot.state.offset, null)
  assert.deepEqual(savedOffsets, [])
})

test('handleUpdate advances offset after successful message processing', async () => {
  const { bot, savedOffsets } = createBotForHandleUpdateTests()
  bot.processMessage = async () => {}

  await bot.handleUpdate(update)
  assert.equal(bot.state.offset, 11)
  assert.deepEqual(savedOffsets, [11])
})

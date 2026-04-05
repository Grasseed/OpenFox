import { execFile } from 'node:child_process'
import os from 'node:os'
import path from 'node:path'

const DEFAULT_LMS_BIN = path.join(os.homedir(), '.lmstudio', 'bin', 'lms')
const DEFAULT_BASE_URL = 'http://127.0.0.1:1234'

/**
 * Manages LM Studio model loading via both the `lms` CLI and the REST API.
 *
 * Why?  OpenFox passes `--model lmstudio/<id>` to opencode which forwards the
 * request to LM Studio.  If the model is not already loaded, LM Studio's
 * auto-load may fail with "Operation canceled" when another large model is
 * occupying GPU memory.  This client explicitly unloads the old model and
 * loads the new one *before* opencode runs.
 */
export class LmStudioClient {
  constructor(options = {}) {
    this.lmsBin = options.lmsBin || process.env.LMS_BIN || DEFAULT_LMS_BIN
    this.baseURL = (options.baseURL || process.env.LMSTUDIO_BASE_URL || DEFAULT_BASE_URL).replace(/\/+$/, '')
    this.timeoutMs = options.timeoutMs ?? 120_000
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /**
   * Return the list of models known to LM Studio together with their state
   * (`loaded` | `not-loaded`).  Uses the REST API so it works even when the
   * `lms` CLI is missing.
   */
  async listModels() {
    try {
      const data = await this._apiGet('/api/v0/models')
      const models = Array.isArray(data) ? data : (data?.data ?? [])
      return models.map((m) => ({
        id: m.id,
        state: m.state || 'unknown'
      }))
    } catch {
      return []
    }
  }

  /**
   * Return the id of the currently loaded model, or `null` if nothing is
   * loaded.  When multiple models are loaded the first one wins.
   */
  async getLoadedModelId() {
    const models = await this.listModels()
    const loaded = models.find((m) => m.state === 'loaded')
    return loaded?.id ?? null
  }

  /**
   * Ensure `modelId` (the LM Studio identifier, **without** the `lmstudio/`
   * opencode prefix) is loaded.  If a different model is loaded it is unloaded
   * first.
   *
   * Returns `{ changed: boolean, loaded: string|null }`.
   */
  async ensureModelLoaded(modelId) {
    if (!modelId) return { changed: false, loaded: null }

    const currentlyLoaded = await this.getLoadedModelId()
    if (currentlyLoaded === modelId) {
      return { changed: false, loaded: modelId }
    }

    // Unload whatever is loaded right now.
    if (currentlyLoaded) {
      console.log(`[lmstudio] unloading current model: ${currentlyLoaded}`)
      await this._lmsExec(['unload', '--all']).catch((err) => {
        console.warn('[lmstudio] unload warning:', err.message)
      })
    }

    // Load the requested model.
    console.log(`[lmstudio] loading model: ${modelId}`)
    await this._lmsExec(['load', modelId, '--gpu', 'max', '-y'])

    // Verify.
    const newLoaded = await this.getLoadedModelId()
    if (newLoaded !== modelId) {
      throw new Error(`LM Studio failed to load "${modelId}" (currently loaded: ${newLoaded ?? 'none'})`)
    }

    console.log(`[lmstudio] model ready: ${modelId}`)
    return { changed: true, loaded: modelId }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /**
   * Strip the `lmstudio/` opencode provider prefix to get the bare model id
   * that LM Studio understands.
   */
  static toLocalId(opencodeModelName) {
    if (!opencodeModelName) return ''
    return opencodeModelName.startsWith('lmstudio/')
      ? opencodeModelName.slice('lmstudio/'.length)
      : ''
  }

  /**
   * Returns `true` when the model name looks like an LM Studio model
   * (`lmstudio/...`).
   */
  static isLmStudioModel(opencodeModelName) {
    return typeof opencodeModelName === 'string' && opencodeModelName.startsWith('lmstudio/')
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /** Run an `lms` CLI sub-command and return stdout. */
  _lmsExec(args) {
    return new Promise((resolve, reject) => {
      const child = execFile(this.lmsBin, args, { timeout: this.timeoutMs }, (error, stdout, stderr) => {
        if (error) {
          const msg = (stderr || stdout || error.message).trim()
          reject(new Error(`lms ${args.join(' ')} failed: ${msg}`))
          return
        }
        resolve(stdout.trim())
      })
      // Prevent the timer from keeping the process alive.
      if (child.unref) child.unref()
    })
  }

  /** Simple GET against the LM Studio REST API. */
  async _apiGet(endpoint) {
    const url = `${this.baseURL}${endpoint}`
    const res = await fetch(url, { signal: AbortSignal.timeout(10_000) })
    if (!res.ok) throw new Error(`LM Studio API ${endpoint}: ${res.status}`)
    return res.json()
  }
}

import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case traditionalChinese = "zh-TW"
    case simplifiedChinese = "zh-CN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Auto"
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

@MainActor
final class LocaleManager: ObservableObject {
    static let shared = LocaleManager()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
            resolveActive()
        }
    }

    private(set) var activeLanguage: AppLanguage = .english

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        language = AppLanguage(rawValue: saved) ?? .system
        resolveActive()
    }

    private func resolveActive() {
        if language == .system {
            activeLanguage = Self.detectSystemLanguage()
        } else {
            activeLanguage = language
        }
    }

    private static func detectSystemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") {
            return .traditionalChinese
        } else if preferred.hasPrefix("zh-Hans") || preferred.hasPrefix("zh-CN") || preferred.hasPrefix("zh-SG") {
            return .simplifiedChinese
        }
        return .english
    }

    func t(_ key: L10nKey) -> String {
        return L10n.string(key, language: activeLanguage)
    }
}

enum L10nKey {
    // Sidebar / Navigation
    case navDashboard, navConfiguration, navLogs, navUsage
    case statusRunning, statusStopped
    case btnStart, btnStop, btnRestart, btnReload, btnSave, btnClear, btnChange
    case btnOpen, btnQuit

    // Dashboard
    case dashTitle, dashSubtitle
    case dashBotRunning, dashBotStopped
    case dashBotRunningDesc, dashBotStoppedDesc
    case dashUptime, dashReloadConfig, dashReloadConfigSub
    case dashStartSub, dashStopSub
    case dashRecentActivity, dashNoActivity, dashEntries

    // Configuration
    case cfgTitle, cfgSubtitle
    case cfgProject, cfgProjectDir
    case cfgTelegram, cfgBotToken, cfgAllowGroups, cfgSkipPending
    case cfgShow, cfgHide, cfgNotConfigured
    case cfgModel, cfgModelLabel, cfgVariant, cfgPermission
    case cfgAdvanced, cfgPollTimeout, cfgOcTimeout, cfgWebhookPort, cfgDeleteWebhook
    case cfgSaved, cfgSavedMsg
    case cfgProvider, cfgSelectProvider, cfgSelectModel, cfgLoadingModels, cfgCustomModel
    case cfgVariantLow, cfgVariantMedium, cfgVariantHigh
    case cfgPermAsk, cfgPermAllow

    // Logs
    case logsTitle, logsSubtitle, logsFilter, logsAll
    case logsAutoScroll

    // Usage
    case usageTitle, usageSubtitle, usageRefresh
    case usageTotalTokens, usageSessions, usageBreakdown
    case usageInput, usageOutput, usageReasoning
    case usageCurrentConfig, usageModel, usageVariant, usagePermission, usageGroups
    case usageDefault, usageAllowed, usagePrivateOnly

    // Menu bar
    case menuOpenWindow, menuQuit, menuStart, menuStop, menuRestart
    case menuUptime, menuTokens

    // Language
    case settingsLanguage
}

struct L10n {
    static func string(_ key: L10nKey, language: AppLanguage) -> String {
        switch language {
        case .traditionalChinese: return zhTW[key] ?? en[key] ?? "\(key)"
        case .simplifiedChinese: return zhCN[key] ?? en[key] ?? "\(key)"
        default: return en[key] ?? "\(key)"
        }
    }

    // MARK: - English
    static let en: [L10nKey: String] = [
        .navDashboard: "Dashboard",
        .navConfiguration: "Configuration",
        .navLogs: "Logs",
        .navUsage: "Usage",
        .statusRunning: "Running",
        .statusStopped: "Stopped",
        .btnStart: "Start",
        .btnStop: "Stop",
        .btnRestart: "Restart",
        .btnReload: "Reload",
        .btnSave: "Save",
        .btnClear: "Clear",
        .btnChange: "Change...",
        .btnOpen: "Open Window",
        .btnQuit: "Quit OpenFox",
        .dashTitle: "Dashboard",
        .dashSubtitle: "Monitor and control your OpenFox bot",
        .dashBotRunning: "Bot is Running",
        .dashBotStopped: "Bot is Stopped",
        .dashBotRunningDesc: "Your Telegram bot is active and processing messages.",
        .dashBotStoppedDesc: "Press Start to launch the Telegram bot.",
        .dashUptime: "Uptime",
        .dashReloadConfig: "Reload Config",
        .dashReloadConfigSub: "Re-read .env file",
        .dashStartSub: "Launch polling mode",
        .dashStopSub: "Gracefully shut down",
        .dashRecentActivity: "Recent Activity",
        .dashNoActivity: "No activity yet",
        .dashEntries: "entries",
        .cfgTitle: "Configuration",
        .cfgSubtitle: "Manage your OpenFox bot settings",
        .cfgProject: "Project",
        .cfgProjectDir: "Project Directory",
        .cfgTelegram: "Telegram",
        .cfgBotToken: "Bot Token",
        .cfgAllowGroups: "Allow Groups",
        .cfgSkipPending: "Skip Pending Updates",
        .cfgShow: "Show",
        .cfgHide: "Hide",
        .cfgNotConfigured: "Not configured",
        .cfgModel: "AI Model",
        .cfgModelLabel: "Model",
        .cfgVariant: "Thinking Variant",
        .cfgPermission: "Permission Mode",
        .cfgAdvanced: "Advanced",
        .cfgPollTimeout: "Poll Timeout (seconds)",
        .cfgOcTimeout: "Opencode Timeout (ms)",
        .cfgWebhookPort: "Webhook Port",
        .cfgDeleteWebhook: "Delete Webhook on Start",
        .cfgSaved: "Configuration Saved",
        .cfgSavedMsg: "Settings saved to .env file.\nRestart the bot for changes to take effect.",
        .cfgProvider: "Provider",
        .cfgSelectProvider: "Select provider",
        .cfgSelectModel: "Select model",
        .cfgLoadingModels: "Loading models...",
        .cfgCustomModel: "Custom",
        .cfgVariantLow: "Low",
        .cfgVariantMedium: "Medium",
        .cfgVariantHigh: "High",
        .cfgPermAsk: "Ask",
        .cfgPermAllow: "Allow",
        .logsTitle: "Logs",
        .logsSubtitle: "Real-time bot activity and output",
        .logsFilter: "Filter logs...",
        .logsAll: "All",
        .logsAutoScroll: "Auto-scroll",
        .usageTitle: "Usage Statistics",
        .usageSubtitle: "Token consumption and session overview",
        .usageRefresh: "Refresh",
        .usageTotalTokens: "Total Tokens",
        .usageSessions: "Active Sessions",
        .usageBreakdown: "Token Breakdown",
        .usageInput: "Input Tokens",
        .usageOutput: "Output Tokens",
        .usageReasoning: "Reasoning Tokens",
        .usageCurrentConfig: "Current Configuration",
        .usageModel: "Model",
        .usageVariant: "Variant",
        .usagePermission: "Permission",
        .usageGroups: "Groups",
        .usageDefault: "Default",
        .usageAllowed: "Allowed",
        .usagePrivateOnly: "Private Only",
        .menuOpenWindow: "Open Window",
        .menuQuit: "Quit OpenFox",
        .menuStart: "Start Bot",
        .menuStop: "Stop Bot",
        .menuRestart: "Restart Bot",
        .menuUptime: "Uptime:",
        .menuTokens: "Tokens:",
        .settingsLanguage: "Language",
    ]

    // MARK: - 繁體中文
    static let zhTW: [L10nKey: String] = [
        .navDashboard: "儀表板",
        .navConfiguration: "設定",
        .navLogs: "日誌",
        .navUsage: "用量",
        .statusRunning: "運行中",
        .statusStopped: "已停止",
        .btnStart: "啟動",
        .btnStop: "停止",
        .btnRestart: "重啟",
        .btnReload: "重新載入",
        .btnSave: "儲存",
        .btnClear: "清除",
        .btnChange: "更改...",
        .btnOpen: "開啟視窗",
        .btnQuit: "退出 OpenFox",
        .dashTitle: "儀表板",
        .dashSubtitle: "監控並控制您的 OpenFox 機器人",
        .dashBotRunning: "機器人運行中",
        .dashBotStopped: "機器人已停止",
        .dashBotRunningDesc: "您的 Telegram 機器人正在運行並處理訊息。",
        .dashBotStoppedDesc: "按下啟動鍵以啟動 Telegram 機器人。",
        .dashUptime: "運行時間",
        .dashReloadConfig: "重新載入設定",
        .dashReloadConfigSub: "重新讀取 .env 檔案",
        .dashStartSub: "啟動輪詢模式",
        .dashStopSub: "正常關閉",
        .dashRecentActivity: "最近活動",
        .dashNoActivity: "尚無活動記錄",
        .dashEntries: "筆記錄",
        .cfgTitle: "設定",
        .cfgSubtitle: "管理您的 OpenFox 機器人設定",
        .cfgProject: "專案",
        .cfgProjectDir: "專案目錄",
        .cfgTelegram: "Telegram",
        .cfgBotToken: "Bot Token",
        .cfgAllowGroups: "允許群組",
        .cfgSkipPending: "跳過待處理更新",
        .cfgShow: "顯示",
        .cfgHide: "隱藏",
        .cfgNotConfigured: "未設定",
        .cfgModel: "AI 模型",
        .cfgModelLabel: "模型",
        .cfgVariant: "思考等級",
        .cfgPermission: "權限模式",
        .cfgAdvanced: "進階設定",
        .cfgPollTimeout: "輪詢逾時（秒）",
        .cfgOcTimeout: "Opencode 逾時（毫秒）",
        .cfgWebhookPort: "Webhook 埠號",
        .cfgDeleteWebhook: "啟動時刪除 Webhook",
        .cfgSaved: "設定已儲存",
        .cfgSavedMsg: "設定已寫入 .env 檔案。\n重新啟動機器人以套用變更。",
        .cfgProvider: "供應商",
        .cfgSelectProvider: "選擇供應商",
        .cfgSelectModel: "選擇模型",
        .cfgLoadingModels: "載入模型中...",
        .cfgCustomModel: "自訂",
        .cfgVariantLow: "低",
        .cfgVariantMedium: "中",
        .cfgVariantHigh: "高",
        .cfgPermAsk: "詢問",
        .cfgPermAllow: "允許",
        .logsTitle: "日誌",
        .logsSubtitle: "即時機器人活動與輸出",
        .logsFilter: "篩選日誌...",
        .logsAll: "全部",
        .logsAutoScroll: "自動捲動",
        .usageTitle: "使用統計",
        .usageSubtitle: "Token 用量與 Session 概覽",
        .usageRefresh: "重新整理",
        .usageTotalTokens: "總 Token 數",
        .usageSessions: "活躍 Session",
        .usageBreakdown: "Token 分佈",
        .usageInput: "輸入 Token",
        .usageOutput: "輸出 Token",
        .usageReasoning: "推理 Token",
        .usageCurrentConfig: "目前設定",
        .usageModel: "模型",
        .usageVariant: "思考等級",
        .usagePermission: "權限",
        .usageGroups: "群組",
        .usageDefault: "預設",
        .usageAllowed: "允許",
        .usagePrivateOnly: "僅私訊",
        .menuOpenWindow: "開啟視窗",
        .menuQuit: "退出 OpenFox",
        .menuStart: "啟動機器人",
        .menuStop: "停止機器人",
        .menuRestart: "重啟機器人",
        .menuUptime: "運行時間：",
        .menuTokens: "Token：",
        .settingsLanguage: "語言",
    ]

    // MARK: - 简体中文
    static let zhCN: [L10nKey: String] = [
        .navDashboard: "仪表板",
        .navConfiguration: "设置",
        .navLogs: "日志",
        .navUsage: "用量",
        .statusRunning: "运行中",
        .statusStopped: "已停止",
        .btnStart: "启动",
        .btnStop: "停止",
        .btnRestart: "重启",
        .btnReload: "重新加载",
        .btnSave: "保存",
        .btnClear: "清除",
        .btnChange: "更改...",
        .btnOpen: "打开窗口",
        .btnQuit: "退出 OpenFox",
        .dashTitle: "仪表板",
        .dashSubtitle: "监控并控制您的 OpenFox 机器人",
        .dashBotRunning: "机器人运行中",
        .dashBotStopped: "机器人已停止",
        .dashBotRunningDesc: "您的 Telegram 机器人正在运行并处理消息。",
        .dashBotStoppedDesc: "按下启动键以启动 Telegram 机器人。",
        .dashUptime: "运行时间",
        .dashReloadConfig: "重新加载配置",
        .dashReloadConfigSub: "重新读取 .env 文件",
        .dashStartSub: "启动轮询模式",
        .dashStopSub: "正常关闭",
        .dashRecentActivity: "最近活动",
        .dashNoActivity: "暂无活动记录",
        .dashEntries: "条记录",
        .cfgTitle: "设置",
        .cfgSubtitle: "管理您的 OpenFox 机器人设置",
        .cfgProject: "项目",
        .cfgProjectDir: "项目目录",
        .cfgTelegram: "Telegram",
        .cfgBotToken: "Bot Token",
        .cfgAllowGroups: "允许群组",
        .cfgSkipPending: "跳过待处理更新",
        .cfgShow: "显示",
        .cfgHide: "隐藏",
        .cfgNotConfigured: "未配置",
        .cfgModel: "AI 模型",
        .cfgModelLabel: "模型",
        .cfgVariant: "思考级别",
        .cfgPermission: "权限模式",
        .cfgAdvanced: "高级设置",
        .cfgPollTimeout: "轮询超时（秒）",
        .cfgOcTimeout: "Opencode 超时（毫秒）",
        .cfgWebhookPort: "Webhook 端口",
        .cfgDeleteWebhook: "启动时删除 Webhook",
        .cfgSaved: "配置已保存",
        .cfgSavedMsg: "设置已写入 .env 文件。\n重启机器人以使更改生效。",
        .cfgProvider: "供应商",
        .cfgSelectProvider: "选择供应商",
        .cfgSelectModel: "选择模型",
        .cfgLoadingModels: "正在加载模型...",
        .cfgCustomModel: "自定义",
        .cfgVariantLow: "低",
        .cfgVariantMedium: "中",
        .cfgVariantHigh: "高",
        .cfgPermAsk: "询问",
        .cfgPermAllow: "允许",
        .logsTitle: "日志",
        .logsSubtitle: "实时机器人活动与输出",
        .logsFilter: "筛选日志...",
        .logsAll: "全部",
        .logsAutoScroll: "自动滚动",
        .usageTitle: "使用统计",
        .usageSubtitle: "Token 用量与 Session 概览",
        .usageRefresh: "刷新",
        .usageTotalTokens: "总 Token 数",
        .usageSessions: "活跃 Session",
        .usageBreakdown: "Token 分布",
        .usageInput: "输入 Token",
        .usageOutput: "输出 Token",
        .usageReasoning: "推理 Token",
        .usageCurrentConfig: "当前配置",
        .usageModel: "模型",
        .usageVariant: "思考级别",
        .usagePermission: "权限",
        .usageGroups: "群组",
        .usageDefault: "默认",
        .usageAllowed: "允许",
        .usagePrivateOnly: "仅私信",
        .menuOpenWindow: "打开窗口",
        .menuQuit: "退出 OpenFox",
        .menuStart: "启动机器人",
        .menuStop: "停止机器人",
        .menuRestart: "重启机器人",
        .menuUptime: "运行时间：",
        .menuTokens: "Token：",
        .settingsLanguage: "语言",
    ]
}

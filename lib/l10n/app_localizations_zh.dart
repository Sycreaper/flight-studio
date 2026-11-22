// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Flight Studio';

  @override
  String get navRecentFlights => '开始';

  @override
  String get navPluginCenter => '插件中心';

  @override
  String get navSettings => '设置';

  @override
  String get createFirstFlight => '创建你的第一个航班';

  @override
  String get createFlight => '新建航班';

  @override
  String get worldMap => '世界地图';

  @override
  String get flightAcademy => '飞行学院';

  @override
  String get searchFlights => '搜索航班…';

  @override
  String get noResults => '未找到匹配的航班';

  @override
  String get pluginCenterTitle => '插件中心';

  @override
  String get pluginCenterDesc => '管理模拟器桥接与扩展';

  @override
  String get settingsTitle => '设置';

  @override
  String get comingSoon => '敬请期待';

  @override
  String get openSettings => '打开设置';

  @override
  String get tabMap => '地图';

  @override
  String get tabFlightPlan => '飞行计划';

  @override
  String get tabChat => '聊天';

  @override
  String get chatNewConversation => '新对话';

  @override
  String get panelConversations => '对话';

  @override
  String get conversationNew => '新建对话';

  @override
  String get conversationEmpty => '暂无对话';

  @override
  String get conversationDelete => '删除对话';

  @override
  String get conversationDeleteConfirm => '确定删除该对话？删除后无法恢复。';

  @override
  String get conversationDeleteAction => '删除';

  @override
  String get conversationExport => '导出对话';

  @override
  String get conversationApprovalLog => '权限日志';

  @override
  String get approvalLogTitle => '权限日志';

  @override
  String get approvalLogEmpty => '此会话暂无工具权限决策记录';

  @override
  String get approvalLogLoadFailed => '权限日志不可用——网关是否在运行？';

  @override
  String get approvalOutcomeApproved => '已批准';

  @override
  String get approvalOutcomeDenied => '已拒绝';

  @override
  String get approvalOutcomeDeniedTimeout => '已拒绝（超时）';

  @override
  String get approvalOutcomeAutoAllowed => '自动允许';

  @override
  String get approvalOutcomePolicyDenied => '策略拦截';

  @override
  String get approvalOutcomeSilentAllowed => '技能（始终允许）';

  @override
  String get approvalOutcomeFailClosed => '失败关闭';

  @override
  String get approvalRevealTooltip => '回到上下文';

  @override
  String approvalLevelTooltip(Object level) {
    return '本回合授予的访问级别：$level';
  }

  @override
  String get conversationExportUser => '用户';

  @override
  String get conversationExportAssistant => '飞行助理';

  @override
  String get conversationExportDone => '已导出';

  @override
  String get approvalResolvedAllow => '已批准';

  @override
  String get approvalResolvedDeny => '已拒绝';

  @override
  String get approvalAutoAllowed => '已自动允许';

  @override
  String get approvalAutoDenied => '已自动拒绝';

  @override
  String get aiLevelChipLabel =>
      'AI 权限级别（L0–L3）——L0 一切工具调用需手动确认；L1+ 数据读取自动执行；写操作与其他工具需手动确认；Bash 命令一律拒绝；技能直接放行';

  @override
  String get aiLevel0 => 'L0 · 手动确认';

  @override
  String get aiLevel1 => 'L1 · 数据自动';

  @override
  String get aiLevel2 => 'L2 · 预留';

  @override
  String get aiLevel3 => 'L3 · 预留';

  @override
  String get tabMapUnnamed => '地图';

  @override
  String get tabPlanUnnamed => '飞行计划';

  @override
  String get addTab => '新建标签页';

  @override
  String get newMapTab => '新建地图';

  @override
  String get newFlightPlanTab => '新建飞行计划';

  @override
  String get closeTab => '关闭标签页';

  @override
  String get noOpenTabs => '没有打开的标签页';

  @override
  String get clickPlusToOpen => '点击右侧的 + 打开新标签页';

  @override
  String get sectionFlightInfo => '航班信息';

  @override
  String get sectionRoute => '航路';

  @override
  String get sectionPerformance => '燃油与性能';

  @override
  String get sectionProcedures => '飞行程序';

  @override
  String get fieldAircraft => '机型';

  @override
  String get fieldAirframe => '机身 / 注册号';

  @override
  String get fieldAirline => '航空公司';

  @override
  String get fieldFlightNumber => '航班号';

  @override
  String get fieldCallsign => '呼号';

  @override
  String get fieldDeparture => '起飞机场（ICAO）';

  @override
  String get fieldDestination => '目的机场（ICAO）';

  @override
  String get fieldAlternate => '备降场（ICAO）';

  @override
  String get fieldCruiseLevel => '巡航高度层（FL）';

  @override
  String get fieldCostIndex => '成本指数';

  @override
  String get fieldRoute => '航路字符串';

  @override
  String get fieldContingency => '应急燃油';

  @override
  String get fieldReserve => '备份燃油';

  @override
  String get fieldTaxiFuel => '滑行燃油';

  @override
  String get fieldExtraFuel => '额外燃油';

  @override
  String get fieldUnits => '单位';

  @override
  String get fieldSid => 'SID 离场';

  @override
  String get fieldStar => 'STAR 进场';

  @override
  String get fieldApproach => '进近';

  @override
  String get fieldPlanDetail => '计划详细程度';

  @override
  String get unitsKg => '千克';

  @override
  String get unitsLb => '磅';

  @override
  String get detailFull => '完整';

  @override
  String get detailRouteOnly => '仅航路';

  @override
  String get calculatePlan => '计算计划';

  @override
  String get resetForm => '重置';

  @override
  String get settingsResetDefaults => '恢复默认';

  @override
  String get settingsResetDefaultsConfirm => '将所有设置恢复为默认值？此操作无法撤销。';

  @override
  String get settingsReset => '重置';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsClose => '关闭';

  @override
  String get settingsSave => '保存';

  @override
  String get settingsEdit => '编辑';

  @override
  String get settingsBrowse => '浏览…';

  @override
  String get settingsNotSet => '未设置';

  @override
  String get settingsPlannedBadge => '计划中';

  @override
  String get settingsConnectedBadge => '已连接';

  @override
  String get settingsDisconnectedBadge => '未连接';

  @override
  String get gearMenuTooltip => '打开菜单';

  @override
  String get gearMenuSettings => '设置…';

  @override
  String get gearMenuAbout => '关于 Flight Studio';

  @override
  String get gearMenuCheckUpdates => '检查更新…';

  @override
  String get gearMenuCheckUpdatesNone => '已是最新版本。';

  @override
  String get gearMenuHelp => '帮助';

  @override
  String get gearMenuExit => '退出';

  @override
  String get toolbarHome => '返回欢迎页';

  @override
  String get aboutDialogTitle => '关于 Flight Studio';

  @override
  String get settingsCategoryGeneral => '常规';

  @override
  String get settingsCategoryData => '数据';

  @override
  String get settingsCategorySimulator => '模拟器';

  @override
  String get settingsCategoryNavdata => '导航数据';

  @override
  String get settingsCategoryAi => 'AI 副驾驶';

  @override
  String get settingsCategoryAbout => '关于';

  @override
  String get settingsAppearanceTitle => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get settingsFontFamily => '界面字体';

  @override
  String get settingsFontDefault => '默认';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageZh => '中文（简体）';

  @override
  String get settingsStartupTitle => '启动';

  @override
  String get settingsReopenLastWorkspace => '启动时重新打开上次的工作区';

  @override
  String get settingsCheckUpdatesOnLaunch => '启动时检查更新';

  @override
  String get settingsUnitsTitle => '默认单位';

  @override
  String get settingsUnitsMetric => '公制（千克、千米）';

  @override
  String get settingsUnitsImperial => '英制（磅、海里）';

  @override
  String get settingsSimulatorTitle => '模拟器连接';

  @override
  String get settingsXplaneTitle => 'X-Plane 12';

  @override
  String settingsXplaneStatusConnected(int port) {
    return '已在端口 $port 检测到桥接';
  }

  @override
  String get settingsXplaneStatusDisconnected => '未连接';

  @override
  String get settingsXplaneInstallPath => 'X-Plane 安装目录';

  @override
  String get settingsXplaneInstallPick => '选择目录…';

  @override
  String get settingsXplaneInstallClear => '清除';

  @override
  String get settingsXplaneUdpPort => '遥测 UDP 端口';

  @override
  String get settingsXplaneBridgePort => '桥接命令端口';

  @override
  String get settingsXplaneInstallBridge => '安装 FlyWithLua 桥接…';

  @override
  String get settingsXplaneTestConnection => '测试连接';

  @override
  String get settingsMsfsTitle => 'MSFS 2020 / 2024 与 Prepar3D';

  @override
  String get settingsMsfsPlanned =>
      'C++ SimConnect 桥接守护进程计划于后续阶段提供。MSFS 与 Prepar3D 的遥测和指令支持将共用同一适配器。';

  @override
  String get settingsMsfsBridgePath => 'SimConnect 桥接守护进程';

  @override
  String get settingsNavdataTitle => '导航数据源';

  @override
  String get settingsNavdataBundledTitle => '内置数据（免费开源）';

  @override
  String get settingsNavdataOurAirports => 'OurAirports';

  @override
  String get settingsNavdataFaaCifp => 'FAA CIFP / NASR';

  @override
  String get settingsNavdataXplaneNative => '解析 X-Plane 原生文件';

  @override
  String get settingsNavdataRefreshBundled => '刷新内置数据';

  @override
  String get settingsNavdataNavigraphTitle => 'Navigraph（用户订阅）';

  @override
  String settingsNavdataNavigraphSignedIn(String user) {
    return '已登录为 $user';
  }

  @override
  String get settingsNavdataNavigraphSignedOut => '未登录';

  @override
  String get settingsNavdataNavigraphSignIn => '使用 Navigraph 登录…';

  @override
  String get settingsNavdataNavigraphSignOut => '退出登录';

  @override
  String get settingsNavdataNavigraphAirac => '当前 AIRAC 周期';

  @override
  String get settingsNavdataNavigraphAiracNone => '不可用';

  @override
  String get settingsNavdataSimBriefTitle => 'SimBrief（免费账户）';

  @override
  String settingsNavdataSimBriefLinked(String username) {
    return '已关联到 $username';
  }

  @override
  String get settingsNavdataSimBriefNotLinked => '未关联';

  @override
  String get settingsNavdataSimBriefLink => '关联 SimBrief 账户…';

  @override
  String get settingsNavdataSimBriefUnlink => '解除关联';

  @override
  String get settingsAiTitle => 'AI 副驾驶';

  @override
  String get settingsAiProvider => '提供商';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI 兼容';

  @override
  String get settingsAiProviderAnthropic => 'Anthropic';

  @override
  String get settingsAiProviderOllama => '本地（Ollama）';

  @override
  String get settingsAiApiKey => 'API 密钥';

  @override
  String get settingsAiApiKeyHidden => '已设置密钥（隐藏）';

  @override
  String get settingsAiEndpoint => '端点 URL';

  @override
  String get settingsAiEndpointPlaceholder => 'https://api.openai.com/v1';

  @override
  String get settingsAiModel => '模型';

  @override
  String get settingsAiModelPlaceholder => '模型 ID';

  @override
  String get settingsReasoningEffort => '思考强度';

  @override
  String get settingsAiModelService => '模型服务';

  @override
  String get aiLettaRuntimeTitle => 'Letta CLI（本地 Agent 运行时）';

  @override
  String get aiLettaChecking => '正在检测环境…';

  @override
  String get aiLettaNotInstalledTitle => 'Letta CLI 未安装';

  @override
  String get aiLettaInstalledTitle => 'Letta CLI 已安装';

  @override
  String get aiLettaNodeMissingTitle => '未检测到 Node.js';

  @override
  String get aiLettaNodeTooOldTitle => 'Node.js 版本过低';

  @override
  String aiLettaNodeDetected(String version) {
    return '检测到 Node.js $version';
  }

  @override
  String get aiLettaNodeRequiredHint =>
      'Letta CLI 需要 Node.js 22.19 或更高版本（通过 npm 分发）。';

  @override
  String get aiLettaNodeDownload => '打开 Node.js 下载页';

  @override
  String get aiLettaRecheck => '重新检测';

  @override
  String get aiLettaInstall => '一键安装';

  @override
  String get aiLettaUninstall => '一键卸载';

  @override
  String get aiLettaInstalling => '正在安装 Letta CLI…';

  @override
  String get aiLettaUninstalling => '正在卸载 Letta CLI…';

  @override
  String get aiLettaInstallFailed => '安装失败';

  @override
  String get aiLettaUninstallFailed => '卸载失败';

  @override
  String get aiLettaLog => '输出日志';

  @override
  String get aiLettaUninstallConfirmTitle => '卸载 Letta CLI？';

  @override
  String get aiLettaUninstallConfirmDesc =>
      '仅移除 Letta CLI 程序本身。你的本地账户与长期记忆数据（~/.letta）不会被删除。';

  @override
  String get settingsAiClearApiKey => '清除';

  @override
  String get settingsAboutTitle => '关于 Flight Studio';

  @override
  String get settingsAboutVersion => '版本';

  @override
  String get settingsAboutLicense => '许可证';

  @override
  String get settingsAboutLicenseValue => 'MIT — 宽松许可，净室重写';

  @override
  String get settingsAboutViewLicense => '查看完整许可证';

  @override
  String get settingsAboutThirdParty => '第三方数据';

  @override
  String get settingsAboutThirdPartyDesc =>
      'Navigraph 与 SimBrief 数据由用户授权，绝不打包再分发。OpenStreetMap 图块版权归 OSM 贡献者（ODbL）。OurAirports 与 FAA CIFP/NASR 属公共领域。';

  @override
  String get settingsAboutViewThirdParty => '查看第三方声明';

  @override
  String get settingsAboutHomepage => '主页';

  @override
  String get settingsAboutOpenSource => '在 GitHub 上开源';

  @override
  String get settingsAboutInspiredBy => '灵感来自 Little Navmap（未复用任何 GPL 源码）。';

  @override
  String get tabSettings => '设置';

  @override
  String get welcomeSubtitle => 'AI 飞行智能体工作台';

  @override
  String get ttNewFlightPlan => '新建飞行计划';

  @override
  String get ttOpenFlightPlan => '打开飞行计划';

  @override
  String get ttExport => '导出';

  @override
  String get ttCalculateRoute => '计算航线';

  @override
  String get ttConnectSim => '连接模拟器';

  @override
  String get ttPauseSim => '暂停模拟器';

  @override
  String get ttToggleProjection => '切换投影';

  @override
  String get ttCalculatePlan => '计算计划';

  @override
  String get ttResetForm => '重置表单';

  @override
  String get ttImportRoute => '导入航路';

  @override
  String get ttExportPlan => '导出计划';

  @override
  String get ttFetchSimBrief => '从 SimBrief 获取';

  @override
  String get ttSavePlan => '保存计划';

  @override
  String get mapPlaceholder => '地图';

  @override
  String get mapApiKeyCta => '绑定你的地图 API 密钥以启用实时瓦片';

  @override
  String get mapLoadError => '地图加载失败';

  @override
  String get mapErrorNoNetwork => '无网络连接 —— 请检查网络后重试。';

  @override
  String get mapError404 => '瓦片服务器返回 404。瓦片 URL 可能不正确或服务器已关闭。';

  @override
  String mapErrorGeneric(String code) {
    return '错误 $code';
  }

  @override
  String get mapRetry => '重试';

  @override
  String get mapZoomIn => '放大';

  @override
  String get mapZoomOut => '缩小';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusDisconnected => '未连接';

  @override
  String get statusNoNavdata => '未加载导航数据';

  @override
  String get statusCpu => 'CPU';

  @override
  String get statusGpu => 'GPU';

  @override
  String get statusMem => '内存';

  @override
  String get panelFlightPlans => '飞行计划';

  @override
  String get panelInspector => '检查器';

  @override
  String get panelProfile => '剖面';

  @override
  String get hidePanel => '隐藏';

  @override
  String get inspectorHint => '双击地图图标或搜索结果，在此查看详细信息。';

  @override
  String get inspectorType => '类型';

  @override
  String get inspectorCoordinates => '坐标';

  @override
  String get inspectorElevation => '标高';

  @override
  String get inspectorFrequency => '频率';

  @override
  String get inspectorRunways => '跑道';

  @override
  String get inspectorIata => 'IATA';

  @override
  String get inspectorCity => '城市';

  @override
  String get inspectorFlyTo => '定位到该点';

  @override
  String get inspectorClear => '清除检查器';

  @override
  String get inspectorFrequencies => 'ATC 频率';

  @override
  String get inspectorWeather => '天气';

  @override
  String get inspectorWeatherUnavailable => '该机场暂无天气信息。';

  @override
  String get inspectorTabOverview => '概述';

  @override
  String get inspectorTabComms => '通信';

  @override
  String get inspectorIcao => 'ICAO';

  @override
  String get inspectorXplaneIdent => 'X-Plane 识别码';

  @override
  String get inspectorRegion => '地域';

  @override
  String get inspectorCountry => '国家或地区代码';

  @override
  String get inspectorMagvar => '磁偏角';

  @override
  String get inspectorSunTimes => '日出和日落';

  @override
  String get inspectorNotAvailable => '—';

  @override
  String get inspectorRawReport => '源报文';

  @override
  String get inspectorWindCalm => '静风';

  @override
  String get splashStarting => '正在启动 FlightStudio';

  @override
  String get splashScanning => '正在扫描导航数据…';

  @override
  String get splashNoNavdata => '未找到导航数据';

  @override
  String get settingsSplash => '启动画面';

  @override
  String get settingsSplashScan => '启动时自动扫描导航数据';

  @override
  String get splashScanAlways => '始终';

  @override
  String get splashScanAfter14 => '上次扫描超过 14 天';

  @override
  String get splashScanAfter28 => '上次扫描超过 28 天';

  @override
  String get splashScanNever => '从不';

  @override
  String get navActiveSource => '使用中';

  @override
  String get inspectorDataSource => '数据来源';

  @override
  String get inspectorRunwayCount => '跑道数量';

  @override
  String get inspectorLongestRunway => '最长跑道';

  @override
  String get airportTypeAirport => '机场';

  @override
  String get airportTypeHeliport => '直升机机场';

  @override
  String get airportTypeSeaplane => '水上机场';

  @override
  String get navFreqAtis => 'ATIS';

  @override
  String get navFreqCtaf => 'CTAF';

  @override
  String get navFreqGnd => '地面';

  @override
  String get navFreqTwr => '塔台';

  @override
  String get navFreqCld => '放行';

  @override
  String get navFreqApp => '进近';

  @override
  String get navFreqDep => '离场';

  @override
  String get treeNoPlans => '没有飞行计划';

  @override
  String get treeCreateHint => '点击创建';

  @override
  String get profileTabAltitude => '高度';

  @override
  String get profileTabFuel => '燃油';

  @override
  String get profileTabSpeed => '速度';

  @override
  String get profileTabWeather => '天气';

  @override
  String get profileHint => '高度/燃油剖面将在此处显示';

  @override
  String get settingsCategoryApiKeys => 'API 密钥';

  @override
  String get apiKeysSecurityNote => '密钥仅存储于本设备，保存后不再完整显示。';

  @override
  String get apiTileProvider => '地图瓦片提供商';

  @override
  String get apiTileProviderOsm => 'OSM';

  @override
  String get apiTileProviderMapboxStreets => 'Mapbox 街道';

  @override
  String get apiTileProviderMapboxSatellite => 'Mapbox 卫星';

  @override
  String get apiTileProviderCustom => '自定义';

  @override
  String get apiMapboxToken => 'Mapbox 访问令牌';

  @override
  String get apiCustomTileUrl => '自定义瓦片 URL';

  @override
  String get apiCustomTileUrlPlaceholder =>
      'https://tiles.example.com/14/8560/12745.png';

  @override
  String get apiFlightAwareKey => 'FlightAware API 密钥';

  @override
  String get apiKeySet => '密钥已设置';

  @override
  String get apiKeyAdd => '添加 API 密钥';

  @override
  String get apiKeyAddTitle => '添加 API 密钥';

  @override
  String get apiKeyType => '类型';

  @override
  String get apiKeyValue => 'API 密钥';

  @override
  String get apiKeyValueHint => '在此粘贴你的密钥。保存后将自动掩码。';

  @override
  String get apiKeyLabel => '标签（可选）';

  @override
  String get apiKeyLabelHint => '帮助你识别此密钥的名称';

  @override
  String get apiKeyEmpty => '未存储 API 密钥';

  @override
  String get apiKeyEmptyHint => '点击 + 添加';

  @override
  String get apiKeyTypeMapboxToken => 'Mapbox 令牌';

  @override
  String get apiKeyTypeOsmToken => 'OSM 瓦片令牌';

  @override
  String get startHeroTitle => '准备好了，随时开始';

  @override
  String get startPromptHint => '有问题，随便问';

  @override
  String get startSend => '发送';

  @override
  String get apiKeyTypeFlightAware => 'FlightAware 密钥';

  @override
  String get apiKeyTypeAiCopilot => 'AI 副驾驶密钥';

  @override
  String get apiKeyTypeOpenAiCompatible => 'OpenAI 兼容 API 密钥';

  @override
  String get openAiProvider => '提供商';

  @override
  String get openAiProviderGlm => '非编码套餐 GLM';

  @override
  String get openAiProviderQwen => '千问';

  @override
  String get openAiProviderDeepseek => 'DeepSeek';

  @override
  String get openAiProviderMinimax => 'MiniMax';

  @override
  String get openAiProviderMoonshot => '月之暗面 Kimi';

  @override
  String get openAiProviderSiliconflow => '硅基流动';

  @override
  String get openAiProviderOpenrouter => 'OpenRouter';

  @override
  String get openAiProviderCustom => '自定义';

  @override
  String get openAiBaseUrl => '基 URL';

  @override
  String get openAiBaseUrlHint => 'https://api.openai.com/v1';

  @override
  String get openAiTest => '测试';

  @override
  String get openAiTestOk => '✓ 连接成功';

  @override
  String get openAiTestFail => '✗ 连接失败';

  @override
  String get openAiModelsEmpty => '暂无模型——请先添加 OpenAI 兼容密钥';

  @override
  String get modelChipLabel => '模型';

  @override
  String get modelChipNoModel => '未设置模型——请编辑该 API 密钥';

  @override
  String get modelChipNoModels => '未发现模型——请重新创建该密钥';

  @override
  String get reasoningNone => '无';

  @override
  String get reasoningMinimal => '极低';

  @override
  String get reasoningLow => '低';

  @override
  String get reasoningMedium => '中';

  @override
  String get reasoningHigh => '高';

  @override
  String get reasoningXhigh => '超高';

  @override
  String get chatThinking => '思考中…';

  @override
  String get phaseThinking => '思考中…';

  @override
  String get thinkBlockLabel => '思考过程';

  @override
  String get phaseSearching => '搜索中…';

  @override
  String get phaseReading => '读取中…';

  @override
  String get phaseWriting => '写入中…';

  @override
  String get phaseTool => '调用工具';

  @override
  String get phaseWaitingApproval => '等待你的确认…';

  @override
  String get phaseWorking => '处理中…';

  @override
  String get approvalTitle => '权限请求';

  @override
  String approvalWantsToUse(Object tool) {
    return '副驾驶请求使用“$tool”。';
  }

  @override
  String get approvalAllow => '允许';

  @override
  String get approvalDeny => '拒绝';

  @override
  String get approvalRestored => '已结束';

  @override
  String get mcpToolAirportData => '机场数据';

  @override
  String get mcpToolChartsRead => '航图查询';

  @override
  String get mcpToolWeatherRead => '天气报告';

  @override
  String get mcpToolSearchNavdata => '导航数据搜索';

  @override
  String get mcpToolSearchManual => '手册搜索';

  @override
  String get mcpToolSimState => '模拟器状态';

  @override
  String get mcpToolActionPlan => '行动方案提案';

  @override
  String get mcpToolRenderMap => '地图渲染';

  @override
  String get mcpToolSetComFrequency => '设置 COM 频率';

  @override
  String get mcpToolSendSimCommand => '发送模拟器指令';

  @override
  String get aiDeleteLettaData => '删除 Letta 数据';

  @override
  String get aiDeleteLettaDataDesc =>
      '将永久删除全部 Letta 数据——智能体、会话、长期记忆与已存储的提供商密钥（C:\\Users\\<你>\\.letta）。此操作不可撤销。下一条消息将重新初始化副驾驶。';

  @override
  String get aiDeleteLettaDataFailed => '删除 Letta 数据失败——网关可能仍在运行，请重试。';

  @override
  String get chatCopy => '复制';

  @override
  String get chatCopied => '已复制';

  @override
  String get chatErrNoModel => '未选择模型——请先在 设置 → API 密钥 添加 OpenAI 兼容密钥，再回到此处选择。';

  @override
  String get chatErrGateway =>
      'AI 网关启动失败。请安装 Node.js ≥ 22.19（可在 设置 → AI 中安装）后重试。';

  @override
  String get chatErrProvider =>
      'Letta 拒绝了模型连接——请检查 设置 → API 密钥 中的密钥、基 URL 与模型名。';

  @override
  String get openAiModel => '模型';

  @override
  String get apiKeyTypeCustomTileUrl => '自定义瓦片 URL';

  @override
  String get mapTheme => '地图主题';

  @override
  String get mapProjectionFlat => '平面（2D）';

  @override
  String get mapProjectionGlobe => '球体（3D）';

  @override
  String get mapNetworkRepair => '网络修复';

  @override
  String get apiKeyConfirmDelete => '删除此 API 密钥？';

  @override
  String get apiKeyConfirmDeleteDesc => '此操作无法撤销。';

  @override
  String get simAddTitle => '添加模拟器';

  @override
  String get simExperimental => '实验性';

  @override
  String get simConnStateTitle => '连接';

  @override
  String get simConnDisconnected => '未连接';

  @override
  String get simConnConnecting => '连接中…';

  @override
  String get simConnConnected => '已连接';

  @override
  String get simConnError => '连接失败';

  @override
  String get simConnVersion => 'X-Plane 版本';

  @override
  String get simConnAddress => '地址';

  @override
  String get simConnUnknownVersion => '未知';

  @override
  String get simConnConnect => '连接';

  @override
  String get simConnDisconnect => '断开';

  @override
  String get simConnNoInstall => '请先在 数据 → 模拟器 中添加 X-Plane 12 安装';

  @override
  String get simWebApiPort => 'Web API 端口';

  @override
  String get simAutoConnectLabel => '启动时自动连接';

  @override
  String get legendAircraft => '飞机';

  @override
  String get aircraftPanelTitle => '飞机';

  @override
  String get aircraftNotConnected => '未连接模拟器';

  @override
  String get aircraftNotConnectedHint =>
      '需要 X-Plane 12.1.1+ 并开启本地 Web API；或在 设置 → 模拟器 中开启自动连接。';

  @override
  String get aircraftOpenSettings => '打开设置';

  @override
  String get aircraftGroupName => '机型';

  @override
  String get aircraftGroupPosition => '位置';

  @override
  String get aircraftGroupSpeed => '速度';

  @override
  String get aircraftGroupAttitude => '姿态';

  @override
  String get aircraftGroupAutopilot => '自动驾驶';

  @override
  String get aircraftModel => '机型';

  @override
  String get aircraftLatitude => '纬度';

  @override
  String get aircraftLongitude => '经度';

  @override
  String get aircraftAltitudeMsl => '海拔（MSL）';

  @override
  String get aircraftAltitudeAgl => '高度（AGL）';

  @override
  String get aircraftGroundSpeed => '地速';

  @override
  String get aircraftIas => '表速';

  @override
  String get aircraftTas => '真速';

  @override
  String get aircraftVerticalSpeed => '升降速度';

  @override
  String get aircraftHeadingTrue => '真航向';

  @override
  String get aircraftHeadingMag => '磁航向';

  @override
  String get aircraftPitch => '俯仰';

  @override
  String get aircraftRoll => '坡度';

  @override
  String get aircraftApOn => '自动驾驶';

  @override
  String get aircraftApAltitude => '高度窗';

  @override
  String get aircraftApHeading => '航向窗';

  @override
  String get aircraftApSpeed => '速度窗';

  @override
  String get aircraftApVs => '垂直速度设定';

  @override
  String get aircraftApOnLabel => '接通';

  @override
  String get aircraftApOffLabel => '关闭';

  @override
  String get simType => '模拟器类型';

  @override
  String get simInstallPath => '安装路径';

  @override
  String get simInstallPathHint => '浏览选择模拟器根目录';

  @override
  String get simBrowse => '浏览';

  @override
  String get simPathPlaceholder => 'D:\\Resources\\Softwares\\X-Plane12';

  @override
  String get simValidating => '验证中';

  @override
  String get simValid => '找到有效安装';

  @override
  String get simInvalid => '此目录中未找到 X-Plane.exe';

  @override
  String get simLabel => '标签（可选）';

  @override
  String get simLabelHint => '用于识别此安装的名称';

  @override
  String get simXplane12 => 'X-Plane 12';

  @override
  String get simMsfs2020 => 'MSFS 2020';

  @override
  String get simMsfs2024 => 'MSFS 2024';

  @override
  String get simPrepar3dV4 => 'Prepar3D v4';

  @override
  String get simPrepar3dV5 => 'Prepar3D v5';

  @override
  String get simPrepar3dV6 => 'Prepar3D v6';

  @override
  String get simComingSoon => '敬请期待 —— 将在后续阶段支持';

  @override
  String get simEmpty => '未添加模拟器';

  @override
  String get simEmptyHint => '点击 + 添加';

  @override
  String get navAddTitle => '添加导航数据源';

  @override
  String get navSelectSimulator => '选择模拟器';

  @override
  String get navNoSimulator => '未找到模拟器，请先添加一个模拟器。';

  @override
  String get navDataType => '数据类型';

  @override
  String get navDefaultData => '默认数据';

  @override
  String get navCustomData => '自定义数据';

  @override
  String get navCustomPath => '自定义数据路径';

  @override
  String get navScan => '扫描';

  @override
  String get navScanning => '扫描中';

  @override
  String get navEmpty => '无导航数据源';

  @override
  String get navEmptyHint => '点击 + 添加';

  @override
  String simInvalidNotFound(String exe) {
    return '此目录中未找到 $exe';
  }

  @override
  String get simConfirmDelete => '移除此模拟器？';

  @override
  String get simConfirmDeleteDesc => '关联的导航数据源也会被移除。';

  @override
  String get navConfirmDelete => '移除此导航数据源？';

  @override
  String get navConfirmDeleteDesc => '此操作无法撤销。';

  @override
  String get navCheckAll => '检查全部导航数据';

  @override
  String get legendAirport => '机场';

  @override
  String get legendVor => 'VOR';

  @override
  String get legendVordme => 'VOR/DME';

  @override
  String get legendVortac => 'VORTAC';

  @override
  String get legendTacan => '塔康';

  @override
  String get legendDme => 'DME';

  @override
  String get legendNdb => 'NDB';

  @override
  String get legendWaypoint => '航路点';

  @override
  String get legendIls => 'ILS';

  @override
  String get legendGs => '下滑台';

  @override
  String get legendMarker => '信标';

  @override
  String get panelSearch => '搜索';

  @override
  String get searchHint => '搜索机场、导航台、航路点…';

  @override
  String get searchStart => '输入以开始搜索';

  @override
  String get searchNoResults => '无结果';
}

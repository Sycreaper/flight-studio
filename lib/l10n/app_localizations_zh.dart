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
  String get navRecentFlights => '近期飞行';

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
  String get createFlightHint => '从零开始规划一条新航线';

  @override
  String get worldMapHint => '浏览全球地图与机场';

  @override
  String get flightAcademyHint => '学习航路规划与飞行程序';

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
  String get settingsDesc => '应用首选项';

  @override
  String get comingSoon => '敬请期待';

  @override
  String get openSettings => '打开设置';

  @override
  String get tabMap => '地图';

  @override
  String get tabFlightPlan => '飞行计划';

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
  String get settingsSearchHint => '搜索设置…';

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
  String get settingsRestartHint => '需要重启 Flight Studio 才能完全生效。';

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
  String get settingsCategoryGeneralDesc => '外观、语言与启动行为。';

  @override
  String get settingsCategorySimulator => '模拟器';

  @override
  String get settingsCategorySimulatorDesc => 'X-Plane、MSFS 与 Prepar3D 桥接。';

  @override
  String get settingsCategoryNavdata => '导航数据';

  @override
  String get settingsCategoryNavdataDesc => '机场、航路、程序与 AIRAC 数据源。';

  @override
  String get settingsCategoryAi => 'AI 副驾驶';

  @override
  String get settingsCategoryAiDesc => '使用你自己的 LLM 密钥并配置工具权限。';

  @override
  String get settingsCategoryRemote => '远程访问';

  @override
  String get settingsCategoryRemoteDesc => '为手机和网页客户端托管内嵌服务器。';

  @override
  String get settingsCategoryAbout => '关于';

  @override
  String get settingsCategoryAboutDesc => '版本、许可证与致谢。';

  @override
  String get settingsAppearanceTitle => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeHint => '夜间在驾驶舱中推荐使用深色主题。';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageHint => '应用界面语言。';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageZh => '中文（简体）';

  @override
  String get settingsStartupTitle => '启动';

  @override
  String get settingsReopenLastWorkspace => '启动时重新打开上次的工作区';

  @override
  String get settingsReopenLastWorkspaceHint => '跳过欢迎页，直接进入上次会话。';

  @override
  String get settingsCheckUpdatesOnLaunch => '启动时检查更新';

  @override
  String get settingsCheckUpdatesOnLaunchHint => '当有新的 Flight Studio 构建可用时通知我。';

  @override
  String get settingsUnitsTitle => '默认单位';

  @override
  String get settingsUnitsMetric => '公制（千克、千米）';

  @override
  String get settingsUnitsImperial => '英制（磅、海里）';

  @override
  String get settingsUnitsHint => '用于新建的飞行计划和燃油规划。';

  @override
  String get settingsSimulatorTitle => '模拟器连接';

  @override
  String get settingsSimulatorDesc =>
      'Flight Studio 通过每个模拟器对应的桥接读取遥测并下发指令。同一时间只需要连接一个模拟器。';

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
  String get settingsXplaneInstallHint =>
      'X-Plane 12 根目录位置（应包含 ‘Resources’ 与 ‘Aircraft’）。';

  @override
  String get settingsXplaneInstallPick => '选择目录…';

  @override
  String get settingsXplaneInstallClear => '清除';

  @override
  String get settingsXplaneUdpPort => '遥测 UDP 端口';

  @override
  String get settingsXplaneUdpPortHint => 'X-Plane 数据输出所发送到的端口（默认 49000）。';

  @override
  String get settingsXplaneBridgePort => '桥接命令端口';

  @override
  String get settingsXplaneBridgePortHint => '内置 FlyWithLua 脚本监听的端口（默认 49001）。';

  @override
  String get settingsXplaneInstallBridge => '安装 FlyWithLua 桥接…';

  @override
  String get settingsXplaneInstallBridgeHint =>
      '将 FlightStudioBridge.lua 复制到 FlyWithLua 的 Scripts 目录。';

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
  String get settingsMsfsBridgePathHint => '守护进程发布后将自动发现。';

  @override
  String get settingsNavdataTitle => '导航数据源';

  @override
  String get settingsNavdataDesc =>
      '可组合使用多种数据源。信任层会显示每条计划的数据来源，并在导入/导出时校验 AIRAC 一致性。';

  @override
  String get settingsNavdataBundledTitle => '内置数据（免费开源）';

  @override
  String get settingsNavdataOurAirports => 'OurAirports';

  @override
  String get settingsNavdataOurAirportsHint => '机场、跑道、频率与导航台（公共领域）。';

  @override
  String get settingsNavdataFaaCifp => 'FAA CIFP / NASR';

  @override
  String get settingsNavdataFaaCifpHint => '美国仪表飞行程序（公共领域）。';

  @override
  String get settingsNavdataXplaneNative => '解析 X-Plane 原生文件';

  @override
  String get settingsNavdataXplaneNativeHint =>
      '直接从安装目录读取 apt.dat、earth_nav.dat、earth_fix.dat 与 awy.dat。';

  @override
  String get settingsNavdataRefreshBundled => '刷新内置数据';

  @override
  String get settingsNavdataNavigraphTitle => 'Navigraph（用户订阅）';

  @override
  String get settingsNavdataNavigraphHint =>
      '使用你自己的 Navigraph 账户登录。航图与 AIRAC 数据不会被 Flight Studio 打包或再分发。';

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
  String get settingsNavdataSimBriefHint =>
      '关联你的 SimBrief 账户以导入 OFP 与航路字符串。不会被再分发。';

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
  String get settingsAiDesc =>
      '助理对任何具有副作用的操作都只能调用 MCP 工具——它本身从不计算航路或写入文件。航路计算、导出与模拟器指令均由确定性的 Dart 代码执行。';

  @override
  String get settingsAiProvider => '提供商';

  @override
  String get settingsAiProviderOpenAi => 'OpenAI 兼容';

  @override
  String get settingsAiProviderAnthropic => 'Anthropic';

  @override
  String get settingsAiProviderOllama => '本地（Ollama）';

  @override
  String get settingsAiProviderHint =>
      '‘OpenAI 兼容’涵盖 OpenAI、Groq、Together、OpenRouter、LM Studio 等。';

  @override
  String get settingsAiApiKey => 'API 密钥';

  @override
  String get settingsAiApiKeyHint => '仅存储在本设备，且只会发送给你选择的提供商。';

  @override
  String get settingsAiApiKeyHidden => '已设置密钥（隐藏）';

  @override
  String get settingsAiClearApiKey => '清除';

  @override
  String get settingsAiEndpoint => '端点 URL';

  @override
  String get settingsAiEndpointHint =>
      '覆盖提供商的默认基础 URL（例如 Ollama 为 http://localhost:11434）。';

  @override
  String get settingsAiEndpointPlaceholder => 'https://api.openai.com/v1';

  @override
  String get settingsAiModel => '模型';

  @override
  String get settingsAiModelHint =>
      '示例：gpt-4o-mini、claude-3-5-sonnet、llama3.1。';

  @override
  String get settingsAiModelPlaceholder => '模型 ID';

  @override
  String get settingsAiToolPolicy => '工具策略';

  @override
  String get settingsAiConfirmWrites => '写入操作需要确认';

  @override
  String get settingsAiConfirmWritesHint => '导出、模拟器指令与文件写入在执行前需要你批准。';

  @override
  String get settingsAiAutoRead => '允许读工具无需确认';

  @override
  String get settingsAiAutoReadHint => '导航数据、天气、遥测与飞行记录无需提示即可提供给模型。';

  @override
  String get settingsRemoteTitle => '远程访问';

  @override
  String get settingsRemoteDesc =>
      '在桌面端进程内托管内嵌的 HTTP/WebSocket 服务器，让配套的手机与网页客户端可以通过局域网查看移动地图、暂停模拟器并远程操作 MCDU。';

  @override
  String get settingsRemoteEnable => '启用内嵌服务器';

  @override
  String get settingsRemotePort => '监听端口';

  @override
  String get settingsRemotePortHint => '桌面端监听的 TCP 端口（默认 48080）。';

  @override
  String get settingsRemoteToken => '访问令牌';

  @override
  String get settingsRemoteTokenHint => '每个手机/网页客户端都必须出示的共享密钥。';

  @override
  String get settingsRemoteRegenerateToken => '重新生成令牌';

  @override
  String get settingsRemoteStatusTitle => '服务器状态';

  @override
  String get settingsRemoteNotRunning => '未运行';

  @override
  String settingsRemoteRunningOn(String host, int port) {
    return '正在监听 http://$host:$port';
  }

  @override
  String get settingsRemoteMdns => '在局域网广播（mDNS）';

  @override
  String get settingsRemoteMdnsHint => '让配套应用可以自动发现本机。';

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
  String get welcomeSubtitle => '飞行规划器';

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
  String get statusNoNavdata => '未加载导航数据';

  @override
  String get statusCpu => 'CPU';

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
  String get inspectorHint => '在地图上选择一个航点或航段以查看其详情。';

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
}

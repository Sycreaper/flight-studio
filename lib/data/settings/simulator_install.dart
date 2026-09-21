import 'dart:convert';
import 'dart:math' as math;

/// Every kind of simulator Flight Studio can connect to.
enum SimulatorType {
  xplane12,
  msfs2020,
  msfs2024,
  prepar3dV4,
  prepar3dV5,
  prepar3dV6;

  String get persistedName => name;

  /// The executable file to look for when validating an install path.
  String get validatorExe => switch (this) {
    SimulatorType.xplane12 => 'X-Plane.exe',
    SimulatorType.msfs2020 => 'FlightSimulator.exe',
    SimulatorType.msfs2024 => 'FlightSimulator.exe',
    SimulatorType.prepar3dV4 => 'Prepar3D.exe',
    SimulatorType.prepar3dV5 => 'Prepar3D.exe',
    SimulatorType.prepar3dV6 => 'Prepar3D.exe',
  };

  // NOTE: "is this sim connectable / navdata-importable today" is NOT an enum
  // flag — ask SimConnectorRegistry.instance.isSupported(type) and
  // NavdataProviderRegistry.instance.forInstall(...) instead, so third-party
  // connectors and providers plug in without touching this enum.

  static SimulatorType fromPersistedName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => SimulatorType.xplane12,
    );
  }
}

/// One installed simulator on the user's machine. Users can add multiple
/// installs of the same type (e.g. two X-Plane 12 installs).
class SimulatorInstall {
  SimulatorInstall({
    required this.id,
    required this.type,
    required this.path,
    this.name,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final SimulatorType type;
  final String path;
  final String? name;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.persistedName,
    'path': path,
    'name': name,
    'addedAt': addedAt.toIso8601String(),
  };

  static SimulatorInstall fromJson(Map<String, dynamic> json) =>
      SimulatorInstall(
        id: json['id'] as String,
        type: SimulatorType.fromPersistedName(json['type'] as String?),
        path: json['path'] as String,
        name: json['name'] as String?,
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'] as String)
            : null,
      );

  static String encodeList(List<SimulatorInstall> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SimulatorInstall> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => SimulatorInstall.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static String generateId() {
    final rng = math.Random.secure();
    return List.generate(8, (_) => rng.nextInt(36).toRadixString(36)).join();
  }
}

/// What kind of navdata to scan from a simulator install.
enum NavdataDataType { defaultData, custom }

/// A navigation-data source linked to a specific simulator install. One
/// simulator can have multiple navdata sources (e.g. default + custom).
class NavdataSource {
  NavdataSource({
    required this.id,
    required this.simulatorId,
    required this.dataType,
    this.customDataPath,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final String simulatorId;
  final NavdataDataType dataType;
  final String? customDataPath;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'simulatorId': simulatorId,
    'dataType': dataType.name,
    'customDataPath': customDataPath,
    'addedAt': addedAt.toIso8601String(),
  };

  static NavdataSource fromJson(Map<String, dynamic> json) => NavdataSource(
    id: json['id'] as String,
    simulatorId: json['simulatorId'] as String,
    dataType: NavdataDataType.values.firstWhere(
      (e) => e.name == json['dataType'],
      orElse: () => NavdataDataType.defaultData,
    ),
    customDataPath: json['customDataPath'] as String?,
    addedAt: json['addedAt'] != null
        ? DateTime.parse(json['addedAt'] as String)
        : null,
  );

  static String encodeList(List<NavdataSource> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<NavdataSource> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => NavdataSource.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static String generateId() {
    final rng = math.Random.secure();
    return List.generate(8, (_) => rng.nextInt(36).toRadixString(36)).join();
  }
}

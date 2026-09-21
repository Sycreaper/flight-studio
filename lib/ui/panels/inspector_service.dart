import 'package:flutter/foundation.dart';

import '../../core/navdata/navdata_types.dart';

/// Holds the nav point currently shown in the inspector drawer. Double-
/// clicking a map marker or a search result inspects it; the inspector panel
/// and the workspace shell (which auto-shows the drawer / opens the narrow
/// full-screen page) both listen here.
class InspectorService extends ChangeNotifier {
  InspectorService._();

  static final InspectorService instance = InspectorService._();

  NavPoint? _point;

  NavPoint? get point => _point;

  /// Shows [point] in the inspector (`null` clears it).
  void inspect(NavPoint? point) {
    if (identical(_point, point)) return;
    _point = point;
    notifyListeners();
  }

  /// Clears the inspector back to its hint state.
  void clear() => inspect(null);
}

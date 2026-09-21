import 'package:flutter/foundation.dart';

/// Generic, observable registry for one extension point.
///
/// Every seam a third-party plugin will later hook into (workspace tabs,
/// flight-plan exporters, simulator connectors, navdata providers, AI tools)
/// funnels through one of these registries. Built-in features register through
/// the exact same channel a plugin will use, so no switch statements or
/// enum-membership gates remain in the host code.
///
/// Runtime plugin loading itself (QuickJS JavaScript sandbox, desktop-only —
/// Windows / macOS / Linux) lands in Phase 10; until then all registrations
/// are in-process Dart made during app startup.
class ExtensionRegistry<T> extends ChangeNotifier {
  ExtensionRegistry({required this.idOf});

  /// Extracts the registry id from an item (overridable per registration).
  final String Function(T item) idOf;
  final Map<String, T> _items = {};

  /// Registers [item]. Later registrations with the same id replace earlier
  /// ones (last-writer-wins), which is also how a user-disabled built-in
  /// could be overridden in the future.
  ///
  /// [id] overrides the descriptor-derived id — used by registries whose
  /// items are factories or lambdas with no intrinsic identity.
  void register(T item, {String? id}) {
    _items[id ?? idOf(item)] = item;
    notifyListeners();
  }

  /// Removes the item registered under [id]. Returns whether one existed.
  bool unregister(String id) {
    final removed = _items.remove(id) != null;
    if (removed) notifyListeners();
    return removed;
  }

  /// Looks up the item registered under [id].
  T? byId(String id) => _items[id];

  /// First registered item satisfying [test], or `null`.
  T? first(bool Function(T item) test) {
    for (final item in _items.values) {
      if (test(item)) return item;
    }
    return null;
  }

  /// All registered items in registration order.
  List<T> get all => _items.values.toList(growable: false);
}

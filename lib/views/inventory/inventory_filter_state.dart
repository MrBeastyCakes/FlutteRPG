import 'package:flutter/foundation.dart';

enum InventoryFilter { all, tool, weapon, armor, food, quest }

enum InventorySort { name, quality, type }

/// View-scoped filter/search/sort state for the inventory grid.
class InventoryFilterState extends ChangeNotifier {
  InventoryFilter _filter = InventoryFilter.all;
  InventorySort _sort = InventorySort.name;
  String _query = '';

  InventoryFilter get filter => _filter;
  InventorySort get sort => _sort;
  String get query => _query;

  void setFilter(InventoryFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  void setSort(InventorySort s) {
    if (_sort == s) return;
    _sort = s;
    notifyListeners();
  }

  void setQuery(String q) {
    if (_query == q) return;
    _query = q;
    notifyListeners();
  }

  void clear() {
    _filter = InventoryFilter.all;
    _query = '';
    notifyListeners();
  }
}

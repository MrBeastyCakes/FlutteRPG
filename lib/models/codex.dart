enum CodexTag { wilds, stone, tide, source, oldEmpire, misc }

class CodexFragment {
  final String id;
  final CodexTag tag;
  final String title;            // short title (e.g., "On Black Sap")
  final String text;             // 1–3 sentences
  final String? sourceHint;      // "Found at: Crumbling Obelisk in Whispering Woods I"
  final int orderInTag;          // puzzle ordering; Spec 2 uses, Spec 1 stores inertly

  const CodexFragment({
    required this.id,
    required this.tag,
    required this.title,
    required this.text,
    this.sourceHint,
    required this.orderInTag,
  });
}

class CodexFragments {
  static const List<CodexFragment> all = [];  // empty in Spec 1; Spec 2 fills
  static CodexFragment? findById(String id) {
    for (var f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}

class BestiaryEntry {
  final String beastId;
  final DateTime firstDefeated;
  int defeatCount;
  Set<String> droppedItemIds;

  BestiaryEntry({
    required this.beastId,
    required this.firstDefeated,
    required this.defeatCount,
    required this.droppedItemIds,
  });
}

enum RegionStatus { locked, anomalous, spreading, cleansed }

class RegionStatusInfo {
  final String zoneId;
  RegionStatus status;
  DateTime? discoveredAt;
  DateTime? cleansedAt;

  RegionStatusInfo({
    required this.zoneId,
    required this.status,
    this.discoveredAt,
    this.cleansedAt,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;             // emoji
  final bool hidden;             // hidden achievements don't appear until earned
  final String? titleUnlock;     // optional Title text granted on unlock

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.hidden = false,
    this.titleUnlock,
  });
}

class Achievements {
  static const List<Achievement> all = [];  // empty in Spec 1; Spec 6 fills
}

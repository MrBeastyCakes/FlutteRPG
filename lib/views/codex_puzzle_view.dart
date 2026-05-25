import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/codex.dart';
import '../models/quest.dart';
import '../models/skill.dart';
import '../theme/game_theme.dart';
import '../widgets/reading_overlay.dart';

class CodexPuzzleView extends StatefulWidget {
  final CodexTag tag;
  const CodexPuzzleView({super.key, required this.tag});

  @override
  State<CodexPuzzleView> createState() => _CodexPuzzleViewState();
}

class _CodexPuzzleViewState extends State<CodexPuzzleView> {
  static bool _showedFailedOnboarding = false;
  late List<CodexFragment> _ordered;
  List<bool>? _lastCorrectness;
  StreamSubscription<PuzzleResult>? _sub;

  CodexFragment? get _correctFirstFragment {
    final expected = CodexFragments.all
        .where((f) => f.tag == widget.tag)
        .toList()
      ..sort((a, b) => a.orderInTag.compareTo(b.orderInTag));
    return expected.isNotEmpty ? expected.first : null;
  }

  @override
  void initState() {
    super.initState();
    final engine = Provider.of<GameEngine>(context, listen: false);
    final available = CodexFragments.all
        .where((f) =>
            f.tag == widget.tag &&
            engine.knownCodexFragmentIds.contains(f.id))
        .toList();
    // Shuffle initial order so player can't trivially see the data file
    available.shuffle();
    _ordered = available;

    _sub = engine.puzzleResults.listen((result) {
      if (result.tag != widget.tag) return;
      setState(() => _lastCorrectness = result.correctness);
      if (result.reading != null) {
        _showReading(result.reading!);
      } else {
        if (!_showedFailedOnboarding) {
          _showedFailedOnboarding = true;
          _showFailedOnboardingDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showReading(CodexReading reading) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Reading',
      pageBuilder: (context, _, __) => ReadingOverlay(
        reading: reading,
        onDismiss: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // close puzzle view too
        },
      ),
    );
  }

  void _lock() {
    final engine = Provider.of<GameEngine>(context, listen: false);
    final ids = _ordered.map((f) => f.id).toList();
    engine.lockCodexPuzzle(widget.tag, ids);
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: Text('${widget.tag.name[0].toUpperCase()}${widget.tag.name.substring(1)} — Order the Fragments'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Drag to reorder. Lock when ready.',
              style: TextStyle(color: GameTheme.textMuted),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _ordered.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ordered.removeAt(oldIndex);
                  _ordered.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final fragment = _ordered[index];
                final correctness = _lastCorrectness;
                Color? border;
                if (correctness != null && index < correctness.length) {
                  border = correctness[index] ? Colors.green : Colors.red;
                }
                return Card(
                  key: ValueKey(fragment.id),
                  color: GameTheme.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: border != null
                        ? BorderSide(color: border, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Text('${index + 1}.', style: const TextStyle(color: GameTheme.textMuted)),
                    title: Text(fragment.title, style: const TextStyle(color: Colors.white)),
                    subtitle: (engine.skillSubSpecs[SkillType.lore] == 'lore_translator' &&
                            (engine.puzzleAttempts[widget.tag] ?? 0) >= 5 &&
                            fragment.id == _correctFirstFragment?.id)
                        ? const Text('Translator Hint: Belongs in position 1', style: TextStyle(color: GameTheme.accentGold, fontSize: 11))
                        : null,
                    trailing: const Icon(Icons.drag_handle, color: GameTheme.textMuted),
                    onTap: () => _showFragmentText(fragment),
                  ),
                );
              },
            ),
          ),
          if (_lastCorrectness != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_lastCorrectness!.where((c) => c).length} of ${_lastCorrectness!.length} in correct place. (Wrong-Lock cost: −3 Lore XP)',
                style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _ordered.length == 10 ? _lock : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.accentGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Lock Sequence', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFragmentText(CodexFragment fragment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: Text(fragment.title, style: const TextStyle(color: Colors.white)),
        content: Text(fragment.text, style: const TextStyle(color: GameTheme.textLight, fontStyle: FontStyle.italic)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFailedOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: GameTheme.accentGold),
            SizedBox(width: 8),
            Text('Puzzle Tip', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'It seems the sequence wasn\'t correct. Tapping on any fragment card in the list lets you read its content. Pay close attention to the chronological clues, dates, and narrative hints in the text to solve the puzzle!',
          style: TextStyle(color: GameTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

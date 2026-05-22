import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

class LoreView extends StatefulWidget {
  const LoreView({Key? key}) : super(key: key);

  @override
  State<LoreView> createState() => _LoreViewState();
}

class _LoreViewState extends State<LoreView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: GameTheme.accentGold,
          labelColor: GameTheme.accentGold,
          unselectedLabelColor: GameTheme.textMuted,
          tabs: const [
            Tab(text: 'Codex & History', icon: Icon(Icons.menu_book)),
            Tab(text: 'Recipe Blueprint', icon: Icon(Icons.auto_awesome)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCodexTab(),
              _buildRecipesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodexTab() {
    final books = [
      {
        'title': 'The Cataclysm of Elaria',
        'icon': '🌋',
        'chapter': 'Chapter 1: The Shattering',
        'content':
            'Three hundred years ago, the land of Elaria was whole. When the Core cracked, the mountains bled iron, and the whispering trees began to hum with magic. It is said the spirits of the forest created the level cap gates to prevent greedy miners and woodcutters from destroying the balance of the valley. Only those who complete the Masterwork challenges can gain their trust.',
      },
      {
        'title': 'The Legend of Ironwood',
        'icon': '🪵',
        'chapter': 'Chapter 2: Heart of the Oak',
        'content':
            'Deep in the Whispering Woods, there grows a timber that does not burn and cannot be cut by common stone. The Ironbark tree absorbs metal deposits from the subterranean veins, coating its trunk in steel-like bark. To cut it, a lumberjack must reinforce their axe head with pure iron and strikes along the stress lines of the grains.',
      },
      {
        'title': 'Secrets of the Glinting Core',
        'icon': '🔮',
        'chapter': 'Chapter 3: The Depths',
        'content':
            'Deep in the Darkstone Mines lie crystal clusters that store natural energy. The Glinting Core is highly volatile. Striking it blindly causes shockwaves that crumble cavern supports. An apprentice miner must learn structural vaulting to extract it without triggering a fatal cave-in.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: GameTheme.border, width: 1),
          ),
          child: ExpansionTile(
            leading: Text(
              book['icon']!,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              book['title']!,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              book['chapter']!,
              style: const TextStyle(color: GameTheme.textMuted, fontSize: 11),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                child: Text(
                  book['content']!,
                  style: const TextStyle(color: GameTheme.textLight, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipesTab() {
    final recipes = [
      {
        'name': 'Iron Axe',
        'icon': '🪓',
        'skill': 'Crafting Lvl 10',
        'desc': 'Reinforced lumberjacking tool. Increases chop speed by 15%.',
        'reqs': ['🪵 5 Willow Logs', '⛰️ 5 Iron Ores'],
      },
      {
        'name': 'Iron Pickaxe',
        'icon': '⛏️',
        'skill': 'Crafting Lvl 10',
        'desc': 'Sturdy excavation tool. Increases mine speed by 15%.',
        'reqs': ['🪵 5 Willow Logs', '⛰️ 5 Iron Ores'],
      },
      {
        'name': 'Philter of Clarity',
        'icon': '🧪',
        'skill': 'Herbalism Lvl 10',
        'desc': 'Unlock trial elixir. Clears the mind to unlock skill limits.',
        'reqs': ['🍇 2 Nightshade Berries', '🫐 3 Wild Berries'],
      },
      {
        'name': 'Baked Potato',
        'icon': '🥔',
        'skill': 'Cooking Lvl 5',
        'desc': 'Satisfying meal that heals 15 Health and 5 Energy.',
        'reqs': ['🥔 1 Raw Potato', '🪵 1 Oak Log'],
      },
      {
        'name': 'Herbal Tea',
        'icon': '🍵',
        'skill': 'Cooking Lvl 8',
        'desc': 'A warm beverage restoring 30 Energy.',
        'reqs': ['🪻 2 Wild Bluebells', '🍵 Hot Water'],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: GameTheme.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['icon'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recipe['name'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            recipe['skill'] as String,
                            style: const TextStyle(color: GameTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe['desc'] as String,
                        style: const TextStyle(color: GameTheme.textLight, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // Requirements list
                      Wrap(
                        spacing: 8,
                        children: (recipe['reqs'] as List<String>).map((req) {
                          return Chip(
                            backgroundColor: const Color(0xFF151D26),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: const BorderSide(color: GameTheme.border, width: 0.5),
                            ),
                            label: Text(
                              req,
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AiHelperPage extends StatefulWidget {
  const AiHelperPage({super.key});

  @override
  State<AiHelperPage> createState() => _AiHelperPageState();
}

class _AiHelperPageState extends State<AiHelperPage> {
  final TextEditingController promptController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  List<String> pantryIngredients = [];
  List<_HelperMessage> messages = [];

  bool isLoading = true;
  bool isResponding = false;

  @override
  void initState() {
    super.initState();

    loadPantry();
  }

  Future<void> loadPantry() async {
    final Box pantryBox = Hive.isBoxOpen('pantry')
        ? Hive.box('pantry')
        : await Hive.openBox('pantry');

    final List<String> loadedIngredients =
        pantryBox.keys
            .where((dynamic key) => pantryBox.get(key) == true)
            .map((dynamic key) => key.toString().trim())
            .where((String ingredient) => ingredient.isNotEmpty)
            .toList()
          ..sort((String first, String second) {
            return first.toLowerCase().compareTo(second.toLowerCase());
          });

    if (!mounted) return;

    setState(() {
      pantryIngredients = loadedIngredients;
      isLoading = false;
    });
  }

  Future<void> submitPrompt([String? suggestedPrompt]) async {
    final String prompt = (suggestedPrompt ?? promptController.text).trim();

    if (prompt.isEmpty || isResponding) {
      return;
    }

    setState(() {
      messages.add(_HelperMessage(text: prompt, isUser: true));

      promptController.clear();
      isResponding = true;
    });

    scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 450));

    final String response = createLocalResponse(prompt);

    if (!mounted) return;

    setState(() {
      messages.add(_HelperMessage(text: response, isUser: false));

      isResponding = false;
    });

    scrollToBottom();
  }

  String createLocalResponse(String prompt) {
    final String lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.contains('pantry') ||
        lowerPrompt.contains('what can i make') ||
        lowerPrompt.contains('meal idea') ||
        lowerPrompt.contains('dinner idea')) {
      return createPantryResponse();
    }

    if (lowerPrompt.contains('substitute') ||
        lowerPrompt.contains('substitution') ||
        lowerPrompt.contains('instead of') ||
        lowerPrompt.contains('replace')) {
      return createSubstitutionResponse(lowerPrompt);
    }

    if (lowerPrompt.contains('egg')) {
      return '''
Egg substitutions depend on what the egg is doing in the recipe:

• For binding: use 1 tablespoon of ground flaxseed mixed with 3 tablespoons of water.
• For moisture: use around 60g of yoghurt or mashed banana.
• For cakes: use a commercial egg replacer or 1/4 teaspoon bicarbonate of soda with 1 tablespoon vinegar.
• For glazing: use milk or melted butter.

The best option depends on the recipe, so check whether the egg is mainly binding, enriching or helping the mixture rise.
''';
    }

    if (lowerPrompt.contains('cream')) {
      return '''
Possible cream substitutions include:

• Greek yoghurt for sauces and dips.
• Crème fraîche for creamy savoury dishes.
• Milk mixed with a little butter for cooking.
• Coconut milk for curries and some desserts.
• Soft cheese loosened with milk for pasta sauces.

Add yoghurt on a low heat to reduce the chance of it splitting.
''';
    }

    if (lowerPrompt.contains('butter')) {
      return '''
Butter can often be replaced with:

• Margarine in most baking recipes.
• Neutral oil in cakes and traybakes.
• Olive oil in savoury cooking.
• Greek yoghurt in some cakes.
• Applesauce for a lower-fat cake, although the texture will be softer.

For baking, use a replacement designed for the same purpose rather than automatically swapping equal quantities.
''';
    }

    if (lowerPrompt.contains('too salty')) {
      return '''
To rescue food that is too salty:

• Add more unsalted ingredients to dilute it.
• Add water or unsalted stock to soups and sauces.
• Add dairy, coconut milk or yoghurt where suitable.
• Add acidity such as lemon juice or vinegar to balance the flavour.
• Serve it with plain rice, pasta, potatoes or bread.

Avoid adding sugar immediately because it may make the dish both salty and sweet rather than properly balanced.
''';
    }

    if (lowerPrompt.contains('too spicy')) {
      return '''
To reduce heat in a spicy dish:

• Add yoghurt, cream, coconut milk or another creamy ingredient.
• Add more tomatoes, stock or other base ingredients.
• Serve it with rice, bread or potatoes.
• Add a little sweetness if it suits the dish.
• Add lemon or lime juice to balance the flavour.

Water alone usually spreads the chilli heat rather than removing it.
''';
    }

    if (lowerPrompt.contains('thicken')) {
      return '''
Ways to thicken a sauce include:

• Simmer it uncovered to reduce the liquid.
• Mix cornflour with cold water before stirring it in.
• Add a flour-and-butter paste.
• Stir in cream cheese or grated cheese.
• Blend part of the sauce if it contains vegetables or beans.

Add thickening ingredients gradually because sauces often continue to thicken as they cool.
''';
    }

    return '''
I can currently help with:

• Meal ideas using your pantry
• Common ingredient substitutions
• Fixing food that is too salty or spicy
• Thickening sauces
• Basic cooking and baking questions

Try asking “What can I make from my pantry?” or “What can I use instead of eggs?”

This is the local helper version. A later update can connect it to a full AI service for more detailed and recipe-specific answers.
''';
  }

  String createPantryResponse() {
    if (pantryIngredients.isEmpty) {
      return '''
Your pantry does not currently contain any ingredients marked as in stock.

Open My Pantry, add your ingredients and tick the ones you currently have. I can then use them to suggest possible meals.
''';
    }

    final Set<String> normalisedIngredients = pantryIngredients
        .map((String ingredient) => ingredient.toLowerCase())
        .toSet();

    final List<String> suggestions = [];

    bool hasIngredient(List<String> possibleNames) {
      return normalisedIngredients.any((String ingredient) {
        return possibleNames.any((String name) => ingredient.contains(name));
      });
    }

    final bool hasEggs = hasIngredient(<String>['egg']);

    final bool hasCheese = hasIngredient(<String>[
      'cheese',
      'cheddar',
      'mozzarella',
    ]);

    final bool hasPasta = hasIngredient(<String>[
      'pasta',
      'spaghetti',
      'penne',
    ]);

    final bool hasRice = hasIngredient(<String>['rice']);

    final bool hasPotatoes = hasIngredient(<String>['potato']);

    final bool hasTomatoes = hasIngredient(<String>['tomato']);

    final bool hasOnions = hasIngredient(<String>['onion']);

    final bool hasChicken = hasIngredient(<String>['chicken']);

    final bool hasBeans = hasIngredient(<String>['bean', 'chickpea', 'lentil']);

    final bool hasBread = hasIngredient(<String>['bread']);

    if (hasEggs && hasCheese) {
      suggestions.add('Cheese omelette or frittata');
    }

    if (hasPasta && hasTomatoes) {
      suggestions.add(
        hasOnions ? 'Tomato and onion pasta' : 'Simple tomato pasta',
      );
    }

    if (hasPasta && hasCheese) {
      suggestions.add('Creamy or cheesy pasta');
    }

    if (hasRice && hasChicken) {
      suggestions.add('Chicken rice bowl or simple chicken fried rice');
    }

    if (hasRice && hasBeans) {
      suggestions.add('Bean and rice bowl');
    }

    if (hasPotatoes && hasCheese) {
      suggestions.add('Cheesy baked potatoes');
    }

    if (hasPotatoes && hasEggs) {
      suggestions.add('Potato hash with eggs');
    }

    if (hasBread && hasCheese) {
      suggestions.add('Cheese toastie');
    }

    if (hasTomatoes && hasBeans) {
      suggestions.add('Tomato and bean stew');
    }

    if (suggestions.isEmpty) {
      suggestions.addAll(<String>[
        'A soup using your available vegetables and cupboard ingredients',
        'A traybake seasoned with herbs and spices',
        'A mixed rice, pasta or grain bowl',
      ]);
    }

    final String ingredientList = pantryIngredients.take(12).join(', ');

    final String additionalIngredientText = pantryIngredients.length > 12
        ? ' and ${pantryIngredients.length - 12} more'
        : '';

    final String suggestionList = suggestions
        .take(5)
        .map((String suggestion) => '• $suggestion')
        .join('\n');

    return '''
You currently have:

$ingredientList$additionalIngredientText

Possible meal ideas:

$suggestionList

For a more accurate match with recipes you have already saved, use the What Can I Make? section from the Home page.
''';
  }

  String createSubstitutionResponse(String prompt) {
    if (prompt.contains('egg')) {
      return '''
For one egg, possible substitutions include:

• 1 tablespoon ground flaxseed plus 3 tablespoons water
• Around 60g yoghurt
• Around 60g mashed banana for sweet recipes
• A commercial egg replacer

The best choice depends on whether the egg is needed for binding, moisture or rising.
''';
    }

    if (prompt.contains('butter')) {
      return '''
Butter can usually be replaced with margarine, baking spread or oil.

For cakes, approximately 80ml of oil can often replace 100g of butter, although the final texture may be softer. For frying or savoury cooking, olive oil is usually suitable.
''';
    }

    if (prompt.contains('milk')) {
      return '''
Milk can often be replaced with:

• Oat, soya or almond milk
• Lactose-free milk
• Water mixed with a little cream
• Evaporated milk diluted with water

Use an unsweetened alternative in savoury recipes.
''';
    }

    if (prompt.contains('cream')) {
      return '''
Cream can often be replaced with Greek yoghurt, crème fraîche, coconut milk or soft cheese loosened with milk.

Use a low heat when adding yoghurt because it can split if boiled.
''';
    }

    if (prompt.contains('flour')) {
      return '''
The correct flour replacement depends heavily on the recipe.

• Plain flour can sometimes replace self-raising flour when baking powder is added.
• Cornflour can thicken sauces but cannot directly replace flour in most cakes.
• Gluten-free flour blends work best when specifically designed for baking.

Tell me what recipe you are making for a more suitable substitution.
''';
    }

    return '''
Tell me which ingredient you need to replace.

For example:

• What can I use instead of eggs?
• Can I replace cream in a pasta sauce?
• What can I use instead of butter in a cake?
• Can I replace plain flour with self-raising flour?
''';
  }

  void useSuggestedPrompt(String prompt) {
    promptController.text = prompt;

    submitPrompt(prompt);
  }

  void clearConversation() {
    setState(() {
      messages = [];
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    promptController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Kitchen Helper'),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear conversation',
              onPressed: clearConversation,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          IconButton(
            tooltip: 'Refresh pantry',
            onPressed: loadPantry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? buildWelcomeView()
                      : buildConversationView(),
                ),
                buildPromptArea(),
              ],
            ),
    );
  }

  Widget buildWelcomeView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF625F85),
                    size: 31,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your cooking assistant',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Ask for meal ideas, substitutions or help fixing a dish.',
                        style: TextStyle(color: Color(0xFF7C7470), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1DA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.kitchen_outlined, color: Color(0xFF9A6824)),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  pantryIngredients.isEmpty
                      ? 'No pantry ingredients are currently marked in stock.'
                      : '${pantryIngredients.length} pantry '
                            '${pantryIngredients.length == 1 ? 'ingredient is' : 'ingredients are'} '
                            'currently marked in stock.',
                  style: const TextStyle(
                    color: Color(0xFF75501E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Try asking',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _SuggestedPromptCard(
          icon: Icons.restaurant_menu,
          title: 'What can I make from my pantry?',
          subtitle: 'Get meal ideas using in-stock ingredients',
          onTap: () {
            useSuggestedPrompt('What can I make from my pantry?');
          },
        ),
        _SuggestedPromptCard(
          icon: Icons.swap_horiz,
          title: 'What can I use instead of eggs?',
          subtitle: 'Find a suitable ingredient substitution',
          onTap: () {
            useSuggestedPrompt('What can I use instead of eggs?');
          },
        ),
        _SuggestedPromptCard(
          icon: Icons.local_fire_department_outlined,
          title: 'How do I fix food that is too spicy?',
          subtitle: 'Balance an overly hot dish',
          onTap: () {
            useSuggestedPrompt('How do I fix food that is too spicy?');
          },
        ),
        _SuggestedPromptCard(
          icon: Icons.soup_kitchen_outlined,
          title: 'How can I thicken a sauce?',
          subtitle: 'Choose the right thickening method',
          onTap: () {
            useSuggestedPrompt('How can I thicken a sauce?');
          },
        ),
      ],
    );
  }

  Widget buildConversationView() {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      itemCount: messages.length + (isResponding ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == messages.length) {
          return const _TypingMessage();
        }

        return _MessageBubble(message: messages[index]);
      },
    );
  }

  Widget buildPromptArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7E0DC))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: promptController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask a cooking question…',
                  filled: true,
                  fillColor: const Color(0xFFF8F5F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  submitPrompt();
                },
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: isResponding
                  ? null
                  : () {
                      submitPrompt();
                    },
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperMessage {
  final String text;
  final bool isUser;

  const _HelperMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _HelperMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFFD96C3F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 20),
          ),
          boxShadow: message.isUser
              ? null
              : const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 2),
                    color: Color(0x12000000),
                  ),
                ],
        ),
        child: Text(
          message.text.trim(),
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF3E3936),
            height: 1.45,
            fontSize: 15.5,
          ),
        ),
      ),
    );
  }
}

class _TypingMessage extends StatelessWidget {
  const _TypingMessage();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _SuggestedPromptCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestedPromptCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3D5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFD96C3F)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF7C7470)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8A817C)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CookingModePage extends StatefulWidget {
  final String recipeName;
  final String ingredients;
  final String method;
  final String prepTime;
  final String cookTime;
  final String servings;

  const CookingModePage({
    super.key,
    required this.recipeName,
    required this.ingredients,
    required this.method,
    this.prepTime = '',
    this.cookTime = '',
    this.servings = '',
  });

  @override
  State<CookingModePage> createState() =>
      _CookingModePageState();
}

class _CookingModePageState
    extends State<CookingModePage> {
  late final List<String> ingredientLines;
  late final List<String> methodSteps;

  final Set<int> checkedIngredients = {};

  int currentStepIndex = 0;
  bool showIngredients = true;

  @override
  void initState() {
    super.initState();

    ingredientLines = _splitIngredients(
      widget.ingredients,
    );

    methodSteps = _splitMethod(
      widget.method,
    );
  }

  List<String> _splitIngredients(
    String ingredients,
  ) {
    return ingredients
        .split('\n')
        .map(
          (String line) => line.trim(),
        )
        .where(
          (String line) => line.isNotEmpty,
        )
        .toList();
  }

  List<String> _splitMethod(
    String method,
  ) {
    final List<String> lines = method
        .split('\n')
        .map(
          (String line) => line.trim(),
        )
        .where(
          (String line) => line.isNotEmpty,
        )
        .toList();

    if (lines.length > 1) {
      return lines
          .map(_removeStepNumber)
          .where(
            (String step) => step.isNotEmpty,
          )
          .toList();
    }

    final List<String> sentenceSteps = method
        .split(
          RegExp(r'(?<=[.!?])\s+'),
        )
        .map(
          (String step) =>
              step.trim(),
        )
        .where(
          (String step) =>
              step.isNotEmpty,
        )
        .toList();

    if (sentenceSteps.isNotEmpty) {
      return sentenceSteps;
    }

    return <String>[
      'No cooking instructions saved.',
    ];
  }

  String _removeStepNumber(
    String value,
  ) {
    return value.replaceFirst(
      RegExp(
        r'^\s*(step\s*)?\d+[\.\):\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
  }

  void toggleIngredient(
    int index,
  ) {
    setState(() {
      if (checkedIngredients
          .contains(index)) {
        checkedIngredients
            .remove(index);
      } else {
        checkedIngredients.add(index);
      }
    });
  }

  void showPreviousStep() {
    if (currentStepIndex <= 0) {
      return;
    }

    setState(() {
      currentStepIndex--;
    });
  }

  void showNextStep() {
    if (currentStepIndex >=
        methodSteps.length - 1) {
      return;
    }

    setState(() {
      currentStepIndex++;
    });
  }

  void restartCookingMode() {
    setState(() {
      currentStepIndex = 0;
      checkedIngredients.clear();
      showIngredients = true;
    });
  }

  double get progress {
    if (methodSteps.isEmpty) {
      return 0;
    }

    return (currentStepIndex + 1) /
        methodSteps.length;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'Cooking Mode',
        ),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed:
                restartCookingMode,
            icon: const Icon(
              Icons.restart_alt,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _RecipeCookingHeader(
              recipeName:
                  widget.recipeName,
              prepTime:
                  widget.prepTime,
              cookTime:
                  widget.cookTime,
              servings:
                  widget.servings,
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                8,
              ),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(
                      Icons
                          .checklist_outlined,
                    ),
                    label: Text(
                      'Ingredients',
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(
                      Icons
                          .format_list_numbered,
                    ),
                    label: Text(
                      'Steps',
                    ),
                  ),
                ],
                selected: <bool>{
                  showIngredients,
                },
                onSelectionChanged:
                    (Set<bool> selection) {
                  setState(() {
                    showIngredients =
                        selection.first;
                  });
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 220,
                ),
                child: showIngredients
                    ? _IngredientsView(
                        key: const ValueKey(
                          'ingredients',
                        ),
                        ingredients:
                            ingredientLines,
                        checkedIngredients:
                            checkedIngredients,
                        onToggle:
                            toggleIngredient,
                      )
                    : _MethodView(
                        key: const ValueKey(
                          'method',
                        ),
                        steps:
                            methodSteps,
                        currentStepIndex:
                            currentStepIndex,
                        progress:
                            progress,
                        onPrevious:
                            showPreviousStep,
                        onNext:
                            showNextStep,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCookingHeader
    extends StatelessWidget {
  final String recipeName;
  final String prepTime;
  final String cookTime;
  final String servings;

  const _RecipeCookingHeader({
    required this.recipeName,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasDetails =
        prepTime.isNotEmpty ||
            cookTime.isNotEmpty ||
            servings.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE7DFDA),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            recipeName,
            style: const TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.bold,
              height: 1.15,
            ),
          ),
          if (hasDetails) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                if (prepTime.isNotEmpty)
                  _CookingDetailChip(
                    icon:
                        Icons.schedule,
                    label:
                        'Prep $prepTime',
                  ),
                if (cookTime.isNotEmpty)
                  _CookingDetailChip(
                    icon: Icons
                        .local_fire_department_outlined,
                    label:
                        'Cook $cookTime',
                  ),
                if (servings.isNotEmpty)
                  _CookingDetailChip(
                    icon:
                        Icons.people_outline,
                    label:
                        'Serves $servings',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IngredientsView
    extends StatelessWidget {
  final List<String> ingredients;
  final Set<int> checkedIngredients;
  final ValueChanged<int> onToggle;

  const _IngredientsView({
    super.key,
    required this.ingredients,
    required this.checkedIngredients,
    required this.onToggle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (ingredients.isEmpty) {
      return const _CookingEmptyState(
        icon: Icons
            .shopping_basket_outlined,
        title:
            'No ingredients saved',
        message:
            'Return to the recipe and add the ingredient list first.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        30,
      ),
      itemCount: ingredients.length,
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final bool checked =
            checkedIngredients
                .contains(index);

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),
          elevation: 1,
          child: CheckboxListTile(
            value: checked,
            onChanged: (_) {
              onToggle(index);
            },
            controlAffinity:
                ListTileControlAffinity
                    .leading,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            title: Text(
              ingredients[index],
              style: TextStyle(
                fontSize: 18,
                height: 1.3,
                decoration: checked
                    ? TextDecoration
                        .lineThrough
                    : TextDecoration.none,
                color: checked
                    ? const Color(
                        0xFF8A817C,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MethodView
    extends StatelessWidget {
  final List<String> steps;
  final int currentStepIndex;
  final double progress;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MethodView({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.progress,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (steps.isEmpty) {
      return const _CookingEmptyState(
        icon:
            Icons.format_list_numbered,
        title:
            'No method saved',
        message:
            'Return to the recipe and add the cooking instructions first.',
      );
    }

    final bool isFirstStep =
        currentStepIndex == 0;

    final bool isLastStep =
        currentStepIndex ==
            steps.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        22,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${currentStepIndex + 1}/${steps.length}',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: Color(
                    0xFF7C7470,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Step ${currentStepIndex + 1}',
                      style:
                          const TextStyle(
                        color: Color(
                          0xFFD96C3F,
                        ),
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    Expanded(
                      child:
                          SingleChildScrollView(
                        child: Text(
                          steps[
                              currentStepIndex],
                          style:
                              const TextStyle(
                            fontSize: 25,
                            height: 1.45,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: isFirstStep
                      ? null
                      : onPrevious,
                  icon: const Icon(
                    Icons
                        .arrow_back_outlined,
                  ),
                  label: const Text(
                    'Previous',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLastStep
                      ? null
                      : onNext,
                  icon: const Icon(
                    Icons
                        .arrow_forward_outlined,
                  ),
                  label: Text(
                    isLastStep
                        ? 'Finished'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CookingDetailChip
    extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CookingDetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE5),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(
              0xFFD96C3F,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: Color(
                0xFF695F5A,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingEmptyState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CookingEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: const Color(
                0xFFAAA19C,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(
                  0xFF7C7470,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
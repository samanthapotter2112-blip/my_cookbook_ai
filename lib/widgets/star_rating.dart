import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double iconSize;
  final bool enabled;

  const StarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.iconSize = 32,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: rating == 0
          ? 'No rating selected'
          : '$rating out of 5 stars',
      child: Wrap(
        spacing: 2,
        children: List<Widget>.generate(
          5,
          (int index) {
            final int starNumber = index + 1;
            final bool isSelected =
                starNumber <= rating;

            return IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: iconSize + 6,
                minHeight: iconSize + 6,
              ),
              tooltip: enabled
                  ? 'Rate $starNumber out of 5'
                  : null,
              onPressed: enabled
                  ? () {
                      if (rating == starNumber) {
                        onChanged(0);
                      } else {
                        onChanged(starNumber);
                      }
                    }
                  : null,
              icon: Icon(
                isSelected
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: iconSize,
                color: isSelected
                    ? const Color(0xFFE0A12F)
                    : const Color(0xFFAAA19C),
              ),
            );
          },
        ),
      ),
    );
  }
}
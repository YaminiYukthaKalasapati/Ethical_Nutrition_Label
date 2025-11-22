import 'package:flutter/material.dart';

class MultiSelectChips extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selectedValues;
  final void Function(String) onToggle;

  const MultiSelectChips({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
              selectedColor: Colors.teal.shade200,
              checkmarkColor: Colors.teal.shade900,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.teal.shade900 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

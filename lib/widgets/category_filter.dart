import 'package:flutter/material.dart';
import '../models/sms_message.dart';

class CategoryFilter extends StatelessWidget {
  final SmsCategory? selectedCategory;
  final Function(SmsCategory?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildChip(context, 'All', '📱', null, selectedCategory == null),
          ...SmsCategory.values.map(
            (category) => _buildChip(
              context,
              category.displayName,
              category.icon,
              category,
              selectedCategory == category,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    String icon,
    SmsCategory? category,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) {
          onCategorySelected(isSelected ? null : category);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

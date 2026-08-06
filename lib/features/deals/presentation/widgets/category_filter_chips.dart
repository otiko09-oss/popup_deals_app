import 'package:flutter/material.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';

class CategoryFilterChips extends StatefulWidget {
  const CategoryFilterChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    super.key,
  });
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final isSelected = widget.selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  widget.onCategoryChanged(category);
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
}

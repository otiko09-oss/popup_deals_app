import 'package:flutter/material.dart';

import '../../../../core/constants/marketplace_categories.dart';

/// Widget for selecting a category from predefined list
class CategorySelector extends StatefulWidget {
  const CategorySelector({
    required this.onCategorySelected,
    super.key,
    this.selectedCategory,
    this.categories,
    this.errorText,
  });
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final List<String>? categories;
  final String? errorText;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  static final List<String> defaultCategories = MarketplaceCategories.ids;

  late List<String> _categories;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories ?? defaultCategories;
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorText != null
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('Select a category'),
              items: _categories
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  widget.onCategorySelected(newValue);
                }
              },
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
}

/// Widget for adding tags to a deal
class TagsInput extends StatefulWidget {
  const TagsInput({
    required this.onTagsChanged,
    super.key,
    this.initialTags = const [],
  });
  final List<String> initialTags;
  final Function(List<String>) onTagsChanged;

  @override
  State<TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<TagsInput> {
  late List<String> _tags;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      widget.onTagsChanged(_tags);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor: Colors.green.shade100,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (_tags.length < 5)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add tag and press Add',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
        ],
      );
}

import 'package:flutter/material.dart';

import '../../core/constants/incident_category.dart';
import '../../core/constants/incident_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Search field, category filter and status chips. It holds no filter state
/// of its own: the values come in and changes go out through callbacks, so
/// both the student and staff lists can reuse it.
class SearchAndFilterBar extends StatefulWidget {
  const SearchAndFilterBar({
    super.key,
    required this.query,
    required this.statusFilter,
    required this.categoryFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  final String query;
  final IncidentStatus? statusFilter;
  final IncidentCategory? categoryFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<IncidentStatus?> onStatusChanged;
  final ValueChanged<IncidentCategory?> onCategoryChanged;

  @override
  State<SearchAndFilterBar> createState() => _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends State<SearchAndFilterBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  /// Popup menu values. -1 stands for "All categories" because a popup menu
  /// treats a null value as "dismissed".
  static const int _allCategories = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.categoryFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => TextField(
                  controller: _controller,
                  onChanged: widget.onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search reports',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              widget.onQueryChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<int>(
              tooltip: 'Filter by category',
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (index) => widget.onCategoryChanged(
                index == _allCategories ? null : IncidentCategory.values[index],
              ),
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: _allCategories,
                  checked: category == null,
                  child: const Text('All categories'),
                ),
                for (final option in IncidentCategory.values)
                  CheckedPopupMenuItem(
                    value: option.index,
                    checked: category == option,
                    child: Text(option.label),
                  ),
              ],
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: category == null
                      ? AppColors.surface
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.inputRadius),
                  border: Border.all(
                    color: category == null
                        ? AppColors.inputBorder
                        : AppColors.primary,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: category == null
                      ? AppColors.textSecondary
                      : AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: 'All',
                selected: widget.statusFilter == null,
                onSelected: () => widget.onStatusChanged(null),
              ),
              for (final status in IncidentStatus.values)
                _StatusChip(
                  label: status.label,
                  selected: widget.statusFilter == status,
                  onSelected: () => widget.onStatusChanged(status),
                ),
              if (category != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InputChip(
                    avatar: Icon(
                      category.icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(category.label),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                    deleteIconColor: AppColors.primary,
                    onDeleted: () => widget.onCategoryChanged(null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class FilterBarChipList extends StatefulWidget {
  final List<FilterBarChip> buildFilterChips;

  const FilterBarChipList({super.key, required this.buildFilterChips});

  @override
  State<FilterBarChipList> createState() => _FilterBarChipListState();
}

class _FilterBarChipListState extends State<FilterBarChipList> {
  final chipsListController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    chipsListController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: chipsListController,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: chipsListController,
        scrollDirection: Axis.horizontal,
        child: Row(children: widget.buildFilterChips),
      ),
    );
  }
}

class FilterBarChip extends StatelessWidget {
  final Widget label;
  final void Function()? onDeleted;
  final String? deleteButtonTooltipMessage;

  const FilterBarChip({super.key, required this.label, this.onDeleted, this.deleteButtonTooltipMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        deleteIcon: const Icon(Icons.close, size: 20),
        onDeleted: onDeleted,
        deleteButtonTooltipMessage: deleteButtonTooltipMessage,
        label: label,
      ),
    );
  }
}

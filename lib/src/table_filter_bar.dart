part of 'paged_datatable.dart';

class TableFilterBar<K extends Comparable<K>, T> extends StatelessWidget {
  final Widget? trailing;

  const TableFilterBar({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final controller = TableControllerProvider.of<K, T>(context);
    final theme = PagedDataTableTheme.of(context);
    final localizations = PagedDataTableLocalization.of(context);

    return FilterBar(
      controller: controller,
      theme: theme,
      buttonIcons: {"default": Icons.filter_list_rounded},
      buttonTooltips: {"default": localizations.showFilterMenuTooltip},
      menuBuilder: (String button) => Form(
        key: controller._filtersFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(localizations.filterByTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...controller._filtersState.entries
                .where((element) => element.value._filter.visible)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: entry.value._filter.buildPicker(context, entry.value),
                  ),
                ),
          ],
        ),
      ),
      onRemoveFilters: (String button) {
        controller.removeFilters();
      },
      onApplyFilters: (String button) {
        // to ensure onSaved is called on filters
        controller._filtersFormKey.currentState!.save();
        controller.applyFilters();
      },
      center: ListenableBuilder(
        listenable: controller,
        builder: (context, child) => FilterBarChipList(
          buildFilterChips: controller._filtersState.values
              .where((element) => element.value != null)
              .map(
                (e) => FilterBarChip(
                  onDeleted: () {
                    controller.removeFilter(e._filter.id);
                  },
                  label: Text((e._filter as dynamic).chipFormatter(e.value)),
                ),
              )
              .toList(),
        ),
      ),
      trailing: trailing,
    );
  }
}

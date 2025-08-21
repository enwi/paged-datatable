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
      menuButtons: [
        FilterBarMenuButton(
          icon: Icons.filter_list_rounded,
          tooltip: localizations.showFilterMenuTooltip,
          onRemoveFilters: () => controller.removeFilters(),
          onCancelFilters: () {},
          onApplyFilters: () {
            // to ensure onSaved is called on filters
            controller._filtersFormKey.currentState!.save();
            controller.applyFilters();
          },
          menuBuilder: () => Form(
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
        ),
      ],

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

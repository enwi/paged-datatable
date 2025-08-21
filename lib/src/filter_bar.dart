part of 'paged_datatable.dart';

/// The filter bar is displayed above the table header
class FilterBar extends StatelessWidget {
  /// Controller for FilterBar
  final FilterBarController controller;

  /// Theming for FilterBar
  final FilterBarThemeData theme;

  /// All filter bar menu buttons
  final List<FilterBarMenuButton> menuButtons;

  /// Optional leading widget
  final Widget? leading;

  /// Optional center widget, usually [FilterBarChipList]
  final Widget? center;

  /// Optional trailing widget
  final Widget? trailing;

  const FilterBar({
    super.key,
    required this.controller,
    required this.theme,
    required this.menuButtons,
    this.leading,
    this.center,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox(
      height: theme.filterBarHeight,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /* Leading widget */
              ?leading,

              /* Buttons and center widget */
              Flexible(
                child: Row(
                  children: [
                    /* Filter buttons */
                    Container(
                      margin: theme.padding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...menuButtons.map(
                            (button) => IconButton(
                              padding: theme.cellPadding,
                              onPressed: controller.isFetching()
                                  ? null
                                  : () => _showFilterOverlay(
                                      context: context,
                                      theme: theme,
                                      menuBuilder: button.menuBuilder,
                                      onRemoveFilters: button.onRemoveFilters,
                                      onCancelFilters: button.onCancelFilters,
                                      onApplyFilters: button.onApplyFilters,
                                    ),
                              tooltip: button.tooltip,
                              icon: Icon(button.icon),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /* Center widget */
                    if (center != null) Expanded(child: center!),
                  ],
                ),
              ),

              /* Trailing widget */
              ?trailing,
            ],
          );
        },
      ),
    );

    if (theme.chipTheme != null) {
      child = ChipTheme(data: theme.chipTheme!, child: child);
    }

    return child;
  }

  Future<void> _showFilterOverlay({
    required final BuildContext context,
    required final FilterBarThemeData theme,
    required final Widget Function(BuildContext context) menuBuilder,
    final void Function()? onRemoveFilters,
    final void Function()? onCancelFilters,
    final void Function()? onApplyFilters,
  }) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final bool isBottomSheet = mediaWidth < theme.filterDialogBreakpoint;

    if (isBottomSheet) {
      return showModalBottomSheet(
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        context: context,
        builder: (context) => _FiltersDialog(
          theme: theme,
          menuBuilder: menuBuilder,
          onRemoveFilters: onRemoveFilters,
          onCancelFilters: onCancelFilters,
          onApplyFilters: onApplyFilters,
          availableWidth: mediaWidth,
          rect: null,
        ),
      );
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = RelativeRect.fromLTRB(offset.dx + 10, offset.dy + renderBox.size.height - 10, 0, 0);

    return showDialog(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => _FiltersDialog(
        theme: theme,
        menuBuilder: menuBuilder,
        onRemoveFilters: onRemoveFilters,
        onCancelFilters: onCancelFilters,
        onApplyFilters: onApplyFilters,
        availableWidth: mediaWidth,
        rect: rect,
      ),
    );
  }
}

class _FiltersDialog extends StatelessWidget {
  final FilterBarThemeData theme;
  final Widget Function(BuildContext context) menuBuilder;
  final void Function()? onRemoveFilters;
  final void Function()? onCancelFilters;
  final void Function()? onApplyFilters;
  final double availableWidth;
  final RelativeRect? rect;

  const _FiltersDialog({
    required this.theme,
    required this.menuBuilder,
    this.onRemoveFilters,
    this.onCancelFilters,
    this.onApplyFilters,
    required this.availableWidth,
    this.rect,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = PagedDataTableLocalization.of(context);

    Widget filtersList = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
      child: menuBuilder.call(context),
    );

    final buttons = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (onRemoveFilters != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
              onPressed: () {
                Navigator.pop(context);
                onRemoveFilters?.call();
              },
              child: Text(localizations.removeAllFiltersButtonText),
            ),

          const Spacer(),

          if (onCancelFilters != null)
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
              onPressed: () {
                Navigator.pop(context);
                onCancelFilters?.call();
              },
              child: Text(localizations.cancelFilteringButtonText),
            ),

          if (onCancelFilters != null) ...[
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
              onPressed: () {
                Navigator.pop(context);
                onApplyFilters?.call();
              },
              child: Text(localizations.applyFilterButtonText),
            ),
          ],
        ],
      ),
    );

    if (rect == null) {
      filtersList = Expanded(child: filtersList);
    }

    Widget child = Material(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [filtersList, const Divider(height: 0), buttons],
      ),
    );

    if (rect != null) {
      return Stack(
        fit: StackFit.loose,
        children: [
          Positioned(
            top: rect!.top,
            left: rect!.left,
            child: Container(
              width: availableWidth * theme.filterDialogWidthFactor,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black54)],
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
              child: child,
            ),
          ),
        ],
      );
    }

    return child;
  }
}

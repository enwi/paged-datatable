part of 'paged_datatable.dart';

/// A Row renderer that uses slivers for efficient vertical scrolling with unified rows
class _DoubleListRows<K extends Comparable<K>, T> extends StatefulWidget {
  final List<ReadOnlyTableColumn> columns;
  final LinkedScrollControllerGroup linkedControllers;
  final int fixedColumnCount;
  final PagedDataTableController<K, T> controller;
  final PagedDataTableConfiguration configuration;
  final List<double> sizes;

  const _DoubleListRows({
    required this.columns,
    required this.fixedColumnCount,
    required this.linkedControllers,
    required this.controller,
    required this.configuration,
    required this.sizes,
  });

  @override
  State<StatefulWidget> createState() => _DoubleListRowsState<K, T>();
}

class _DoubleListRowsState<K extends Comparable<K>, T> extends State<_DoubleListRows<K, T>> {
  final ScrollController _verticalController = ScrollController();
  late final ScrollController _horizontalScrollbarController;

  late TableState state;
  double _variableColumnsWidth = 0;
  double _fixedColumnsWidth = 0;

  @override
  void initState() {
    super.initState();

    state = widget.controller._state;
    widget.controller.addListener(_rebuildUi);
    _horizontalScrollbarController = widget.linkedControllers.addAndGet();
    _variableColumnsWidth = widget.sizes.skip(widget.fixedColumnCount).fold(0.0, (a, b) => a + b);
    _fixedColumnsWidth = widget.sizes.take(widget.fixedColumnCount).fold(0.0, (a, b) => a + b);
  }

  void _rebuildUi() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Checks if any column requires dynamic height calculation
  bool get _hasDynamicHeightColumns {
    return widget.columns.any((col) => col.requiresDynamicHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PagedDataTableTheme.of(context);

    return DefaultTextStyle(
      style: theme.cellTextStyle,
      child: Opacity(
        opacity: widget.controller.isIdle() ? 1 : 0.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final variableViewportWidth = availableWidth - _fixedColumnsWidth;

            return Stack(
              children: [
                // Main content with vertical scrollbar
                Scrollbar(
                  thumbVisibility: theme.verticalScrollbarVisibility,
                  controller: _verticalController,
                  child: CustomScrollView(
                    controller: _verticalController,
                    reverse: widget.configuration.reverse,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _UnifiedRow<K, T>(
                            index: index,
                            columns: widget.columns,
                            fixedColumnCount: widget.fixedColumnCount,
                            sizes: widget.sizes,
                            linkedControllers: widget.linkedControllers,
                            variableColumnsWidth: _variableColumnsWidth,
                            variableViewportWidth: variableViewportWidth,
                            fixedColumnsWidth: _fixedColumnsWidth,
                            useDynamicHeight: _hasDynamicHeightColumns,
                          ),
                          childCount: widget.controller._totalItems,
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontal scrollbar overlay at the bottom (only for variable columns area)
                if (_variableColumnsWidth > variableViewportWidth)
                  Positioned(
                    left: _fixedColumnsWidth,
                    right: 0,
                    bottom: 0,
                    height: 16, // Height for the scrollbar track
                    child: IgnorePointer(
                      ignoring: false,
                      child: Scrollbar(
                        thumbVisibility: theme.horizontalScrollbarVisibility,
                        controller: _horizontalScrollbarController,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScrollbarController,
                          child: SizedBox(width: _variableColumnsWidth, height: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller.removeListener(_rebuildUi);
    _verticalController.dispose();
    _horizontalScrollbarController.dispose();
  }
}

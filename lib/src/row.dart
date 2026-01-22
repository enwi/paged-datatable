part of 'paged_datatable.dart';

abstract class _RowBuilder<K extends Comparable<K>, T> extends StatefulWidget {
  final int index;

  const _RowBuilder({required this.index, super.key});

  @override
  State<StatefulWidget> createState() => _RowBuilderState<K, T>();

  List<Widget> buildColumns(
    BuildContext context,
    int index,
    PagedDataTableController<K, T> controller,
    PagedDataTableThemeData theme,
  );
}

class _RowBuilderState<K extends Comparable<K>, T> extends State<_RowBuilder<K, T>> {
  late final controller = TableControllerProvider.of<K, T>(context);
  late final theme = PagedDataTableTheme.of(context);
  bool selected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    controller.addRowChangeListener(widget.index, _onRowChanged);
    setState(() {
      selected = controller._selectedRows.contains(widget.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(children: widget.buildColumns(context, widget.index, controller, theme));
    var color = theme.rowColor?.call(widget.index);
    if (selected && theme.selectedRow != null) {
      color = theme.selectedRow;
    }
    if (color != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: child,
      );
    }

    return SizedBox(height: theme.rowHeight, child: child);
  }

  void _onRowChanged(int index, T value) {
    if (mounted) {
      setState(() {
        selected = controller._selectedRows.contains(index);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    controller.removeRowChangeListener(widget.index, _onRowChanged);
  }
}

class _FixedPartRow<K extends Comparable<K>, T> extends _RowBuilder<K, T> {
  final int fixedColumnCount;
  final List<ReadOnlyTableColumn> columns;
  final List<double> sizes;

  const _FixedPartRow({
    required super.index,
    required this.fixedColumnCount,
    required this.columns,
    required this.sizes,
    super.key,
  });

  @override
  List<Widget> buildColumns(
    BuildContext context,
    int index,
    PagedDataTableController<K, T> controller,
    PagedDataTableThemeData theme,
  ) {
    final item = controller._tableRow(index);
    final list = <Widget>[];

    for (int i = 0; i < fixedColumnCount; i++) {
      final column = columns[i];
      final widget = _buildCell(context, index, item, sizes[i], theme, column);
      list.add(widget);
    }

    return list;
  }
}

class _VariablePartRow<K extends Comparable<K>, T> extends _RowBuilder<K, T> {
  final List<ReadOnlyTableColumn> columns;
  final int fixedColumnCount;
  final List<double> sizes;

  const _VariablePartRow({
    required super.index,
    required this.fixedColumnCount,
    required this.columns,
    required this.sizes,
    super.key,
  });

  @override
  List<Widget> buildColumns(
    BuildContext context,
    int index,
    PagedDataTableController<K, T> controller,
    PagedDataTableThemeData theme,
  ) {
    final item = controller._tableRow(index);
    final list = <Widget>[];

    for (int i = fixedColumnCount; i < columns.length; i++) {
      final column = columns[i];
      final widget = _buildCell(context, index, item, sizes[i], theme, column);
      list.add(widget);
    }

    return list;
  }
}

Widget _buildCell<T>(
  BuildContext context,
  int index,
  T value,
  double width,
  PagedDataTableThemeData theme,
  ReadOnlyTableColumn column,
) {
  // Build cell content WITHOUT applying column.format.transform() here
  // since alignment is handled at a higher level
  Widget cellContent = Container(
    padding: theme.cellPadding,
    margin: theme.padding,
    decoration: BoxDecoration(border: theme.cellBorderSide),
    child: column.build(context, value, index),
  );

  // Wrap in SizedBox for width, and Align for positioning within stretched row
  Widget child = SizedBox(
    width: width,
    child: Align(alignment: _getVerticalAlignmentFromFormat(column.format), child: cellContent),
  );

  return child;
}

/// Extracts vertical alignment from ColumnFormat
AlignmentGeometry _getVerticalAlignmentFromFormat(ColumnFormat format) {
  if (format is AlignColumnFormat) {
    return format.alignment;
  } else if (format is NumericColumnFormat) {
    return Alignment.centerRight;
  }
  return Alignment.centerLeft; // default
}

/// A unified row widget that handles both fixed and variable parts with dynamic height support.
class _UnifiedRow<K extends Comparable<K>, T> extends StatefulWidget {
  final int index;
  final List<ReadOnlyTableColumn> columns;
  final int fixedColumnCount;
  final List<double> sizes;
  final LinkedScrollControllerGroup linkedControllers;
  final double variableColumnsWidth;
  final double variableViewportWidth;
  final double fixedColumnsWidth;
  final bool useDynamicHeight;

  const _UnifiedRow({
    required this.index,
    required this.columns,
    required this.fixedColumnCount,
    required this.sizes,
    required this.linkedControllers,
    required this.variableColumnsWidth,
    required this.variableViewportWidth,
    required this.fixedColumnsWidth,
    required this.useDynamicHeight,
    super.key,
  });

  @override
  State<_UnifiedRow<K, T>> createState() => _UnifiedRowState<K, T>();
}

class _UnifiedRowState<K extends Comparable<K>, T> extends State<_UnifiedRow<K, T>> {
  late final controller = TableControllerProvider.of<K, T>(context);
  late final theme = PagedDataTableTheme.of(context);
  late final ScrollController _horizontalScrollController;
  bool selected = false;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = widget.linkedControllers.addAndGet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    controller.addRowChangeListener(widget.index, _onRowChanged);
    setState(() {
      selected = controller._selectedRows.contains(widget.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = controller._tableRow(widget.index);

    // Calculate dynamic height if needed
    double rowHeight = theme.rowHeight;
    if (widget.useDynamicHeight) {
      rowHeight = _calculateRowHeight(item);
    }

    // Build the row with fixed columns on the left and variable columns on the right
    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed columns (always visible, no clipping)
        SizedBox(
          width: widget.fixedColumnsWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildFixedColumns(item),
          ),
        ),
        // Variable columns (horizontally scrollable, synced with header)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: widget.variableColumnsWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildVariableColumns(item),
              ),
            ),
          ),
        ),
      ],
    );

    // Apply row color
    var color = theme.rowColor?.call(widget.index);
    if (selected && theme.selectedRow != null) {
      color = theme.selectedRow;
    }
    if (color != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: child,
      );
    }

    // Add divider
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: rowHeight, child: child),
        const Divider(height: 0),
      ],
    );
  }

  double _calculateRowHeight(T item) {
    double maxHeight = theme.rowHeight;
    final direction = Directionality.of(context);

    for (int i = 0; i < widget.columns.length; i++) {
      final column = widget.columns[i];
      if (column.requiresDynamicHeight) {
        // Get available width for this column (subtract both margin AND padding)
        final cellPadding = theme.cellPadding.resolve(direction);
        final cellMargin = theme.padding.resolve(direction);
        final availableWidth = widget.sizes[i] - cellMargin.horizontal - cellPadding.horizontal;

        final cellHeight = column.calculateCellHeight(
          context,
          item,
          widget.index,
          availableWidth > 0 ? availableWidth : 100,
          theme.cellTextStyle,
        );

        if (cellHeight != null) {
          // Add padding to the calculated height, plus a small buffer for line height differences
          final totalCellHeight = cellHeight + cellPadding.vertical + 4.0;
          if (totalCellHeight > maxHeight) {
            maxHeight = totalCellHeight;
          }
        }
      }
    }

    return maxHeight;
  }

  List<Widget> _buildFixedColumns(T item) {
    final list = <Widget>[];
    for (int i = 0; i < widget.fixedColumnCount; i++) {
      final column = widget.columns[i];
      final cellWidget = _buildCell(context, widget.index, item, widget.sizes[i], theme, column);
      list.add(cellWidget);
    }
    return list;
  }

  List<Widget> _buildVariableColumns(T item) {
    final list = <Widget>[];
    for (int i = widget.fixedColumnCount; i < widget.columns.length; i++) {
      final column = widget.columns[i];
      final cellWidget = _buildCell(context, widget.index, item, widget.sizes[i], theme, column);
      list.add(cellWidget);
    }
    return list;
  }

  void _onRowChanged(int index, T value) {
    if (mounted) {
      setState(() {
        selected = controller._selectedRows.contains(index);
      });
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    controller.removeRowChangeListener(widget.index, _onRowChanged);
    super.dispose();
  }
}

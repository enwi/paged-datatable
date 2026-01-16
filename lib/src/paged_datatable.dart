import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:paged_datatable/src/filter_bar_chip_list.dart';
import 'package:paged_datatable/src/linked_scroll_controller.dart';

part 'column.dart';
part 'column_widgets.dart';
part 'controller.dart';
part 'double_list_rows.dart';
part 'filter.dart';
part 'filter_bar.dart';
part 'filter_bar_menu_button.dart';
part 'filter_model.dart';
part 'filter_state.dart';
part 'filter_widgets.dart';
part 'footer_widgets.dart';
part 'header.dart';
part 'row.dart';
part 'sort_model.dart';
part 'table_view_rows.dart';
part 'table_filter_bar.dart';

/// [PagedDataTable] renders a table of items that is paginable.
///
/// The type of element to be displayed in the table is [T] and [K] is the type of key
/// used to paginate the table.
final class PagedDataTable<K extends Comparable<K>, T> extends StatefulWidget {
  /// An specific [PagedDataTableController] to be use in this [PagedDataTable].
  final PagedDataTableController<K, T>? controller;

  /// The list of columns to draw in the table.
  final List<ReadOnlyTableColumn<K, T>> columns;

  /// The initial page size of the table.
  ///
  /// If [pageSizes] is not null, this value must match any of the its values.
  final int initialPageSize;

  /// The initial page query.
  final K? initialPage;

  /// The list of available page sizes to be selected in the footer.
  final List<int>? pageSizes;

  /// The callback used to fetch new items.
  final Fetcher<K, T> fetcher;

  /// The amount of columns to fix, starting from the left.
  final int fixedColumnCount;

  /// The configuration of this [PagedDataTable].
  final PagedDataTableConfiguration configuration;

  /// The widget to display at the footer of the table.
  ///
  /// If null, the default footer will be displayed.
  final Widget? footer;

  /// Alternative filter bar widget.
  final Widget? filterBar;

  /// Additional widget to add at the right of the filter bar.
  final Widget? filterBarChild;

  /// The list of filters to use.
  final List<TableFilter> filters;

  const PagedDataTable({
    required this.columns,
    required this.fetcher,
    this.initialPage,
    this.initialPageSize = 50,
    this.pageSizes = const [10, 50, 100],
    this.controller,
    this.fixedColumnCount = 0,
    this.configuration = const PagedDataTableConfiguration(),
    this.footer,
    this.filterBar,
    this.filterBarChild,
    this.filters = const <TableFilter>[],
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PagedDataTableState<K, T>();
}

final class _PagedDataTableState<K extends Comparable<K>, T> extends State<PagedDataTable<K, T>> {
  final verticalController = ScrollController();
  final linkedControllers = LinkedScrollControllerGroup();
  late final headerHorizontalController = linkedControllers.addAndGet();
  late final horizontalController = linkedControllers.addAndGet();
  late final PagedDataTableController<K, T> tableController;
  // late FixedTableSpanExtent rowSpanExtent, headerRowSpanExtent;
  bool selfConstructedController = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.pageSizes != null ? widget.pageSizes!.contains(widget.initialPageSize) : true,
      "initialPageSize must be inside pageSizes. To disable this restriction, set pageSizes to null.",
    );

    if (widget.controller == null) {
      selfConstructedController = true;
      tableController = PagedDataTableController();
    } else {
      tableController = widget.controller!;
    }
    tableController.init(
      columns: widget.columns,
      pageSizes: widget.pageSizes,
      initialPageSize: widget.initialPageSize,
      fetcher: widget.fetcher,
      config: widget.configuration,
      filters: widget.filters,
    );
  }

  @override
  void didUpdateWidget(covariant PagedDataTable<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.columns.length != widget.columns.length /*!listEquals(oldWidget.columns, widget.columns)*/ ) {
      tableController._reset(columns: widget.columns);
      debugPrint("PagedDataTable<$T> changed and rebuilt.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PagedDataTableTheme.of(context);

    return Card(
      color: theme.backgroundColor,
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
      margin: EdgeInsets.zero,
      child: TableControllerProvider(
        controller: tableController,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sizes = _calculateColumnWidth(constraints.maxWidth);

            return Column(
              children: [
                if (widget.filterBar != null)
                  widget.filterBar!
                else
                  TableFilterBar<K, T>(trailing: widget.filterBarChild),

                _Header(
                  controller: tableController,
                  configuration: widget.configuration,
                  columns: widget.columns,
                  sizes: sizes,
                  fixedColumnCount: widget.fixedColumnCount,
                  horizontalController: headerHorizontalController,
                ),
                const Divider(height: 0),

                Expanded(
                  child: _DoubleListRows(
                    fixedColumnCount: widget.fixedColumnCount,
                    columns: widget.columns,
                    horizontalController: horizontalController,
                    controller: tableController,
                    configuration: widget.configuration,
                    sizes: sizes,
                  ),
                ),

                // Expanded(
                //   child: _TableViewRows<T>(
                //     columns: widget.columns,
                //     controller: tableController,
                //     fixedColumnCount: widget.fixedColumnCount,
                //     horizontalController: horizontalController,
                //     verticalController: verticalController,
                //   ),
                // ),
                const Divider(height: 0),
                SizedBox(height: theme.footerHeight, child: widget.footer ?? DefaultFooter<K, T>()),
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
    verticalController.dispose();
    horizontalController.dispose();
    headerHorizontalController.dispose();

    if (selfConstructedController) {
      tableController.dispose();
    }
  }

  /// Calculates the final width for each column given the available [maxWidth].
  ///
  /// Flow:
  /// 1) Collect per-column sizing capabilities (fixed, fractional, remaining).
  /// 2) Aggregate fixed and fractional totals, excluding Remaining columns.
  /// 3) Iteratively promote Max(Fixed, Fractional) columns to Fixed when their
  ///    fixed width would exceed the computed fractional width.
  /// 4) Compute fractional widths, then assign remaining space to Remaining
  ///    columns, honoring their own fixed/fractional constraints.
  /// 5) Normalize any leftover width to avoid gaps due to rounding.
  ///
  /// The returned list length matches [widget.columns.length].
  List<double> _calculateColumnWidth(double maxWidth) {
    final sizes = List<double>.filled(widget.columns.length, 0.0, growable: false);

    double totalFixedWidth = 0.0;
    double totalFraction = 0.0;
    int remainingColumnCount = 0;

    final fractions = List<double>.filled(widget.columns.length, 0.0, growable: false);
    final fixedWidths = List<double>.filled(widget.columns.length, 0.0, growable: false);
    final hasRemaining = List<bool>.filled(widget.columns.length, false, growable: false);

    // Pass 1: collect size characteristics per column and total fixed/fractional sizes.
    for (int i = 0; i < widget.columns.length; i++) {
      final size = widget.columns[i].size;
      final maxFraction = fractions[i] = size.maxFraction();
      final fixedWidth = fixedWidths[i] = size.maxFixedWidth();
      final includesRemaining = hasRemaining[i] = size.includesRemaining();

      // Only count non-Remaining columns here. Remaining columns are resolved later.
      if (includesRemaining) {
        remainingColumnCount++;
      } else if (maxFraction > 0.0) {
        totalFraction += maxFraction;
      } else if (fixedWidth > 0.0) {
        totalFixedWidth += fixedWidth;
      }
    }

    // Pass 2: iteratively convert Max(Fixed, Fractional) columns to Fixed if the
    // fixed width is larger than their fractional allocation.
    bool adjusted;
    do {
      adjusted = false;
      if (totalFraction <= 0.0) break;

      final remainingWidthAfterFixed = math.max(0.0, maxWidth - totalFixedWidth);

      for (int i = 0; i < widget.columns.length; i++) {
        if (hasRemaining[i]) continue;
        final fraction = fractions[i];
        final fixedWidth = fixedWidths[i];

        if (fraction <= 0.0 || fixedWidth <= 0.0) continue;

        final fractionalWidth = remainingWidthAfterFixed * fraction / totalFraction;

        if (fixedWidth > fractionalWidth) {
          adjusted = true;
          totalFraction -= fraction;
          fractions[i] = 0.0;
          totalFixedWidth += fixedWidth;
        }
      }
    } while (adjusted);

    // Ensure totalFraction is within a valid range to prevent overflow.
    assert(totalFraction <= 1.0, "Total fraction exceeds 1.0, which means the columns will overflow.");

    // Remaining width after fixed sizes are allocated.
    final remainingWidthAfterFixed = math.max(0.0, maxWidth - totalFixedWidth);
    // Total width reserved for fractional columns.
    final totalFractionalWidth = remainingWidthAfterFixed * totalFraction;
    // Width left for Remaining columns after fractional allocation.
    final remainingWidth = math.max(0.0, remainingWidthAfterFixed - totalFractionalWidth);
    final remainingColumnWidth = remainingColumnCount > 0.0 ? remainingWidth / remainingColumnCount : 0.0;

    // Pass 3: assign final sizes for each column.
    for (int i = 0; i < widget.columns.length; i++) {
      final size = widget.columns[i].size;
      final fixedWidth = fixedWidths[i];
      final fraction = fractions[i];

      if (hasRemaining[i]) {
        double resolvedSize = remainingColumnWidth;
        if (fraction > 0.0) {
          final fractionalWidth = remainingWidth * fraction;
          resolvedSize = math.max(resolvedSize, fractionalWidth);
        }
        if (fixedWidth > 0.0) {
          resolvedSize = math.max(resolvedSize, fixedWidth);
        }
        sizes[i] = resolvedSize;
      } else if (fraction > 0.0 && totalFraction > 0.0) {
        final fractionalWidth = totalFractionalWidth * fraction / totalFraction;
        sizes[i] = fixedWidth > 0.0 ? math.max(fixedWidth, fractionalWidth) : fractionalWidth;
      } else if (fixedWidth > 0.0) {
        sizes[i] = fixedWidth;
      } else {
        // Fallback to size constraints for any other custom type.
        sizes[i] = size.calculateConstraints(totalFixedWidth);
      }
    }

    // Pass 4: normalize widths to consume all available space and avoid gaps.
    const epsilon = 0.01;
    double totalWidth = 0.0;
    for (final width in sizes) {
      totalWidth += width;
    }
    final delta = maxWidth - totalWidth;
    if (delta > epsilon) {
      final flexibleIndices = <int>[];
      for (int i = 0; i < widget.columns.length; i++) {
        if (hasRemaining[i] || fractions[i] > 0.0) {
          flexibleIndices.add(i);
        }
      }

      if (flexibleIndices.isNotEmpty) {
        final perColumn = delta / flexibleIndices.length;
        for (final index in flexibleIndices) {
          sizes[index] = math.max(0.0, sizes[index] + perColumn);
        }
      } else if (sizes.isNotEmpty) {
        sizes[sizes.length - 1] = math.max(0.0, sizes.last + delta);
      }
    }

    return sizes;
  }
}

part of 'paged_datatable.dart';

class _SimpleRowList<K extends Comparable<K>, T> extends StatefulWidget {
  final PagedDataTableController<K, T> controller;
  final Widget Function(BuildContext context, T item, int rowIndex) builder;

  const _SimpleRowList({required this.controller, required this.builder});

  @override
  State<_SimpleRowList> createState() => _SimpleRowListState<K, T>();
}

class _SimpleRowListState<K extends Comparable<K>, T> extends State<_SimpleRowList<K, T>> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(rebuildUi);
  }

  @override
  void dispose() {
    widget.controller.removeListener(rebuildUi);

    super.dispose();
  }

  void rebuildUi() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = PagedDataTableTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.controller._state.isFetching()) const LinearProgressIndicator(),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Opacity(
              opacity: widget.controller.isIdle() ? 1 : 0.5,
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: theme.verticalScrollbarVisibility,
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: widget.controller._totalItems,
                  itemBuilder: (context, index) =>
                      widget.builder(context, widget.controller._currentDataset[index], index),
                  separatorBuilder: (context, index) => const SizedBox(height: 4.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

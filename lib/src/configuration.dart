/// A set of properties used to configure a [PagedDataTable]
final class PagedDataTableConfiguration {
  /// A flag that indicates if the table should copy the list of items returned
  /// by a fetch callback.
  ///
  /// This is useful when you don't want to accidentally modify the returned list.
  final bool copyItems;

  /// When true, the table renders the dataset in reverse order and reverses the
  /// vertical scroll direction (defaulting the scroll position to the bottom).
  final bool reverse;

  const PagedDataTableConfiguration({this.copyItems = false, this.reverse = false});
}

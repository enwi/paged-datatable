import 'package:flutter/material.dart';
import 'package:paged_datatable/paged_datatable.dart';

abstract class FilterBarController extends ChangeNotifier {
  /// Get the current state of the table
  TableState get state;
  bool isIdle() => state.isIdle();
  bool isFetching() => state.isFetching();
  bool isError() => state.isError();
}

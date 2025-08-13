enum TableState {
  idle,
  fetching,
  error;

  bool isIdle() => this == idle;
  bool isFetching() => this == fetching;
  bool isError() => this == error;
}

enum TableState {
  idle,
  fetching,
  backgroundLoading,
  error;

  bool isIdle() => this == idle || this == backgroundLoading;
  bool isFetching() => this == fetching;
  bool isBackgroundLoading() => this == backgroundLoading;
  bool isError() => this == error;
}

class SyncResult {
  final int pushedCount;
  final int pulledCount;
  final int deletedCount;
  final bool isOffline;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;

  const SyncResult({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.deletedCount = 0,
    this.isOffline = false,
    this.errorMessage,
  });

  const SyncResult.offline()
    : pushedCount = 0,
      pulledCount = 0,
      deletedCount = 0,
      isOffline = true,
      errorMessage = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncResult &&
          other.pushedCount == pushedCount &&
          other.pulledCount == pulledCount &&
          other.deletedCount == deletedCount &&
          other.isOffline == isOffline &&
          other.errorMessage == errorMessage);

  @override
  int get hashCode => Object.hash(
    pushedCount,
    pulledCount,
    deletedCount,
    isOffline,
    errorMessage,
  );
}

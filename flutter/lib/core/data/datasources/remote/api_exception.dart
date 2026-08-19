class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Whether retrying the same request could plausibly succeed later.
  /// `null` (no response reached the client at all — dropped connection,
  /// timeout, DNS failure) and 5xx (server-side/transient) are retryable.
  /// Any 4xx is a business rejection the backend has already made a final
  /// decision on — a 409 "insufficient stock" won't become true by trying
  /// again seconds later. [SyncManager]/[CartSyncManager] use this to skip
  /// straight to a failed state instead of burning the retry/backoff
  /// budget on something that can never succeed.
  bool get isRetryable => statusCode == null || statusCode! >= 500;

  @override
  String toString() => message;
}

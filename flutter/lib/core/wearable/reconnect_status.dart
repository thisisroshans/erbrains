class ReconnectStatus {
  const ReconnectStatus({
    required this.attempt,
    required this.maxAttempts,
    required this.retryInSeconds,
  });

  final int attempt;
  final int maxAttempts;
  final int retryInSeconds;
}

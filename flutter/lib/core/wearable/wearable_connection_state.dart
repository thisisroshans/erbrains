/// Mirrors screen 03 (Connection states) exactly: connected, disconnected,
/// an in-flight (re)connect attempt, and the terminal failure state after
/// backoff is exhausted.
enum WearableConnectionState {
  connected,
  disconnected,
  connecting,
  reconnecting,
  connectionFailed,
}

class UnknownMergeStrategyException implements Exception {
  final String message;

  UnknownMergeStrategyException([this.message]);

  String toString() {
    String result = "UnknownMergeStrategyException";
    if (message != null) result = "$result: $message";
    return result;
  }
}
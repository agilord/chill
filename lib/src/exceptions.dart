class ExitError extends Error {
  final String message;
  final int exitCode;

  ExitError(this.message, [this.exitCode = -1]);

  @override
  String toString() => 'ExitError($exitCode): $message';
}

/// Normalized error type thrown by [ApiClient] so screens don't need to know
/// about Dio's internals.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

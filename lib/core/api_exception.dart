/// A typed error from the Speek API or the network layer.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, {this.code});

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode${code != null ? ' $code' : ''}): $message';
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, List<String>>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  bool get hasErrors => errors != null && errors!.isNotEmpty;

  String get errorMessage {
    if (!hasErrors) return message;

    final errorList = <String>[];
    errors!.forEach((key, value) {
      errorList.addAll(value);
    });

    return errorList.join('\n');
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, hasData: ${data != null}, hasErrors: $hasErrors}';
  }
}

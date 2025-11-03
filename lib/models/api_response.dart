class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJson) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : null,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
    };
  }
}

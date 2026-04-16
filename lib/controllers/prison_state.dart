class PrisonState {
  final bool isBailingOut;
  final String errorMessage;
  final String successMessage;

  PrisonState({
    this.isBailingOut = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  PrisonState copyWith({
    bool? isBailingOut,
    String? errorMessage,
    String? successMessage,
  }) {
    return PrisonState(
      isBailingOut: isBailingOut ?? this.isBailingOut,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
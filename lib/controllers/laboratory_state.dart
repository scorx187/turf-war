class LaboratoryState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  LaboratoryState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  LaboratoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return LaboratoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
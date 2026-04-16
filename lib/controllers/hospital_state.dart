class HospitalState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  HospitalState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  HospitalState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return HospitalState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
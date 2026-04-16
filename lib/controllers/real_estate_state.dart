class RealEstateState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  RealEstateState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  RealEstateState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return RealEstateState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
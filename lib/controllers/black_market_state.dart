class BlackMarketState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  BlackMarketState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  BlackMarketState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return BlackMarketState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
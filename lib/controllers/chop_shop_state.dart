class ChopShopState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  ChopShopState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  ChopShopState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ChopShopState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
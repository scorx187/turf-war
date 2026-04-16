class CrimeState {
  final bool isLoading;
  final String errorMessage;
  final String eventMessage;
  final int? eventColor;

  CrimeState({
    this.isLoading = false,
    this.errorMessage = '',
    this.eventMessage = '',
    this.eventColor,
  });

  CrimeState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? eventMessage,
    int? eventColor,
  }) {
    return CrimeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      eventMessage: eventMessage ?? this.eventMessage,
      eventColor: eventColor ?? this.eventColor,
    );
  }
}
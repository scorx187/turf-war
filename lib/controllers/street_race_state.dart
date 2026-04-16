class StreetRaceState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;
  final Map<String, dynamic>? raceResult; // 🟢 يخزن نتيجة السباق عشان الواجهة تعرضها

  StreetRaceState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
    this.raceResult,
  });

  StreetRaceState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? raceResult,
    bool clearRaceResult = false,
  }) {
    return StreetRaceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      raceResult: clearRaceResult ? null : (raceResult ?? this.raceResult),
    );
  }
}
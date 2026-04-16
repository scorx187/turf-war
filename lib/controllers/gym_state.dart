class GymState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;
  final double? gainedStats; // 🟢 هذي القيمة بنستخدمها لتشغيل أنيميشن الأرقام المتطايرة

  GymState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
    this.gainedStats,
  });

  GymState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    double? gainedStats,
    bool clearGainedStats = false,
  }) {
    return GymState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      gainedStats: clearGainedStats ? null : (gainedStats ?? this.gainedStats),
    );
  }
}
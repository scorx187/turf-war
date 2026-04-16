class LuckyWheelState {
  final bool isSpinning;
  final int currentIndex;
  final String statusText;
  final List<Map<String, dynamic>>? wonPrizes; // لتخزين الجوائز وعرضها
  final String errorMessage; // لعرض الأخطاء لو السيرفر فصل

  LuckyWheelState({
    this.isSpinning = false,
    this.currentIndex = 0,
    this.statusText = '',
    this.wonPrizes,
    this.errorMessage = '',
  });

  LuckyWheelState copyWith({
    bool? isSpinning,
    int? currentIndex,
    String? statusText,
    List<Map<String, dynamic>>? wonPrizes,
    String? errorMessage,
  }) {
    return LuckyWheelState(
      isSpinning: isSpinning ?? this.isSpinning,
      currentIndex: currentIndex ?? this.currentIndex,
      statusText: statusText ?? this.statusText,
      // إذا مررنا null، نبي نصفر الجوائز، فلازم طريقة مسح
      wonPrizes: wonPrizes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
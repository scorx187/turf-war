class ResourcesState {
  final int cash;
  final int influence;

  ResourcesState({required this.cash, required this.influence});

  // دالة مساعدة عشان ننسخ الحالة الحالية ونعدل جزء منها بسهولة
  ResourcesState copyWith({int? cash, int? influence}) {
    return ResourcesState(
      cash: cash ?? this.cash,
      influence: influence ?? this.influence,
    );
  }
}
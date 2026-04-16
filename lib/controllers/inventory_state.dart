class InventoryState {
  final String message;
  final bool isError;

  InventoryState({
    this.message = '',
    this.isError = false,
  });

  InventoryState copyWith({
    String? message,
    bool? isError,
  }) {
    return InventoryState(
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}
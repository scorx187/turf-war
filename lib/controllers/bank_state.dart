class BankState {
  final bool isLoading;
  final String message;
  final bool isSuccess;

  BankState({
    this.isLoading = false,
    this.message = '',
    this.isSuccess = false,
  });
}
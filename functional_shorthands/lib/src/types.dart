class PanicError extends Error {
  final String message;

  PanicError(this.message);

  @override
  String toString() => 'PanicError: $message';
}

typedef UnaryMap<X, T> = T Function(X);
typedef Unary<T> = UnaryMap<T, T>;

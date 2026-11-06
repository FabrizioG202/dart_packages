import 'dart:io';

import 'types.dart';
import 'package:path/path.dart' as path_lib;
import 'dart:async' as async_lib;

extension DirectoryExt on Directory {
  Directory dir(String name) => Directory(path_lib.join(path, name));
  File file(String name) => File(path_lib.join(path, name));
  Directory nParent([int levels = 1]) {
    var parent = this;
    for (var i = 0; i < levels; i++) {
      parent = parent.parent;
    }
    return parent;
  }

  bool existsSync() => Directory(path_lib.join(path)).existsSync();
}

extension AsExt<T> on T {
  R as<R>() => this as R;
}

extension MapGetExt<X, Y> on Map<X, Y> {
  Y? get(X key) => this[key];

  J? getOfOrNull<J extends Y>(X key, {J? Function(Y)? onWrongType}) {
    final value = this[key];
    if (value is J) {
      return value;
    } else if (value != null && onWrongType != null) {
      return onWrongType(value);
    } else {
      return null;
    }
  }

  List<J> getListOf<J extends Y>(X key) {
    final value = this[key];
    if (value is List) {
      return value.cast<J>().toList();
    }

    throw Exception(
      'Expected value of type List<$J> for key $key but got ${value.runtimeType}',
    );
  }

  J getOf<J extends Y>(X key) {
    final value = this[key];
    if (value is J) {
      return value;
    }
    throw Exception(
      'Expected value of type $J for key $key but got ${value.runtimeType}',
    );
  }
}

extension OrExt<T> on T? {
  @pragma('vm:prefer-inline')
  T or(T fallback) => this ?? fallback;

  T orPanic([String message = 'Expected non-null value']) {
    return this ?? (throw PanicError(message));
  }

  T orFn(T Function() compute) => this ?? compute();
}

extension MapPlusExt<X, Y> on Map<X, Y> {
  Map<X, Y> operator +(Map<X, Y> other) {
    return {...this, ...other};
  }
}

extension LetExt<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

extension LetOrExt<T> on T? {
  R letOrValue<R>(R Function(T) block, R or) => switch (this) {
    final t? => block(t),
    null => or,
  };

  R letOr<R>(R Function(T) block, R Function() compute) => switch (this) {
    final t? => block(t),
    null => compute(),
  };
}

extension ToMapExt<T> on Iterable<T> {
  Map<K, V> toMap<K, V>((K, V) Function(T) block) {
    final map = <K, V>{};
    for (final element in this) {
      final (key, value) = block(element);
      map[key] = value;
    }
    return map;
  }

  Map<K, V> toMapWith<K, V>(
    K Function(T) keySelector,
    V Function(T) valueSelector,
  ) {
    return <K, V>{
      for (final element in this) keySelector(element): valueSelector(element),
    };
  }
}

extension FileExt on File {
  String get basenameWithoutExtension =>
      path_lib.basenameWithoutExtension(path);

  String get basename => path_lib.basename(path);
}

Iterable<(T, U)> zip2<T, U>(Iterable<T> a, Iterable<U> b) sync* {
  final aIterator = a.iterator;
  final bIterator = b.iterator;
  while (aIterator.moveNext() && bIterator.moveNext()) {
    yield (aIterator.current, bIterator.current);
  }
}

extension Map2Ext<T, U> on Iterable<(T, U)> {
  Iterable<R> map2<R>(R Function(T, U) block) sync* {
    for (final pair in this) {
      yield block(pair.$1, pair.$2);
    }
  }
}

Unary<T> withValue<T>(T value) =>
    (T _) => value;
Unary<T>? withValueOrKeep<T>(T? value) {
  if (value == null) {
    return null;
  }
  return withValue(value);
}

Unary<List<T>> withAddAll<T>(List<T> values) =>
    (List<T> list) => [...list, ...values];

Unary<T> withNull<T extends Object?>() =>
    (T _) => null as T;

extension OrElseExt<T> on Unary<T>? {
  @Deprecated('use `|` instead')
  T orElse(T value) {
    return switch (this) {
      final Unary<T> fn => fn(value),
      _ => value,
    };
  }

  T operator |(T value) {
    return switch (this) {
      final fn? => fn(value),
      _ => value,
    };
  }

  Unary<T> orElseWith(Unary<T> fallback) => this ?? fallback;
}

Never todo([String? message]) {
  throw UnimplementedError(message);
}

extension LockListExt<T> on List<T> {
  List<T> get lock {
    return List.unmodifiable(this);
  }
}

extension LockSetExt<T> on Set<T> {
  Set<T> get lock {
    return Set.unmodifiable(this);
  }
}

extension LockMapExt<K, V> on Map<K, V> {
  Map<K, V> get lock {
    return Map.unmodifiable(this);
  }
}

extension ToMapByExt<T> on Iterable<T> {
  Map<K, T> toMapBy<K>(K Function(T) keySelector) {
    return Map.fromEntries(map((e) => MapEntry(keySelector(e), e)));
  }
}

extension MapExt<K, V> on Map<K, V> {
  Map<K, V> whereKeys(bool Function(K) predicate) {
    return Map.fromEntries(entries.where((e) => predicate(e.key)));
  }

  Map<K, V> whereValues(bool Function(V) predicate) {
    return Map.fromEntries(entries.where((e) => predicate(e.value)));
  }
}

extension ForkExt<T> on List<T> {
  /// Returns a pair of lists where the first list contains elements that satisfy the predicate
  /// and the second list contains elements that do not satisfy the predicate.
  (List<T>, List<T>) fork2(bool Function(T) predicate) {
    final left = <T>[];
    final right = <T>[];
    for (final element in this) {
      if (predicate(element)) {
        left.add(element);
      } else {
        right.add(element);
      }
    }
    return (left, right);
  }

  /// Splits the list into two lists at the given index.
  /// The first list contains elements from the start to the index (exclusive),
  (List<T>, List<T>) forkAt2(int index) {
    return (sublist(0, index), sublist(index));
  }
}

/// a handle null function
extension HandleNullExt<T extends Object> on T? {
  T handleNull(T Function() onNull) {
    return switch (this) {
      final value? => value,
      null => onNull(),
    };
  }
}

extension FutureExt<T> on Future<T> {
  void unawaited() => async_lib.unawaited(this);
}

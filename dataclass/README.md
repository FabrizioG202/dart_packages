# dataclass

An alternative take on dataclass generation and management in Dart. The main reason I created this is to deal with the problem of updating a value to `null` in the `copyWith` functions (for more information read below), but decided to add few more QOL features as I needed them in my personal projects.

The general syntax is inspired by rust's `derive` syntax, which I find particularly clean and nice to work with.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dataclass:
    git:
      url: https://github.com/FabrizioG202/dart_packages
      path: dataclass
```

## Features

- `copyWith` generation. This is the main feature of this package, and it allows you to create a new instance of a class with some fields updated. The generated `copyWith` method takes a **function** for each field, which allows you to update the field to `null` if needed.
- `toString` generation
- Equality and `hashCode` generation
- Optional deep equality for `List` fields

## Usage

Add the package and a build runner to your Dart project, then annotate a class:

```dart
import 'package:dataclass/dataclass.dart';

part 'user.g.dart';

@Dataclass([
  CopyWith(),
  ToString(),
  Equality(useListEquality: true),
  HashCode(),
])
class User with _$User {
  const User({
    required this.name,
    required this.roles,
  });

  final String name;
  final List<String> roles;
}
```

Generate the supporting code with:

```shell
dart run build_runner build
```

or

```shell
dart run build_runner watch
```

The generated methods can then be used like this:

```dart
final user = User(name: 'Ada', roles: ['admin']);
final updated = user.copyWith(name: (_) => 'Grace');

print(updated); // User(name: Grace, roles: [admin])
print(user == updated); // false
```

By default, list fields use identity equality. Set `useListEquality: true` on
`Equality` to compare list contents instead.
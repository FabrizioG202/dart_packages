import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// An abstract base class for all derivable annotations.
abstract base class Derivable {
  const Derivable();
}

/// The main annotation for dataclasses.
final class Dataclass {
  const Dataclass([this.derives = const []]);

  final List<Derivable> derives;
}

final class CopyWith extends Derivable {
  const CopyWith();
}

final class ToString extends Derivable {
  const ToString();
}

final class Equality extends Derivable {
  const Equality({this.useListEquality = false});

  /// If true, list equality will be used for list fields.
  /// Otherwise, list identity will be used.
  final bool useListEquality;
}

final class HashCode extends Derivable {
  const HashCode();
}

const kCopyWithTypeChecker = TypeChecker.typeNamed(
  CopyWith,
  inPackage: 'dataclass',
);
const kToStringTypeChecker = TypeChecker.typeNamed(
  ToString,
  inPackage: 'dataclass',
);
const kEqualityTypeChecker = TypeChecker.typeNamed(
  Equality,
  inPackage: 'dataclass',
);
const kHashCodeTypeChecker = TypeChecker.typeNamed(
  HashCode,
  inPackage: 'dataclass',
);

class DataclassGenerator extends GeneratorForAnnotation<Dataclass> {
  const DataclassGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final output = StringBuffer();

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`. '
        '`@dataclass` can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;

    if (className == null) {
      throw InvalidGenerationSourceError(
        'Generator cannot target an unnamed class.',
        element: element,
      );
    }

    final typeParameters = element.typeParameters;

    final derivedName = '_\$$className';

    output.writeln('mixin class $derivedName {');

    final derives = annotation.peek('derives')?.listValue;

    var hasCopyWithDerive = false;
    var hasToStringDerive = false;
    var hasEqualityDerive = false;
    var hasHashCodeDerive = false;
    var useListEquality = false;

    if (derives != null) {
      hasCopyWithDerive = derives.any(
        (derive) => kCopyWithTypeChecker.isExactlyType(derive.type!),
      );
      hasToStringDerive = derives.any(
        (derive) => kToStringTypeChecker.isExactlyType(derive.type!),
      );
      hasEqualityDerive = derives.any(
        (derive) => kEqualityTypeChecker.isExactlyType(derive.type!),
      );
      final equalityDerive = derives
          .where((derive) => kEqualityTypeChecker.isExactlyType(derive.type!))
          .firstOrNull;
      useListEquality =
          equalityDerive?.getField('useListEquality')?.toBoolValue() ?? false;
      hasHashCodeDerive = derives.any(
        (derive) => kHashCodeTypeChecker.isExactlyType(derive.type!),
      );
    }

    if (typeParameters.isNotEmpty && hasCopyWithDerive) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `$className` with type parameters when '
        '`CopyWith` is derived. `@dataclass` does not currently support '
        'generics for copyWith.',
        element: element,
      );
    }

    // Now, we generate the code for the dataclass.
    // 1) Generate the copyWith which has the same parameters as the constructor
    // // but that can be passed as a T Function<T>() for each parameter.
    // 2) Generate equality and hashCode based on the fields.
    // 3) Generate toString method.
    final fields = element.fields.where((field) => !field.isStatic).toList();
    final storedFields = fields.toList();

    if (fields.isNotEmpty && hasCopyWithDerive) {
      // Get the primary constructor to check parameter types
      final constructor = element.unnamedConstructor;

      if (constructor != null) {
        // Build parameter mappings from constructor
        final positionalParams = <String>[];
        final namedParams = <String>[];
        final copyWithParams = <String>[];

        for (final param in constructor.formalParameters) {
          final fieldType = param.type.getDisplayString();
          final paramName = param.name;

          copyWithParams.add('$fieldType Function($fieldType)? $paramName');

          if (param.isNamed) {
            namedParams.add(
              '$paramName: $paramName != null ? $paramName(this0.$paramName) : this0.$paramName',
            );
          } else {
            positionalParams.add(
              '$paramName != null ? $paramName(this0.$paramName) : this0.$paramName',
            );
          }
        }

        // Build constructor call
        String constructorCall;
        if (namedParams.isNotEmpty && positionalParams.isNotEmpty) {
          constructorCall =
              '$className(\n        ${positionalParams.join(',\n        ')},\n        ${namedParams.join(',\n        ')}\n      )';
        } else if (namedParams.isNotEmpty) {
          constructorCall =
              '$className(\n        ${namedParams.join(',\n        ')}\n      )';
        } else {
          constructorCall =
              '$className(\n        ${positionalParams.join(',\n        ')}\n      )';
        }

        final copyWithMethod =
            '''
    $className copyWith({${copyWithParams.join(', ')}}) {
      final this0 = this as $className;
      return $constructorCall;
    }
    ''';
        output.writeln(copyWithMethod);
      }
    }

    // Generate toString method
    if (hasToStringDerive) {
      final String toStringMethod;
      if (fields.isEmpty) {
        toStringMethod =
            '''
      @override
      String toString() {
        return '$className()';
      }
    ''';
      } else {
        final toStringFields = fields
            .map((field) => '${field.name}: \${this0.${field.name}}')
            .join(', ');
        toStringMethod =
            '''
      @override
      String toString() {
        final this0 = this as $className;
        return '$className($toStringFields)';
      }
    ''';
      }
      output.writeln(toStringMethod);
    }

    // Generate equals method
    if (hasEqualityDerive) {
      final equalsComparisons = storedFields
          .map((field) {
            if (useListEquality && field.type.isDartCoreList) {
              return 'const ListEquality<Object?>().equals(this0.${field.name}, other.${field.name})';
            }

            return 'this0.${field.name} == other.${field.name}';
          })
          .join(' && ');

      final String equalsMethod;
      if (storedFields.isEmpty) {
        equalsMethod =
            '''
      @override
      bool operator ==(Object other) {
        return other is $className;
      }
    ''';
      } else {
        equalsMethod =
            '''
      @override
      bool operator ==(Object other) {
        final this0 = this as $className;
        return other is $className && $equalsComparisons;
      }
    ''';
      }
      output.writeln(equalsMethod);
    }

    // Generate hashCode method
    if (hasHashCodeDerive) {
      final String hashCodeMethod;
      if (storedFields.isEmpty) {
        hashCodeMethod = '''
      @override
      int get hashCode {
        return runtimeType.hashCode;
      }
    ''';
      } else if (storedFields.length == 1) {
        hashCodeMethod =
            '''
      @override
      int get hashCode {
        final this0 = this as $className;
        return this0.${storedFields.first.name}.hashCode;
      }
    ''';
      } else {
        final hashCodeFields = storedFields
            .map((field) => 'this0.${field.name}')
            .join(', ');
        hashCodeMethod =
            '''
      @override
      int get hashCode {
        final this0 = this as $className;
        return Object.hash($hashCodeFields);
      }
    ''';
      }
      output.writeln(hashCodeMethod);
    }

    output.writeln('}');

    return output.toString();
  }
}

Builder dataclassBuilder([BuilderOptions? options]) =>
    SharedPartBuilder([const DataclassGenerator()], 'dataclass');

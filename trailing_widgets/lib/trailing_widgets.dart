import 'package:flutter/widgets.dart';

extension WidgetExt<W extends Widget> on W {
  Padding padHV<T extends num>(T i, T j, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(
      horizontal: i.toDouble(),
      vertical: j.toDouble(),
    ),
    child: this,
  );

  Padding padH<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(horizontal: i.toDouble()),
    child: this,
  );

  Padding padV<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(vertical: i.toDouble()),
    child: this,
  );

  Padding padTop<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.only(top: i.toDouble()),
    child: this,
  );

  Padding padBottom<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.only(bottom: i.toDouble()),
    child: this,
  );

  Padding padLeft<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.only(left: i.toDouble()),
    child: this,
  );

  Padding padRight<T extends num>(T i, {Key? key}) => Padding(
    key: key,
    padding: EdgeInsets.only(right: i.toDouble()),
    child: this,
  );

  Padding padAll<T extends num>(T i, {Key? key}) =>
      Padding(key: key, padding: EdgeInsets.all(i.toDouble()), child: this);

  Expanded expanded({int flex = 1, Key? key}) =>
      Expanded(key: key, flex: flex, child: this);
}

extension WidgetListExt<I extends Iterable<Widget>> on I {
  Column col({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 0,
  }) => Column(
    key: key,
    spacing: spacing,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,

    // TODO: Maybe we should only convert to list if necessary?
    children: toList(),
  );

  Row row({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double spacing = 0,
  }) => Row(
    key: key,
    spacing: spacing,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,

    // TODO: Maybe we should only convert to list if necessary?
    children: toList(),
  );
}

extension NumSizedBoxExt<T extends num> on T {
  SizedBox get v => SizedBox(height: toDouble());
  SizedBox get h => SizedBox(width: toDouble());
}

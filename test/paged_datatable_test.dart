import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paged_datatable/paged_datatable.dart';

void main() {
  group('ColumnSize', () {
    test('FixedColumnSize reports fixed size and constraints', () {
      const size = FixedColumnSize(120);

      expect(size.calculateConstraints(999), 120);
      expect(size, const FixedColumnSize(120));
      expect(size, isNot(const FixedColumnSize(121)));
    });

    test('FractionalColumnSize reports fraction and constraints', () {
      const size = FractionalColumnSize(0.25);

      expect(size.fraction, closeTo(0.25, 0.0001));
      expect(size.calculateConstraints(400), closeTo(100, 0.0001));
      expect(size, const FractionalColumnSize(0.25));
    });

    test('FractionalColumnSize rejects non-positive values', () {
      expect(() => FractionalColumnSize(0), throwsAssertionError);
      expect(() => FractionalColumnSize(-0.1), throwsAssertionError);
    });

    test('RemainingColumnSize clamps negative widths', () {
      const size = RemainingColumnSize();

      expect(size.calculateConstraints(-50), 0);
      expect(size.calculateConstraints(100), 100);
    });

    test('MaxColumnSize uses max constraints and fractions', () {
      const size = MaxColumnSize(FixedColumnSize(120), FractionalColumnSize(0.5));

      expect(size.fraction, closeTo(0.5, 0.0001));
      expect(size.calculateConstraints(400), closeTo(200, 0.0001));
    });

    test('MaxColumnSize combinations resolve max constraints', () {
      const fixedFixed = MaxColumnSize(FixedColumnSize(80), FixedColumnSize(120));
      const fixedFractional = MaxColumnSize(FixedColumnSize(80), FractionalColumnSize(0.25));
      const fractionalFractional = MaxColumnSize(FractionalColumnSize(0.25), FractionalColumnSize(0.5));
      const fixedRemaining = MaxColumnSize(FixedColumnSize(80), RemainingColumnSize());
      const fractionalRemaining = MaxColumnSize(FractionalColumnSize(0.25), RemainingColumnSize());
      const remainingRemaining = MaxColumnSize(RemainingColumnSize(), RemainingColumnSize());

      expect(fixedFixed.calculateConstraints(500), 120);

      expect(fixedFractional.fraction, closeTo(0.25, 0.0001));
      expect(fixedFractional.calculateConstraints(200), 80);
      expect(fixedFractional.calculateConstraints(400), closeTo(100, 0.0001));

      expect(fractionalFractional.fraction, closeTo(0.5, 0.0001));
      expect(fractionalFractional.calculateConstraints(200), closeTo(100, 0.0001));
      expect(fractionalFractional.calculateConstraints(400), closeTo(200, 0.0001));

      expect(fixedRemaining.fraction, 0);
      expect(fixedRemaining.calculateConstraints(50), 80);
      expect(fixedRemaining.calculateConstraints(200), 200);

      expect(fractionalRemaining.fraction, closeTo(0.25, 0.0001));
      expect(fractionalRemaining.calculateConstraints(0), 0);
      expect(fractionalRemaining.calculateConstraints(100), 100);

      expect(remainingRemaining.fraction, 0);
      expect(remainingRemaining.calculateConstraints(300), 300);
    });

    test('Nested MaxColumnSize resolves max of max', () {
      const nested = MaxColumnSize(
        MaxColumnSize(FixedColumnSize(50), FractionalColumnSize(0.2)),
        MaxColumnSize(RemainingColumnSize(), FixedColumnSize(120)),
      );

      expect(nested.fraction, closeTo(0.2, 0.0001));
      expect(nested.calculateConstraints(100), 120);
      expect(nested.calculateConstraints(400), 400);
    });
  });

  group('_calculateColumnWidth', () {
    testWidgets('resolves fixed, fractional, and remaining sizes', (tester) async {
      const maxWidth = 800.0;

      await tester.pumpWidget(
        _TestHarness(
          width: maxWidth,
          child: PagedDataTable<String, String>(
            columns: [
              TableColumn<String, String>(
                title: const Text('Fixed', key: Key('fixed-title')),
                cellBuilder: _emptyCell,
                size: const FixedColumnSize(100),
              ),
              TableColumn<String, String>(
                title: const Text('Fractional', key: Key('fractional-title')),
                cellBuilder: _emptyCell,
                size: const FractionalColumnSize(0.25),
              ),
              TableColumn<String, String>(
                title: const Text('Remaining', key: Key('remaining-title')),
                cellBuilder: _emptyCell,
                size: const RemainingColumnSize(),
              ),
            ],
            fetcher: _emptyFetcher,
            filterBar: const SizedBox.shrink(),
            footer: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pump();

      expect(_headerWidthForKey(tester, const Key('fixed-title')), closeTo(100, 0.1));
      expect(_headerWidthForKey(tester, const Key('fractional-title')), closeTo(175, 0.1));
      expect(_headerWidthForKey(tester, const Key('remaining-title')), closeTo(525, 0.1));
    });

    testWidgets('max size honors fixed minimum when remaining is smaller', (tester) async {
      const maxWidth = 200.0;

      await tester.pumpWidget(
        _TestHarness(
          width: maxWidth,
          child: PagedDataTable<String, String>(
            columns: [
              TableColumn<String, String>(
                title: const Text('Max', key: Key('max-title')),
                cellBuilder: _emptyCell,
                size: const MaxColumnSize(RemainingColumnSize(), FixedColumnSize(200)),
              ),
              TableColumn<String, String>(
                title: const Text('Fixed', key: Key('fixed-title-2')),
                cellBuilder: _emptyCell,
                size: const FixedColumnSize(100),
              ),
            ],
            fetcher: _emptyFetcher,
            filterBar: const SizedBox.shrink(),
            footer: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pump();

      expect(_headerWidthForKey(tester, const Key('max-title')), closeTo(200, 0.1));
      expect(_headerWidthForKey(tester, const Key('fixed-title-2')), closeTo(100, 0.1));
    });

    testWidgets('remaining column clamps to zero when no space left', (tester) async {
      const maxWidth = 200.0;

      await tester.pumpWidget(
        _TestHarness(
          width: maxWidth,
          child: PagedDataTable<String, String>(
            columns: [
              TableColumn<String, String>(
                title: const Text('Fixed', key: Key('fixed-title-3')),
                cellBuilder: _emptyCell,
                size: const FixedColumnSize(250),
              ),
              TableColumn<String, String>(
                title: const Text('Remaining', key: Key('remaining-title-2')),
                cellBuilder: _emptyCell,
                size: const RemainingColumnSize(),
              ),
            ],
            fetcher: _emptyFetcher,
            filterBar: const SizedBox.shrink(),
            footer: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pump();

      final remainingTitleSize = tester.getSize(find.byKey(const Key('remaining-title-2'), skipOffstage: false));
      expect(remainingTitleSize.width, closeTo(0, 0.1));
    });
  });
}

class _TestHarness extends StatelessWidget {
  final double width;
  final Widget child;

  const _TestHarness({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        PagedDataTableLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: 300, child: child),
        ),
      ),
    );
  }
}

Widget _emptyCell(BuildContext context, String item, int index) => const SizedBox.shrink();

Future<(List<String> resultset, String? nextPageToken)> _emptyFetcher(
  int pageSize,
  SortModel? sortModel,
  FilterModel filterModel,
  String? pageToken,
) {
  return Future.value((<String>[], null));
}

double _headerWidthForKey(WidgetTester tester, Key key) {
  final titleFinder = find.byKey(key, skipOffstage: false);
  final titleElement = tester.element(titleFinder);

  double? width;
  titleElement.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is SizedBox && widget.width != null) {
      width = widget.width;
      return false;
    }
    return true;
  });

  if (width != null) {
    return width!;
  }

  final sizedBoxes = find.ancestor(of: titleFinder, matching: find.byType(SizedBox));
  if (tester.widgetList(sizedBoxes).isNotEmpty) {
    return tester.getSize(sizedBoxes.first).width;
  }

  return tester.getSize(titleFinder).width;
}

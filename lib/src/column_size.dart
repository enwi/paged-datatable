import 'dart:math' as math;

/// Indicates the size of a table column
sealed class ColumnSize {
  const ColumnSize();

  /// Returns the size of the column as fractional units.
  double get fraction => 0.0;

  /// The function used to calculate the constraints for the column given the [availableWidth].
  double calculateConstraints(double availableWidth);

  /// Returns the maximum fraction defined in this ColumnSize.
  double maxFraction() {
    return switch (this) {
      FractionalColumnSize(:final fraction) => fraction,
      MaxColumnSize(:final a, :final b) => math.max(a.maxFraction(), b.maxFraction()),
      _ => 0.0,
    };
  }

  /// Returns the maximum fixed width defined in this ColumnSize.
  double maxFixedWidth() {
    return switch (this) {
      FixedColumnSize(:final size) => size,
      MaxColumnSize(:final a, :final b) => math.max(a.maxFixedWidth(), b.maxFixedWidth()),
      _ => 0.0,
    };
  }

  /// Returns true if this ColumnSize or any nested ColumnSize includes a RemainingColumnSize.
  bool includesRemaining() {
    return switch (this) {
      RemainingColumnSize() => true,
      MaxColumnSize(:final a, :final b) => a.includesRemaining() || b.includesRemaining(),
      _ => false,
    };
  }
}

/// Indicates a fixed size of a column. If the content of a cell does not fit, it will be wrapped
final class FixedColumnSize extends ColumnSize {
  final double size;

  const FixedColumnSize(this.size);

  @override
  int get hashCode => size.hashCode;

  @override
  bool operator ==(Object other) => other is FixedColumnSize && other.size == size;

  @override
  double calculateConstraints(double availableWidth) => size;
}

/// Indicates a fraction size of a column. That is, a column that takes a fraction of the available viewport.
final class FractionalColumnSize extends ColumnSize {
  final double _fraction;

  const FractionalColumnSize(double fraction)
    : _fraction = fraction,
      assert(fraction > 0, "Fraction cannot be less than or equal to zero.");

  @override
  int get hashCode => fraction.hashCode;

  @override
  bool operator ==(Object other) => other is FractionalColumnSize && other.fraction == fraction;

  @override
  double get fraction => _fraction;

  @override
  double calculateConstraints(double availableWidth) => availableWidth * fraction;
}

/// Indicates that a column will take the remaining space in the viewport.
final class RemainingColumnSize extends ColumnSize {
  const RemainingColumnSize();

  @override
  double calculateConstraints(double availableWidth) => math.max(0.0, availableWidth);
}

/// A column size that uses the maximum value of two provided constraints.
final class MaxColumnSize extends ColumnSize {
  final ColumnSize a, b;

  const MaxColumnSize(this.a, this.b);

  @override
  double get fraction => math.max(a.fraction, b.fraction);

  @override
  int get hashCode => Object.hash(a.hashCode, b.hashCode);

  @override
  bool operator ==(Object other) => other is MaxColumnSize && other.a == a && other.b == b;

  @override
  double calculateConstraints(double availableWidth) =>
      math.max(a.calculateConstraints(availableWidth), b.calculateConstraints(availableWidth));
}

/// Uncoordinated unique ID
/// that fits `MAX_SAFE_INTEGER` on web platform for long enough time.
library safe_int_id;

import "dart:math";

/// `SafeIntId` config and methods. Please see `README.md` for details.
class SafeIntId {
  /// The first year you use this ID.
  late final int firstYear;

  /// Milliseconds from Epoch to the UTC start of the [firstYear].
  late final int _firstYearMillis;

  /// Random generator.
  late final Random random;

  /// Number of possible random values per millisecond.
  /// Makes ID more unique in exchange for [safeYears].
  late final int randomValues;

  /// How many years since [firstYear] this ID will be safe.
  late final int safeYears;

  /// Last year this ID will be safe.
  late final int lastSafeYear;

  /// Create new `SafeIntId` generator.
  SafeIntId({
    this.firstYear = 2023,
    Random? random,
    int randomValues = 1024,
  }) {
    _firstYearMillis = DateTime.utc(firstYear).millisecondsSinceEpoch;
    this.random = random ?? Random();
    this.randomValues = max(randomValues, 1);
    safeYears =
        pow(2, 53) ~/ (this.randomValues * 1000 * 60 * 60 * 24 * 365.2425);
    lastSafeYear = firstYear + safeYears - 1;
  }

  /// Get a new uncoordinated unique ID
  /// that fits `Number.MAX_SAFE_INTEGER` on web platform for long enough time.
  int getId() {
    final millis = DateTime.now().millisecondsSinceEpoch - _firstYearMillis;
    return millis * randomValues + random.nextInt(randomValues);
  }

  /// Get [DateTime] when given [id] was created at.
  DateTime getCreatedAt(int id, {bool isUtc = false}) =>
      DateTime.fromMillisecondsSinceEpoch(id ~/ randomValues + _firstYearMillis,
          isUtc: isUtc);
}

/// `SafeIntId` with default config.
final safeIntId = SafeIntId();

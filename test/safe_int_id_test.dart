import "dart:io";
import "package:safe_int_id/safe_int_id.dart";
import "package:test/test.dart";

void main() {
  group("By default", () {
    test("ID and createdAt are generated as expected", () {
      final start = DateTime.now();
      final id = safeIntId.getId();
      final createdAt = safeIntId.getCreatedAt(id);
      final diffMillis = createdAt.difference(start).inMilliseconds;
      expect(diffMillis, inInclusiveRange(0, 10));
    });

    test("IDs don't collide when generating 1 or less IDs per millisecond", () {
      final previous = <int>{};
      for (int i = 0; i < 1000; i++) {
        final id = safeIntId.getId();
        expect(previous, isNot(contains(id)));
        previous.add(id);
        expect(previous, contains(id));
        sleep(Duration(milliseconds: 1));
      }
    });

    test("IDs are non-decreasing when using `incId`", () {
      int previous = 0;
      for (int i = 0; i < 10000; i++) {
        final id = safeIntId.incId();
        expect(previous, lessThan(id));
        previous = id;
      }
    });

    test("config is set as expected", () {
      expect(safeIntId.firstYear, equals(2023));
      expect(safeIntId.randomValues, equals(1024));
      expect(safeIntId.safeYears, equals(278));
      expect(safeIntId.lastSafeYear, equals(2300));
    });
  });

  group("With custom config", () {
    test("bigger [firstYear] increases [lastSafeYear]", () {
      final customId = SafeIntId(firstYear: 2024);
      expect(customId.safeYears, equals(278));
      expect(customId.lastSafeYear, equals(2301));
    });

    test("bigger [randomValues] decreases [safeYears] and [lastSafeYear]", () {
      final customId = SafeIntId(randomValues: 2048);
      expect(customId.safeYears, equals(139));
      expect(customId.lastSafeYear, equals(2161));
    });

    test("smaller [randomValues] increases [safeYears] and [lastSafeYear]`",
        () {
      final customId = SafeIntId(randomValues: 512);
      expect(customId.safeYears, equals(557));
      expect(customId.lastSafeYear, equals(2579));
    });

    test(
        "zero [randomValues] increases [safeYears] and [lastSafeYear] a lot, "
        "while [getId] and [getCreatedAt] are still working", () {
      final customId = SafeIntId(randomValues: 0);
      expect(customId.safeYears, equals(285426));
      expect(customId.lastSafeYear, equals(287448));

      final id = customId.getId();
      expect(id, greaterThan(0));

      final diffMillis = customId
          .getCreatedAt(id)
          .difference(DateTime(customId.firstYear))
          .inMilliseconds;
      expect(diffMillis, greaterThan(0));
    });
  });
}

/// Example of how to use `SafeIntId`.
/// Run it with `dart run --enable-asserts example/safe_int_id_example.dart`

import "dart:math";
import "package:safe_int_id/safe_int_id.dart";

void main() {
  // Get a new uncoordinated unique ID
  // that fits `Number.MAX_SAFE_INTEGER` on web platform for long enough time.
  final id = safeIntId.getId();
  print("id: $id");

  // Get [DateTime] when given [id] was created at.
  final createdAt = safeIntId.getCreatedAt(id, isUtc: true);
  print("createdAt: $createdAt");

  // Custom configuration, defaults are:
  final customId = SafeIntId(
    firstYear: 2023, // The first year you use this ID.
    random: Random(), // Random generator, e.g. `Random.secure()`
    randomValues: 1024, // Number of possible random values per millisecond.
    // Makes ID more unique in exchange for [safeYears].
  );

  // How many years since [firstYear] this ID will be safe:
  assert(customId.safeYears == 278);

  // Last year this ID will be safe:
  assert(customId.lastSafeYear == 2300);

  // Custom configuration has the same [getId] and [getCreatedAt] methods:
  assert(!customId.getCreatedAt(customId.getId()).isBefore(createdAt));
}

# SafeIntId

Uncoordinated unique ID that fits [MAX_SAFE_INTEGER](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER) on web platform for long enough time.

## Existing solutions

There are [a lot](https://medium.com/geekculture/the-wild-world-of-unique-identifiers-uuid-ulid-etc-17cfb2a38fce)
of well-designed unique IDs. Few well-known ones are, alphabetically:  
[Cuid2](https://github.com/paralleldrive/cuid2),
[KSUID](https://github.com/segmentio/ksuid),
[Nano ID](https://github.com/ai/nanoid),
[ObjectId](https://www.mongodb.com/docs/manual/reference/method/ObjectId/),
[Push ID](https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68#whats-in-a-push-id),
[Sharding ID](https://instagram-engineering.com/sharding-ids-at-instagram-1cf5a71e5a5c),
[Snowflake ID](https://en.wikipedia.org/wiki/Snowflake_ID),
[Sonyflake](https://github.com/sony/sonyflake),
[ULID](https://github.com/ulid/spec),
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier),
[XID](https://github.com/rs/xid).

These IDs are great for their use cases, but none meets our special requirements.

## Requirements

* ID should fit signed 64-bit int as in [Isar Database ID](https://isar.dev/schema.html#isar-id).
* ID should fit +/- (2⁵³-1) as in [safe integers on web platform](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isSafeInteger#description).
* IDs should be generated at multiple places without coordination over the network
  as in offline-first app running on multiple devices.
* IDs created at different moments of time should have zero probability of collision,
  not just small one.
* IDs should be unique as much as possible given the constraints above.

## Nice to have

* IDs could be sorted by their created-at timestamp.
* This timestamp could be extractable from ID.
* ID could be URL-friendly.
    * Max ID is `9007199254740991` which is URL-friendly as is.
    * If you need even shorter string, you can encode and decode ID, e.g:
        * `9007199254740991.toRadixString(36) == "2gosa7pa2gv"`
        * `int.parse("2gosa7pa2gv", radix: 36) == 9007199254740991`
* ID could optionally contain an auto-incrementing counter instead of a random part.

## Not required

* We don't require ID to be highly unpredictable:
  we'd use auto-increment ID, but it would collide without coordination.

## Design and usage

* Import:
    ```dart
    import 'package:safe_int_id/safe_int_id.dart';
    ```
* Get a new ID:
    ```dart
    final id = safeIntId.getId();
    ```
    * ID is a positive integer less or equal than 2⁵³-1 for some number of years.
    * We could have 54 bits by using negative integers too,
      but this would increase complexity and reduce compatibility.
    * So we have 53 bits.
* ID contains, by default:
    * 43 bits of timestamp:
        * Milliseconds since the UTC start of the first year you use this ID,
          2023 by default, configurable:
            ```dart
            final customId = SafeIntId(firstYear: 2024);
            ```
        * To get `DateTime` when given `id` was created at:
            ```dart
            safeIntId.getCreatedAt(id) is DateTime
            ```
        * 43 bits give us more than 278 years of millisecond-precise timestamps:
            ```dart
            pow(2, 43) / (1000*60*60*24*365.2425) > 278
            ```
        * So for the default first year 2023 the last safe year is 2300, good enough.
    * 10 bits of random:
        * Non-secure random generator is used by default:
          it is always available and is faster than the secure one.
        * If you prefer secure random generator, it is configurable:
            ```dart
            final customId = SafeIntId(random: Random.secure());
            ```
        * 10 random bits give 1024 possible values per millisecond, configurable
          in exchange for how many years since `firstYear` this ID will be safe:
            ```dart
            final customId = SafeIntId(randomValues: 2048);
            assert(customId.safeYears == 139);
            assert(customId.lastSafeYear == 2161);
            ```

```
| random |                  default firstYear 2023 |
|   bits | randomValues | safeYears | lastSafeYear |
| ------ | ------------ | --------- | ------------ |
|      8 |          256 |      1114 |         3136 |
|      9 |          512 |       557 |         2579 |
|     10 | default 1024 |       278 |         2300 |
|     11 |         2048 |       139 |         2161 |
|     12 |         4096 |        69 |         2091 |
|     13 |         8192 |        34 |         2056 |
|     14 |        16384 |        17 |         2039 |
|     15 |        32768 |         8 |         2030 |
|     16 |        65536 |         4 |         2026 |
```

* Probability of generating more than one ID with the same value
  is [approximately N²/2M](https://en.wikipedia.org/wiki/Birthday_problem#Square_approximation),
  where:
    * M is `randomValues` - how many possible values we have.
    * N is how many IDs per millisecond we generate.
    * For N = 1 or less the probability is exactly zero for any M.
    * For N = 2 and default M = 1024 we have probability 0.002 = 0.2%.
    * 2 IDs per millisecond means 2K IDs per second,
      120K IDs per minute, 7.2M IDs per hour.
    * To get 1% probability of collision with default M = 1024 we need to generate
      `sqrt(2*1024*0.01)` = 5 IDs per millisecond,
      5K IDs per second, 272K IDs per minute, 16M IDs per hour.
    * Please check the table below to adjust `SafeIntId(randomValues: M)` if needed.
    * This approximation works well for probabilities of 50% or less,
      so the higher ones are not shown.

```
| M     | N                                                                                |
|       | 1 | 2      | 5     | 10   | 20   | 30  | 40  | 60  | 80  | 100 | 150 | 200 | 250 |
|------ | - | ------ | ----- | ---- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|   256 | 0 | 0.8%   | 4.9%  |  20% |      |     |     |     |     |     |     |     |     |
|   512 | 0 | 0.4%   | 2.4%  |  10% |  39% |     |     |     |     |     |     |     |     |
|  1024 | 0 | 0.2%   | 1.2%  | 4.9% |  20% | 44% |     |     |     |     |     |     |     |
|  2048 | 0 | 0.1%   | 0.6%  | 2.4% |  10% | 22% | 39% |     |     |     |     |     |     |
|  4096 | 0 | 0.05%  | 0.3%  | 1.2% |   5% | 11% | 20% | 44% |     |     |     |     |     |
|  8192 | 0 | 0.02%  | 0.15% | 0.6% |   2% |  5% | 10% | 22% | 39% |     |     |     |     |
| 16384 | 0 | 0.01%  | 0.08% | 0.3% |   1% |  3% |  5% | 11% | 20% | 31% |     |     |     |
| 32768 | 0 | 0.01%  | 0.04% | 0.2% |   1% |  1% |  2% |  5% | 10% | 15% | 34% |     |     |
| 65536 | 0 | 0.003% | 0.01% | 0.1% | 0.3% |  1% |  1% |  3% |  5% |  8% | 17% | 31% | 48% |
```

* If you generate a lot of IDs on the same device,
  use `incId()` instead of `getId()`:
    * `incId()` increments a counter instead of using a random value.
    * This counter resets to zero each millisecond, and blocks reaching `randomValues` (1024 by default).
    * If a hot loop for less than 1 millisecond burns,
      use `await incIdAsync()` or increase `randomValues` in exchange for `safeYears`.
    * This way you can get an increasing sequence of unique IDs.

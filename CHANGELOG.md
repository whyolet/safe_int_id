# 1.1.1

* Added test for `incIdAsync`.
* Fixed docs re "increasing sequence".

# 1.1.0

* Added `incId()` incrementing counter instead of using random value.
  Counter resets to zero each millisecond, blocks reaching `randomValues`.
* Added `incIdAsync()` if hot loop for less than 1 millisecond burns.

# 1.0.0

* Initial stable release.

# Timestamp tests

`Timestamp` must behave the same on every platform (on the web a `DateTime`
has no microseconds and an integer above 2^53 loses precision), run its test
on each of them:

```sh
dart test -p vm,chrome,node test/timestamp_test.dart
```

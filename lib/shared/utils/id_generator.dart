import 'dart:math';

/// Generates unique client-side ids (e.g. optimistic message ids).
///
/// Not cryptographically meaningful; do not use for secrets.
abstract interface class IdGenerator {
  String next();
}

class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;
  int _counter = 0;

  @override
  String next() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _random.nextInt(1 << 32).toRadixString(36);
    return '$time-${(_counter++).toRadixString(36)}-$rand';
  }
}

/// Deterministic ids for tests: `prefix-1`, `prefix-2`, ...
class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator([this.prefix = 'id']);

  final String prefix;
  int _counter = 0;

  @override
  String next() => '$prefix-${++_counter}';
}

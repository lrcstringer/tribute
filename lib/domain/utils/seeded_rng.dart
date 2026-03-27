/// Minimal LCG (linear congruential generator) seeded with a deterministic
/// integer. Produces the same sequence for the same seed — suitable for
/// variable-reinforcement scheduling and notification timing where reproducible
/// pseudo-randomness is required.
///
/// Not cryptographically secure. Not intended for security-sensitive use.
class SeededRng {
  int _state;
  SeededRng(int seed) : _state = seed;

  int next() {
    _state = ((_state * 1103515245) + 12345) & 0x7fffffff;
    return _state;
  }
}

#ifndef LEAGUE_SOCCER_RNG_HPP
#define LEAGUE_SOCCER_RNG_HPP

#include <random>

namespace blunted {

// Generador pseudoaleatorio de juego (no criptografico) basado en <random>;
// sustituye a std::rand()/srand() de C.
inline std::mt19937& GameRng() {
  static thread_local std::mt19937 gen{std::random_device{}()};
  return gen;
}

inline void SeedGameRng(unsigned int seed) {
  GameRng().seed(seed);
}

// Entero uniforme en [0, n). Con n <= 0 devuelve 0.
inline int GameRandInt(int n) {
  if (n <= 0)
    return 0;
  return std::uniform_int_distribution<int>(0, n - 1)(GameRng());
}

}  // namespace blunted

#endif

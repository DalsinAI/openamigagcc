#include <cstdio>
#include <vector>
int main() { std::vector<int> v; for (int i = 0; i < 100; i++) v.push_back(i * i); int s = 0; for (int x : v) s += x; std::printf("nothreads OK %d\n", s); return 0; }

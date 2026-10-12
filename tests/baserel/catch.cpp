#include <cstdio>
#include <stdexcept>
#include <vector>
#include <string>
struct Mine { int code; };
struct Base { virtual ~Base() {} }; struct Derived : Base {};
static int fails = 0;
#define CHECK(c, n) do { if (c) std::printf("PASS %s\n", n); else { std::printf("FAIL %s\n", n); ++fails; } } while (0)
int main() {
    int r = 0;
    try { throw Mine{42}; } catch (const Mine &m) { r = m.code; } catch (...) { r = -1; }
    CHECK(r == 42, "catch own struct by type");
    r = 0; try { std::vector<int> v(2); (void)v.at(5); } catch (const std::out_of_range &) { r = 1; } catch (const std::exception &) { r = 2; } catch (...) { r = 3; }
    CHECK(r == 1, "catch std::out_of_range thrown inside libstdc++");
    r = 0; try { throw std::runtime_error("x"); } catch (const std::logic_error &) { r = 1; } catch (const std::exception &e) { r = std::string(e.what()) == "x" ? 2 : 3; }
    CHECK(r == 2, "catch through base class, skip non-matching");
    r = 0; try { throw Derived(); } catch (const Base &) { r = 1; } catch (...) { r = 2; }
    CHECK(r == 1, "catch derived by base");
    r = 0; try { try { throw 7; } catch (int i) { r = i; throw; } } catch (int j) { r += j; }
    CHECK(r == 14, "rethrow int");
    std::printf(fails ? "catch FAILED\n" : "catch OK\n");
    return fails ? 20 : 0;
}

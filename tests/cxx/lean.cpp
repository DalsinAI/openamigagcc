// The lean C++ library profile (docs/lean-cxx.md): everything here must
// compile to code that needs no libstdc++, no exception or RTTI support and no
// static constructors. tests/cxx/lean-check.sh checks the object.
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <type_traits>

extern "C" void *AllocVecGlue(unsigned long size);   // the library's glue
extern "C" void FreeVecGlue(void *p);

void *operator new(std::size_t n) noexcept { return AllocVecGlue(n); }
void *operator new[](std::size_t n) noexcept { return AllocVecGlue(n); }
void operator delete(void *p) noexcept { FreeVecGlue(p); }
void operator delete[](void *p) noexcept { FreeVecGlue(p); }
void operator delete(void *p, std::size_t) noexcept { FreeVecGlue(p); }
void operator delete[](void *p, std::size_t) noexcept { FreeVecGlue(p); }
extern "C" void __cxa_pure_virtual() { for (;;) {} }

namespace {

struct LibBase {              // shared with C: standard layout
  std::uint32_t opens;
  std::uint32_t flags;
};
static_assert(std::is_standard_layout_v<LibBase>);

class Shape {
public:
  virtual ~Shape() = default;
  virtual std::int32_t area() const = 0;
};

class Rect final : public Shape {
public:
  constexpr Rect(std::int32_t w, std::int32_t h) : w_(w), h_(h) {}
  std::int32_t area() const override { return w_ * h_; }
private:
  std::int32_t w_, h_;
};

template <typename T, std::size_t N>
constexpr T sum(const std::array<T, N> &a) {
  T s{};
  for (auto v : a) s += v;
  return s;
}

constinit std::array<std::int32_t, 4> table{1, 2, 3, 4};
static_assert(sum(std::array<std::int32_t, 4>{1, 2, 3, 4}) == 10);

}  // namespace

extern "C" std::int32_t LeanEntry(LibBase *base, std::int32_t w, std::int32_t h) {
  base->opens++;
  Shape *s = new Rect(w, h);
  if (!s) return -1;
  std::int32_t a = s->area();
  delete s;
  auto scale = [base](std::int32_t v) { return v * static_cast<std::int32_t>(base->flags + 1); };
  std::int32_t t = 0;
  for (auto v : std::span<const std::int32_t>(table)) t += scale(v);
  return a + t;
}

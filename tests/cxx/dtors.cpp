// SPDX-License-Identifier: MIT
// Copyright (c) 2026 AmiCradle Team
// dtors: C++ destructors at thread exit and program exit, built with the
// compiler's defaults (no -fuse-cxa-atexit, no __dso_handle of its own).
//   - a thread_local at namespace scope, used in a thread: destroyed when
//     the thread ends, before join() returns;
//   - the same thread_local, used in the main program: destroyed at exit,
//     before any static object;
//   - static objects and an atexit() function: called at exit in the
//     reverse order of their registration.
// The last function called at exit prints "dtors OK" when the order is
// right, or "dtors FAILED" with what ran. Before GFOpenAmigaGCC's gcc 0010 and
// libnix 0005 no thread_local destructor ran, and the static objects were
// destroyed after every atexit() function, the last one included:
// "thread_local destroyed when its thread ended: no", "dtors FAILED: g".
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <thread>

static char ran[128];
static void note(const char *what) { std::strcat(ran, what); std::strcat(ran, " "); }

static void verdict()
{
    const char *want = "tm b g a ";
    if (std::strcmp(ran, want) == 0)
        std::puts("dtors OK");
    else
        std::printf("dtors FAILED: %s(want %s)\n", ran, want);
    std::fflush(stdout);
}
static int v = std::atexit(verdict); // registered first, called last

struct S {
    const char *name;
    explicit S(const char *n) : name(n) {}
    ~S() { note(name); }
};
static void g() { note("g"); }

static S a("a");
static int r = std::atexit(g);
static S b("b");
thread_local S t("tm");

int main()
{
    std::thread th([] { t.name = "tt"; });
    th.join();
    bool thread_ok = std::strcmp(ran, "tt ") == 0;
    std::printf("thread_local destroyed when its thread ended: %s\n", thread_ok ? "yes" : "no");
    ran[0] = 0;
    (void) t.name; // the main program's own t, destroyed at exit
    std::fflush(stdout);
    return thread_ok && v == 0 && r == 0 ? 0 : 20;
}

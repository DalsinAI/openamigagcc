/* exitpark: libpthread at exit leaves a thread that crashed (its task parked
 * by exec's trap handling in Wait(0)), and pthread_cond_timedwait times out.
 *   exitpark crash   a thread writes to 0xBBADBEEF (WTFCrash's address); main returns
 *   exitpark join    a thread ends normally; main joins at exit as before
 *   exitpark timed   timedwait: an absolute time already past, then 200 ms ahead
 * Prints EXITPARK lines; the Shell's RC shows that the program returned.
 * zlib licence, as aros-stuff's pthreads. Copyright (c) 2026 AmiCradle Team. */
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include <proto/exec.h>
#include <proto/dos.h>

static volatile int ran;

static void *crasher(void *arg)
{
    (void)arg;
    ran = 1;
    *(volatile unsigned long *)0xBBADBEEFUL = 0;   /* as WTFCrash: the write, */
    __builtin_trap();                              /* then the trap (a CPU exception) */
    ran = 2;
    for (;;)
        Delay(50);
    return NULL;
}

static void *worker(void *arg)
{
    (void)arg;
    Delay(10);
    ran = 3;
    return NULL;
}

static long now(void)   /* milliseconds */
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000L + tv.tv_usec / 1000;
}

static int timed(void)
{
    pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
    pthread_cond_t c = PTHREAD_COND_INITIALIZER;
    struct timeval tv;
    struct timespec ts;
    long t0, t1;
    int r, ok = 1;

    pthread_mutex_lock(&m);
    gettimeofday(&tv, NULL);
    ts.tv_sec = tv.tv_sec - 2;                     /* two seconds ago */
    ts.tv_nsec = tv.tv_usec * 1000;
    t0 = now();
    r = pthread_cond_timedwait(&c, &m, &ts);
    t1 = now();
    printf("EXITPARK timedwait past: %s after %ld ms\n", r == ETIMEDOUT ? "ETIMEDOUT" : "NOT ETIMEDOUT", t1 - t0);
    ok &= r == ETIMEDOUT && t1 - t0 < 1000;

    gettimeofday(&tv, NULL);
    tv.tv_usec += 200000;
    if (tv.tv_usec >= 1000000) { tv.tv_sec++; tv.tv_usec -= 1000000; }
    ts.tv_sec = tv.tv_sec;
    ts.tv_nsec = tv.tv_usec * 1000;
    t0 = now();
    r = pthread_cond_timedwait(&c, &m, &ts);
    t1 = now();
    printf("EXITPARK timedwait 200 ms: %s after %ld ms\n", r == ETIMEDOUT ? "ETIMEDOUT" : "NOT ETIMEDOUT", t1 - t0);
    ok &= r == ETIMEDOUT && t1 - t0 >= 100 && t1 - t0 < 1500;
    pthread_mutex_unlock(&m);
    return ok;
}

int main(int argc, char **argv)
{
    pthread_t t;
    const char *mode = argc > 1 ? argv[1] : "crash";

    if (!strcmp(mode, "timed")) {
        int ok = timed();
        printf("EXITPARK timed %s\n", ok ? "PASS" : "FAIL");
        return ok ? 0 : 10;
    }
    if (pthread_create(&t, NULL, !strcmp(mode, "join") ? worker : crasher, NULL)) {
        printf("EXITPARK pthread_create failed\n");
        return 20;
    }
    Delay(50);                                      /* let it run (and crash) */
    printf("EXITPARK %s: thread state ran=%d; returning from main\n", mode, ran);
    fflush(stdout);
    return 0;                                       /* exit joins every thread */
}

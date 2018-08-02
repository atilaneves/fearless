# fearless

[![Build Status](https://travis-ci.org/atilaneves/fearless.png?branch=master)](https://travis-ci.org/atilaneves/fearless)
[![Coverage](https://codecov.io/gh/atilaneves/fearless/branch/master/graph/badge.svg)](https://codecov.io/gh/atilaneves/fearless)

Safe concurrency in D

This package implements `@safe` easy sharing of mutable data between threads without having
to cast from shared and lock/unlock a mutex. It does so by using `scope` and
[DIP1000](https://github.com/dlang/DIPs/blob/master/DIPs/DIP1000.md). It was inspired by
Rusts's [std::sync::Mutex](https://doc.rust-lang.org/1.21.0/std/sync/struct.Mutex.html).

The main type is `Exclusive!T` which is safely shareable between
threads even if T is not `immutable` or `shared`. To create one, call
of one `gcExclusive` or `rcExclusive` with the parameters to the
constructor to create a type T. Passing an already created T would not
be safe since references to it or its internal data might exist
elsewhere.

As the names indicate, `gcExclusive` allocates on the GC heap, whereas `rcExclusive` uses
`RefCounted` from [automem](https://github.com/atilaneves/automem). This is optional and only
available at compile-time if the client code defines `Have_automem`, which is automatically
done by dub if automem is listed as a dependency.

To actually get access to the protected value, use `.lock()` to get exclusive access for the
current block of code.

An example (notice that `main` is `@safe`):

```d
import fearless;


struct Foo {
    int i;
}

int* gEvilInt;


void main() @safe {

    // create an instance of Exclusive!Foo allocated on the GC heap
    auto foo = gcExclusive!Foo(42);
    // from now the value inside `foo` can only be used by calling `lock`

    {
        int* oldIntPtr;
        auto xfoo = foo.lock();  // get exclusive access to the data (this locks a mutex)

        safeWriteln("i: ", xfoo.i);
        xfoo.i = 1;
        safeWriteln("i: ", xfoo.i);

        // can't escape to a global
        static assert(!__traits(compiles, gEvilInt = &xfoo.i));

        // ok to assign to a local that lives less
        int* intPtr;
        static assert(__traits(compiles, intPtr = &xfoo.i));

        // not ok to assign to a local that lives longer
        static assert(!__traits(compiles, oldIntPtr = &xfoo.i));
    }

    // Demonstrate sending to another thread and mutating
    auto tid = spawn(&func, thisTid);
    tid.send(foo);
    receiveOnly!Ended;
    safeWriteln("i: ", foo.lock.i);
}

struct Ended{}

void func(Tid tid) @safe {
    receive(
        // ref Exclusive!Foo doesn't compile, use pointer instead
        (Exclusive!Foo* m) {
            auto xfoo = m.lock;
            xfoo.i++;
        },
    );

    tid.send(Ended());
}


void safeWriteln(A...)(auto ref A args) { // for some reason the writelns here are all @system
    import std.stdio: writeln;
    import std.functional: forward;
    () @trusted { writeln(forward!args); }();
}

```

This program prints:

```
i: 42
i: 1
i: 2
```

Please consult the examples directory and/or unit tests for more.

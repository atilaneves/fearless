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

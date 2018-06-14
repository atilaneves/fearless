import fearless;

struct Ended{}

struct Foo {
    int i;
}

Foo* gEvilStruct;
int* gEvilInt;


void main() @safe {

    auto foo = gcExclusive!Foo(42);

    {
        auto xfoo = foo.lock();

        safeWriteln("i: ", xfoo.i);
        xfoo.i = 1;
        safeWriteln("i: ", xfoo.i);

        // can't escape to a global
        static assert(!__traits(compiles, gEvilStruct = xfoo));
        static assert(!__traits(compiles, gEvilInt = &xfoo.i));

        // ok to assign to a local
        Foo* fooPtr;
        int* intPtr;
        static assert(__traits(compiles, fooPtr = xfoo));
        static assert(__traits(compiles, intPtr = &xfoo.i));
    }

    // Demonstrate sending to another thread
    auto tid = spawn(&func, thisTid);
    tid.send(foo);
    receiveOnly!Ended;
    safeWriteln("i: ", foo.lock.i);
}


void func(Tid tid) @safe {
    receive(
        // ref shared(Exclusive!Foo) didn't work
        (shared(Exclusive!Foo)* m) {
            auto xfoo = m.lock;
            xfoo.i++;
        },
    );

    tid.send(Ended());
}

void safeWriteln(A...)(auto ref A args) {
    import std.stdio: writeln;
    import std.functional: forward;
    () @trusted { writeln(forward!args); }();
}

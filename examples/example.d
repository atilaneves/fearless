import fearless;


int* gEvilInt;


void main() @safe {

    auto s = gcExclusive!int(42);

    {
        auto i = s.lock();

        safeWriteln("i: ", *i);
        *i = 33;
        safeWriteln("i: ", *i);

        // can't escape to a global
        static assert(!__traits(compiles, gEvilInt = i));

        // ok to assign to a local
        int* intPtr;
        static assert(__traits(compiles, intPtr = i));
    }

    // Demonstrate sending to another thread
    auto tid = spawn(&func, thisTid);
    tid.send(s);
    receiveOnly!bool;
    safeWriteln("i: ", *s.lock);
}


void func(Tid tid) @safe {

    receive(
        // ref shared(GcExclusive!int) didn't work
        (shared(Exclusive!int)* m) {
            auto i = m.lock;
            *i = ++*i;
        },
    );

    tid.send(true);
}

void safeWriteln(A...)(auto ref A args) {
    import std.stdio: writeln;
    import std.functional: forward;
    () @trusted { writeln(forward!args); }();
}

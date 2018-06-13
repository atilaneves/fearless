import fearless;
import std.concurrency: Tid;


int* gEvil;


void main() @safe {
    import std.stdio: writeln;
    import std.concurrency: spawn, send, receiveOnly, thisTid;

    auto s = shared Shared!int(42);

    {
        auto i = s.lock();

        // writeln is @system for some reason
        () @trusted { writeln("i: ", *i); }();
        *i = 33;
        () @trusted { writeln("i: ", *i); }();

        // can't escape to a global
        static assert(!__traits(compiles, gEvil = i));

        // ok to assign to a local
        int* intPtr;
        static assert(__traits(compiles, intPtr = i));
    }

    // Demonstrate sending to another thread
    () @trusted { // all the std.concurrency functions are @system
        // Need to find a way here to stop sending it to another thread
        // in the same scope as .lock() to avoid deadlocks.
        auto tid = spawn(&func, thisTid);
        tid.send(&s);
        receiveOnly!bool;
        writeln("i: ", *s.lock);
    }();
}


void func(Tid tid) @trusted { // Both receive and send are @system
    import std.concurrency: receive, send;

    receive(
        // ref shared(Shared!int) didn't work
        (shared(Shared!int)* m) {
            auto i = m.lock;
            *i = ++*i;
        },
    );

    tid.send(true);
}

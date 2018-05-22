import std.concurrency: Tid;

void main() @safe {
    import std.stdio: writeln;
    import std.concurrency: spawn, send, receiveOnly, thisTid;

    auto s = shared Shared!int(42);

    {
        scope i = s.lock();
        // writeln is @system for some reason
        () @trusted { writeln("i: ", *i); }();
        *i = 33;
        () @trusted { writeln("i: ", *i); }();
    }

    auto tid = () @trusted { return spawn(&func, thisTid); }();
    () @trusted { tid.send(&s); }();
    () @trusted { receiveOnly!bool; }();
    () @trusted { writeln("i: ", *s.lock); }();
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


struct Shared(T) {

    import core.sync.mutex: Mutex;

    private T _payload;
    private Mutex _mutex;  // see below why not core.sync.mutex.Mutex

    this(A...)(auto ref A args) shared {
        import std.functional: forward;
        this._mutex = new shared Mutex;
        this._payload = T(forward!args);
    }

    // non-static didn't work - weird error messages
    static struct Guard {

        private shared T* _payload;
        private shared Mutex* _mutex;

        alias payload this;

        // I tried ref(T) as a return type here. That didn't compile.
        // I can't remember why.
        scope T* payload() @trusted {
            return cast(T*) _payload;
        }

        ~this() {
            _mutex.unlock_nothrow();
        }
    }

    auto lock() shared @trusted {
        _mutex.lock_nothrow;
        return Guard(&_payload, &_mutex);
    }
}

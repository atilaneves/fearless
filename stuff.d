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

    private T _payload;
    private Mutex _mutex;

    this(A...)(auto ref A args) shared {
        import std.functional: forward;
        this._mutex = shared Mutex(null /*attr*/);
        this._payload = T(forward!args);
    }

    // non-static didn't work - weird error messages
    static struct Guard {

        private shared T* _payload;
        private shared Mutex* _mutex;

        alias payload this;

        scope T* payload() @trusted {
            return cast(T*) _payload;
        }

        ~this() scope {
            _mutex.unlock_nothrow();
        }
    }

    auto lock() shared @trusted {
        _mutex.lock_nothrow;
        return Guard(&_payload, &_mutex);
    }
}

// Can't use core.sync.mutex due to the member functions not being `scope`
static struct Mutex {

    import core.sys.posix.pthread;

    private pthread_mutex_t _mutex;

    @disable this();

    this(pthread_mutexattr_t* attr) @trusted shared scope {
        pthread_mutex_init(cast(pthread_mutex_t*)&_mutex, attr);
    }

    ~this() @trusted scope {
        pthread_mutex_destroy(cast(pthread_mutex_t*)&_mutex);
    }

    void lock_nothrow() @trusted shared scope nothrow {
        pthread_mutex_lock(cast(pthread_mutex_t*)&_mutex);
    }

    void unlock_nothrow() @trusted shared scope nothrow {
        pthread_mutex_unlock(cast(pthread_mutex_t*)&_mutex);
    }
}

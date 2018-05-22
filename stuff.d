import std.concurrency: Tid;

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

    void lock_nothrow() shared scope nothrow {
        pthread_mutex_lock(cast(pthread_mutex_t*)&_mutex);
    }

    void unlock_nothrow() shared scope nothrow {
        pthread_mutex_unlock(cast(pthread_mutex_t*)&_mutex);
    }
}

struct Shared(T) {

    // Can't use core.sync.mutex due to the member functions not being `scope`
    //import core.sync.mutex: Mutex;

    private T _payload;
    private Mutex _mutex;

    this(A...)(auto ref A args) shared {
        import std.functional: forward;

        //this._mutex = new shared Mutex();
        this._mutex = shared Mutex(null /*attr*/);
        this._payload = T(forward!args);
    }

    static struct Guard {

        private shared T* _payload;
        private shared Mutex* _mutex;

        alias payload this;

        scope T* payload() @trusted {
            return cast(T*)_payload;
        }

        ~this() scope @trusted  {
            _mutex.unlock_nothrow();
        }
    }

    auto lock() shared @trusted {
        _mutex.lock_nothrow;
        return Guard(&_payload, &_mutex);
    }
}


void main() @safe {
    import std.stdio: writeln;
    import std.concurrency: spawn, send, receiveOnly, thisTid;

    auto s = shared Shared!int(42);

    {
        scope i = s.lock();
        *i = 33;
        // writeln here is @system for some reason
        () @trusted { writeln("i: ", *i); }();
        (*i)++;
        () @trusted { writeln("i: ", *i); }();
    }

    auto tid = () @trusted { return spawn(&func, thisTid); }();
    () @trusted { tid.send(&s); }();
    () @trusted { receiveOnly!bool; }();
    () @trusted { writeln("i is now ", *s.lock); }();
}


// Both receive and send are @system
void func(Tid tid) @trusted {
    import std.concurrency: receive, send;

    receive(
        (shared(Shared!int)* m) {
            auto i = m.lock;
            *i = ++*i;
        },
    );

    tid.send(true);
}

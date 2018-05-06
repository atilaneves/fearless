@safe:

import std.concurrency: Tid;

struct Mutex(T) {

    import core.sync.mutex: MutexImpl = Mutex;

    private shared T _payload;
    private shared MutexImpl _mutex;

    this(A...)(auto ref A args) shared {
        import std.functional: forward;

        this._mutex = new shared MutexImpl();
        this._payload = T(forward!args);
    }

    static struct Guard {

        private shared T* _payload;
        private shared MutexImpl _mutex;

        alias payload this;

        T* payload() @trusted {
            return cast(T*)_payload;
        }

        ~this() {
            _mutex.unlock_nothrow();
        }
    }

    auto lock() shared {
        _mutex.lock_nothrow;
        return Guard(&_payload, _mutex);
    }
}


void main() {
    import std.stdio;
    import std.concurrency: spawn, send, receiveOnly, thisTid;

    auto s = shared Mutex!int(42);

    {
        scope i = s.lock();
        *i = 33;
        writeln("i: ", *i);
    }

    auto tid = () @trusted { return spawn(&func, thisTid); }();
    () @trusted { tid.send(&s); }();
    () @trusted { receiveOnly!bool; }();
    writeln("i is now ", *s.lock);
}


void func(Tid tid) @trusted {
    import std.concurrency: receive, send;

    receive(
        (shared(Mutex!int)* m) {
            auto i = m.lock;
            *i = ++*i;
        },
    );

    tid.send(true);
}

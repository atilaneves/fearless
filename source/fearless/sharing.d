/**
   D implementation of Rust's std::sync::Mutexmodule fearless.sharing;
*/
module fearless.sharing;


// Shared instead of the original's Mutex since it might get confusing.
// Then again, `shared Shared` isn't great either.
struct Shared(T) {

    import core.sync.mutex: Mutex;

    private T _payload;
    private Mutex _mutex;  // see below why not core.sync.mutex.Mutex

    this(A...)(auto ref A args) shared {
        import std.functional: forward;
        this._mutex = new shared Mutex;
        this._payload = T(forward!args);
    }

    auto lock() shared {
        () @trusted { _mutex.lock_nothrow; }();
        return Guard(&_payload, _mutex);
    }

    // non-static didn't work - weird error messages
    static struct Guard {

        private shared T* _payload;
        private shared Mutex _mutex;

        alias payload this;

        // I tried ref(T) as a return type here. That didn't compile.
        // I can't remember why.
        scope T* payload() @trusted {
            return cast(T*) _payload;
        }

        ~this() scope @trusted {
            _mutex.unlock_nothrow();
        }
    }
}

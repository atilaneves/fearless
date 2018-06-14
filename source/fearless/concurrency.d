/**
   Safe concurrency based on std.concurrency.
 */
module fearless.concurrency;


public import std.concurrency: Tid, thisTid;


auto spawn(F, A...)(F fn, auto ref A args) {
    import std.functional: forward;
    import std.concurrency: spawn_ = spawn;
    return () @trusted { return spawn_(fn, forward!args); }();
}


/**
   Wraps std.concurrency.send to make sure it's not possible to send
   a fearless.sharing.Exclusive that is already locked to another thread.
 */
void send(A...)(Tid tid, auto ref A args) {

    import fearless.sharing: Exclusive;
    import std.functional: forward;
    import std.concurrency: send_ = send;
    import std.traits: isInstanceOf, isPointer, PointerTarget;

    static immutable alreadyLockedException =
        new Exception("Cannot send already locked Exclusive to another thread");

    foreach(ref arg; args) {

        alias T = typeof(arg);

        static if(isPointer!T && isInstanceOf!(Exclusive, PointerTarget!T)) {
            if(arg.isLocked)
                throw alreadyLockedException;
        }
    }

    return () @trusted { send_(tid, forward!args); }();
}

void receive(T...)(auto ref T ops) {
    import std.concurrency: receive_ = receive;
    import std.functional: forward;
    () @trusted { receive_(forward!ops); }();
}

auto receiveOnly(A...)() {
    import std.concurrency: receiveOnly_ = receiveOnly;
    return () @trusted { return receiveOnly_!A(); }();
}

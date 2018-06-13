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


void send(A...)(Tid tid, auto ref A args) {
    import std.functional: forward;
    import std.concurrency: send_ = send;
    return () @trusted { send_(tid, forward!args); }();
}


auto receiveOnly(A...)() {
    import std.concurrency: receiveOnly_ = receiveOnly;
    return () @trusted { return receiveOnly_!A(); }();
}

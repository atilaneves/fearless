module ut.concurrency;


import fearless.sharing;
import fearless.concurrency;
import unit_threaded;


private struct Stop{}
private struct Ended{}


private void threadFunc(Tid tid) {
    import std.concurrency: receive, send;

    for(bool stop; !stop;) {

        receive(
            (Stop _) {
                stop = true;
            },
            (shared(Exclusive!int)* m) {
                auto i = m.lock;
                *i = ++*i;
            },
        );
    }

    tid.send(Ended());
}

@("send works")
@safe unittest {
    auto tid = spawn(&threadFunc, thisTid);
    auto s = exclusive!int(42);
    tid.send(s);
    tid.send(Stop());
    receiveOnly!Ended;
}

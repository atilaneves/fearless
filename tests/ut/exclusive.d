module ut.exclusive;


import fearless.sharing;
import unit_threaded;


@("GC exclusive")
@safe unittest {
    auto e = exclusive!int(42);
}

version(none)
@("RC exclusive default allocator")
@safe unittest {
    auto e = rcExclusive!int(42);
}

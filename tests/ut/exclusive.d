module ut.exclusive;


import fearless.sharing;
import unit_threaded;


@("GC exclusive int")
@safe unittest {
    auto e = gcExclusive!int(42);
}

@("GC exclusive int moved payload")
@safe unittest {

    int i = 42;
    auto e = gcExclusive(i);

    // should be reset to T.init
    i.should == 0;

    {
        auto p = e.lock;
        p.reference.should == 42;
    }
}

@("GC exclusive struct with indirection moved payload")
@safe unittest {
    struct Struct {
        int[] ints;
    }

    auto s = Struct([1, 2, 3, 4]);
    auto i = s.ints;
    static assert(!__traits(compiles, gcExclusive(s)));
}

version(none)
@("RC exclusive default allocator")
@safe unittest {
    auto e = rcExclusive!int(42);
}

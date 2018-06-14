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

@("GC exclusive int[] moved payload")
@safe unittest {

    auto ints = [1, 2, 3, 4];
    auto e = gcExclusive(ints);

    // should be reset to T.init
    ints.shouldBeEmpty;

    {
        auto p = e.lock;
        p.dup.should == [1, 2, 3, 4];
    }
}


version(none)
@("RC exclusive default allocator")
@safe unittest {
    auto e = rcExclusive!int(42);
}

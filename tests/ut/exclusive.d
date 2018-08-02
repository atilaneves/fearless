module ut.exclusive;


import fearless.sharing;
import unit_threaded;


@("GC exclusive int")
@safe unittest {
    auto e = gcExclusive!int(42);
}

@("GC exclusive struct moved payload")
@safe unittest {

    static struct Foo {
        int i;
    }

    auto foo = Foo(42);
    auto e = gcExclusive(foo);

    // should be reset to T.init
    foo.should == foo.init;

    {
        auto p = e.lock;
        p.reference.should == Foo(42);
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

@("RC exclusive int default allocator")
@system unittest {
    auto e = rcExclusive!int(42);
}

@("RC exclusive struct default allocator")
@system unittest {
    static struct Foo {
        int i;
        double d;
    }

    auto e = rcExclusive!Foo(42, 33.3);
    {
        auto p = e.lock;
        p.reference.i.should == 42;
        p.reference.d.should ~ 33.3;
    }
}

@("RC exclusive struct mallocator")
@system unittest {

    import stdx.allocator.mallocator: Mallocator;

    static struct Foo {
        int i;
        double d;
    }

    auto e = rcExclusive!Foo(Mallocator.instance, 42, 33.3);
    {
        auto p = e.lock;
        p.reference.i.should == 42;
        p.reference.d.should ~ 33.3;
    }
}

@("RC exclusive struct test allocator")
@system unittest {

    import test_allocator: TestAllocator;

    static struct Foo {
        int i;
        double d;
    }

    auto allocator = TestAllocator();
    auto e = rcExclusive!Foo(&allocator, 42, 33.3);
    {
        auto p = e.lock;
        p.reference.i.should == 42;
        p.reference.d.should ~ 33.3;
    }
}

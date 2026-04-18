/* Copyright Xanadu Operating Company 1991, All Rights Reserved */
/*
	WeakPtrArray tester
*/

#ifndef WPARRAYT_HXX
#define WPARRAYT_HXX

#include "wparrayx.hxx"

#include "wparrayt.oxx"

class TestExecutor : public XnExecutor {
    CONCRETE(TestExecutor)
    NO_GC(TestExecutor)

 public:

    static RPTR(TestExecutor) make ();

    void execute (Int32 estateIndex);

 protected:

    TestExecutor ();
};

class SmallDyingThing : public Heaper {
    CONCRETE(SmallDyingThing)
    EQ(SmallDyingThing)
    NO_GC(SmallDyingThing)

 public:

    static RPTR(SmallDyingThing) make (Int32 number);

 protected:

    SmallDyingThing (Int32 number);
};

#endif /* WPARRAYT_HXX */

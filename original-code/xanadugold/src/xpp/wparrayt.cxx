/* Copyright Xanadu Operating Company 1991, All Rights Reserved */

#include "wparrayt.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"

#include "wparrayt.sxx"

RPTR(TestExecutor) TestExecutor::make ()
{
    RETURN_CONSTRUCT(TestExecutor,());
}

void TestExecutor::execute (Int32 estateIndex)
{
    cerr << "SmallDyingThing #" << estateIndex << " has passed on.\n";
}

TestExecutor::TestExecutor ()
{
    cerr << "Creating TestExecutor\n";
}

RPTR(SmallDyingThing) SmallDyingThing::make (Int32 number)
{
    RETURN_CONSTRUCT(SmallDyingThing,(number));
}

SmallDyingThing::SmallDyingThing (Int32 number)
{
    cerr << "SmallDyingThing #" << number << " is born.\n";
}

void performWeakTest ()
{
    SPTR(PtrArray) strongArray;
    SPTR(WeakPtrArray) weakArray;
    Int32 i;

    cerr << "Create arrays\n";
    strongArray = PtrArray::nulls(16);
    weakArray = WeakPtrArray::make(TestExecutor::make(), 16);
    cerr << "Filling the arrays\n";
    for (i = 0; i < 16; i++) {
	SPTR(SmallDyingThing) sdt = SmallDyingThing::make(i);
	strongArray->store(i, sdt);
	weakArray->store(i, sdt);
    }
    cerr << "First GC\n";
//    gcOpportunity(-1);
Heaplet::garbageCollect ();
    cerr << "SmallDyingThings weakly at ";
    for (i = 0; i < 16; i++) {
	if (weakArray->fetch(i) != NULL) {
	    cerr << i << " ";
	}
    }
    cerr << "\n";
    cerr << "NULLing ";
    for (i = 1; i < 16; i += 4) {
	strongArray->store(i, NULL);
	cerr << i << " ";
    }
    cerr << "\n";
    cerr << "Second GC\n";
//    gcOpportunity(-1);
    cerr << "SmallDyingThings weakly at ";
    for (i = 0; i < 16; i++) {
	if (weakArray->fetch(i) != NULL) {
	    cerr << i << " ";
	}
    }
    cerr << "\n";
}

int XU_MAIN (int ac, char *av[])
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);
    Initializer initialize(ac,av);
    performWeakTest ();
    return 0;
}

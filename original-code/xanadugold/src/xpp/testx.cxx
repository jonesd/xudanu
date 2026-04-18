#include "tofux.hxx"
#include "tablesx.hxx"
#include "integerx.hxx"
#include <stream.h>

RPTR(Heaper) foo (APTR(Heaper)) {
    return IntegerPos::make (1);
}

RPTR(Heaper) bar (APTR(Heaper)) {
    return MuTable::make(IntegerSpace::make());
}

void testFn () {
    SPTR(Heaper) (*fnP)(APTR(Heaper));

    fnP = foo;
    fnP = bar;
}


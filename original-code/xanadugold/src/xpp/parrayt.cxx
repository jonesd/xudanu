#include "parrayp.hxx"

VERSION_ID(parrayt_cxx,
	   "$Id: parrayt.cxx,v 2.9 1993/02/15 23:53:28 eric Exp $")

#include "parrayt.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
#include "integerx.hxx"

#include "parrayt.sxx"

//
//	Changed to have its own main() rather than depend on the
//	tester mechanism.
//	 - Anonymous, July 1991
//
//	Crutched PrimArrayTester::compactTestOn (ostream& oo)
//		- michael, Jul 14 1991 (merged Jul 22 1991)
//
//	Added newline to main()'s output, to mimic ST and maint.cxx
//		- michael Jul 25 1991

int XU_MAIN (int ac, char *av[]) {
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);
    HeapChunkSize = 0x1000;
    Initializer initialize(ac,av);
    SPTR(PrimArrayTester) pat;
    CONSTRUCT(pat,PrimArrayTester,());
    pat->allTestsOn (cerr);
    pat->destroy();
    cerr << "\n";
    return 0;
}

PrimArrayTester::PrimArrayTester () {}

void PrimArrayTester::allTestsOn (ostream& oo) {
    this->oldTestsOn (oo);
    this->compactTestOn (oo);
    this->testUnsignedness (oo);
}

void PrimArrayTester::compactTestOn (ostream& oo) {
    oo << "makeManyArrays\n";
    SPTR(PtrArray) pa = PtrArray::nulls(1000);
    for (UInt4 i = 0; i < 1000; i++) {
	SPTR(UInt8Array) u1a = UInt8Array::make(100);
	pa->store(i, u1a);
	for (UInt8 j = 0; j < 100; j++) {
	    u1a->storeUInt(j, j);
	}
	if (i > 2 && i & 1) {
	    WPTR(Heaper) toDestroy;
	    if ((toDestroy = pa->fetch(i-1)) == NULL) {
		BLAST(COMPACT_SCREWUP_1);
	    }
	    toDestroy->destroy();
	    pa->store(i-1, NULL);
	}
	if (! i & 7) {
	    UInt32 save = u1a->uIntAt(40);
	    //u1a->myHeapStore->compact();
	    if (u1a->uIntAt(40) != save) {
		BLAST(COMPACT_SCREWUP_2);
	    }
	}
	WPTR(Heaper) u1b;
	if (i > 7) {
	  if ( (u1b = pa->fetch(i-6)) != NULL) {
	    if( !(u1b->isKindOf(cat_UInt8Array))) {
		BLAST(UInt8Array_GCed_wrongly);
	    }
	  }
	}
    }
    oo << "done with makeManyArrays\n";
}

void PrimArrayTester::testUnsignedness (ostream& oo) {
    oo << "test for unsigned memcmp\n";
    SPTR(UInt8Array) a1 = UInt8Array::make(8);
    SPTR(UInt8Array) a2 = UInt8Array::make(8);
    for (UInt8 i = 0; i < 8; i++) {
	a1->storeUInt(i, i+128);
	a2->storeUInt(i, i);
    }
    if (a1->compare(a2) != 1) {
	BLAST(UNSIGNED_COMPARE_WRONG);
    }
    oo << "uInt1Array memcmp unsignedness test complete.\n";
}

void PrimArrayTester::oldTestsOn (ostream& oo) {
  SPTR(UInt8Array) testString;
  //SPTR(UInt8Array) dst;
  testString = UInt8Array::string ("This is a test.");
  oo << "testString = \"";
  for (UInt4 i = 0; i < testString->count(); i++) {
    oo << (char) testString->uIntAt(i);
  }
  oo << "\"\n";
  SPTR(UInt8Array) copied;
  copied = CAST(UInt8Array,testString->copy());
  oo << "copied = \"";
  for (i = 0; i < copied->count(); i++) {
    oo << (char) copied->uIntAt(i);
  }
  oo << "\"\n";
  SPTR(PtrArray) ptrs = PtrArray::nulls(10);
  for (i = 0; i < 10; i++) {
    ptrs->store(i, IntegerPos::make(i));
  }
  oo << "ptrs = ";
  for (i = 0; i < ptrs->count(); i++) {
    oo << ptrs->fetch(i) << ", ";
  }
  oo << "\ncopiedPtrs = ";
  SPTR(PtrArray) copiedPtrs = CAST(PtrArray,ptrs->copy());
  for (i = 0; i < ptrs->count(); i++) {
    oo << ptrs->fetch(i) << ", ";
  }
  oo << "\n";
  SPTR(UInt8Array) string1;
  SPTR(UInt8Array) string2;
  string1 = UInt8Array::string ("This is");
  string2 = UInt8Array::string (" a test.");
  oo << "string1 = \"";
  for (i = 0; i < string1->count(); i++) {
    oo << (char) string1->uIntAt(i);
  }
  oo << "\"\n";
  oo << "string2 = \"";
  for (i = 0; i < string2->count(); i++) {
    oo << (char) string2->uIntAt(i);
  }
  oo << "\"\n";
//  oo << "UInt8Array::make(string1, string2) = \"";
//  SPTR(UInt8Array) cated = UInt8Array::make(string1, string2);
//  for (i = 0; i < cated->count(); i++) {
//    oo << cated->uIntAt(i);
//  }
//  oo << "\"\n";
}

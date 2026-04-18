/*
	Test Module for Scavenging Garbage Collector

     NOTE: this is not an isolated test of the memory allocator and
     collector because the included libraries use the heap extensively
     for their own initialization beyond the control of this module.

*/

/* $Id$ */

#include "scavt.hxx"
#include "initx.hxx"
#include "parrayx.hxx"

/* ============================================================================

		Class TConsCell

   =========================================================================== */

Int32 TConsCell::NextToken = 0;

RPTR(TConsCell) TConsCell::cons (APTR(TConsCell) car, APTR(TConsCell) cdr) {
    RETURN_CONSTRUCT(TConsCell,(car, cdr));
}

TConsCell::TConsCell (APTR(TConsCell) car, APTR(TConsCell) cdr) {
    myCar = car;
    myCdr = cdr;
    myToken = NextToken++;
}

void TConsCell::printOn (ostream& oo) {
    ObjHead * head = ((ObjHead*) this) - 1;
    oo << "(" << myToken << "[" << (int)head->age << "]";
    if (myCar != NULL || myCdr != NULL) {
	oo << " ";
    }
    if (myCar != NULL) {
	myCar->printOn (oo);
    }
    if (myCar != NULL || myCdr != NULL) {
	oo << ".";
    }
    if (myCdr != NULL) {
	myCdr->printOn (oo);
    }
    oo << ")";
}

static RPTR(TConsCell) cons (APTR(TConsCell) car, APTR(TConsCell) cdr) {
    return TConsCell::cons (car, cdr);
}

static RPTR(TConsCell) car (APTR(TConsCell) cell) {
    return cell->car ();
}

static RPTR(TConsCell) cdr (APTR(TConsCell) cell) {
    return cell->cdr ();
}

static void scar (APTR(TConsCell) cell, APTR(TConsCell) item) {
    cell->setCar (item);
}

static void scdr (APTR(TConsCell) cell, APTR(TConsCell) item) {
    cell->setCdr (item);
}

static RPTR(TConsCell) deepCopy (APTR(TConsCell) l) {
    if (!(l && (car(l) || cdr(l)))) {
	return l;
    }
    return cons (deepCopy (car (l)), deepCopy (cdr (l)));
}

static RPTR(TConsCell) flip (APTR(TConsCell) l) {
    if (!(l && (car(l) || cdr(l)))) {
	return l;
    }
    return cons (cdr (l), car (l));
}

static RPTR(TConsCell) growBig (APTR(TConsCell) l) {
    return cons (deepCopy (l), flip (l));
}

static void addLeaf (APTR(TConsCell) l, APTR(TConsCell) leaf) {
    if (!l) {
	return;
    }
    if (car (l) && car (l) != leaf) {
	addLeaf (car (l), leaf);
    } else {
	scar(l, leaf);
    }
    if (cdr(l) && cdr (l) != leaf) {
	addLeaf (cdr (l), leaf);
    } else {
	scdr(l, leaf);
    }
}

static void deepPrintOn (APTR(TConsCell) l, ostream& oo) {
    if (l) {
	oo << "(" << l->token() << " ";
	deepPrintOn (car (l), oo);
	oo << ".";
	deepPrintOn (cdr (l), oo);
	oo << ")";
    }
}

static void deepPrintOnWithAge (APTR(TConsCell) l, ostream& oo) {
    if (l) {
	ObjHead * head = ((ObjHead*) l) - 1;
	oo << "(" << l->token() << "[" << (int)head->age << "] ";
	deepPrintOnWithAge (car (l), oo);
	oo << ".";
	deepPrintOnWithAge (cdr (l), oo);
	oo << ")";
    }
}


/* ============================================================================

		Class ScavengeTestExecutor

   ========================================================================== */

RPTR(XnExecutor) ScavengeTestExecutor::make (Int32 arrayID) {
    RETURN_CONSTRUCT (ScavengeTestExecutor,(arrayID));
}

void ScavengeTestExecutor::execute (Int32 estateIndex) {
    cerr << "Executing array#" << myArrayID << "[" << estateIndex << "]\n";
}


/* ============================================================================

		Class ScavengerTester & misc testing methods

   ========================================================================== */

void ScavengerTester::printRememberSetOn (ostream& oo,
					  Heaplet * heap,
					  Heaper * obj)
{
    for (PointerReferenceSet * set = heap->myRememberSet; set;
	 set = set->myNext)
    {
	for (Int32 i = 0; i < set->myCount; i++) {
	    Heaper** ref = set->myRefs[i];
	    if (ref && (obj == NULL || *ref == obj)) {
		if (0 > (Int32) ref) {	// !!!! platform dependent
		    oo << "ref of obj on stack\n";
		} else {
		    oo << "ref of obj at "
		    << (void*) ((Int32) ref & ~PAGEMASK) << "\n";
		}
	    }
	}
    }
}

void ScavengerTester::printArraySetOn (ostream& oo,
				       Heaplet * heap,
				       Heaper * obj)
{
    for (ArrayReferenceSet * set = heap->myArrayRememberSet; set;
	 set = set->myNext)
    {
	for (Int32 i = 0; i < set->myCount; i++) {
	    PtrArray* array = set->myArrays[i];
	    Int32 idx = set->myIndices[i];
	    if (array && (obj == NULL || array->unsafeFetch(idx) == obj)) {
		oo << "array ref of obj at array@"
		<< (void*) ((Int32) array & ~PAGEMASK)
		<< "[" << idx << "]\n";
	    }
	}
    }
}

void ScavengerTester::printWeakArraySetOn (ostream& oo,
					   Heaplet * heap,
					   Heaper * obj)
{
    for (ArrayReferenceSet * set = heap->myWeakReferenceSet; set;
	 set = set->myNext)
    {
	for (Int32 i = 0; i < set->myCount; i++) {
	    PtrArray* array = set->myArrays[i];
	    Int32 idx = set->myIndices[i];
	    if (array && (obj == NULL || array->unsafeFetch(idx) == obj)) {
		oo << "array ref of obj at array@"
		<< (void*) ((Int32) array & ~PAGEMASK)
		<< "[" << idx << "]\n";
	    }
	}
    }
}

/* Allocation */

/*	Page sets */
/*		Large sets */
/*			Enumeration */

void testLargeHeapletSetOn (ostream& oo) {
    oo << "Testing (large) HeapletSet and HeapletSetStepper\n";
    HeapletSet * set = HeapletSet::make (128);
    Heaplet * low = (Heaplet*)(16*PAGESIZE);
    Heaplet * high = (Heaplet*)(80*PAGESIZE);
    oo << "Storing range " << (void*)low << " to " << (void*)high 
    	<< " in HeapletSet\n";
    oo << "Range chosen to straddle word boundaries in bitmap\n";
    oo << "Should be 64 items\n";
    Int32 count = 0;
    set->introduceMany (low, high);
    oo << "set->count() == " << set->count() << ", should be 64\n";
    oo << "Taking stored items off of set: ";
    void * item;
    while (item = set->take ()) {
	oo << item << " ";
	if (set->contains(item)) {
	    oo << "not taken from set!\n";
	}
	count++;
    }
    oo << "\nCounted " << count << " items\n";
    oo << "set->count() == " << set->count() << ", should be 0\n";
    oo << "Storing range " << (void*)low << " to " << (void*)high
    	<< " in HeapletSet\n";
    oo << "Should be 64 items\n";
    count = 0;
    set->introduceMany (low, high);
    oo << "set->count() == " << set->count() << ", should be 64\n";
    oo << "Stepping over stored items in set: ";
    HeapletSetStepper * stepper = set->stepper ();
    while (item = stepper->fetch ()) {
	oo << item << " ";
	stepper->step();
	count++;
    }
    oo << "\nCounted " << count << " items\n";
    oo << "set->count() == " << set->count() << ", should be 64\n";
    delete stepper;
    Heaplet * loc = (Heaplet*) 0xa0000;
    oo << "Should contain " << (void*) loc << ": ";
    if (set->contains(loc)) {
	oo << "it does\n";
    } else {
	oo << "it does not\n";
    }
    loc = (Heaplet*) 0x140000;
    oo << "Should not contain " << (void*) loc << " (in range but not present): ";
    if (set->contains(loc)) {
	oo << "it does\n";
    } else {
	oo << "it does not\n";
    }
    loc = (Heaplet*) 0x400000;
    oo << "Should not contain " << (void*) loc << " (off high end): ";
    if (set->contains(loc)) {
	oo << "it does\n";
    } else {
	oo << "it does not\n";
    }
    loc = (Heaplet*) 0xa0000;
    oo << "Removing " << (void*) loc << ": ";
    set->remove (loc);
    oo << "Should not contain " << (void*) loc << ": ";
    if (set->contains(loc)) {
	oo << "it does\n";
    } else {
	oo << "it does not\n";
    }
    oo << "set->count() == " << set->count() << ", should be 63\n";
    loc = (Heaplet*) 0x140000;
    oo << "Introducing " << (void*) loc << ": ";
    set->introduce (loc);
    oo << "Should contain " << (void*) loc << ": ";
    if (set->contains(loc)) {
	oo << "it does\n";
    } else {
	oo << "it does not\n";
    }
    oo << "set->count() == " << set->count() << ", should be 64\n";
    delete set;
    oo << "Done with HeapletSet and HeapletSetStepper test\n\n";
}

/*		Small sets */
/*			Enumeration */

void testSmallHeapletSetOn (ostream& oo) {
    oo << "No SmallHeapletSets yet\n\n";
}

/*	Page pool */
/*		Acquisition of storage from OS */
/*		Giving scraps to random object allocator (later) */
/*		Take & Release */

void testHeapletManagerOn (ostream& oo) {
    oo << "No useful HeapletManager test yet, just initializing\n\n";
    Heaplet::initialize ();
}

/*	Allocation within page */
/*	Overflow allocation for page-local structures */

void ScavengerTester::testHeaplet1On (ostream& oo) {
    oo << "Heaplet test 1: allocation within Heaplet\n";
    Heaplet * heaplet = Heaplet::PagePool->take ();
    oo << "sizeof(Heaplet) == " << sizeof(Heaplet) << "\n";
    Int32 * heap = &heaplet->myHeap[0];
    void * obj1 = heaplet->fetchAlloc (1024);
    oo << "Allocated 1024 word object @ &heaplet->myHeap[0] + "
    	<< (Int32*)obj1 - heap << "\n";
    void * obj2 = heaplet->fetchAlloc (2048);
    oo << "Allocated 2048 word object @ &heaplet->myHeap[0] + "
	<< (Int32*)obj2 - heap << ", or &obj1 + "
	<< (Int32*)obj2 - (Int32*)obj1 << "\n";
    oo << "Asking for more space than in page: ";
    obj1 = heaplet->fetchAlloc (PAGESIZE/4);
    if (obj1) {
	oo << "got unexpected " << obj1 << "\n";
    } else {
	oo << "got expected NULL\n";
    }
    oo << "Asking for 64 bytes from getBytes; should be in current page";
    oo << " with extra word in front for object head\n";
    obj1 = heaplet->getBytes(64);
    oo << "\tgot &heaplet->myHeap[0] + " << (Int32*)obj1 - heap << " (words)\n";
    oo << "Asking for 10kb from getBytes; should be from new page with extra";
    oo << " word in front for object head\n";
    obj1 = heaplet->getBytes (10240);
    oo << "\tgot &heaplet->myHeap[0] + " << (Int32*)obj1 - heap << " (words)\n";
    Int32 * heap2 = &heaplet->myOverflow->myHeap[0];
    oo << "\tsame as getting &heap->myOverflow->myHeap[0] + "
    	<< (Int32*)obj1 - heap2 << " (words)\n";
    Heaplet::PagePool->release (heaplet);
    oo << "Done with Heaplet test 1\n\n";
}

/*	Allocation acquiring pages as necessary */

void ScavengerTester::testHeaplet2On (ostream& oo) {
    oo << "Heaplet test 2: allocation from overall Heaplet pool\n";
    oo << "Allocating lots of stuff from heap with allocateWords:\n";
    Heaplet * heap = NULL;
    for (Int32 i = 1; i < 100; i++) {
	oo << "\t" << 3 * i << " words: ";
	ObjHead * obj = Heaplet::allocateWords (3 * i);
	if (heap != Heaplet::pageOf (obj)) {
	    oo << "(new page) ";
	    heap = Heaplet::pageOf (obj);
	}
	oo << "heap->myHeap[0] + " << obj - (ObjHead*)&heap->myHeap[0]
		<< ": age = " << (int)obj->age
		<< ", size = " << (int)obj->size << "\n";
    }
    oo << "Allocating lots of stuff from heap with allocate:\n";
    for (i = 0; i < 100; i++) {
	oo << "\t" << 3 * i << " bytes: ";
	void * obj = Heaplet::allocate ((size_t) (3 * i));
	if (heap != Heaplet::pageOf (obj)) {
	    oo << "(new page) ";
	    heap = Heaplet::pageOf (obj);
	}
	oo << "heap->myHeap[0] + " << (char*)obj - (char*)&heap->myHeap[0]
		<< "\n";
    }
    oo << "End of Heaplet test 2\n\n";
}

/* Migration */
/*	Forwarding */
/*	Aging */

void ScavengerTester::testMigrate1On (ostream& oo) {
    static GPTR(TConsCell) Root = NULL;

    oo << "Migrate test 1\n";

    SPTR(TConsCell) cell = cons(NULL, NULL);
    oo << "building a structure\n";
    cell = growBig (growBig (growBig (cell)));
    oo << "structure before GC\n";
    oo << cell << "\n";
    Root = cell;
    oo << "GC\n";
    Heaplet::garbageCollect ();
    Heaplet * page = Heaplet::pageOf (cell);
    Heaplet * npage = Heaplet::pageOf (Root);
    if (page == npage) {
	oo << "before and after on same page\n";
    } else {
	if (cell == Root) {
	    oo << "migrate did not happen, cell == Root\n";
	} else {
	    ObjHead * head = ((ObjHead*) cell) - 1;
	    HeapletManager::unprotect (page);
	    if (head->age == FORWARDER_FLAG) {
		oo << "cell has become a forwarder to ";
		if (Root != *(TConsCell**)cell) {
		    oo << "something other than ";
		}
		oo << "Root";
	    } else {
		oo << "cell does not look like a forwarder";
	    }
	    oo << "\n";
	    HeapletManager::protect (page);
	}
    }
    oo << "structure after GC\n";
    cell = Root;
    oo << cell << "\n";
    oo << "adding to structure\n";
    cell = growBig (growBig (cell));
    oo << "structure before GC\n";
    oo << cell << "\n";
    Root = cell;
    oo << "GC\n";
    Heaplet::garbageCollect ();
    page = Heaplet::pageOf (cell);
    npage = Heaplet::pageOf (Root);
    if (page == npage) {
	oo << "before and after on same page\n";
    } else {
	if (cell == Root) {
	    oo << "migrate did not happen, cell == Root\n";
	} else {
	    ObjHead * head = ((ObjHead*) cell) - 1;
	    HeapletManager::unprotect (page);
	    if (head->age == FORWARDER_FLAG) {
		oo << "cell has become a forwarder to ";
		if (Root != *(TConsCell**)cell) {
		    oo << "something other than ";
		}
		oo << "Root";
	    } else {
		oo << "cell does not look like a forwarder";
	    }
	    oo << "\n";
	    if (!Heaplet::Current->contains(page)) {
		HeapletManager::protect (page);
	    }
	}
    }
    oo << "structure after GC\n";
    cell = Root;
    oo << cell << "\n";
    
    oo << "End of Migrate test 1\n\n";
}


/* PtrArray migration */
/* PtrArray store checking */

void ScavengerTester::testPtrArrayMigrate1On (ostream& oo) {
    oo << "PtrArray test 1\n";
    oo << "Tenure age set to 0\n";
    Heaplet::setTenureAge (0);
    static GPTR(PtrArray) Root = NULL;

    Root = PtrArray::nulls(8);
    TConsCell** rawPtrs = new TConsCell* [8];

    for (Int32 i = 0; i < 8; i++) {
	rawPtrs[i] = cons (NULL, NULL);
	Root->store (i, rawPtrs[i]);
    }
    oo << "initial PtrArray\n\tRoot = " << Root << "\n";
    oo << "GC\n";
    Heaplet::garbageCollect ();
    oo << "PtrArray after GC\n\tRoot = " << Root << "\n";
    for (i = 0; i < 8; i++) {
	Heaper ** cell = (Heaper**) rawPtrs[i];
	ObjHead * head = ((ObjHead*) cell) - 1;
	Heaplet * page = Heaplet::pageOf (cell);
	HeapletManager::unprotect (page);
	oo << "rawPtrs[" << i << "] ";
	if (head->age == FORWARDER_FLAG) {
	    oo << "has become a forwarder to ";
	    if (Root->fetch(i) != *cell) {
		oo << "something other than ";
	    }
	    oo << "Root[" << i << "]";
	} else {
	    oo << "does not look like a forwarder";
	}
	oo << "\n";
	if (!Heaplet::Current->contains(page)) {
	    HeapletManager::protect (page);
	}
    }
    for (i = 0; i < 8; i++) {
	rawPtrs[i] = CAST(TConsCell,Root->fetch (i));
    }
    oo << "Increasing tenure age to 20\n";
    Heaplet::setTenureAge(20);
    oo << "storing new element in old PtrArray\n";
    rawPtrs[2] = cons (rawPtrs[2], cons (NULL, NULL));
    Root->store (2, rawPtrs[2]);
    oo << "\tRoot = " << Root << "\n";
    oo << "Array set for page of new cell:\n";
    printArraySetOn (oo, Heaplet::pageOf (rawPtrs[2]), rawPtrs[2]);
    oo << "GC\n";
    Heaplet::garbageCollect ();
    oo << "PtrArray after GC\n\tRoot = " << Root << "\n";
    for (i = 0; i < 8; i++) {
	Heaper ** cell = (Heaper**) rawPtrs[i];
	ObjHead * head = ((ObjHead*) cell) - 1;
	Heaplet * page = Heaplet::pageOf (cell);
	HeapletManager::unprotect (page);
	oo << "rawPtrs[" << i << "] ";
	if (head->age == FORWARDER_FLAG) {
	    oo << "has become a forwarder to ";
	    if (Root->fetch(i) != *cell) {
		oo << "something other than ";
	    }
	    oo << "Root[" << i << "]";
	} else {
	    oo << "does not look like a forwarder";
	}
	oo << "\n";
	if (!Heaplet::Current->contains(page)) {
	    HeapletManager::protect (page);
	}
    }
    delete rawPtrs;
    oo << "End of PtrArray test 1\n\n";
}

/* Tenuring */
/* Store checking for Global pointers */
/* Store checking for OldSpace pointers */
/* Update of OldSpace pointers during NewSpace scavenge */

void ScavengerTester::testStoreCheck1On (ostream& oo) {
    oo << "Store check test 1: pointer store checking\n";
    oo << "Tenure age set to 0\n";
    Heaplet::setTenureAge (0);
    GPTR(TConsCell) Root = NULL;
    Root = growBig (growBig (growBig (cons (NULL, NULL))));
    oo << "Root = " << Root << "\n";
    oo << "GC\n";
    Heaplet::garbageCollect ();
    oo << "Root = " << Root << "\n";
    oo << "side effecting leaves of Root\n";
    SPTR(TConsCell) newCell = cons (NULL, NULL);
    addLeaf (Root, newCell);
    oo << "Root = " << Root << "\n";
    Heaplet * heap = Heaplet::pageOf (newCell);
    oo << "References to newCell in remember set\n";
    printRememberSetOn (oo, heap, newCell);
    oo << "pointing to newCell with a root\n";
    GPTR(TConsCell) aRoot = newCell;
    heap = Heaplet::pageOf (newCell);
    oo << "References to newCell in remember set\n";
    printRememberSetOn (oo, heap, newCell);
    oo << "removing root to newCell\n";
    aRoot = NULL;
    heap = Heaplet::pageOf (newCell);
    oo << "References to newCell in remember set\n";
    printRememberSetOn (oo, heap, newCell);
    oo << "replacing root to newCell\n";
    aRoot = newCell;
    oo << "References to newCell in remember set\n";
    printRememberSetOn (oo, heap, newCell);
    oo << "removing pointer to structure, but restoring root to newCell\n";
    aRoot = newCell;
    Root = NULL;
    oo << "Garbage collecting\n";
    Heaplet::garbageCollect ();
    oo << "References to newCell in remember set\n";
    newCell = aRoot;
    heap = Heaplet::pageOf (newCell);
    printRememberSetOn (oo, heap, newCell);
    oo << "Garbage collecting again\n";
    Heaplet::garbageCollect ();
    oo << "References to newCell in remember set\n";
    newCell = aRoot;
    heap = Heaplet::pageOf (newCell);
    printRememberSetOn (oo, heap, newCell);
    oo << "Garbage collecting again\n";
    Heaplet::garbageCollect ();
    oo << "References to newCell in remember set\n";
    newCell = aRoot;
    heap = Heaplet::pageOf (newCell);
    printRememberSetOn (oo, heap, newCell);
    oo << "(these last couple of gc's revealed problems in code that is\n";
    oo << " meant to be tested in exercises that follow, so I'm keeping them.)\n";
    oo << "End of store check test 1\n\n";
}

/* Store checking for OldSpace PtrArrays */
/* Update of OldSpace PtrArrays during NewSpace scavenge */

void ScavengerTester::testStoreCheck2On (ostream& oo) {
    oo << "Store check test 2: PtrArray store checking\n";
    oo << "Tenure age set to 0\n";
    Heaplet::setTenureAge (0);
    GPTR(PtrArray) pRoot = PtrArray::nulls (8);
    oo << "original PtrArray pRoot = " << pRoot << "\n";
    oo << "garbage collecting to make pRoot old\n";
    Heaplet::garbageCollect ();
    oo << "storing new object (cell) in pRoot[0]\n";
    SPTR(TConsCell) cell = cons(NULL, NULL);
    pRoot->store (0, cell);
    oo << "pRoot now = " << pRoot << "\n";
    oo << "(pRoot%PAGESIZE="
    << (void*)((Int32)(Heaper*)pRoot & ~PAGEMASK) << ")\n";
    oo << "References to cell in array remember set\n";
    Heaplet * heap = Heaplet::pageOf (cell);
    printArraySetOn (oo, heap, cell);
    oo << "garbage collecting to cause cell to migrate: ";
    Heaplet::garbageCollect ();
    if (pRoot->fetch(0) == cell) {
	oo << "cell did not migrate\n";
    } else {
	oo << "cell migrated\n";
    }
    oo << "pRoot now = " << pRoot << "\n";
    oo << "(pRoot%PAGESIZE="
    << (void*)((Int32)(Heaper*)pRoot & ~PAGEMASK) << ")\n";
    cell = CAST(TConsCell,pRoot->fetch(0));
    oo << "References to cell at new loc in array remember set\n";
    heap = Heaplet::pageOf (cell);
    printArraySetOn (oo, heap, cell);
    oo << "End of store check test 2\n\n";
}

/* Store checking for OldSpace WeakPtrArrays */
/* Update of OldSpace WeakPtrArrays during NewSpace scavenge */
/* Weak finalization */

void ScavengerTester::testWeakArrayOn (ostream& oo) {
    oo << "Weak Array test\n";
    oo << "setting tenure age to 3 to migrate often\n";
    Heaplet::setTenureAge(3);
    oo << "creating weak array #1: ";
    GPTR(WeakPtrArray) Array1 =
	WeakPtrArray::make (ScavengeTestExecutor::make(1), 8);
    oo << Array1 << "\n";
    oo << "storing a cons cell at 4 in array 1\n";
    GPTR(TConsCell) CellRoot = cons (NULL, NULL);
    Array1->store (4, CellRoot);
    oo << "array 1 = " << Array1 << "\n";
    oo << "references to cell in weak reference set\n";
    Heaplet * heap = Heaplet::pageOf (CellRoot);
    printWeakArraySetOn (oo, heap, CellRoot);
    oo << "garbage collecting\n";
    Heaplet::garbageCollect ();
    oo << "array 1 = " << Array1 << "\n";
    oo << "references to cell in weak reference set\n";
    heap = Heaplet::pageOf (CellRoot);
    printWeakArraySetOn (oo, heap, CellRoot);
    oo << "garbage collecting again to check completeness of forwarding\n";
    Heaplet::garbageCollect ();
    oo << "array 1 = " << Array1 << "\n";
    oo << "references to cell in weak reference set\n";
    heap = Heaplet::pageOf (CellRoot);
    printWeakArraySetOn (oo, heap, CellRoot);
    oo << "dropping root to cell\n";
    CellRoot = NULL;
    oo << "garbage collecting\n";
    Heaplet::garbageCollect ();
    oo << "array 1 = " << Array1 << "\n";
    oo << "storing another cell in weak array at 6\n";
    CellRoot = cons (NULL, NULL);
    Array1->store (6, CellRoot);
    oo << "array 1 = " << Array1 << "\n";
    oo << "references to cell in weak reference set\n";
    heap = Heaplet::pageOf (CellRoot);
    printWeakArraySetOn (oo, heap, CellRoot);
    oo << "garbage collecting\n";
    Heaplet::garbageCollect ();
    oo << "references to cell in weak reference set\n";
    heap = Heaplet::pageOf (CellRoot);
    printWeakArraySetOn (oo, heap, CellRoot);
    oo << "array 1 = " << Array1 << "\n";
    oo << "dropping root to array 1 and to cell\n";
    Array1 = NULL;
    CellRoot = NULL;
    oo << "garbage collecting: no executor should run\n";
    Heaplet::garbageCollect ();
    oo << "Setting tenure age to 0 to test old store check\n";
    Heaplet::setTenureAge(0);
    oo << "Creating new array\n\t";
    Array1 = WeakPtrArray::make (ScavengeTestExecutor::make(2), 8);
    oo << Array1 << "\n";
    oo << "Garbage collecting\n";
    Heaplet::garbageCollect ();
    oo << "storing a cons cell at 3 in array\n\t";
    CellRoot = cons (NULL, NULL);
    Array1->store (3, CellRoot);
    oo << Array1 << "\n";
    oo << "Garbage collecting, nothing should happen\n";
    Heaplet::garbageCollect ();
    oo << "Array is\n\t" << Array1 << "\n";
    oo << "Dropping strong pointer to cell\n";
    CellRoot = NULL;
    oo << "Garbage collecting, something should happen\n";
    Heaplet::garbageCollect ();
    oo << "Array is\n\t" << Array1 << "\n";
    oo << "storing a cons cell at 5 in array\n\t";
    CellRoot = cons (NULL, NULL);
    Array1->store (5, CellRoot);
    oo << Array1 << "\n";
    oo << "Garbage collecting, nothing should happen\n";
    Heaplet::garbageCollect ();
    oo << "Array is\n\t" << Array1 << "\n";
    oo << "Dropping strong pointer to cell\n";
    CellRoot = NULL;
    oo << "Garbage collecting, something should happen\n";
    Heaplet::garbageCollect ();
    oo << "Array is\n\t" << Array1 << "\n";
    oo << "End of weak array test\n";
}

/* OldSpace scavenge */

/* Incremental Stop-and-Copy of OldSpace */

int  XU_MAIN (int argc, char* * argv){
    Initializer mainInit(argc,argv);

    testLargeHeapletSetOn (cerr);
    testSmallHeapletSetOn (cerr);
    testHeapletManagerOn (cerr);
    ScavengerTester::testHeaplet1On (cerr);
    ScavengerTester::testHeaplet2On (cerr);
    ScavengerTester::testMigrate1On (cerr);
    ScavengerTester::testPtrArrayMigrate1On (cerr);
    ScavengerTester::testStoreCheck1On (cerr);
    ScavengerTester::testStoreCheck2On (cerr);
    ScavengerTester::testWeakArrayOn (cerr);

    return 0;
}

#include "scavt.sxx"

/* Copyright (C) 1993, Memex, Inc., All Rights Reserved */
/*
        WARNING: This module contains pointer arithmetic that may not
        be portable.
*/

/* $Id$ */

#include "scavx.hxx"
#include "scavp.hxx"

#include "scavx.ixx"
#include "scavp.ixx"

#include "parrayx.hxx"
#include "wparrayx.hxx"

#include <assert.h>
#include <osfcn.h>
#if sun
#include <sys/mman.h>
#endif /* sun */
#define PROTECT_FREE_PAGES 1

Int32 DisableGC = 0;
Int32 ProtectFree = 1;
Int32 RecycleOld = 1;

#define SANITY_CHECK {if(!(isScavengeable(this) && pageOf(this)==this)){BLAST(SanityViolation);}}

/*
        Class Heaplet

        The heap of contained Heapers starts at the bottom of the page
        after the page description.  The sets of in and out pointers
        grow downward from the end of the page, relocating as needed.
        The page is full when the heap reaches the pointer sets.
        Since stores to the pointer sets must never fail, an overflow
        mechanism is used.  Things should be tuned to avoid this.
        (at least the page layout is understandable!  hkh */

// Note for newbies!  Operator new is overridden in xunewx.cxx
// There it calls falloc which is in allocx.cxx.  Thus, the 32k
// heapletSets are obtained there and not by system malloc. hkh

HeapletManager * Heaplet::PagePool = NULL;
HeapletSet *     Heaplet::Old = NULL;

/* fluid-like class variables */
Heaplet *       Heaplet::NewPage = NULL;
Heaplet *       Heaplet::AltNewPage = NULL;
HeapletSet *    Heaplet::Current = NULL;
HeapletSet *    Heaplet::NextCurrent = NULL;
HeapletSet *    Heaplet::CurrentDrainSet = NULL;
Int32 Heaplet::TenureAge = 20;  // a random number for later tuning
Int32 Heaplet::NumberOfPagesSinceLastCollect = 0;


/* If storing into Old space or a global variable:
    Updates the remembered sets for the pages referenced
    by both the old and new value of the pointer being assigned.

 MORE detail needed here!  hkh

    The container argument is a pointer within the page holding
    the object responsible for holding the pointer.  This is
    necessary as the PrimArray classes keep their storage outside
    of the Heaplets. (so true! see parray. hkh) */
 
/*inline*/ void Heaplet::checkedStore (Heaper** ptr, 
                                       Heaper* newValue,
                                       void* container)
{
    /* All of the other checking methods will only be called after
       the scavenger data structures are set up. Does this mean
       that this one is called before the structure has been set
       up?  hkh */

    if (Current && (Old->contains (container) || !isScavengeable(container))) {
        actualCheckedStore (ptr, newValue, container);
    }
    *ptr = newValue;
}

/*inline*/ void Heaplet::checkedArrayStore (PtrArray* array,
                                            Heaper** ptr, 
                                            Heaper* newValue,
                                            Int32 index)
{
    if (Old->contains (array)) {
        actualCheckedArrayStore (array, ptr, newValue, index);
    } else {
        ObjHead * head = (ObjHead*)array - 1;
        if (head->age == OLD_AGE) {
            BLAST(SanityViolation);
        }
    }
    *ptr = newValue;
}

/*inline*/ void Heaplet::checkedWeakStore (WeakPtrArray* array,
                                           Heaper** ptr, 
                                           Heaper* newValue,
                                           Int32 index)
{
    if (Old->contains (array)) {
        actualCheckedWeakStore (array, ptr, newValue, index);
    } else {
        ObjHead * head = (ObjHead*)array - 1;
        if (head->age == OLD_AGE) {
            BLAST(SanityViolation);
        }
    }
    *ptr = newValue;
}

/* The out-of-line work function for initialization */
void Heaplet::actualInitialize () {
    PagePool    = HeapletManager::make ();
    Current     = HeapletSet::make (MAXPAGES);
    Old         = HeapletSet::make (MAXPAGES);
    NextCurrent = HeapletSet::make (MAXPAGES);

    NewPage = PagePool->take ();
    NumberOfPagesSinceLastCollect++;
    Current->introduce (NewPage);
}

void Heaplet::tenureAll () {
    Int32 save = TenureAge;
    TenureAge = 0;
    garbageCollect ();
    TenureAge = save;
}

Int32 Heaplet::setTenureAge (Int32 age) {
    Int32 old = TenureAge;
    TenureAge = age;
    return old;
}

/* Acquire storage for a new Heaper in new space. */
void * Heaplet::allocate (size_t nBytes) {
    Int32 nInt32s = (nBytes + 3) / sizeof(Int32) + 1; // extra for age and size
    ObjHead * result = allocateWords (nInt32s);
    return result + 1; 
}

/* Acquire storage for a new Heaper in new space. */
ObjHead * Heaplet::allocateWords (Int32 nInt32s) {
    ObjHead * head = NewPage->fetchAlloc (nInt32s);
    if (!head) {
        NewPage = PagePool->take ();  // returns or BLASTS
        NumberOfPagesSinceLastCollect++;
        Current->introduce (NewPage);
        head = NewPage->fetchAlloc (nInt32s);
    }
    return head;
}

/* Acquire storage for a new Heaper in new space. */
ObjHead * Heaplet::allocateOldWords (Int32 nInt32s) {
    if (AltNewPage == NULL) {
        AltNewPage = PagePool->take ();
        Old->introduce (AltNewPage);
    }
    ObjHead * head = AltNewPage->fetchAlloc (nInt32s);
    if (!head) {
        AltNewPage = PagePool->take ();  // returns or BLASTS
        Old->introduce (AltNewPage);
        head = AltNewPage->fetchAlloc (nInt32s);
    }
    return head;
}

/* Perform a scavenge over Current */
void Heaplet::garbageCollect () {
    /* NextCurrent is empty from last collection */
    if (DisableGC) {
        return;
    }
    Heaplet* target;
    HeapletSetStepper* stepper;
    checkStackInit(&target); /* see doc on checkStack */ /* zzz  reg nov 9 1994kluge I wanted to use &this, what is right */

    EstateRecorder::reset ();

    /* First we scavenge new pages */

    AltNewPage = NULL;
    CurrentDrainSet = Current;
    Current = NextCurrent;
    NewPage = PagePool->take ();
    Current->introduce (NewPage);

    stepper = CurrentDrainSet->stepper ();
    while (target = stepper->fetch ()) {
        target->scavengeNew ();
        if(target == stepper->fetch()){ /* if scavenge has not removet this one step*/
                stepper->step ();       /* else don't stepover the bit and miss it */
        }
    }
    delete stepper;

    while (target = CurrentDrainSet->take ()) {
        if (Old->contains (target)) {
            Old->remove (target);
        }
        PagePool->release (target);
    }

    NextCurrent = CurrentDrainSet;      // which is now empty

    AltNewPage = NULL;
    CurrentDrainSet = NULL;
    NewPage = PagePool->take ();
    Current->introduce (NewPage);

    EstateRecorder::handleAllEstates ();
}

/* Return TRUE if ptr is in a scavengeable page */
BooleanVar Heaplet::isScavengeable (void * ptr) {
    return PagePool->contains (ptr);
}

/* Updates the remembered sets for the pages referenced
    by both the old and new value of the pointer being assigned.
    The container argument is a pointer within the page holding
    the object responsible for holding the pointer.  This is
    necessary as the PrimArray classes keep their storage outside
    of the Heaplets. */
void Heaplet::actualCheckedStore (Heaper** ptr, 
                                  Heaper* newValue,
                                  void* container)
{
    Heaplet * storedPage = pageOf (container);
    BooleanVar containerIsOld = Old->contains (storedPage);
checkStack(ptr);
checkStack(newValue);
    if (containerIsOld || !isScavengeable (storedPage)) {
        Heaplet * oldPage = pageOf (*ptr);
        Heaplet * newPage = pageOf (newValue);
        if (oldPage != newPage) {
            if (oldPage != storedPage && isScavengeable (oldPage)) {
                oldPage->forget (ptr);
                if (Old->contains (oldPage)) {
                    if (containerIsOld && storedPage != oldPage) {
                        storedPage->removeOutPointer (oldPage);
                    }
                    Current->store (oldPage);
                }
            }
            if (newPage != storedPage && isScavengeable (newPage)) {
                newPage->remember (ptr);
                if (containerIsOld) {
                    storedPage->addOutPointer (newPage);
                }
            }
        }
    }
}

/* Updates the remembered sets for the pages referenced
    by both the old and new value of the pointer being assigned
    to a PtrArray. */
void Heaplet::actualCheckedArrayStore (PtrArray* array,
                                       Heaper** ptr, 
                                       Heaper* newValue,
                                       Int32 index)
{
    Heaplet * storedPage = pageOf (array);
    BooleanVar containerIsOld = Old->contains (storedPage);
    if (containerIsOld) {
        Heaplet * oldPage = pageOf (*ptr);
        Heaplet * newPage = pageOf (newValue);
        if (oldPage != newPage) {
            if (isScavengeable (oldPage)) {
                oldPage->forgetArray (array, index);
                if (Old->contains (oldPage)) {
                    if (containerIsOld && storedPage != oldPage) {
                        storedPage->removeOutPointer (oldPage);
                    }
                    Current->store (oldPage);
                }
            }
            if (newPage != storedPage && isScavengeable (newPage)) {
                newPage->rememberArray (array, index, NULL);
                if (containerIsOld) {
                    storedPage->addOutPointer (newPage);
                }
            }
        }
    }
}

/* Updates the remembered sets for the pages referenced
    by both the old and new value of the pointer being assigned
    to a WeakPtrArray. */
void Heaplet::actualCheckedWeakStore (WeakPtrArray* array,
                                      Heaper** ptr, 
                                      Heaper* newValue,
                                      Int32 index)
{
    Heaplet * oldPage = pageOf (*ptr);
    Heaplet * newPage = pageOf (newValue);

    if (newPage != oldPage) {
        Heaplet * storedPage = pageOf (array);
        if (*ptr && isScavengeable(oldPage)) {
            oldPage->forgetWeak (array, index);
            storedPage->removeOutPointer (oldPage);
        }

        if (isScavengeable(newValue)) {
            newPage->rememberWeak (array, index,NULL);  /* zzz reg nov 10 1994 added null to get right number of parameters */
            storedPage->addOutPointer (newPage);
        }
    }
    *ptr = newValue;
}

/* Removes the pointer from the remembered set of the page it
    references.  Called by ~CheckedPtrVar during become.
    The container argument is a pointer within the page holding
    the object responsible for holding the pointer.  This is
    necessary as the PrimArray classes keep their storage outside
    of the Heaplets. */
void Heaplet::forgetPointer (Heaper** ptr, void* container) {
    if (*ptr && (Old->contains(ptr) || Current->contains(*ptr))) {
        Heaplet * storedPage = pageOf (container);
        Heaplet * oldPage = pageOf (*ptr);
        if (pageOf(ptr) != oldPage) {
            oldPage->forget (ptr);
            if (PagePool->contains(container)) {
                storedPage->removeOutPointer (oldPage);
            }
        }
    }
}

/* Move the object to a new page if it''s still here.
   Returns the new address. */
Heaper * Heaplet::forward (Heaper* obj) {
    /* Uses the magic cookie age to indicate a forwarder.
       The first word of a forwarder is the new address.
    */
    if (!CurrentDrainSet->contains(obj)) {
        return obj;  // includes NULL
    }
    ObjHead * head = (ObjHead*) obj - 1;
    if (head->size == 0) {
        BLAST(SanityViolation); // !!!! tmp debug
    }
    Int32 age = head->age;
    if (age == FORWARDER_FLAG) {
        return *(Heaper**)obj;
    }
    if (age != OLD_AGE) {
        if (++age >= TenureAge) {
            age = OLD_AGE;
        }
    }
    /* Move object and construct forwarder */
    ObjHead * newHead;
    if (age != OLD_AGE) {
        newHead = allocateWords (head->size);
    } else {
        newHead = allocateOldWords (head->size);
    }
    if (head->size * sizeof(Int32) > PAGESIZE) {
        BLAST(SanityViolation);         // !!!! tmp debug
    }
    MEMMOVE(newHead, head, head->size * sizeof(Int32));
    newHead->age = age;
    Heaper * nobj = (Heaper*) (newHead + 1);
    head->age = FORWARDER_FLAG;
    *(Heaper**)obj = nobj;
    nobj->migrate (obj, newHead->age == OLD_AGE);
    return nobj;
}

/* Return NULL if obj is in CurrentDrainSet and not forwarded,
   otherwise return the new location. */
Heaper * Heaplet::forwardOrNULL (Heaper * obj) {
    if (!CurrentDrainSet->contains (obj)) {
        return obj;
    }
    ObjHead * head = (ObjHead*) obj - 1;
    if (head->age == FORWARDER_FLAG) {
        return *(Heaper**)obj;
    } else {
        return NULL;
    }
}

void Heaplet::forwardToOld (Heaper ** oldPtr, Heaper ** newPtr) {
    Heaper * obj = *oldPtr;
    if (obj) {
        if (isScavengeable (obj)) {
            Heaplet * op = pageOf (obj);
            Heaper * nobj = Heaplet::forward (obj);
            if (obj == nobj) {
                op->changeRemembered (oldPtr, newPtr);
            } else {
                *newPtr = nobj;
                if (op != pageOf (oldPtr)) {
                    op->forget (oldPtr);
                }
                Heaplet * np = pageOf (nobj);
                if (np != pageOf (newPtr)) {
                    np->remember (newPtr);
                }
            }
        }
    }
}


/* ================= start of instance methods ================= */

/* Attempt to allocate storage in this page. */
ObjHead * Heaplet::fetchAlloc (Int32 nInt32s) {
SANITY_CHECK
    if (nInt32s <= 0) {
        BLAST(SanityViolation); // !!!! tmp debug
    }
    Int32 * newEnd = myHighWaterMark + nInt32s;
    if (newEnd >= myLastWord) {
        return NULL;
    }
    ObjHead * result = (ObjHead*) myHighWaterMark;
    myHighWaterMark = newEnd;
    ObjHead * i;
    for(i = result ; ((void *)i) <= ((void *)newEnd); i++){

        if( (*(int*)i) != 0){
                cerr << "stomping on mem \n" << result << "at " << __FILE__ << __LINE__ <<" so watch out, in fetchAlloc ";
        }
    }

    result->age = 0;
    result->size = nInt32s;
    return result;
}

/* Allocate storage associated with this page, going into
   overflow if necessary.  This is used for small PrimArrays */
ObjHead * Heaplet::getWords (Int32 nInt32s) {
SANITY_CHECK
    ObjHead * result = this->fetchAlloc (nInt32s+1);
    if (result) {
        return result + 1; 
    }
    if (!myOverflow) {
        myOverflow =  PagePool->take ();
    }
    return myOverflow->getWords (nInt32s);
}

/* Allocate storage associated with this page, going into
   overflow if necessary.  This is used for interpage
   reference recording that must not fail. */
ObjHead * Heaplet::getBytes (Int32 nBytes) {
SANITY_CHECK
    Int32 nInt32s = (nBytes + 3) / sizeof(Int32) + 1; // extra for age and size
    ObjHead * result = this->fetchAlloc (nInt32s);
    if (result) {
        return result + 1; 
    }
    if (!myOverflow) {
        myOverflow =  PagePool->take ();
    }
    return myOverflow->getBytes (nBytes);  // wastes a shift, but rarely used
}
static int debuga = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugb = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugc = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugd = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debuge = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugf = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugg = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugh = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
static int debugi = 1; /* zzz reg temporary debugging switches reg sep 28 1994 */
/* Do a scavenge of this new page */
void Heaplet::scavengeNew () {
SANITY_CHECK
    if (myRememberSet && debuga) {
        myRememberSet->scavengeNew (CurrentDrainSet);
    }
    if (myArrayRememberSet && debugb) {
        myArrayRememberSet->scavengeNew (CurrentDrainSet);
    }
    if (myWeakReferenceSet && debugc) {
        myWeakReferenceSet->executeWeakly ();
    }
    if (myPtrArraySet && debugd) {
        myPtrArraySet->cleanup ();
    }
    if (myOutPointerSet && debuge) {
        myOutPointerSet->dropInto (Old, Current, CurrentDrainSet);
    }
}

/* Add a pointer to the remember set */
void Heaplet::remember (Heaper** ptr) {
SANITY_CHECK
    if (pageOf(ptr) == this) {
        BLAST(SanityViolation);         // !!!! tmp debug
    }
    if (!myRememberSet) {
        myRememberSet = PointerReferenceSet::make (this);
    }
    myRememberSet->remember (ptr);
}

/* Remove a pointer from the remember set */
void Heaplet::forget (Heaper** ptr) {
SANITY_CHECK
    if (pageOf(ptr) == this) {
        BLAST(SanityViolation);         // !!!! tmp debug
    }
    if (myRememberSet) {
        myRememberSet->forget (ptr);
    }
}

/* Change a pointer in the remember set.  Useful for migration */
void Heaplet::changeRemembered (Heaper** oldPtr, Heaper** newPtr) {
SANITY_CHECK
    if (pageOf(oldPtr) == this || pageOf(newPtr) == this) {
        BLAST(SanityViolation);         // !!!! tmp debug
    }
    if (myRememberSet) {
        myRememberSet->change (oldPtr, newPtr);
    }
}

/* Add a pointer to the array reference set */
void Heaplet::rememberArray (PtrArray* array, Int32 index,
                             PtrArray* oldArray) {
SANITY_CHECK
    if (!myArrayRememberSet) {
        myArrayRememberSet = ArrayReferenceSet::make (this);
    }
    myArrayRememberSet->remember (array, index, oldArray);
}

/* Remove a pointer from the array reference set */
void Heaplet::forgetArray (PtrArray* array, Int32 index) {
SANITY_CHECK
    if (myArrayRememberSet) {
        myArrayRememberSet->forget (array, index);
    }
}

/* Change an entry in the array reference set */
void Heaplet::changeArray (PtrArray* oldArray, PtrArray* newArray) {
SANITY_CHECK
    if (myArrayRememberSet) {
        myArrayRememberSet->change (oldArray, newArray);
    }
}

/* Add a pointer to the weak reference set */
void Heaplet::rememberWeak (WeakPtrArray* array, Int32 index,
                            WeakPtrArray* oldArray) {
SANITY_CHECK
    if (!myWeakReferenceSet) {
        myWeakReferenceSet = ArrayReferenceSet::make (this);
    }
    myWeakReferenceSet->remember (array, index, oldArray);
}

/* Remove a pointer from the weak array reference set */
void Heaplet::forgetWeak (WeakPtrArray* array, Int32 index) {
SANITY_CHECK
    if (myWeakReferenceSet) {
        myWeakReferenceSet->forget (array, index);
    }
}

/* Change an entry in the weak reference set */
void Heaplet::changeWeak (WeakPtrArray* oldArray, WeakPtrArray* newArray) {
SANITY_CHECK
    if (myWeakReferenceSet) {
        myWeakReferenceSet->change (oldArray, newArray);
    }
}

/* Remove all references from page from remember, array, and
   weak reference sets.  In the weak case this is to prevent
   bogus finalization if an object is collected after its
   referencing weak arrays go away. */
void Heaplet::forgetFromPage (Heaplet * page) {
SANITY_CHECK
    if (myRememberSet) {
        myRememberSet->forgetFromPage (page);
    }
    if (myArrayRememberSet) {
        myArrayRememberSet->forgetFromPage (page);
    }
    if (myWeakReferenceSet) {
        myWeakReferenceSet->forgetFromPage (page);
    }
}

/* Add an outward pointer. */
void Heaplet::addOutPointer (Heaplet* other) {
SANITY_CHECK
    if (!myOutPointerSet) {
        myOutPointerSet = OutPointerSet::make (this);
    }
    myOutPointerSet->reference (other);
}

/* Remove an outward pointer. */
void Heaplet::removeOutPointer (Heaplet* other) {
SANITY_CHECK
    if (myOutPointerSet) {
        myOutPointerSet->unreference (other);
    }
}

/* Record that a PtrArray resides in this page. */
void Heaplet::registerPtrArray (PtrArray* array) {
SANITY_CHECK
    if (!myPtrArraySet) {
        myPtrArraySet = PtrArraySet::make (this);
    }
    myPtrArraySet->registerPtrArray (array);
}

/* Remove a PtrArray from this page. */
void Heaplet::unregisterPtrArray (PtrArray* array) {
SANITY_CHECK
    if (myPtrArraySet) {
        myPtrArraySet->unregisterPtrArray (array);
    }
}
/* Below, see .hxx, but myHeap is the 9th (last) 32 bit word into
the stuct which is "Head of Heaplet."  The next line gens
a pointer to the start of the page plus PAGESIZE hkh */

Heaplet::Heaplet () {
    myHighWaterMark = myHeap;
    myLastWord = (Int32*) ((char*) this + PAGESIZE);
    myOverflow = NULL;
    myRememberSet = NULL;
    myArrayRememberSet = NULL;
    myWeakReferenceSet = NULL;
    myOutPointerSet = NULL;
    myPtrArraySet = NULL;
}


/*
        Class HeapletManager

        Manages the pool of empty pages.

        It would be good for this to allocate pages so that freed
        pages remain free as long as possible to catch errors that
        access freed memory.
*/

HeapletManager * HeapletManager::make () {
    return new HeapletManager ();
}

/* disable access to pages memory */
void HeapletManager::protect (Heaplet * page) {
#if sun && PROTECT_FREE_PAGES
    if (ProtectFree) {
        mprotect((caddr_t)page, PAGESIZE, PROT_NONE);
    }
#endif
}

/* enable access to pages memory */
void HeapletManager::unprotect (Heaplet * page) {
#if sun && PROTECT_FREE_PAGES
    if (ProtectFree) {
        mprotect((caddr_t)page, PAGESIZE, PROT_READ | PROT_WRITE);
    }
#endif
}

/* Return TRUE if pointer is into this pool.  hkh--this code
sends the msg "contains" to the object myPagePool, which is
a HeapletSet.  Thus the contains refered is the one defined
in scavp.ixx

*/
 
BooleanVar HeapletManager::contains (void * ptr) {
    return myPagePool->contains (ptr);
}
 
inline void * operator new (size_t, void * p) {
    return p;
}

/* Take a page from the free page pool.  Fails if none available. */
Heaplet * HeapletManager::take () {
    Heaplet * result = myEmptyPagePool->take ();
    if (result == NULL) {
        this->moreStorage ();
        result = myEmptyPagePool->take ();
        if (result == NULL) {
            BLAST(MEM_ALLOC_ERROR);
        }
    }
    unprotect (result);
    return new (result) Heaplet ();
}

/* Release a page to the free page pool. */
void HeapletManager::release (Heaplet * page) {
    if (RecycleOld) {
        Heaplet * next;
        for (Heaplet * ovr = page->overflow(); ovr; ovr = next) {
            next = ovr->overflow ();
memset((char *) ovr,0,PAGESIZE);
            protect (ovr);
            myEmptyPagePool->introduce (ovr);
        }
memset((char *) page,0,PAGESIZE);
        protect (page);
        myEmptyPagePool->introduce (page);
    }
}

HeapletManager::~HeapletManager () {
    /* should release pages to OS */
    delete myEmptyPagePool;
    delete myPagePool;
}

HeapletManager::HeapletManager () {
    myEmptyPagePool = HeapletSet::make (MAXPAGES);
    myPagePool = HeapletSet::make (MAXPAGES);
    this->moreStorage ();
}
/* This section deserves an explaination.  SBRK returns a pointer to the
*old* end of the programs data segment if it was able to get the requested
amount of storage.  The function of the modulo arithmatic is to throw away
missaligned memory, in this case up to 16k-1, and then use the rest for
pages. hkh */

void HeapletManager::moreStorage () {
    void * storage = SBRK(ALLOCINCR);
    Int32 remainder = ((Int32)storage) % PAGESIZE;
    int fragmentSize = (int) (PAGESIZE - remainder);
    if (fragmentSize) {
        SBRK(fragmentSize);
    }
    storage = (char*)storage + fragmentSize;
#if sun && PROTECT_FREE_PAGES
    if (ProtectFree) {
        mprotect((caddr_t)storage, ALLOCINCR, PROT_NONE);
    }
#endif
    myPagePool->introduceMany
        ((Heaplet*) storage,
         (Heaplet*) ((char*)storage+ALLOCINCR-PAGESIZE));
    myEmptyPagePool->introduceMany
        ((Heaplet*) storage,
         (Heaplet*) ((char*)storage+ALLOCINCR-PAGESIZE));
}


/*
        Class HeapletSetStepper
*/

void HeapletSetStepper::step () {
    if (myBitIndex >= 0) {
           myWord = mySet->wordAt (myWordIndex)>> (myBitIndex );/* fakeup the word i point at, as the fucking set may change underneith the fucking stepper */   /* normally this code would be written assuming thet the set was stable, it ain't */
        Int32 count = mySet->highestIndex () / 32;
        while (myWordIndex <= count) {
            while (++myBitIndex < 32) {
                myWord >>= 1;
                if (myWord & 1) {
                    return;
                }
                if (!myWord) {
                    break;
                }
            }
            UInt32 word = 0;
            while (myWordIndex < count 
                   && !(word = mySet->wordAt (++myWordIndex))) ;
            if (!word) {
                myBitIndex = -1;
                return;
            }
            myWord = word;
            myBitIndex = 0;
            if (myWord & 1) {
                return;
            }
        }
    }
}

HeapletSetStepper::HeapletSetStepper (HeapletSet * set) {
    mySet = set;
    myWordIndex = set->lowestIndex () / 32;
    if (mySet->highestIndex () >= 0) {
        myBitIndex = 0;
        myWord = mySet->wordAt (myWordIndex);
        if (!(myWord & 1)) {
            this->step ();
        }
    } else {
        myWord = 0;
        myBitIndex = -1;
    }
}


/*
        Class HeapletSet
*/

/* Return an empty set that can store size pages */
HeapletSet * HeapletSet::make (Int32 size) {
    return new HeapletSet (size);
}

/* Take a page from the set.  Return NULL if set is empty */
Heaplet * OR(NULL) HeapletSet::take () {
    if (myTally == 0) {
        return NULL;
    }
    for (Int32 search = myLowest / 32; search < myHighest; search++) {
        if (myBitMap[search]) {
            UInt32 word = myBitMap[search];
            for (Int32 bit = 1, count = 0; count < 32; bit <<= 1, count++) {
                if (word & bit) {
                    myBitMap[search] &= ~bit;
                    myLowest = search * 32 + count + 1;
                    myTally--;
                    return (Heaplet*) ((myLowest - 1) * PAGESIZE);
                }
            }
        }
    }
    BLAST(SanityViolation);
    return NULL;        // compiler fodder
}

/* Remove a particular page from the set */
void HeapletSet::remove (Heaplet * page) {
    Int32 index = ((Int32)page) / PAGESIZE;
    if (index > mySize) {
        BLAST(SanityViolation);
    }
    Int32 bits = myBitMap[index / 32];
    Int32 bit = 1 << (index % 32);
    if (bits & bit) {
        myBitMap[index / 32] &= ~bit;
        myTally--;
    } else {
        BLAST(SanityViolation);
    }
}

/* Add a page to the set */
void HeapletSet::introduce (Heaplet * page) {
    Int32 index = ((Int32)page) / PAGESIZE;
    if (index > mySize) {
        BLAST(SanityViolation);
    }
    Int32 bits = myBitMap[index / 32];
    Int32 bit = 1 << (index % 32);
    if (!(bits & bit)) {
        myTally++;
        myBitMap[index / 32] |= 1 << (index % 32);
        if (index > myHighest) {
            myHighest = index;
        }
        if (index < myLowest) {
            myLowest = index;
        }
    } else {
        BLAST(SanityViolation);
    }
}

/* Add a page to the set */
void HeapletSet::store (Heaplet * page) {
    Int32 index = ((Int32)page) / PAGESIZE;
    if (index > mySize) {
        BLAST(SanityViolation);
    }
    Int32 bits = myBitMap[index / 32];
    Int32 bit = 1 << (index % 32);
    if (!(bits & bit)) {
        myTally++;
        myBitMap[index / 32] |= 1 << (index % 32);
        if (index > myHighest) {
            myHighest = index;
        }
        if (index < myLowest) {
            myLowest = index;
        }
    }
}

/* Add a range of pages to the set */
void HeapletSet::introduceMany (Heaplet * lowPage, Heaplet * highPage) {
    // !!!! assumes pages not yet present--fix soon
    Int32 lowIndex = ((Int32)lowPage) / PAGESIZE;
    Int32 highIndex = ((Int32)highPage) / PAGESIZE;
    if (lowIndex > mySize || highIndex > mySize || lowIndex > highIndex) {
        BLAST(SanityViolation);
    }
    myTally += highIndex - lowIndex;
    if (highIndex > myHighest) {
        myHighest = highIndex;
    }
    if (lowIndex < myLowest) {
        myLowest = lowIndex;
    }
    Int32 lowWord = (lowIndex + 31) / 32;
    Int32 highWord = highIndex / 32;
    memset (myBitMap + lowWord, 255, (int) (highWord - lowWord) * 4);
    UInt32 word = ((UInt32)-1) << (lowIndex % 32);
    myBitMap[lowIndex / 32] |= word;
    word = ((UInt32)-1) >> (32 - (highIndex +1) % 32);
    myBitMap[highIndex / 32] |= word;
}

Int32 HeapletSet::count () {
    return myTally;
}

HeapletSetStepper * HeapletSet::stepper () {
    return new HeapletSetStepper (this);
}

HeapletSet::~HeapletSet () {
    delete myBitMap;
}

HeapletSet::HeapletSet (Int32 size) {
    mySize = size;
    myBitMap = new UInt32[size / 32];
    memset (myBitMap, 0, (int) size / 32);
    myLowest = size;
    myHighest = -1;
    myTally = 0;
}

/*
        Class PointerReferenceSet
*/

PointerReferenceSet * PointerReferenceSet::make (Heaplet * page) {
    void * store = page->getBytes (sizeof (PointerReferenceSet));
    return new (store) PointerReferenceSet (page);
}

/* PointerReferenceSet::remember finds the first NULL reference
 * and stores the refPtr in it, if there are none it makes an overflow
 * array and puts refPtr there.
*/


void PointerReferenceSet::remember (Heaper ** refPtr) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myRefs[i] == NULL) {
            myRefs[i] = refPtr;
            return;
        }
        if (myRefs[i] == refPtr) {
            return;
        }
    }
    if (myCount < POINTER_SET_SIZE) {
        myRefs[myCount++] = refPtr;
        return;
    }
    if (!myNext) {
        myNext = PointerReferenceSet::make (myPage);
    }
    myNext->remember (refPtr);
}

void PointerReferenceSet::change (Heaper ** oldRefPtr, Heaper ** newRefPtr) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myRefs[i] == oldRefPtr) {
            myRefs[i] = newRefPtr;
//          return;
        }
    }
    if (myNext) {
        myNext->change (oldRefPtr, newRefPtr);
    }
}

void PointerReferenceSet::forget (Heaper ** refPtr) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myRefs[i] == refPtr) {
            myRefs[i] = NULL;
//          return;
        }
    }
    if (myNext) {
        myNext->forget (refPtr);
    }
}

void PointerReferenceSet::forgetFromPage (Heaplet * page) {
    for (Int32 i = 0; i < myCount; i++) {
        if (Heaplet::pageOf(myRefs[i]) == page) {
            myRefs[i] = NULL;
        }
    }
    if (myNext) {
        myNext->forgetFromPage (page);
    }
}

void PointerReferenceSet::scavengeNew (HeapletSet * drainSet) {
    for (Int32 i = 0; i < myCount; i++) {
        Heaper ** ref = myRefs[i];
        if (ref) {
            Heaper * obj = *ref;
            if (Heaplet::pageOf(obj) != myPage) {
                BLAST(SanityViolation);
            }
            if (obj) {
                checkStack((void *)ref);
                Heaper * newObject = Heaplet::forward (obj);
                Heaplet * rp = Heaplet::pageOf(ref);
                if (newObject != obj && !drainSet->contains(rp)) {
                    if(Heaplet::isScavengeable(rp)){
                        if(debugf){
                                *ref = newObject;
                        }

                    } else{

                        if(debugg){
                                *ref = newObject;
                        }

                    }
                    Heaplet * newObjectPage = Heaplet::pageOf(newObject);
                    if (rp != newObjectPage) {
                        newObjectPage->remember (ref);
                    }
                    if (Heaplet::isScavengeable (rp)) {
                        rp->removeOutPointer (myPage);
                        if (rp != newObjectPage) {
                            rp->addOutPointer (newObjectPage);
                        }
                    }
                }
            } else {
                 BLAST(SanityViolation);
                /* reg sept 21 1994 */
            }
            myRefs[i] = NULL;
        } /* refs nulled out by forget */
    }
    if (myNext) {
        myNext->scavengeNew (drainSet);
    }
}

PointerReferenceSet::PointerReferenceSet (Heaplet * page) {
    myNext = NULL;
    myPage = page;
    myCount = 0;
    for (Int32 i = 0; i < POINTER_SET_SIZE; i++) {
        myRefs[i] = (Heaper**) -1;
    }
}


/*
        Class ArrayReferenceSet
*/

ArrayReferenceSet * ArrayReferenceSet::make (Heaplet * page) {
    void * store = page->getBytes (sizeof (ArrayReferenceSet));
    return new (store) ArrayReferenceSet (page);
}

//  Have to describe the way these work
//  before the code can be fixed.  An ARS is made of parrallel
//  (and chained!) arrays.  myArrays is pointer types to memory,
//  myIndicies is (I think) offsets from the pointers.  In the
//  examples Bill and I have hand stepped, storage utilization is rather
//  poor, with most of the pointers being the same.  In the original
//  process of remembering a new entry, the "old" test fails
//  and a new location at count+1 is used.  Later some of these
//  may be "forgotten" by making the pointer part NULL, leaving
//  holes which should be filled in in preference to increasing
//  the size of the array (or allocating another chained set.  If
//  oldArray is not true, I think this works ok, by finding the
//  first NULL pointer or using a location on the end of the list
//  (recursively desending).
//
//
//
//
//
//
//
//
//
//
//
//
//
//


void ArrayReferenceSet::remember (PtrArray * array, Int32 index,
                                  PtrArray * oldArray)
{
    ArrayReferenceSet * ptr;
    ArrayReferenceSet * oldPtr;

    if (oldArray) {
         for (ptr = this; ptr; ptr = ptr ->myNext){
             for (Int32 i = 0; i < myCount; i++) {
                  if (ptr->myArrays[i] == oldArray && ptr->myIndices[i] == index) {
                       ptr->myArrays[i] = array;
                       return;
                  }
             }
         }
    } 

    for (ptr = this; ptr; ptr = ptr ->myNext){
            for (Int32 i = 0; i < myCount; i++) {
                if (ptr->myArrays[i] == array && ptr->myIndices[i] == index) {
                    return;
                }
            }

    }
    for (ptr = this; ptr; ptr = ptr ->myNext){
            for (Int32 i = 0; i < myCount; i++) {

                if (ptr->myArrays[i] == NULL) {
                    ptr->myArrays[i] = array;
                    ptr->myIndices[i] = index;
                    return;
                }
            }
             if (myCount < ARRAY_SET_SIZE) {
               ptr->myArrays[myCount] = array;
               ptr->myIndices[myCount++] = index;
               return;
         }
         oldPtr = ptr;
    }
    

    oldPtr ->myNext = ArrayReferenceSet::make (myPage);
    ptr = oldPtr->myNext;
    ptr->myArrays[ptr->myCount] = array;
    ptr->myIndices[ptr->myCount++] = index;
    return;
}

void ArrayReferenceSet::change (PtrArray * oldArray, PtrArray * newArray) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myArrays[i] == oldArray) {
            myArrays[i] = newArray;
        }
    }
    if (myNext) {
        myNext->change (oldArray, newArray);
    }
}

void ArrayReferenceSet::forget (PtrArray * array, Int32 index) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myArrays[i] == array && myIndices[i] == index) {
            myArrays[i] = NULL;
//          return;
        }
    }
    if (myNext) {
        myNext->forget (array, index);
    }
}

void ArrayReferenceSet::forgetFromPage (Heaplet * page) {
    for (Int32 i = 0; i < myCount; i++) {
        if (Heaplet::pageOf(myArrays[i]) == page) {
            myArrays[i] = NULL;
        }
    }
    if (myNext) {
        myNext->forgetFromPage (page);
    }
}

void ArrayReferenceSet::scavengeNew (HeapletSet * drainSet) {
    for (Int32 i = 0; i < myCount; i++) {
        PtrArray * array = myArrays[i];
        if (array) {
            Int32 index = myIndices[i];
            Heaper * obj = array->unsafeFetch(index);
                checkStack(obj);
                checkStack(array);
            if (Heaplet::pageOf(obj) != myPage) {
                BLAST(SanityViolation);
            }
            if (obj) {
                Heaper * nobj = Heaplet::forward (obj);
                if (nobj != obj) {
                    array->unsafeStore (index, nobj);
                    Heaplet::pageOf(nobj)->rememberArray (array, index, NULL);
                    Heaplet * rp = Heaplet::pageOf(array);
                    if (Heaplet::isScavengeable (rp)) {
                        rp->removeOutPointer (myPage);
                        rp->addOutPointer (Heaplet::pageOf(nobj));
                    }
                }
            }
            myArrays[i] = NULL;
        }
    }
    if (myNext) {
        myNext->scavengeNew (drainSet);
    }
}

void ArrayReferenceSet::executeWeakly () {
    for (Int32 i = 0; i < myCount; i++) {
        WeakPtrArray * array = (WeakPtrArray*) myArrays[i];
        if (array) {
            WeakPtrArray * nArray;
            if (Heaplet::pageOf(array) != myPage) {
                if (((ObjHead*)array-1)->age == FORWARDER_FLAG) {
                    nArray = *(WeakPtrArray**)array;
                } else {
                    nArray = array;
                }
            } else {
                if (((ObjHead*)array-1)->age == FORWARDER_FLAG) {
                    nArray = *(WeakPtrArray**)array;
                } else {
                    nArray = NULL;
                }
            }
            if (nArray) {
                Int32 idx = myIndices[i];
                Heaper ** op = (Heaper**)nArray->unsafeFetch(idx);
                if (op) {
                    checkStack(op);
                    if (((ObjHead*)op-1)->age == FORWARDER_FLAG) {
                        nArray->unsafeStore(idx, *op);
                        Heaplet::pageOf(*op)->rememberWeak (nArray, idx, NULL); /* zzz reg nov 10 1994 added NULL to get ther right number of parameters */
                    } else {
                        EstateRecorder::recordDeath (nArray, idx);
                    }
                }
            }
        }
    }
    if (myNext) {
        myNext->executeWeakly ();
    }
}

ArrayReferenceSet::ArrayReferenceSet (Heaplet * page) {
    myNext = NULL;
    myPage = page;
    myCount = 0;
    for (Int32 i = 0; i < ARRAY_SET_SIZE; i++) {
        myArrays[i] = (PtrArray*) -1;
        myIndices[i] = -1;
    }
}

/*
        Class OutPointerSet
*/

OutPointerSet * OutPointerSet::make (Heaplet * page) {
    void * store = page->getBytes (sizeof (OutPointerSet));
    return new (store) OutPointerSet (page);
}

void OutPointerSet::reference (Heaplet * page) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myRefPages[i] == NULL) {
            myRefPages[i] = page;
            myRefCounts[i] = 1;
            return;
        }
        if (myRefPages[i] == page) {
            myRefCounts[i]++;
            return;
        }
    }
    if (myCount < OUT_POINTER_SET_SIZE) {
        myRefPages[myCount] = page;
        myRefCounts[myCount++] = 1;
        return;
    }
    if (!myNext) {
        myNext = OutPointerSet::make (myPage);
    }
    myNext->reference (page);
}

void OutPointerSet::unreference (Heaplet * page, HeapletSet * dropSet) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myRefPages[i] == page) {
            myRefCounts[i]--;
            if (myRefCounts[i] == 0) {
                page->forgetFromPage (myPage);
                if (dropSet) {
                    dropSet->store (myRefPages[i]);
                }
                myRefPages[i] = NULL;
            }
//          return;
        }
    }
    if (myNext) {
        myNext->unreference (page, dropSet);
    }
}

/* Puts remaining referenced pages into set */
void OutPointerSet::dropInto (HeapletSet * oldSet, HeapletSet * dropSet, HeapletSet * exceptSet) {
    for (Int32 i = 0; i < myCount; i++) {
        Heaplet * page = myRefPages[i];
        if (page) {
            page->forgetFromPage (myPage);
            if (oldSet->contains (page) && !exceptSet->contains(page)) {
                // oldSet->remove (page);
                dropSet->store (page);
            } else {
                myRefCounts[i] = 0;
                myRefPages[i] = NULL;
            }
        }
        if (myNext) {
            myNext->dropInto (oldSet, dropSet, exceptSet);
        }
    }
}

OutPointerSet::OutPointerSet (Heaplet * page) {
    myNext = NULL;
    myPage = page;
    myCount = 0;
}

/*
        Class PtrArraySet
*/

PtrArraySet * PtrArraySet::make (Heaplet * page) {
    void * store = page->getBytes (sizeof (PtrArraySet));
    return new (store) PtrArraySet (page);
}

void PtrArraySet::registerPtrArray (PtrArray * array) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myArrays[i] == NULL) {
            myArrays[i] = array;
            return;
        }
        if (myArrays[i] == array) {
            return;
        }
    }
    if (myCount < POINTER_SET_SIZE) {
        myArrays[myCount++] = array;
        return;
    }
    if (!myNext) {
        myNext = PtrArraySet::make (myPage);
    }
    myNext->registerPtrArray (array);
}

void PtrArraySet::unregisterPtrArray (PtrArray * array) {
    for (Int32 i = 0; i < myCount; i++) {
        if (myArrays[i] == array) {
            myArrays[i] = NULL;
        }
    }
    if (myNext) {
        myNext->unregisterPtrArray (array);
    }
}

/* Remove all arrays from target reference sets. */
void PtrArraySet::cleanup () {
    for (Int32 i = 0; i < myCount; i++) {
        PtrArray * array = myArrays[i];
        if (array) {
            if (!Heaplet::isScavengeable(array)) {
                BLAST(SanityViolation);
            }
            if (Heaplet::pageOf(array) != myPage) {
                BLAST(SanityViolation);
            }
            PtrArray * nArray;
            ObjHead * head = (ObjHead*)array-1;
            if (head->age == FORWARDER_FLAG) {
                nArray = *(PtrArray**)array;
            } else {
                nArray = NULL;
            }
            if (nArray) {
                if (nArray->isKindOf(cat_WeakPtrArray)) {
                    Heaplet::pageOf(nArray)->registerPtrArray (nArray);
                    EstateRecorder::changeArray ((WeakPtrArray*)array,
                                                 (WeakPtrArray*)nArray);
                }
            } else {
                if (array->isKindOf(cat_WeakPtrArray)) {
                    WeakPtrArray * wpa = (WeakPtrArray*)array;
                    EstateRecorder::changeArray (wpa, NULL);
                    for (Int32 j = 0; j < array->count (); j++) {
                        Heaper * p = array->unsafeFetch (j);
                        if (Heaplet::isScavengeable (p)) {
                            Heaplet::pageOf (p)->forgetWeak (wpa, j);
                        }
                    }
                } else {
                    for (Int32 j = 0; j < array->count (); j++) {
                        Heaper * p = array->unsafeFetch (j);
                        if (Heaplet::isScavengeable (p)) {
                            Heaplet::pageOf (p)->forgetArray (array, j);
                        }
                    }
                }
            }
            myArrays[i] = NULL;
        }
    }
    if (myNext) {
        myNext->cleanup ();
    }
}

PtrArraySet::PtrArraySet (Heaplet * page) {
    myNext = NULL;
    myPage = page;
    myCount = 0;
}

/*****************************checkStack()*****************
A pervasive and pernicious problem has been Heapers that point to bogus places.
The moving memory managercaused the system to crash.  After months of study a
cause was found to be Heapers that contained pointers to auto objects tat
were no longer valid.  These pointers point into the stack frame, but the routine
that owned that stack frame had exited, thus the pointer could well endup pointing to
some other routines data. 

The check in checkStack, takes the address of the stack  as an argument to checkStackInit.
The argument should point to the top of the stack that is valid for the Heapers to point at.
 
checkStack uses its argument,  dubiousStackPointer and checks it against the saved pointer.
If the saved pointer is less than (> ? which way does the stack grow?  ) the dubiousStackPointer
is BAD.

checkStack(void *) should be called on each pointer in the garbage collector.   The original
intention is to call checkStackInit from within the garbageCollect with the address of this
(&this) thus obtaining the first valid address after the calling routines stack frame.
Code should not reflect this assumption, but "theres allways something"

Note that even stack objects allocated BEFORE the garbage collector can be in
error and they will be found iff the happen to be allocated at enough stack depth.

*/
/* checkStackInit takes to address of the top of the stack and saves it for checkStack */
static void * referenceStackPointer = (void *)0xffffffff;
void checkStackInit( void * currentStackPointer)
{
        referenceStackPointer = (void *) currentStackPointer;

}
void checkStack( void * dubiousStackPointer)
{
        if(referenceStackPointer <= dubiousStackPointer|| (void *)0x3ffffff < dubiousStackPointer){
                cerr << " checkStack failure, abort";
                abort();
        }
} 

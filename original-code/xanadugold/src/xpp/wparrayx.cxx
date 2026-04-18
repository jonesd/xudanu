/* Copyright Xanadu Operating Company 1991, All Rights Reserved */
/*

	Weak PtrArrays

*/

/* $Id: wparrayx.cxx,v 2.15 1993/04/10 00:54:03 eric Exp $ */

#include "wparrayx.hxx"
#include "wparrayx.ixx"
#include "wparrayp.hxx"

static DepartedObject theSecretDepartedObject;
static DepartedObject *Departed = &theSecretDepartedObject;

/* =============================================================================

			Class EstateRecorder

   ===========================================================================*/

#define NUMBER_OF_ESTATES 1024

Int32		EstateRecorder::ListSize   = 0;
Int32		EstateRecorder::LastEmpty  = 0;
WeakPtrArray ** EstateRecorder::Arrays     = NULL;
Int32 *		EstateRecorder::Indices    = NULL;

void EstateRecorder::initialize ()
{
    if (ListSize == 0) {
	ListSize = NUMBER_OF_ESTATES;
	Arrays = new WeakPtrArray* [ListSize];
	Indices = new Int32 [ListSize];
    }
}

void EstateRecorder::reset ()
{
    LastEmpty = 0;
}

void EstateRecorder::recordDeath (APTR(WeakPtrArray) array, Int32 index)
{
    if (LastEmpty < ListSize) {
	array->unsafeStore (index, Departed);
	Arrays[LastEmpty] = array;
	Indices[LastEmpty] = index;
	LastEmpty++;
    } else {
	BLAST(MEM_ALLOC_ERROR);
    }
}

void EstateRecorder::changeArray (APTR(WeakPtrArray) array,
				  APTR(WeakPtrArray) newArray)
{
    for (Int32 i = 0; i < LastEmpty; i++) {
	if (Arrays[i] == array) {
	    Arrays[i] = newArray;
	}
    }
}

void EstateRecorder::handleAllEstates ()
{
    for (Int32 i = 0; i < LastEmpty; i++) {
	if (Arrays[i] != NULL) {
	    Arrays[i]->invokeExecutor (Indices[i]);
	}
    }
}


/* =============================================================================

			Class XnExecutor

   ===========================================================================*/

GPTR(XnExecutor) XnExecutor::TheNoopExecutor = NULL;

BEGIN_INIT_TIME(XnExecutor,initTimeNonInherited) {
    CONSTRUCT(XnExecutor::TheNoopExecutor,XnExecutor,());
} END_INIT_TIME(XnExecutor,initTimeNonInherited);

RPTR(XnExecutor) XnExecutor::noopExecutor ()
{
    if (TheNoopExecutor == NULL) {
	CONSTRUCT(XnExecutor::TheNoopExecutor,XnExecutor,());
    }
    return TheNoopExecutor;
}

void XnExecutor::execute (Int32 /* estateIndex */)
{}

XnExecutor::XnExecutor()
{}


/* =============================================================================

			WeakPtrArray

   ===========================================================================*/

BEGIN_INIT_TIME(WeakPtrArray,initTimeNonInherited) {
    REQUIRES(XnExecutor);
} END_INIT_TIME(WeakPtrArray,initTimeNonInherited);

RPTR(WeakPtrArray) WeakPtrArray::make (APTR(XnExecutor) executor, Int32 size) {
    RETURN_CONSTRUCT(WeakPtrArray,(executor,size, NULL, 0, -1, 0));
}

/* accessing */

void WeakPtrArray::store (Int32 index, APTR(Heaper) OR(NULL) pointer) {
    Heaplet::checkedWeakStore
    	(this,
	 ((Heaper**)this->storage()) + this->rangeCheck (index),
	 pointer,
	 index);
}

 Int32 WeakPtrArray::storageIsOK(){ 
	return ( this &&this->storage() > 100);
}

WeakPtrArray::WeakPtrArray (APTR(XnExecutor) executor,
			    Int32 size,
			    APTR(PrimArray) from,
			    Int32 sourceOffset,
			    Int32 count,
			    Int32 destOffset)
    : PtrArray (size, from, sourceOffset, count, destOffset)
{
    if (executor == NULL) {
	BLAST(SanityViolation);
    }
    EstateRecorder::initialize();
     myExecutor = executor;
}

RPTR(PrimArray) WeakPtrArray::makeNew (Int32 size,
				       APTR(PrimArray) source,
				       Int32 sourceOffset,
				       Int32 count,
				       Int32 destOffset)
{
    RETURN_CONSTRUCT(WeakPtrArray, (myExecutor, size, CAST(PtrArray,source),
				    sourceOffset, count, destOffset));
}

void WeakPtrArray::invokeExecutor (Int32 estateIndex)
{
    this->unsafeStore(estateIndex, NULL);
// #ifdef ENABLEFUCKEDCODE
/* zzz roger nov 9 1994 turned off for testing -- if on this causes select
to fail with errno 9 (bad file)  why??  does it move the file name? hkh  11/27/94*/
    myExecutor->execute (estateIndex);
//  #endif   
}


/* This makes sure things are cleaned up on manual destruction */
WeakPtrArray::~WeakPtrArray () {
    for (Int32 j = 0; j < this->count (); j++) {
	Heaper * p = this->unsafeFetch (j);
	if (Heaplet::isScavengeable (p)) {
	    Heaplet::pageOf (p)->forgetWeak (this, j);
	}
    }
}

/*
   We do not want WeakPtrArrays to cause anything to migrate
   except for their executors.  <-- all the previous doc on this
   routine!  Migrate of WPAs is called by code processing myRememberSet
   or myArrayRememberSet while garbage collecting.  What migrate does
   (generally) is to move an object from an old heaplet to a new one,
   and also to move any persistant objects *pointed at* by the object.
   WPA are *exceptions* to this latter rule, but there is an 
   exception to the exception, the Executor.  Executors clean up
   (zero and free) after a WPA is no longer in use.  This code 
   interacts with that in scavx.cxx, originally in an unfavorable
   way--we have to be careful to detect that a remembered with
   three arguments cleans up the old remember set.  See the minor
   mod in remember where this was fixed.  hkh

More-- the first section of this code forwards (to a new location)
   the Executor with functions as above.  The next section goes
   down the storage part of the WPA.  (WPA have at least three
   parts, the executor (now at 3 words) the main header (which
   has count/size/pointer to storage/ and pointer to executor plus
   some) and the actual storage.)   The for loop goes through all 
   elements of the storage (in some cases quite a lot of them) returning
   obj, a heaper pointer.  This heapers pointer is tested to see if
   it is not NULL, and is inside scavengeble memory (i.e., moveable!)
   if true, then (from ForwardOrNULL comments):

   If the CDS does *not* contain the object, just return the object.
   
   Return NULL if obj is in CurrentDrainSet and not forwarded,
   otherwise return the new location.

   If an non-NULL is returned, then replace (unsafeStore) the original
   with the new (or same) address.  (This might be made less complex!)
   zzz .  Next we rememberWeak on the page to which the header (and
   executor) have been moved.  (interesting thought--what are the
   consequences if the executor and the rest of the WPA winding up in
   different heaplets?  zzz  The else case (the object pointed to by
   WPA has not been forwarded, or at least not yet) goes back to the
   page of origin and does a rememberWeak on the pointer to the 
   original WPA.  This will be used by executeWeakly after all the
   PointerReferenceSets and ArrayReferenceSets have been processed
   to determine what else should be looked at in the process of cleaning
   out a heaplet.

   Re the old section below:  (And note that the WPA header structure
   has already *been* moved when this code is entered.)  Origin is a  
   pointer to the location of the WPA before the current GC.  "this"
   (object context) is the WPA's new location (which might be in "old"
   space).  







   pass to forwardToOld, (mess of cast stuff) origin->myExecutor--we
   take the address of origin->myExecutor (after typecasting it as 
   a WPA, then convert this address into a Heaper **).  The second parm
   passes the address of the location *within* the WPA header structure
   where the executor pointer should be replaced.
   
*/
void WeakPtrArray::migrate (void * origin,
			    BooleanVar destinationIsOld)
{
    if (destinationIsOld) {
	Heaplet::forwardToOld ((Heaper**)&((WeakPtrArray*)origin)->myExecutor,
			       (Heaper**)&myExecutor);
    } else {
	myExecutor.forwardTo (Heaplet::forward (myExecutor));
    }
    for (Int32 i = 0; i < this->count (); i++) {
	Heaper * obj = this->unsafeFetch (i);  // pointer to object
	if (obj && Heaplet::isScavengeable (obj)) {
	    Heaper * nobj = Heaplet::forwardOrNULL (obj);

// Because obj is scavengeable (line above) forwareOrNull will return
// unmodified if the pointed-to-location is *not* in the drain set.  If
// it *is* in the drain set, and is forwarded, the new address will be
// returned.  In either case, nobj will be in that currently being filled.
// Store this location pointer back into the WPA in the old location,
// and make a rememberWeak notation on the new page.

// If the object is not forwarded at all (at least not yet)
// then nobj will return NULL.  Make a notation on the *old page* in
// this case, so executeWeakly will do what is needed to clean up    
// this WPA when it is invoked.  ("this" must be refering to the 
// WPA object when it is sent to rememberWeak.)

	    if (nobj) {
		this->unsafeStore (i, nobj);
		Heaplet::pageOf (nobj)->rememberWeak (this, i,NULL); // on new pg 

/* zzz reg nov 10 1994 for fixing number of args to match, 3dr arg should
 be NULL or origin, see ArrayReferenceSet::remember line 1080 scavx.cxx */

	    } else {
		Heaplet::pageOf (obj)->rememberWeak (this, i,
						     (WeakPtrArray*)origin);
	    }
	}
    }
}

void WeakPtrArray::sendSelfTo (APTR(Xmtr)) {
    BLAST(SanityViolation);
}


#include "wparrayx.sxx"
#include "wparrayp.sxx"

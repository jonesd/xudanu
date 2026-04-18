/* Copyright Xanadu Operating Company 1991, All Rights Reserved */
/*

	Weak PtrArrays

*/
#ifndef WPARRAYX_HXX
#define WPARRAYX_HXX

/* $Id: wparrayx.hxx,v 2.11 1993/04/10 00:54:05 eric Exp $ */

#include "parrayx.hxx"
#include "initx.hxx"

#include "wparrayx.oxx"


/* =============================================================================

			Class EstateRecorder

   ===========================================================================*/

class EstateRecorder ROOTCLASS {

 public:

    /* Call this when creating a weak array to assure that recorder is ready */
    static void initialize ();

    /* Called at beginning of weak array checking phase */
    static void reset ();

    /* Called with each collected entry in a weak array. */
    static void recordDeath (APTR(WeakPtrArray) array, Int32 index);

    /* Change all mention of array to newArray in estate list */
    static void changeArray (APTR(WeakPtrArray) array,
			     APTR(WeakPtrArray) newArray = NULL);

    /* Called after destruction and release phase of garbage collection */
    static void handleAllEstates ();

 private:

    static Int32 ListSize;
    static Int32 LastEmpty;
    static WeakPtrArray ** Arrays;
    static Int32 * Indices;
};


/* =============================================================================

			Class XnExecutor

   ===========================================================================*/

class XnExecutor  : public Heaper {
    CONCRETE(XnExecutor)
    NO_GC(XnExecutor)
    EQ(XnExecutor)

    friend class INIT_TIME_NAME(XnExecutor,initTimeNonInherited);

 public:

    static RPTR(XnExecutor) noopExecutor ();

 public:

    virtual void execute (Int32 estateIndex);	// implements a noop

 protected:

    XnExecutor();	// because of stubble generated constructors

 private:

    static GPTR(XnExecutor) TheNoopExecutor;
};


/* =============================================================================

			Class WeakPtrArray

   ===========================================================================*/

class WeakPtrArray : public PtrArray {
    CONCRETE(WeakPtrArray)
    MANUAL_GC(WeakPtrArray)
    EQ(WeakPtrArray)

    friend class INIT_TIME_NAME(WeakPtrArray,initTimeNonInherited);

 public:

    static RPTR(WeakPtrArray) make (APTR(XnExecutor) executor, Int32 size);

 protected: /* Creation */

    WeakPtrArray (APTR(XnExecutor) executor,
		  Int32 size,
		  APTR(PrimArray) from,
		  Int32 sourceOffset,
		  Int32 count,
		  Int32 destOffset);

    virtual RPTR(PrimArray) makeNew (Int32 size,
				     APTR(PrimArray) source,
				     Int32 sourceOffset,
				     Int32 count,
				     Int32 destOffset);
 public: /* Accessing */

    virtual void store (Int32, APTR(Heaper) OR(NULL) value);
    Int32 storageIsOK();

 public: /* Legal services */

    void invokeExecutor (Int32 estateIndex);

 public: /* destruction */

    ~WeakPtrArray ();

 public: /* GC & comm functions */

    virtual void migrate (void * origin,
			  BooleanVar destinationIsOld);

    /* PtrArray::sendSelfTo is overridden to blast */
    void sendSelfTo(APTR(Xmtr));

 private:

    CHKPTR(XnExecutor) myExecutor;	// one per WeakPtrArray
};

#ifdef USE_INLINE
#include "wparrayx.ixx"
#endif /* USE_INLINE */

#endif /* WPARRAYX_HXX */

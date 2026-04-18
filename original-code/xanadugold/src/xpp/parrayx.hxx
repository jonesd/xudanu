/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef PARRAYX_HXX
#define PARRAYX_HXX

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

VERSION_ID(parrayx_hxx,
	   "$Id: parrayx.hxx,v 3.22 1993/04/10 00:53:56 eric Exp $")

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */


/* ************************************************************************ *
 * 
 *                    Class PrimArray 
 *
 * ************************************************************************ */


	/* Array objects in smalltalk vary in size, while in x++ they 
	allocate separate storage for the varying part.  Thus they 
	require very different Recipes.

	Recipes are normally registered by the class'' associated 
	Recipe class at its own initialization time.  In smalltalk,
	the Array classes share a common Recipe class,
	(STArrayRecipe), which registers an instance of itself for 
	each appropriate concrete subclass of PrimArray.X.

	*/

class PrimArray : public Heaper {

  /* Attributes for class PrimArray */
	DEFERRED(PrimArray)
	EQ(PrimArray)
	NO_GC(PrimArray)
	COPY(PrimArray,XppCuisine)

  public: /* accessing */

	/* How many elements the array can hold */

	INLINE Int32 count ();

	/* Store a value; may be a Heaper, NULL, or a PrimValue as appropriate
	   to PrimArray subclass.  It is expected that most PrimArray clients
	   will want to use less abstract access methods. */

	virtual void storeValue (Int32 /* index */,
				 APTR(Heaper) OR(NULL) /* value */)
			DEFERRED_SUBR;

	/* Fetch a value; may be a Heaper, NULL, or a PrimValue as appropriate
	   to PrimArray subclass.  It is expected that most PrimArray clients
	   will want to use less abstract access methods. */

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 /* index */ )
			DEFERRED_FUNC;

	/* Same fetchValue except it will BLAST if value is NULL */

	virtual CLIENT RPTR(Heaper) getValue (Int32 ARG(index));

	/* A description of the kinds of things which can be stored 
	   in this array */

	virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;

  public: /* testing */

	/* Whether the two ranges contain semantically the same 
	   values. Two non-NULL pointers match iff the Heapers they 
	   point to are isEqual. Two integers match iff they have the 
	   same value, even though they may be represented as different 
	   sizes. Two floats likewise. */

	virtual BooleanVar contentsEqual (APTR(PrimArray) /* other */ )
			DEFERRED_FUNC;

	/* A hash of the entire contents of the array. If two arrays 
	   are contentsEqual, they will have the same contentsHash. */

	virtual UInt32 contentsHash ();

  public: /* bulk accessing */

	/* Copy n elements from the other array into this one. The 
	   other array must be of a compatible type. */

	virtual void storeMany (Int32 to,
				APTR(PrimArray) other,
				Int32 count = -1,
				Int32 from = Int32Zero);

	/* Make a copy of a piece of this array.  With no arguments,
	   copy the entire array.  With one argument copy count elements 
	   from the beginning of the array.  With two arguments, copy 'count'
	   elements starting from start.  The third and fourth arguments both
	   default to 0	and represent the number of null/0 elements to put in
	   the result before/after the copied elements.  If after = 10, for
	   instance, the resulting array would be 10 larger than count, and
	   the copied elements would start at index 10. */

	virtual RPTR(PrimArray) copy (Int32 count = -1,
				      Int32 start = Int32Zero,
				      Int32 before = Int32Zero,
				      Int32 after = Int32Zero);

	/* Make a copy of the array into a larger array.  The array has
	   'after' slots after the copied elements. */

	virtual RPTR(PrimArray) copyGrow (Int32 after);

	/* The index of the nth occurrence of the given value at or 
	   after (before if n is negative) the given index, or -1 if 
	   there is none. */

	virtual Int32 indexOf (APTR(Heaper) /* value */ ,
			       Int32 start = Int32Zero,
			       Int32 n = 1) DEFERRED_FUNC;

	/* The index of the nth occurrence of the given sequence of 
	values at or after (before if n is negative) the given 
	starting index, or -1 if there is none. Negative numbers for 
	start are relative to the end of the array. */

	virtual Int32 indexOfElements (APTR(PrimArray) other,
				       Int32 valueCount = -1,
				       Int32 valueStart = Int32Zero,
				       Int32 start = Int32Zero,
				       Int32 nth = 1);

	/* The index of the nth occurrence of anything but the given 
	value at or after (before if n is negative) the given index,
	or -1 if there is none. */

	virtual Int32 indexPast (APTR(Heaper) value,
				 Int32 start = Int32Zero,
				 Int32 n = 1);

	/* Set a range of elements to have the same value */

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero) DEFERRED_SUBR;

	/* Copy of a piece of this array into the provided buffer with
	   size bytes of space available.  The default is to start at
	   the beginning and go to the end.  The elements will be copied
	   from this array beginning with start, and taking as many
	   of count elements or upto the end of this array as will fit in
	   size bytes.  WARNING:  Note that if this array is a PtrArray,
	   the pointers copied to buffer will not be considered as references
	   for garbage collection.  Therefore the buffer should not be allowed
	   to contain the only pointer to an object in a garbage collecting
	   environment. */

	virtual void copyToBuffer (void * /* buffer */ ,
				   Int32 /*  size */,
				   Int32 count = -1,
				   Int32 start = Int32Zero) DEFERRED_SUBR;

  public: /* bulk testing */

	/* Whether the two ranges contain the same values, using the 
	criteria defined in contentsEqual */

	virtual BooleanVar elementsEqual (Int32 /* here */ ,
					  APTR(PrimArray) /* other */ ,
					  Int32 there = Int32Zero,
					  Int32 n = -1) DEFERRED_FUNC;

	/* A hash of the range of values out of the array. If two 
	ranges are elementsEqual, they will have the same hash. For 
	data values, additional zeros on the end make no difference 
	to the hash. */

	virtual UInt32 elementsHash (Int32 count = -1,
				     Int32 start = Int32Zero) DEFERRED_FUNC;

  public: /* printing */

	virtual void printOn (ostream& oo);

  protected:  /* bounds checking */

	INLINE Int32 rangeCheck (Int32 index);

  protected:  /* create/heap access */

	PrimArray (Int32 count, Int32 datumSize);

	INLINE void * storage();

  public: /* destruction */

	~PrimArray ();

  private: /* hooks */

	virtual RECEIVE_HOOK void receivePrimArray (APTR(Rcvr) rcvr);

  protected: /* helper functions */

	virtual void printElementOn (Int32 /* index */ ,
				     ostream& /* oo */) DEFERRED_SUBR;

	/* subclasses with non-32 bit or other interesting values 
	   should override */

	virtual void copyElements (Int32 to,
				   APTR(PrimArray) source,
				   Int32 from,
				   Int32 count);

	virtual void zeroElements (Int32 from = Int32Zero,
				   Int32 count = -1);

	virtual RPTR(PrimArray) makeNew (Int32 /* size */ ,
					 APTR(PrimArray) /* source */ ,
					 Int32 /* sourceOffset */ ,
					 Int32 /* count */ ,
					 Int32 /* destOffset */ ) DEFERRED_FUNC;
  public:

	static void cleanup();

  protected:

	static Int32 OurGutsCount;

  private:

	/* the canonical out-of-bounds blast for prim arrays */
	void outOfBounds ();

	Int32 myCount;  /* the number of elements contained */
	Int32 mySize;   /* in units of PrimArrayHeap allocation */

	/* PrimArrayHeap stuff */

	friend class PrimArrayHeap;

	/* used in compaction */
	INLINE Int32 size ();
	void moveTo (Int32 * newLoc);

	NOCOPY Int32 * myStorage;

	friend class PrimArrayTester;

};  /* end class PrimArray */


/* ************************************************************************ *
 * 
 *                    Class   PrimDataArray 
 *
 * ************************************************************************ */


	/* A common superclass for primitive arrays of basic data 
	types (i.e. bits of some kind) */

class PrimDataArray : public PrimArray {

  /* Attributes for class PrimDataArray */
	DEFERRED(PrimDataArray)
	COPY(PrimDataArray,XppCuisine)
	NO_GC(PrimDataArray)

  public: /* accessing */

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) /* value */ )
								DEFERRED_SUBR;

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 /* index */ ) DEFERRED_FUNC;

	virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;

  public: /* testing */

	virtual BooleanVar contentsEqual (APTR(PrimArray) other);

  public: /* bulk accessing */

	virtual void addElements (Int32 to,
				  APTR(PrimDataArray) other,
				  Int32 count = -1,
				  Int32 from = Int32Zero);

	virtual void subtractElements (Int32 to,
				       APTR(PrimDataArray) other,
				       Int32 count = -1,
				       Int32 from = Int32Zero);

	virtual Int32 indexOf (APTR(Heaper) value,
			       Int32 start = Int32Zero,
			       Int32 n = 1) DEFERRED_FUNC;

	virtual Int32 indexPast (APTR(Heaper) /* value */ ,
				 Int32 start = Int32Zero,
				 Int32 n = 1) DEFERRED_FUNC;

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero) DEFERRED_SUBR;

	virtual void copyToBuffer (void * /* buffer */ ,
				   Int32 /* size */ ,
				   Int32 count = -1,
				   Int32 start = Int32Zero) DEFERRED_SUBR;

  public: /* bulk testing */

	/* Return -1, 0, or +1 according to whether the elements in 
	the specified span of this array are lexically less than,
	equal to, or greater than the specified span of the other. 
	The other array must be of a compatible type. If the count is 
	negative or goes beyond the end of either array, then the 
	shorter array is considered to be extended with zeros.
		NOTE: Because of zero extension, this is not the same as 
	elementsEqual; it is possible that a->compare (b) == 0 even 
	though ! a->contentsEqual (b) */

	virtual Int32 compare (APTR(PrimDataArray) other,
			       Int32 count = -1,
			       UInt32 here = Int32Zero,
			       Int32 there = Int32Zero);

	virtual BooleanVar elementsEqual (Int32 here,
					  APTR(PrimArray) other,
					  Int32 there = Int32Zero,
					  Int32 count = -1);

	/* A hash of the range of values out of the array */

	virtual UInt32 elementsHash (Int32 count = -1,
				     Int32 start = Int32Zero) DEFERRED_FUNC;

  protected: /* create -- just to pass up to PrimArray */

	PrimDataArray (Int32 count, Int32 datumSize);

  protected: /* helper functions */

	/* over given range, returns - if this < other; 0 if this == other;
	   + if this > other. */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	/* return the sign of the next non-zero element after start, or 0
	   if no such element.  Note that for the unsigned arrays, this
	   will only return 0 or 1. */

	virtual Int32 signOfNonZeroAfter (Int32 /* start */ ) DEFERRED_FUNC;

	/* Add the respective elements of other to this over the given
	   index range. */

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	/* Subtract the respective elements of other from this over the given
	   index range. */

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 /* index */ ,
				     ostream& /* oo */ ) DEFERRED_SUBR;

	virtual RPTR(PrimArray) makeNew (Int32 /* size */ ,
					 APTR(PrimArray) /* source */ ,
					 Int32 /* sourceOffset */ ,
					 Int32 /* count */ ,
					 Int32 /* destOffset */ ) DEFERRED_FUNC;

};  /* end class PrimDataArray */


/* ************************************************************************ *
 * 
 *                    Class     PrimFloatArray 
 *
 * ************************************************************************ */


class PrimFloatArray : public PrimDataArray {

  /* Attributes for class PrimFloatArray */
	DEFERRED(PrimFloatArray)
	COPY(PrimFloatArray,XppCuisine)
	NO_GC(PrimFloatArray)

  public: /* accessing */

        /* Make an array initialized to zero values */

	static CLIENT RPTR(PrimFloatArray) zeros (Int32 bitCount, Int32 count);

	/* Store a floating point value */

	virtual void storeFloat (Int32 /* index */ , 
				 IEEE64 /* value */ ) DEFERRED_SUBR;

	/* Get an actual floating point number */

	virtual IEEE64 floatAt (Int32 /* index */ ) DEFERRED_FUNC;

	virtual void storeValue (Int32 /* index */ ,
				 APTR(Heaper) OR(NULL) /* value */ )
			DEFERRED_SUBR;

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 /* index */ )
			DEFERRED_FUNC;

	virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;

	/* Return the maximum bits/entry that can be stored in this array */

	virtual CLIENT Int32 bitCount () DEFERRED_FUNC;

  public: /* testing */

	virtual UInt32 elementsHash (Int32 count = -1,
				     Int32 start = Int32Zero);

  public: /* bulk accessing */

	virtual Int32 indexOf (APTR(Heaper) value,
			       Int32 start = Int32Zero,
			       Int32 n = 1);

	virtual Int32 indexPast (APTR(Heaper) value,
				 Int32 start = Int32Zero,
				 Int32 n = 1);

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero) DEFERRED_SUBR;

	virtual void copyToBuffer (void * /* buffer */ ,
				   Int32 /* size */ ,
				   Int32 count = -1,
				   Int32 start = Int32Zero) DEFERRED_SUBR;

  protected: /* create -- just to pass up to PrimArray */

	PrimFloatArray (Int32 count, Int32 datumSize);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 /* start */ ) DEFERRED_FUNC;

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 /* index */ ,
				     ostream& /* oo */ ) DEFERRED_SUBR;

	virtual RPTR(PrimArray) makeNew (Int32 /* size */ ,
					 APTR(PrimArray) /* source */ ,
					 Int32 /* sourceOffset */ ,
					 Int32 /* count */ ,
					 Int32 /* destOffset */ ) DEFERRED_FUNC;

};  /* end class PrimFloatArray */


/* ************************************************************************ *
 * 
 *                    Class       IEEE32Array 
 *
 * ************************************************************************ */


class IEEE32Array : public PrimFloatArray {

  /* Attributes for class IEEE32Array */
	CONCRETE(IEEE32Array)
	COPY(IEEE32Array,XppCuisine)
	NO_GC(IEEE32Array)

  public: /* pseudo constructors */

	/* create an IEEE32Array filled with zeros */

	static RPTR(IEEE32Array) make (Int32 count);

	/* create an IEEE32Array filled with the indicated data in 'from' */

	static RPTR(IEEE32Array) make (Int32 size,
				       APTR(PrimArray) from,
				       Int32 sourceOffset = Int32Zero,
				       Int32 count = -1,
				       Int32 destOffset = Int32Zero);

	/* create an IEEE32Array filled with the data at 'buffer' */

	static RPTR(IEEE32Array) make (Int32 count, void * buffer);

  public: /* accessing */

	/* Store an actual floating point value */

	INLINE void storeIEEE32 (Int32 index, IEEE32 value);

	/* Get an actual floating point number */

	INLINE IEEE32 iEEE32At (Int32 index);

	virtual void storeFloat (Int32 index, IEEE64 value);

	virtual IEEE64 floatAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

	/* Return the maximum word size that can be stored in this array */

	virtual CLIENT Int32 bitCount ();

  public: /* bulk accessing */

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero);

	virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

  protected: /* create */

	IEEE32Array (Int32 count, TCSJ);

	IEEE32Array (Int32 size,
		     APTR(PrimArray) from,
		     Int32 sourceOffset,
		     Int32 count,
		     Int32 destOffset);

	IEEE32Array (Int32 count, void * buffer);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);

};  /* end class IEEE32Array */


/* ************************************************************************ *
 * 
 *                    Class       IEEE64Array 
 *
 * ************************************************************************ */


class IEEE64Array : public PrimFloatArray {

  /* Attributes for class IEEE64Array */
	CONCRETE(IEEE64Array)
	COPY(IEEE64Array,XppCuisine)
	NO_GC(IEEE64Array)

  public: /* pseudo constructors */

	/* create an IEEE64 array filled with zeros */

	static RPTR(IEEE64Array) make (Int32 count);

	/* create an IEEE64Array filled with the indicated data in 'from' */

	static RPTR(IEEE64Array) make (Int32 size,
				       APTR(PrimArray) from,
				       Int32 sourceOffset = Int32Zero,
				       Int32 count = -1,
				       Int32 destOffset = Int32Zero);

	/* create an IEEE64Array filled with the data at 'buffer' */

	static RPTR(IEEE64Array) make (Int32 count, void * buffer);

  public: /* accessing */

	/* Store an actual floating point value */

	INLINE void storeIEEE64 (Int32 index, IEEE64 value);

	/* Get an actual floating point number */

	INLINE IEEE64 iEEE64At (Int32 index);

	virtual void storeFloat (Int32 index, IEEE64 value);

	virtual IEEE64 floatAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

	/* Return the maximum word size that can be stored in this array */

	virtual CLIENT Int32 bitCount ();

  public: /* bulk accessing */

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero);

	virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

	virtual void zeroElements (Int32 from = Int32Zero,
				   Int32 count = -1);

  protected: /* create */

	IEEE64Array (Int32 count, TCSJ);

	IEEE64Array (Int32 size,
		     APTR(PrimArray) from,
		     Int32 sourceOffset,
		     Int32 count,
		     Int32 destOffset);

	IEEE64Array (Int32 count, void * buffer);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual void copyElements (Int32 to,
				   APTR(PrimArray) source,
				   Int32 from,
				   Int32 count);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);
};  /* end class IEEE64Array */


/* ************************************************************************ *
 * 
 *                    Class     PrimIntegerArray 
 *
 * ************************************************************************ */


	/* A common superclass for primitive arrays of integer types; 
	this is the point to add bulk operations for Boolean 
	operations, etc if we ever want them */

class PrimIntegerArray : public PrimDataArray {

  /* Attributes for class PrimIntegerArray */
	DEFERRED(PrimIntegerArray)
	COPY(PrimIntegerArray,XppCuisine)
	NO_GC(PrimIntegerArray)

  public: /* accessing */

	/* Store a new value into the array at the given index. If 
	the value does not fit into the range that can be stored 
	here, return an array of a kind that will accept it. If the 
	index is past the end, return a larger array.
		If canModify, then returns a newly created array only if the 
	value will not fit into this one, otherwise will always 
	return a new array. */

	virtual RPTR(PrimIntegerArray) hold (Int32 index,
					     IntegerVar value,
					     BooleanVar canModify = FALSE);

	/* Store an integer value */

	virtual void storeInteger (Int32 /* index */ , IntegerVar /* value */ )
			DEFERRED_SUBR;

	/* Get an actual integer value */

	virtual IntegerVar integerAt (Int32 /* index */ ) DEFERRED_FUNC;

	virtual void storeValue (Int32 /* index */ ,
				 APTR(Heaper) OR(NULL) /* value */ )
			DEFERRED_SUBR;

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 /* index */ )
			DEFERRED_FUNC;

	virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;

  public: /* testing */

	virtual UInt32 elementsHash (Int32 count = -1,
				     Int32 start = Int32Zero);

  public: /* bulk accessing */

	virtual Int32 indexOf (APTR(Heaper) value,
			       Int32 start = Int32Zero,
			       Int32 n = 1);

	virtual Int32 indexOfInteger (IntegerVar value,
				      Int32 start = Int32Zero,
				      Int32 count = 1);

	virtual Int32 indexPast (APTR(Heaper) value,
				 Int32 start = Int32Zero,
				 Int32 n = 1);

	virtual Int32 indexPastInteger (IntegerVar value,
					Int32 start = Int32Zero,
					Int32 count = 1);

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero);

	virtual void copyToBuffer (void * /* buffer */ ,
				   Int32 /* size */ ,
				   Int32 count = -1,
				   Int32 start = Int32Zero) DEFERRED_SUBR;

  protected: /* create -- just to pass up to PrimArray */

	PrimIntegerArray (Int32 count, Int32 datumSize);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 /* start */ ) DEFERRED_FUNC;

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 /* index */ ,
				     ostream& /* oo */ ) DEFERRED_SUBR;

	virtual RPTR(PrimArray) makeNew (Int32 /* size */ ,
					 APTR(PrimArray) /* source */ ,
					 Int32 /* sourceOffset */ ,
					 Int32 /* count */ ,
					 Int32 /* destOffset */ ) DEFERRED_FUNC;
};  /* end class PrimIntegerArray */


/* ************************************************************************ *
 * 
 *                    Class     PrimIntArray 
 *
 * ************************************************************************ */


class PrimIntArray : public PrimIntegerArray {

  /* Attributes for class PrimIntArray */
    ON_CLIENT(PrimIntArray)
    DEFERRED(PrimIntArray)
    COPY(PrimIntArray,XppCuisine)
    NO_GC(PrimIntArray)    

  public: /* pseudo constructors */
      /* Make an array initialized to zeros.
	 The values are signed if bitCount is negative */

      static CLIENT RPTR(PrimIntArray) zeros (IntegerVar ARG(bitCount),
					      IntegerVar ARG(count));

   public: /* accessing */
       
      /* Store an integer value */

      virtual void storeInteger (Int32 /* index */ , IntegerVar /* value */ )
			DEFERRED_SUBR;

      /* Get an actual integer value */

      virtual IntegerVar integerAt (Int32 /* index */ ) DEFERRED_FUNC;

      virtual void storeValue (Int32 /* index */ ,
			       APTR(Heaper) OR(NULL) /* value */ )
      			DEFERRED_SUBR;

      virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 /* index */ )
      			DEFERRED_FUNC;

      virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;

      virtual CLIENT Int32 bitCount () DEFERRED_FUNC;
 
      virtual void copyToBuffer (void * /* buffer */ ,
				   Int32 /* size */ ,
				   Int32 count = -1,
				   Int32 start = Int32Zero) DEFERRED_SUBR;

  protected: /* create -- just to pass up to PrimIntegerArray */

      PrimIntArray (Int32 count, Int32 datumSize);

  protected: /* helper functions */

      virtual Int32 signOfNonZeroAfter (Int32 /* start */ ) DEFERRED_FUNC;

      virtual void printElementOn (Int32 /* index */ ,
				   ostream& /* oo */ ) DEFERRED_SUBR;

  public: /* bulk accessing */

      virtual RPTR(PrimArray) makeNew (Int32 /* size */ ,
				       APTR(PrimArray) /* source */ ,
				       Int32 /* sourceOffset */ ,
				       Int32 /* count */ ,
				       Int32 /* destOffset */ ) DEFERRED_FUNC;
}; /* end class PrimIntArray */


/* ************************************************************************ *
 * 
 *                    Class       Int32Array 
 *
 * ************************************************************************ */


class Int32Array : public PrimIntArray {

  /* Attributes for class Int32Array */
	CONCRETE(Int32Array)
	COPY(Int32Array,XppCuisine)
	NO_GC(Int32Array)

  public: /* pseudo constructors */

	/* create an Int32Array filled with zeros */

	static RPTR(Int32Array) make (Int32 count);

	/* create an Int32Array filled with the indicated data in 'from' */

	static RPTR(Int32Array) make (Int32 size,
				      APTR(PrimArray) from,
				      Int32 sourceOffset = Int32Zero,
				      Int32 count = -1,
				      Int32 destOffset = Int32Zero);

	/* create an Int32Array filled with the data at 'buffer' */

	static RPTR(Int32Array) make (Int32 count, void * buffer);


  public: /* accessing */

	/* Store a 32 bit signed integer value */

	INLINE void storeInt (Int32 index, Int32 value);

	/* Get a 32 bit signed actual integer value */

	INLINE Int32 intAt (Int32 index);

	virtual void storeInteger (Int32 index, IntegerVar value);

	virtual IntegerVar integerAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

	virtual CLIENT Int32 bitCount ();

  public: /* bulk accessing */

        virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

  protected: /* create */

	Int32Array (Int32 count, TCSJ);

	Int32Array (Int32 size,
		    APTR(PrimArray) from,
		    Int32 sourceOffset,
		    Int32 count,
		    Int32 destOffset);

	Int32Array (Int32 count, void * buffer);

  private: /* comm hooks */

	virtual RECEIVE_HOOK void receiveInt32Array (APTR(Rcvr) rcvr);

	virtual SEND_HOOK void sendInt32Array (APTR(Xmtr) xmtr);


  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);
};  /* end class Int32Array */


/* ************************************************************************ *
 * 
 *                    Class       IntegerVarArray 
 *
 * ************************************************************************ */


class IntegerVarArray : public PrimIntegerArray {

  /* Attributes for class IntegerVarArray */
	CONCRETE(IntegerVarArray)
	COPY(IntegerVarArray,XppCuisine)
	NO_GC(IntegerVarArray)

  public: /* pseudo constructors */

	/* create an IntegerVarArray filled with zeros */

	static RPTR(IntegerVarArray) zeros (Int32 count);

	/* create an IntegerVarArray filled with the indicated data in 'from' */

	static RPTR(IntegerVarArray) make (Int32 size,
					   APTR(PrimArray) from,
					   Int32 sourceOffset = Int32Zero,
					   Int32 count = -1,
					   Int32 destOffset = Int32Zero);

	/* create an IntegerVarArray filled with the data at 'buffer' */

	static RPTR(IntegerVarArray) make (Int32 count, void * buffer);

  public: /* accessing */

	/* Store an actual integer value */

	INLINE void storeIntegerVar (Int32 index, IntegerVar value);

	/* Get an actual integer value */

	INLINE IntegerVar integerVarAt (Int32 index);

	virtual void storeInteger (Int32 index, IntegerVar value);

	virtual IntegerVar integerAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

  public: /* bulk accessing */

        virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

	virtual void zeroElements (Int32 from = Int32Zero,
				   Int32 count = -1);

  protected: /* create */

	IntegerVarArray (Int32 count, TCSJ);

	IntegerVarArray (Int32 size,
			 APTR(PrimArray) from,
			 Int32 sourceOffset,
			 Int32 count,
			 Int32 destOffset);

	IntegerVarArray (Int32 count, void * buffer);

  private: /* comm hooks */

	virtual RECEIVE_HOOK void receiveIVArray (APTR(Rcvr) rcvr);

	virtual SEND_HOOK void sendIVArray (APTR(Xmtr) xmtr);

  protected: /* helper functions */

	/* Only called in construction of fresh array when there is no
	   possibility of storage leak from skipping IntegerVar assignment.
	   Also, the normal zeroElements is itself unsafe during construction,
	   because the IntegerVar code could interpret the random bits in the
	   newly allocated IntegerVarArray as pointers to bignums to be freed.
	   */

	virtual void unsafeZeroElements (Int32 from, Int32 count);

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual void copyElements (Int32 to,
				   APTR(PrimArray) source,
				   Int32 from,
				   Int32 count);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);
};  /* end class IntegerVarArray */


/* ************************************************************************ *
 * 
 *                    Class       UInt32Array 
 *
 * ************************************************************************ */


class UInt32Array : public PrimIntArray {

  /* Attributes for class UInt32Array */
	CONCRETE(UInt32Array)
	COPY(UInt32Array,XppCuisine)
	NO_GC(UInt32Array)

  public: /* pseudo constructors */

	/* create a UInt32Array filled with zeros */

	static RPTR(UInt32Array) make (Int32 count);

	/* create a UInt32Array filled with the indicated data in 'from' */

	static RPTR(UInt32Array) make (Int32 size,
				       APTR(PrimArray) from,
				       Int32 sourceOffset = Int32Zero,
				       Int32 count = -1,
				       Int32 destOffset = Int32Zero);

	/* create a UInt32Array filled with the data at 'buffer' */

	static RPTR(UInt32Array) make (Int32 count, void * buffer);

  public: /* accessing */

	/* Store a 32 bit unsigned integer value */

	INLINE void storeUInt (Int32 index, UInt32 value);

	/* Get a 32 bit unsigned actual integer value */

	INLINE UInt32 uIntAt (Int32 index);

	virtual void storeInteger (Int32 index, IntegerVar value);

	virtual IntegerVar integerAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

	virtual CLIENT Int32 bitCount ();

  public: /* bulk accessing */

        virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

  private: /* comm hooks */

	virtual RECEIVE_HOOK void receiveInt32Array (APTR(Rcvr) rcvr);

	virtual SEND_HOOK void sendInt32Array (APTR(Xmtr) xmtr);

  protected: /* create */

	UInt32Array (Int32 count, TCSJ);

	UInt32Array (Int32 size,
		     APTR(PrimArray) from,
		     Int32 sourceOffset,
		     Int32 count,
		     Int32 destOffset);

	UInt32Array (Int32 count, void * buffer);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);
};  /* end class UInt32Array */


/* ************************************************************************ *
 * 
 *                    Class       UInt8Array 
 *
 * ************************************************************************ */


class UInt8Array : public PrimIntArray {

  /* Attributes for class UInt8Array */
	CONCRETE(UInt8Array)
	COPY(UInt8Array,XppCuisine)
	NO_GC(UInt8Array)

  public: /* pseudo constructors */

	/* create a UInt8Array filled with zeros */

	static RPTR(UInt8Array) make (Int32 count);

	/* create a UInt8Array filled with the indicated data in 'from' */

	static RPTR(UInt8Array) make (Int32 size,
				      APTR(PrimArray) from,
				      Int32 sourceOffset = Int32Zero,
				      Int32 count = -1,
				      Int32 destOffset = Int32Zero);

	/* create a UInt8Array filled with the data at 'buffer' */

	static RPTR(UInt8Array) make (Int32 count, void * buffer);

	/* create a UInt8Array of size strlen(string) filled with the
	   contents of the string (keep the '\0' ?) */

	static RPTR(UInt8Array) string (char * string);

  public: /* accessing */

	/* Store a 32 bit unsigned integer value */

	INLINE void storeUInt (Int32 index, UInt32 value);

	/* Get a 32 bit unsigned actual integer value */

	INLINE UInt32 uIntAt (Int32 index);

	virtual void storeInteger (Int32 index, IntegerVar value);

	virtual IntegerVar integerAt (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

	virtual CLIENT Int32 bitCount ();

  public: /* testing */

  public: /* bulk accessing */

	virtual void storeMany (Int32 to,
				APTR(PrimArray) other,
				Int32 count = -1,
				Int32 from = Int32Zero);

        virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

	virtual void zeroElements (Int32 from = Int32Zero,
				   Int32 count = -1);

  public: /* printing */

	virtual void printOn (ostream& oo);

	/* A pointer to the actual string.  While one of these are outstanding, 
	 one may not allocate any PrimArrays, because doing so may cause 
	 compaction, which would relocate the data.  In order to keep track of
	 whether there are outstanding hard pointers, my clients must call
	 noMoreGuts() when they will no longer be using the pointer.
	 */

	virtual char * gutsOf ();
	virtual void noMoreGuts ();

	

  protected: /* create */

	UInt8Array (Int32 count, TCSJ);

	UInt8Array (Int32 size,
		    APTR(PrimArray) from,
		    Int32 sourceOffset,
		    Int32 count,
		    Int32 destOffset);

	UInt8Array (Int32 count, void * buffer);

  private: /* comm hooks */

	virtual RECEIVE_HOOK void receiveUInt8Array (APTR(Rcvr) rcvr);

	virtual SEND_HOOK void sendUInt8Array (APTR(Xmtr) xmtr);

  protected: /* helper functions */

	virtual Int32 compareData (Int32 myStart,
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count);

	virtual Int32 signOfNonZeroAfter (Int32 start);

	virtual void addData (Int32 myStart,
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count);

	virtual void subtractData (Int32 myStart,
				    APTR(PrimDataArray) other,
				    Int32 otherStart,
				    Int32 count);

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual void copyElements (Int32 to,
				   APTR(PrimArray) source,
				   Int32 from,
				   Int32 count);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);

};  /* end class UInt8Array */

ORDER_BOMB(ReleaseGuts,SPTR(UInt8Array));

BUILD_BOMB_BEGIN(ReleaseGuts,SPTR(UInt8Array)) {
	CHARGE->noMoreGuts();
} BUILD_BOMB_END(ReleaseGuts)


/* ************************************************************************ *
 * 
 *                    Class   PtrArray 
 *
 * ************************************************************************ */


class PtrArray : public PrimArray {

  /* Attributes for class PtrArray */
	CONCRETE(PtrArray)
	COPY(PtrArray,XppCuisine)
	MANUAL_GC(PtrArray)

  public: /* pseudo constructors */

	/* create a PtrArray filled with NULLs */

	static RPTR(PtrArray) nulls (Int32 count);

	/* create a PtrArray filled with the indicated data in 'from' */

	static RPTR(PtrArray) make (Int32 size,
				    APTR(PrimArray) from,
				    Int32 sourceOffset = Int32Zero,
				    Int32 count = -1,
				    Int32 destOffset = Int32Zero);

	/* create a PtrArray filled with data from 'buffer' */

	static RPTR(PtrArray) make (Int32 count, void * buffer);

	/* create a zero size PtrArray */

	static RPTR(PtrArray) empty ();

  public: /* accessing */

	virtual void store (Int32 index, APTR(Heaper) OR(NULL) pointer);

	/* Retrieve a single element from the array. Does array 
	bounds checking.  BLAST if NULL */

	INLINE RPTR(Heaper) get (Int32 index);

	/* Retrieve a single element from the array. Does array 
	bounds checking. Non-pointer arrays box up the contents in a 
	PrimValue object. */

	INLINE RPTR(Heaper) OR(NULL) fetch (Int32 index);

	virtual void storeValue (Int32 index, APTR(Heaper) OR(NULL) value);

	virtual RPTR(Heaper) OR(NULL) fetchValue (Int32 index);

	virtual RPTR(PrimSpec) spec ();

  public: /* testing */

	virtual BooleanVar contentsEQ (APTR(PtrArray) other);

	virtual BooleanVar contentsEqual (APTR(PrimArray) other);

	virtual UInt32 contentsHash ();

  public: /* bulk accessing */

	virtual Int32 indexOf (APTR(Heaper) value,
			       Int32 start = Int32Zero,
			       Int32 n = 1);

	virtual Int32 indexPast (APTR(Heaper) value,
				 Int32 start = Int32Zero,
				 Int32 n = 1);

	virtual void storeAll (APTR(Heaper) value = NULL,
			       Int32 count = -1,
			       Int32 start = Int32Zero);

        virtual void copyToBuffer (void * buffer,
				   Int32 size,
				   Int32 count = -1,
				   Int32 start = Int32Zero);

  public: /* EQ bulk accessing */

	virtual Int32 indexOfEQ (APTR(Heaper) value,
				 Int32 start = Int32Zero,
				 Int32 n = 1);

	virtual Int32 indexOfEQOrNull (APTR(Heaper) value,
				       Int32 start = Int32Zero,
				       Int32 n = 1);

	virtual Int32 indexPastEQ (APTR(Heaper) value,
				   Int32 start = Int32Zero,
				   Int32 n = 1);

  public: /* bulk testing */

	virtual BooleanVar elementsEQ (Int32 here,
				       APTR(PrimArray) other,
				       Int32 there = Int32Zero,
				       Int32 count = -1);

	virtual BooleanVar elementsEqual (Int32 here,
					  APTR(PrimArray) other,
					  Int32 there = Int32Zero,
					  Int32 count = -1);

	virtual UInt32 elementsHash (Int32 count = -1,
				     Int32 start = Int32Zero);

  protected: /* create */

	PtrArray (Int32 count, TCSJ);

	PtrArray (Int32 size,
		  APTR(PrimArray) from,
		  Int32 sourceOffset,
		  Int32 count,
		  Int32 destOffset);

	PtrArray (Int32 count, void * buffer);

  public: /* destruct */

	/* For cleanup on manual destruction */
	~PtrArray ();

  private: /* comm hooks */

	virtual RECEIVE_HOOK void receivePtrArray (APTR(Rcvr) rcvr);

	virtual SEND_HOOK void sendPtrArray (APTR(Xmtr) xmtr);

  protected: /* helper functions */

	virtual void printElementOn (Int32 index, ostream& oo);

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);

  public: /* garbage collection, other close friends and trusted allies */

	/* for bulk methods that need checking and for migration */
	INLINE void unsafeStore (Int32 index, APTR(Heaper) ptr);

	/* for bulk methods that need checking and for migration */
	INLINE Heaper* unsafeFetch (Int32 index);

	virtual void migrate (void * destination,
			      BooleanVar destinationIsOld);

  private: /* errors */

	void nullEntry ();

};  /* end class PtrArray */


/* ************************************************************************ *
 * 
 *                    Class     SharedPtrArray 
 *
 * ************************************************************************ */


class SharedPtrArray : public PtrArray {

  /* Attributes for class SharedPtrArray */
	CONCRETE(SharedPtrArray)
	COPY(SharedPtrArray,XppCuisine)
	NO_GC(SharedPtrArray)

  public: /* pseudo constructors */

	/* create a PtrArray filled with NULLs */

	static RPTR(SharedPtrArray) make (Int32 count);

	/* create a SharedPtrArray filled with the indicated data in 'from' */

	static RPTR(SharedPtrArray) make (Int32 size,
					  APTR(PrimArray) from,
					  Int32 sourceOffset = Int32Zero,
					  Int32 count = -1,
					  Int32 destOffset = Int32Zero);

	/* create a PtrArray filled with the data from 'buffer' */

	static RPTR(SharedPtrArray) make (Int32 count, void * buffer);

  public: /* accessing */

	virtual RPTR(PrimSpec) spec ();

	INLINE Int32 shareCount ();

	void shareLess ();

	void shareMore ();

  protected: /* create */

	SharedPtrArray (Int32 count, TCSJ);

	SharedPtrArray (Int32 size,
			APTR(PrimArray) from,
			Int32 sourceOffset,
			Int32 count,
			Int32 destOffset);

	SharedPtrArray (Int32 count, void * buffer);

  protected: /* helper functions */

	virtual RPTR(PrimArray) makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset);

  private:
	Int32 myShareCount;
	friend class PtrArray;

};  /* end class SharedPtrArray */


#ifdef USE_INLINE
#ifndef PARRAYX_IXX
#include "parrayx.ixx"
#endif /* PARRAYX_IXX */
#endif /* USE_INLINE */

#endif /* PARRAYX_HXX */

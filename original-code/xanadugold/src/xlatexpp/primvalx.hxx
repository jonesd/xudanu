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

#ifndef PRIMVALX_HXX
#define PRIMVALX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PrimSpec 
 *
 * ************************************************************************ */



/* Initializers for PrimSpec */







	/* A specification of a kind of primitive data type which can 
	be stored in PrimArrays. It gives you protocol for creating 
	and copying PrimArrays. The class and characteristics of this 
	object determine what kind of things are stored there, and 
	how much precision they have. */

class PrimSpec : public Heaper {

/* Attributes for class PrimSpec */
	DEFERRED(PrimSpec)
	COPY(PrimSpec,XppCuisine)
	AUTO_GC(PrimSpec)

/* Initializers for PrimSpec */



friend class INIT_TIME_NAME(PrimSpec,initTimeNonInherited);

  private: /* private: init */

	/* moved from initTime because MS C++/NT does not like large 
	initTimes */
	
	static void initSpecs ();
	
  public: /* pseudo constructors */

	
	static INLINE RPTR(PrimFloatSpec) iEEE32 ();
	
	
	static INLINE RPTR(PrimFloatSpec) iEEE64 ();
	
	
	static RPTR(PrimFloatSpec) iEEE (Int32 ARG(precision));
	
	
	static INLINE RPTR(PrimIntegerSpec) int32 ();
	
	
	static INLINE RPTR(PrimIntegerSpec) integerVar ();
	
	/* A spec for pointers to object */
	
	static INLINE RPTR(PrimPointerSpec) pointer ();
	
	
	static INLINE RPTR(PrimPointerSpec) sharedPointer ();
	
	
	static RPTR(PrimIntegerSpec) signedInteger (Int32 ARG(bitCount));
	
	/* The least demanding spec that will hold the given value */
	
	static RPTR(PrimIntegerSpec) toHold (IntegerVar ARG(value));
	
	
	static INLINE RPTR(PrimIntegerSpec) uInt32 ();
	
	
	static INLINE RPTR(PrimIntegerSpec) uInt8 ();
	
	
	static RPTR(PrimIntegerSpec) unsignedInteger (Int32 ARG(bitCount));
	
  private: /* private: making */

	/* Support for copy:with:with:with:with: */
	
	virtual RPTR(PrimArray) privateCopy (
			APTR(PrimArray) ARG(array), 
			Int32 ARG(size) = -1, 
			Int32 ARG(start) = Int32Zero, 
			Int32 ARG(count) = -1, 
			Int32 ARG(offset) = Int32Zero)
	 DEFERRED_FUNC;
	
  protected: /* protected: */

	
	INLINE RPTR(Category) arrayClass ();
	
  protected: /* protected: create */

	
	PrimSpec (APTR(Category) ARG(primClass), TCSJ);
	
  public: /* making */

	/* Make an array initialized to some reasonable zero value */
	
	virtual RPTR(PrimArray) array (Int32 ARG(count) = Int32Zero) DEFERRED_FUNC;
	
	/* Make an array with the values at the given address */
	
	virtual RPTR(PrimArray) arrayFromBuffer (Int32 ARG(count), void * ARG(buffer)) DEFERRED_FUNC;
	
	/* Make a single element array containing the given value */
	
	virtual RPTR(PrimArray) arrayWith (APTR(Heaper) ARG(value));
	
	/* Make a two element array containing the given values */
	
	virtual RPTR(PrimArray) arrayWithThree (
			APTR(Heaper) ARG(value), 
			APTR(Heaper) ARG(other), 
			APTR(Heaper) ARG(another))
	;
	
	/* Make a two element array containing the given values */
	
	virtual RPTR(PrimArray) arrayWithTwo (APTR(Heaper) ARG(value), APTR(Heaper) ARG(other));
	
	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	virtual RPTR(PrimArray) copy (
			APTR(PrimArray) ARG(array), 
			Int32 ARG(count) = -1, 
			Int32 ARG(start) = Int32Zero, 
			Int32 ARG(before) = Int32Zero, 
			Int32 ARG(after) = Int32Zero)
	;
	
	/* Make a copy of the array into a larger array.  The array 
	has 'after' slots after the copied elements. */
	
	virtual RPTR(PrimArray) copyGrow (APTR(PrimArray) ARG(array), Int32 ARG(after));
	
  public: /* accessing */

	/* Essential. The size of a single element of the array, to 
	be used to allocated space for copyTo/FromBuffer. In the same 
	units as C sizeof (). */
	
	virtual CLIENT Int32 sizeofElement ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(Category) myClass;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PrimFloatSpec) TheIEEE32Spec;
	static GPTR(PrimFloatSpec) TheIEEE64Spec;
	static GPTR(PrimIntegerSpec) TheInt32Spec;
	static GPTR(PrimIntegerSpec) TheIntegerVarSpec;
	static GPTR(PrimPointerSpec) ThePtrSpec;
	static GPTR(PrimPointerSpec) TheSharedPtrSpec;
	static GPTR(PrimIntegerSpec) TheUInt32Spec;
	static GPTR(PrimIntegerSpec) TheUInt8Spec;
};  /* end class PrimSpec */



/* ************************************************************************ *
 * 
 *                    Class   PrimFloatSpec 
 *
 * ************************************************************************ */




	/* Specifies different precisions and representations of 
	floating point numbers. */

class PrimFloatSpec : public PrimSpec {

/* Attributes for class PrimFloatSpec */
	CONCRETE(PrimFloatSpec)
	COPY(PrimFloatSpec,XppCuisine)
	NO_GC(PrimFloatSpec)
  public: /* accessing */

	/* How many total bits per value */
	
	INLINE Int32 bitCount ();
	
  public: /* create */

	
	PrimFloatSpec (APTR(Category) ARG(primClass), Int32 ARG(bitCount));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: making */

	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	virtual RPTR(PrimArray) privateCopy (
			APTR(PrimArray) ARG(array), 
			Int32 ARG(size) = -1, 
			Int32 ARG(start) = Int32Zero, 
			Int32 ARG(count) = -1, 
			Int32 ARG(offset) = Int32Zero)
	;
	
  public: /* making */

	/* Make an array initialized to zero values */
	
	virtual RPTR(PrimArray) array (Int32 ARG(count) = Int32Zero);
	
	/* Make an array with the values at the given address */
	
	virtual RPTR(PrimArray) arrayFromBuffer (Int32 ARG(count), void * ARG(buffer));
	
	/* A boxed floating point value from a large precision number */
	/* myBitCount = 32 ifTrue: [^PrimIEEE32 make: self with: number].
		myBitCount = 64 ifTrue: [^PrimIEEE64 make: self with: number] */
	
	virtual RPTR(PrimFloatValue) preciseValue (IEEE128 ARG(number));
	
	/* A boxed floating point value */
	
	virtual RPTR(PrimFloatValue) value (IEEE64 ARG(number));
	
  private:
	Int32 myBitCount;
	friend class PrimSpec;
};  /* end class PrimFloatSpec */



/* ************************************************************************ *
 * 
 *                    Class   PrimIntegerSpec 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimIntegerSpec : public PrimSpec {

/* Attributes for class PrimIntegerSpec */
	CONCRETE(PrimIntegerSpec)
	COPY(PrimIntegerSpec,XppCuisine)
	NO_GC(PrimIntegerSpec)
  public: /* accessing */

	/* How many bits, or zero if it is unlimited */
	
	INLINE Int32 bitCount ();
	
	/* A spec whose range of values contains both ranges */
	
	virtual RPTR(PrimIntegerSpec) combine (APTR(PrimIntegerSpec) ARG(other));
	
	/* Whether it allows negative values */
	
	INLINE BooleanVar isSigned ();
	
  public: /* create */

	
	PrimIntegerSpec (
			APTR(Category) ARG(primClass), 
			Int32 ARG(bitCount), 
			BooleanVar ARG(isSigned))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Whether this spec can hold the given value */
	
	virtual BooleanVar canHold (IntegerVar ARG(value));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* making */

	/* Make an array initialized to zero values */
	
	virtual RPTR(PrimArray) array (Int32 ARG(count) = Int32Zero);
	
	/* Make an array with the values at the given address */
	
	virtual RPTR(PrimArray) arrayFromBuffer (Int32 ARG(count), void * ARG(buffer));
	
	/* Make an array the contents of the string */
	
	virtual RPTR(PrimIntegerArray) string (char * ARG(string));
	
	/* A boxed integer value */
	
	INLINE RPTR(PrimIntValue) value (IntegerVar ARG(number));
	
  private: /* private: making */

	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	virtual RPTR(PrimArray) privateCopy (
			APTR(PrimArray) ARG(array), 
			Int32 ARG(size) = -1, 
			Int32 ARG(start) = Int32Zero, 
			Int32 ARG(count) = -1, 
			Int32 ARG(offset) = Int32Zero)
	;
	
  private:
	Int32 myBitCount;
	BooleanVar amSigned;
	Int32 myMin;
	Int32 myMax;
	friend class PrimSpec;
};  /* end class PrimIntegerSpec */



/* ************************************************************************ *
 * 
 *                    Class   PrimPointerSpec 
 *
 * ************************************************************************ */




	/* Describes a kind of primitive pointer array */

class PrimPointerSpec : public PrimSpec {

/* Attributes for class PrimPointerSpec */
	CONCRETE(PrimPointerSpec)
	COPY(PrimPointerSpec,XppCuisine)
	NO_GC(PrimPointerSpec)
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: making */

	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	virtual RPTR(PrimArray) privateCopy (
			APTR(PrimArray) ARG(array), 
			Int32 ARG(size) = -1, 
			Int32 ARG(start) = Int32Zero, 
			Int32 ARG(count) = -1, 
			Int32 ARG(offset) = Int32Zero)
	;
	
  public: /* create */

	
	PrimPointerSpec (APTR(Category) ARG(primClass), TCSJ);
	
  public: /* making */

	/* Make an array initialized to null values */
	
	virtual RPTR(PrimArray) array (Int32 ARG(count) = Int32Zero);
	
	/* Make an array with the values at the given address */
	
	virtual RPTR(PrimArray) arrayFromBuffer (Int32 ARG(count), void * ARG(buffer));
	

	friend class PrimSpec;
};  /* end class PrimPointerSpec */



/* ************************************************************************ *
 * 
 *                    Class PrimValue 
 *
 * ************************************************************************ */




	/* A boxed representation of a primitive data type */

class PrimValue : public Heaper {

/* Attributes for class PrimValue */
	DEFERRED(PrimValue)
	ON_CLIENT(PrimValue)
	NO_GC(PrimValue)

	/* automatic 0-argument constructor */
  public:
	PrimValue();

};  /* end class PrimValue */



/* ************************************************************************ *
 * 
 *                    Class   PrimFloatValue 
 *
 * ************************************************************************ */




	/* A boxed representation of a floating point value */

class PrimFloatValue : public PrimValue {

/* Attributes for class PrimFloatValue */
	DEFERRED(PrimFloatValue)
	ON_CLIENT(PrimFloatValue)
	COPY(PrimFloatValue,XppCuisine)
	NO_GC(PrimFloatValue)
  public: /* accessing */

	/* The value as an IEEE 32-bit floating point number.
		May not be possible if conversion from subclass to IEEE type 
	is not available. */
	
	virtual IEEE32 asIEEE32 () DEFERRED_FUNC;
	
	/* The value as an IEEE 64-bit floating point number.
		May not be possible if conversion from subclass to IEEE type 
	is not available. */
	
	virtual IEEE64 asIEEE64 () DEFERRED_FUNC;
	
	/* What precision is it, in terms of the number of bits used 
	to represent it.  In the interests of efficiency, this may 
	return a number larger than that *needed* to represent it.  
	However, the precision reported must be at least that needed 
	to represent this number.  It is assumed that the format of 
	the number satisfies the IEEE radix independent floating 
	point spec.  Should we represent real numbers other that 
	those representable in IEEE, the meaning of this message will 
	be more fully specified.
		The fact that this message is allowed to overestimate 
	precision doesn't interfere with equality: a->isEqual(b) 
	exactly when they represent that same real number, even if 
	one of them happens to overestimate precision more that the other. */
	
	virtual CLIENT Int32 bitCount () DEFERRED_FUNC;
	
	/* If this is a number, return the exponent */
	
	virtual IntegerVar exponent () DEFERRED_FUNC;
	
	/* Return TRUE if value represents a number. */
	
	virtual BooleanVar isANumber () DEFERRED_FUNC;
	
	/* If this is a number, return the signed mantissa */
	
	virtual IntegerVar mantissa () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	PrimFloatValue();

};  /* end class PrimFloatValue */



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE32 
 *
 * ************************************************************************ */




	/* A boxed representation of an IEEE 32-bit floating point value */

class PrimIEEE32 : public PrimFloatValue {

/* Attributes for class PrimIEEE32 */
	CONCRETE(PrimIEEE32)
	COPY(PrimIEEE32,XppCuisine)
	NO_GC(PrimIEEE32)
  public: /* create */

	
	static RPTR(PrimIEEE32) make (IEEE32 ARG(value));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	/* The value as an IEEE 32-bit floating point number */
	
	virtual IEEE32 asIEEE32 ();
	
	/* The value as an IEEE 64-bit floating point number */
	
	virtual IEEE64 asIEEE64 ();
	
	
	virtual Int32 bitCount ();
	
	/* If this is a number, return the exponent */
	
	virtual IntegerVar exponent ();
	
	
	virtual BooleanVar isANumber ();
	
	
	virtual IntegerVar mantissa ();
	
  protected: /* protected: create */

	
	PrimIEEE32 (IEEE32 ARG(value), TCSJ);
	
  private:
	IEEE32 myValue;
};  /* end class PrimIEEE32 */



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE64 
 *
 * ************************************************************************ */




	/* A boxed representation of an IEEE 64-bit floating point value */

class PrimIEEE64 : public PrimFloatValue {

/* Attributes for class PrimIEEE64 */
	CONCRETE(PrimIEEE64)
	COPY(PrimIEEE64,XppCuisine)
	NO_GC(PrimIEEE64)
  public: /* create */

	
	static RPTR(PrimIEEE64) make (IEEE64 ARG(value));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	/* The value as an IEEE 32-bit floating point number */
	
	virtual IEEE32 asIEEE32 ();
	
	/* The value as an IEEE 64-bit floating point number */
	
	virtual IEEE64 asIEEE64 ();
	
	
	virtual Int32 bitCount ();
	
	/* If this is a number, return the exponent */
	
	virtual IntegerVar exponent ();
	
	
	virtual BooleanVar isANumber ();
	
	
	virtual IntegerVar mantissa ();
	
  protected: /* protected: create */

	
	PrimIEEE64 (IEEE64 ARG(value), TCSJ);
	
  private:
	IEEE64 myValue;
};  /* end class PrimIEEE64 */



/* ************************************************************************ *
 * 
 *                    Class   PrimIntValue 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimIntValue : public PrimValue {

/* Attributes for class PrimIntValue */
	CONCRETE(PrimIntValue)
	ON_CLIENT(PrimIntValue)
	COPY(PrimIntValue,XppCuisine)
	NO_GC(PrimIntValue)
  public: /* create */

	
	static RPTR(PrimIntValue) make (IntegerVar ARG(value));
	
  public: /* operations */

	/* Return the the first number bitwise and'd with the second. */
	
	virtual CLIENT IntegerVar bitwiseAnd (APTR(PrimIntValue) ARG(another));
	
	/* Return the the first number bitwise or'd with the second. */
	
	virtual CLIENT IntegerVar bitwiseOr (APTR(PrimIntValue) ARG(another));
	
	/* Return the the first number bitwise xor'd with the second. */
	
	virtual CLIENT IntegerVar bitwiseXor (APTR(PrimIntValue) ARG(another));
	
	/* Integer divide the two numbers and return the result.  
	This truncates. */
	
	virtual CLIENT IntegerVar dividedBy (APTR(PrimIntValue) ARG(another));
	
	/* Return true if the first number is greater than or euqla 
	to the second number. */
	
	virtual CLIENT BooleanVar isGE (APTR(PrimIntValue) ARG(another));
	
	/* Return the the first number shifted to the left by the 
	second amount. */
	
	virtual CLIENT IntegerVar leftShift (APTR(PrimIntValue) ARG(another));
	
	/* Return the largest of the two numbers. */
	
	virtual CLIENT IntegerVar maximum (APTR(PrimIntValue) ARG(another));
	
	/* Return the smallest of the two numbers. */
	
	virtual CLIENT IntegerVar minimum (APTR(PrimIntValue) ARG(another));
	
	/* Return the difference two numbers. */
	
	virtual CLIENT IntegerVar minus (APTR(PrimIntValue) ARG(another));
	
	/* Return the the first number modulo the second. */
	
	virtual CLIENT IntegerVar mod (APTR(PrimIntValue) ARG(another));
	
	/* Return the sum of two numbers. */
	
	virtual CLIENT IntegerVar plus (APTR(PrimIntValue) ARG(another));
	
	/* Multiply the two numbers and return the result. */
	
	virtual CLIENT IntegerVar times (APTR(PrimIntValue) ARG(another));
	
  public: /* accessing */

	/* The value as a BooleanVar. */
	
	INLINE BooleanVar asBooleanVar ();
	
	/* The value as a 32 bit signed integer */
	
	INLINE Int32 asInt32 ();
	
	/* The value as an indefinite precision integer */
	
	INLINE IntegerVar asIntegerVar ();
	
	/* The value as a 32 bit unsigned integer */
	
	INLINE UInt32 asUInt32 ();
	
	/* The value as a 8 bit unsigned integer */
	
	INLINE UInt8 asUInt8 ();
	
	/* What precision is it, in terms of the number of bits used 
	to represent it.  In the interests of efficiency, this may 
	return a number larger than that *needed* to represent it.  
	However, the precision reported must be at least that needed 
	to represent this number.
		The fact that this message is allowed to overestimate 
	precision doesn't interfere with equality: a->isEqual(b) 
	exactly when they represent that same real number, even if 
	one of them happens to overestimate precision more that the other. */
	
	virtual CLIENT Int32 bitCount ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  protected: /* protected: create */

	
	PrimIntValue (IntegerVar ARG(value), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	IntegerVar myValue;
};  /* end class PrimIntValue */


#ifdef USE_INLINE
#ifndef PRIMVALX_IXX
#include "primvalx.ixx"
#endif /* PRIMVALX_IXX */


#endif /* USE_INLINE */


#endif /* PRIMVALX_HXX */


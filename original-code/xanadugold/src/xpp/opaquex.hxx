/* ========================================================================== */
//
//	Copyright (c) 1991 by Xanadu Operating Company, All Rights Reserved.
//
/* ========================================================================== */
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
/* ========================================================================== */
//
//				opaquex.hxx
//
//	This module allows the declaration of the inheritance relationship
//	of classes, and the definition of pointers-with-lots-of-behavior-to
//	instances of those classes, without exposing the implementation
//	of the classes to which the pointers point.
//
//	It is called "opaque" because such declarations-without-exposure
//	are said to be opaque (though some have suggested it's really
//	because this module is excessively complex and confusing).
//
/* ========================================================================== */
//
//	Eliminated StrongPtrVar::inspectFuse() overriding.  (Unnecessary.)
//	 - michael May  3 1991
//
//	Added/merged the "wimpies are really strongs" stuff
//	(Changed so UNPTRs are WM2_, not WP2_, and true stars art WSP2_, to
//	 detect any explicit WP2_s in other code and in prep for more types.)
//		- michael Jun 29 1991
//
//	Added 16 methods to fix pointer == and != stuff.
//		- michael (with markm) Jul 12-14 1991
//
//	Added destroyIt() methods.
//		- michael Jul 15 1991  (Merged Jul 22 1991)
//
//	Added casts from TYPE* to Heaper* for store calls in response to error
//	when USE_INLINES turned on.
//		- ech Aug 27 1991
//
//	Prettified the code (my style) and fixed the xlint hooks in preparation
//	for surgery during a fix of MB30 (failed inlining of some SPTR()
//	constructors and destructors.)
//		- michael Oct  4 1991
//
//	Moved remaining inline code to opaquex.ixx, and split off opaque2x.ixx
//	(containing only those routines that need to call routines in Heaper.)
//	The routines that need to call heaper inline routines will not be
//	inlined for those pointer classes that must be defined before Tofu
//	and Heaper.  (Currently, that's destroyIt() in pointers to Heaper,
//	Xmtr, and Rcvr.)
//		- michael Oct 10 1991
//
//	RPTRs & GPTRs
//		- ech Oct 12 1992

#ifndef OPAQUEX_HXX
#define OPAQUEX_HXX

/* $Id: opaquex.hxx,v 2.10 1992/12/22 21:42:52 ravi Exp $ */

class Heaper;

/* ===========================================================================
//
//      CheckedPtrVar -- this is the pointer type that an instance variable
//			 must be in order for the garbage collector to
//			 examine it.
//
//	!!!!! These macros do some work that would be done by stubble in
//	      other circumstances.  They define their own sendSelfTo methods
//	      and produce their own Recipe objects.  Be careful to keep these
//	      and the formic script in agreement or bad chaos will occur.
//
// ========================================================================= */

class CheckedPtrVar ROOTCLASS {
    public:

// This is needed for the unsafe expansion of CAST since CheckPtrVars
// cannot in general cast themselves to random pointers.

	INLINE		operator Heaper*();	/* Not virtual !!! */

REQUIRE(1,"reference")
	void		printOn (ostream&);
PERMIT(0,"reference")

	inline Heaper *	fetch() ;
    protected:
	inline Heaper *	get() ;
	inline void	store(Heaper * p);
    public:
	inline void	forwardTo(Heaper * p);
	INLINE void	destroyIt();
	INLINE ~CheckedPtrVar();	// to clean up remember sets
    protected:
	INLINE		CheckedPtrVar();
REQUIRE(1,"single argument constructor")
	INLINE		CheckedPtrVar(Heaper * p);
PERMIT(0,"single argument constructor")
    public:
	Heaper *	value;  /* ???? why is this public ECH - inlining bug?*/
    private:
	static void nullPointer();
#ifdef SEQUENCE_NUMBER_DANGLE_CHECK
	UInt32		sequenceNumber;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK */
};

REQUIRE(3,"reference")
	extern ostream&	operator<< (ostream& oo, CheckedPtrVar& ptrVar);
PERMIT(0,"reference")

#define SMPTR(TYPE)		CAT(CP2_,TYPE) /* need whitespace after */
#define STR_SMPTR(TYPE)		STR_CAT(CP2_,TYPE)

#define CHKPTR(TYPE)		SMPTR(TYPE)
#define STR_CHKPTR(TYPE)	STR_SMPTR(TYPE)

#define WMPTR(TYPE)		CAT(WM2_,TYPE) /* need whitespace after */
#define STR_WMPTR(TYPE)		STR_CAT(WM2_,TYPE)
#define UNPTR(TYPE)		WMPTR(TYPE)
#define STR_UNPTR(TYPE)		STR_WMPTR(TYPE)

// Following will be turned into pointer types later:
//	WK{M}PTR()		True weak pointer (fixes own dangles)
//	WO{M}PTR()		Wimpout pointer (complains on dangling deref)
// Perhaps a third one to complain as soon as dangling, or should that
// be a mode?  Try getting picky on all non-WK ptrs first...
//
// (There are still WPTRs elsewhere in this file.)

#if defined(HIGHC)
#define DECLARE_CHKPTR_EXTRA(TYPE)				\
	INLINE CHKPTR(TYPE)& operator= (CHKPTR(TYPE)&other);	\
	INLINE CHKPTR(TYPE)& operator= (GPTR(TYPE)&other);	\
	INLINE CHKPTR(TYPE) (TYPE * argPtr);			\
	INLINE CHKPTR(TYPE) (GPTR(TYPE)& argPtr); 
#elif defined(GNUSUN_TEST)
#define DECLARE_CHKPTR_EXTRA(TYPE)				\
	INLINE CHKPTR(TYPE)& operator= (CHKPTR(TYPE)&other);	
#else
#define DECLARE_CHKPTR_EXTRA(TYPE)
#endif

#ifdef PRODUCT
#define PTRGET fetch
#else
#define PTRGET get
#endif

#define DECLARE_DECLARE_CHKPTR(TYPE,COERCIONS_DECL)		\
								\
REQUIRE(1,"single argument constructor")			\
REQUIRE(5,"reference")						\
								\
class CHKPTR(TYPE) : public CheckedPtrVar {			\
    public:							\
	CHKPTR(TYPE) (VTBL VTBL_HACK);				\
    public:							\
	INLINE TYPE* operator-> ();				\
	INLINE TYPE& operator* ();				\
	INLINE CHKPTR(TYPE)& operator= (TYPE * other);	        \
	COERCIONS_DECL						\
	INLINE operator TYPE * ();				\
	INLINE CHKPTR(TYPE) ();					\
	INLINE CHKPTR(TYPE) (CHKPTR(TYPE)& argPtr);		\
	DECLARE_CHKPTR_EXTRA(TYPE)				\
	friend class GPTR(TYPE);				\
};								\
								\
PERMIT(0,"single argument constructor")				\
PERMIT(0,"reference")						\

#if defined(HIGHC) 
#define DEFINE_INLINE_CHKPTR_EXTRA(TYPE)			\
	INLINE CHKPTR(TYPE)& CHKPTR(TYPE)::operator= (CHKPTR(TYPE)& other) \
	{							\
		this->store (other.fetch ());			\
		return *this;					\
	}							\
								\
	INLINE CHKPTR(TYPE)::CHKPTR(TYPE) (TYPE * argPtr)	\
		: CheckedPtrVar(argPtr) {}
#elif defined(GNUSUN_TEST)
#define DEFINE_INLINE_CHKPTR_EXTRA(TYPE)			\
	INLINE CHKPTR(TYPE)& CHKPTR(TYPE)::operator= (CHKPTR(TYPE)& other) \
	{							\
		this->store (other.fetch ());			\
		return *this;					\
	}							
#else
#define DEFINE_INLINE_CHKPTR_EXTRA(TYPE)
#endif /* HIGHC */

#define DEFINE_INLINE_CHKPTR(TYPE)				\
								\
REQUIRE(6,"hard cast")						\
REQUIRE(5,"reference")						\
								\
INLINE TYPE * CHKPTR(TYPE)::operator-> ()			\
{								\
	return (TYPE*)PTRGET();					\
}								\
								\
INLINE TYPE& CHKPTR(TYPE)::operator* ()				\
{								\
	return *(TYPE*)PTRGET();				\
}								\
								\
INLINE CHKPTR(TYPE)& CHKPTR(TYPE)::operator= (TYPE * other)	\
{								\
	/* cast needed when inlined */				\
	this->store((Heaper*)other);				\
	return *this;						\
}								\
								\
INLINE CHKPTR(TYPE)::operator TYPE * ()				\
{								\
	return (TYPE *) this->fetch();				\
}								\
								\
INLINE CHKPTR(TYPE)::CHKPTR(TYPE) ()				\
{}								\
								\
INLINE CHKPTR(TYPE)::CHKPTR(TYPE) (CHKPTR(TYPE)& argPtr)	\
	: CheckedPtrVar(argPtr.fetch()) {}			\
								\
DEFINE_INLINE_CHKPTR_EXTRA(TYPE)				\
								\
PERMIT(0,"hard cast")						\
PERMIT(0,"reference")						\


#ifdef USE_INLINE
#define DECLARE_CHKPTR(TYPE,CDECLS)				\
		DECLARE_DECLARE_CHKPTR(TYPE,CDECLS)		\
		DEFINE_INLINE_CHKPTR(TYPE)
#define DEFINE_CHKPTR(TYPE)					\
		CHKPTR(TYPE)::CHKPTR(TYPE) (VTBL) {}
#else
#define DECLARE_CHKPTR(TYPE,CDECLS)				\
		DECLARE_DECLARE_CHKPTR(TYPE,CDECLS)
#define DEFINE_CHKPTR(TYPE)					\
		DEFINE_INLINE_CHKPTR(TYPE)			\
		CHKPTR(TYPE)::CHKPTR(TYPE) (VTBL) {}
#endif /* USE_INLINE */


/* (- Whew!! -) */


/* ==========================================================================
//
//	GPTR(TYPE) - Global strong pointer to TYPE to be used as a root for garbage
//		     collection.  These live on the stack as automatic and
//		     argument variables, in fluid variables, (?) and as globals.
//
// ========================================================================== */

class GlobalStrongPtrVar : public BombSuperclass {
    public:

// This is needed for the unsafe expansion of CAST since GlobalStrongPtrVars
//  cannot in general cast themselves to random pointers

	INLINE		operator Heaper* ();	/* Not virtual !!! */

REQUIRE(1,"reference")
	LEAF void	printOn (ostream&);
PERMIT(0,"reference")

	inline Heaper *	fetch() ;
    public:
	virtual void *	gCHook ();
	virtual void	gCHook (void * value);
    protected:
	inline Heaper *	get() ;
	inline void	store(Heaper * p);
    public:
	INLINE void	destroyIt();
    protected:
	INLINE		GlobalStrongPtrVar ();
    public:
REQUIRE(1,"single argument constructor")
	INLINE		GlobalStrongPtrVar (Heaper * p);
PERMIT(0,"single argument constructor")
    public:
	INLINE		~GlobalStrongPtrVar ();
    public:
	Heaper *	value;
    private:
	static void nullPointer();
	void		badSequenceNumber () ;
#ifdef SEQUENCE_NUMBER_DANGLE_CHECK
	UInt32		sequenceNumber;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK */
};

REQUIRE(3,"reference")
#ifndef GNU
	extern ostream&	operator<< (ostream& oo, GlobalStrongPtrVar& ptrVar);
#endif
PERMIT(0,"reference")

#define GPTR(TYPE)	CAT(GP2_,TYPE) /* need whitespace after */
#define STR_GPTR(TYPE)	STR_CAT(GP2_,TYPE)

#if defined(HIGHC) 
#define DECLARE_GPTR_EXTRA(TYPE)				\
	INLINE GPTR(TYPE)& operator= (CHKPTR(TYPE)& other);     \
	INLINE GPTR(TYPE)& operator= (GPTR(TYPE)& other);
#elif defined(GNUSUN_TEST)
#define DECLARE_GPTR_EXTRA(TYPE)				\
	INLINE GPTR(TYPE)& operator= (CHKPTR(TYPE)& other);     
#else
#define DECLARE_GPTR_EXTRA(TYPE)
#endif

#define DECLARE_DECLARE_GPTR(TYPE,COERCIONS_DECL)		\
								\
REQUIRE(2,"single argument constructor")			\
REQUIRE(5,"reference")						\
								\
class GPTR(TYPE) : public GlobalStrongPtrVar {			\
	public:							\
		GPTR(TYPE) (VTBL VTBL_HACK);			\
    public:							\
	INLINE TYPE* operator-> ();				\
	INLINE TYPE& operator* ();				\
	INLINE GPTR(TYPE)& operator= (TYPE * other);        	\
	COERCIONS_DECL						\
	INLINE operator TYPE * ();	/* ? */			\
	INLINE GPTR(TYPE) ();					\
	INLINE GPTR(TYPE) (TYPE * argPtr);			\
	INLINE GPTR(TYPE) (GPTR(TYPE)& argPtr);			\
	INLINE GPTR(TYPE) (CHKPTR(TYPE)& argPtr);		\
	DECLARE_GPTR_EXTRA(TYPE)				\
	friend class CHKPTR(TYPE);				\
};								\
								\
PERMIT(0,"single argument constructor")				\
PERMIT(0,"reference")						\

#ifdef HIGHC
#define DEFINE_INLINE_GPTR_EXTRA(TYPE)				\
	/* This is not a mistake; it needs to use the GPTR class definition */ \
	INLINE CHKPTR(TYPE)& CHKPTR(TYPE)::operator= (GPTR(TYPE)& other)       \
	{							\
		this->store (other.fetch());			\
		return *this;					\
	}							\
								\
	/* This is not a mistake; it needs to use the GPTR class definition */ \
	INLINE CHKPTR(TYPE)::CHKPTR(TYPE) (GPTR(TYPE)& argPtr)	\
	{							\
		this->store(argPtr.fetch());			\
	}							\
								\
	INLINE GPTR(TYPE)& GPTR(TYPE)::operator= (GPTR(TYPE)& other)	\
	{							\
		this->store (other.fetch());			\
		return *this;					\
	}							\
								\
	INLINE GPTR(TYPE)& GPTR(TYPE)::operator= (CHKPTR(TYPE)& other)	\
	{							\
		this->store (other.fetch());			\
		return *this;					\
#elif defined(GNUSUN_TEST_2)
#define DEFINE_INLINE_GPTR_EXTRA(TYPE)	
	/* This is not a mistake; it needs to use the GPTR class definition */ \
	INLINE CHKPTR(TYPE)& CHKPTR(TYPE)::operator= (GPTR(TYPE)& other)       \
	{							\
		this->store (other.fetch());			\
		return *this;					\
	}							\
								\
	/* This is not a mistake; it needs to use the GPTR class definition */ \
	INLINE CHKPTR(TYPE)::CHKPTR(TYPE) (GPTR(TYPE)& argPtr)	\
	{							\
		this->store(argPtr.fetch());			\
	}							\
								\
	INLINE GPTR(TYPE)& GPTR(TYPE)::operator= (GPTR(TYPE)& other)	\
	{							\
		this->store (other.fetch());			\
		return *this;					\
	}							\
								\
	INLINE GPTR(TYPE)& GPTR(TYPE)::operator= (CHKPTR(TYPE)& other)	\
	{							\
		this->store (other.fetch());			\
		return *this;					\
#else
#define DEFINE_INLINE_GPTR_EXTRA(TYPE)
#endif

#define DEFINE_INLINE_GPTR(TYPE)				\
								\
REQUIRE(7,"hard cast")						\
REQUIRE(5,"reference")						\
								\
INLINE TYPE * GPTR(TYPE)::operator-> ()				\
{								\
	return (TYPE*)PTRGET();					\
}								\
								\
INLINE TYPE& GPTR(TYPE)::operator* ()				\
{								\
	return *(TYPE*)PTRGET();				\
}								\
								\
INLINE GPTR(TYPE)& GPTR(TYPE)::operator= (TYPE * other)		\
{								\
	this->store((Heaper*)other);				\
	return *this;						\
}								\
								\
INLINE GPTR(TYPE)::operator TYPE * ()				\
{								\
	return (TYPE *) this->fetch();				\
}								\
								\
INLINE GPTR(TYPE)::GPTR(TYPE) () : GlobalStrongPtrVar()		\
{}								\
								\
INLINE GPTR(TYPE)::GPTR(TYPE) (TYPE * argPtr)			\
	: GlobalStrongPtrVar((Heaper*)argPtr)			\
{}								\
								\
INLINE GPTR(TYPE)::GPTR(TYPE) (GPTR(TYPE)& argPtr)		\
	: GlobalStrongPtrVar(argPtr.fetch())			\
{}								\
								\
INLINE GPTR(TYPE)::GPTR(TYPE) (CHKPTR(TYPE)& argPtr)		\
	: GlobalStrongPtrVar(argPtr.fetch())			\
{}								\
DEFINE_INLINE_GPTR_EXTRA(TYPE)					\
PERMIT(0,"hard cast")						\
PERMIT(0,"reference")						\


#ifdef USE_INLINE
#define DECLARE_GPTR(TYPE,CDECLS)				\
		DECLARE_DECLARE_GPTR(TYPE,CDECLS) 		\
		DEFINE_INLINE_GPTR(TYPE)
#define DEFINE_GPTR(TYPE)					\
		GPTR(TYPE)::GPTR(TYPE) (VTBL) {}
#else
#define DECLARE_GPTR(TYPE,CDECLS)				\
		DECLARE_DECLARE_GPTR(TYPE,CDECLS)
#define DEFINE_GPTR(TYPE)					\
		DEFINE_INLINE_GPTR(TYPE)			\
		GPTR(TYPE)::GPTR(TYPE) (VTBL) {}
#endif /* USE_INLINE */

/* (- Whew!! -) */


/* ===========================================================================
//
//	SPTR(TYPE) - Strong stack pointer to TYPE to be ignored by garbage collector
//
// ========================================================================= */

#define SPTR(TYPE)  CAT(SP2_,TYPE)

/* ===========================================================================
//
//	WPTR(TYPE) - Wimpy pointer to TYPE to be ignored by garbage collector
//
// ========================================================================= */

#define WPTR(TYPE)  CAT(WSP2_,TYPE)

/* ===========================================================================
//
//	RPTR(TYPE) - Returned pointer to TYPE to be ignored by garbage collector
//
// ========================================================================= */

#define RPTR(TYPE)  CAT(RSP2_,TYPE)

/* ===========================================================================
//
//	OPAQUE_TYPE_N(TYPE0,...,TYPEn-1); declare opaque pointers
//
// ========================================================================= */


/* 
We break from our normal convention and include the definition
directly inside the declaration, because the macro hacking to follow
our convention just got too painful.  This means that these two
routines cannot be switched to be defined in only one compilation unit
(and so cannot be fully supported by most debuggers--try setting a
breakpoint in an inline routine).
*/

#ifdef HIGHC
#define DECL_COERCION(TYPE) 				\
      inline operator GPTR(TYPE) ()			\
	{						\
	    return (TYPE *) this->fetch();		\
	}						\
	inline operator TYPE * () {			\
		return (TYPE *) this->fetch ();		\
	}
#elif defined(GNUSUN_TEST)
#define DECL_COERCION(TYPE) 				\
      inline operator GPTR(TYPE) ()			\
	{						\
	    return (TYPE *) this->fetch();		\
	}						\
	inline operator TYPE * () {			\
		return (TYPE *) this->fetch ();		\
	}
#else
#define DECL_COERCION(TYPE) 				\
      inline operator GPTR(TYPE) ()			\
	{						\
	    return (TYPE *) this->fetch();		\
	}
#endif

#define DECL_COERCION_1(C0)	/* no coercion for derived class */
#define DECL_COERCION_2(C0,C1)				\
	DECL_COERCION_1(C0)			DECL_COERCION(C1)
#define DECL_COERCION_3(C0,C1,C2)			\
	DECL_COERCION_2(C0,C1)			DECL_COERCION(C2)
#define DECL_COERCION_4(C0,C1,C2,C3)			\
	DECL_COERCION_3(C0,C1,C2)		DECL_COERCION(C3)
#define DECL_COERCION_5(C0,C1,C2,C3,C4)			\
	DECL_COERCION_4(C0,C1,C2,C3) 		DECL_COERCION(C4)
#define DECL_COERCION_6(C0,C1,C2,C3,C4,C5) 		\
	DECL_COERCION_5(C0,C1,C2,C3,C4)		DECL_COERCION(C5)
#define DECL_COERCION_7(C0,C1,C2,C3,C4,C5,C6) 		\
	DECL_COERCION_6(C0,C1,C2,C3,C4,C5) 	DECL_COERCION(C6)
#define DECL_COERCION_8(C0,C1,C2,C3,C4,C5,C6,C7)	 \
	DECL_COERCION_7(C0,C1,C2,C3,C4,C5,C6)	DECL_COERCION(C7)


#define OPAQUE_TYPE(C0,CDECLS)		 			\
	class			C0;				\
	class			GPTR(C0);			\
	extern Category *	CAT(cat_,C0);			\
	typedef C0 *		CAT(SP2_,C0);			\
			/* WSP2 = "Wimpy Star Ptr" to catch leftovers WP2s*/ \
	typedef C0 *		CAT(WSP2_,C0);			\
	typedef C0 *		CAT(RSP2_,C0);			\
	typedef C0 *		CAT(WM2_,C0);			\
	DECLARE_CHKPTR(C0,CDECLS);				\
	DECLARE_GPTR(C0,CDECLS)

#define OPAQUE_TYPE_1(C0)			OPAQUE_TYPE(C0,	\
	DECL_COERCION_1(C0))
#define OPAQUE_TYPE_2(C0,C1)			OPAQUE_TYPE(C0,	\
	DECL_COERCION_2(C0,C1))
#define OPAQUE_TYPE_3(C0,C1,C2)			OPAQUE_TYPE(C0,	\
	DECL_COERCION_3(C0,C1,C2))
#define OPAQUE_TYPE_4(C0,C1,C2,C3)		OPAQUE_TYPE(C0,	\
	DECL_COERCION_4(C0,C1,C2,C3))
#define OPAQUE_TYPE_5(C0,C1,C2,C3,C4)		OPAQUE_TYPE(C0,	\
	DECL_COERCION_5(C0,C1,C2,C3,C4))
#define OPAQUE_TYPE_6(C0,C1,C2,C3,C4,C5)	OPAQUE_TYPE(C0,	\
	DECL_COERCION_6(C0,C1,C2,C3,C4,C5))
#define OPAQUE_TYPE_7(C0,C1,C2,C3,C4,C5,C6)	OPAQUE_TYPE(C0,	\
	DECL_COERCION_7(C0,C1,C2,C3,C4,C5,C6))
#define OPAQUE_TYPE_8(C0,C1,C2,C3,C4,C5,C6,C7)	OPAQUE_TYPE(C0,	\
	DECL_COERCION_8(C0,C1,C2,C3,C4,C5,C6,C7))

#define DEFINE_OPAQUE_TYPE(C0)	 				\
	DEFINE_CHKPTR(C0);					\
	DEFINE_GPTR(C0)


/* ===========================================================================
//
//	APTR(TYPE) - Normal gc-safe Argument pointer
//
// ========================================================================= */



#define TEMPORARIES_LIVE_LONG_ENOUGH_FOR_GC

#ifdef TEMPORARIES_LIVE_LONG_ENOUGH_FOR_GC
#define APTR(TYPE) CAT(WSP2_,TYPE)
#else
#define APTR(TYPE) CAT(SP2_,TYPE)
#endif


/* ========================================================================= */
//
//	Pointer comparison operators.
//
//	The pointer superclasses are:
//	 - void *
//	 - CheckedPtrVar
//	 - GlobalStrongPtrVar
//
//	To support all code generation you need a "==" and a "!=" for:
//	 - Every pointer superclass (except void *) against itself.
//	 - Every pairwise combination of two pointer superclasses,
//	   in both orders.
//
//	Note that these are inline even if switchable inlines are off.
//
/* ========================================================================== */

inline BooleanVar operator== (
       CheckedPtrVar&	aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft.fetch() == aRight.fetch();
}

inline BooleanVar operator!= (
       CheckedPtrVar&	aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft.fetch() != aRight.fetch();
}

inline BooleanVar operator== (
       void *		aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft == aRight.fetch();
}

inline BooleanVar operator!= (
       void *		aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft != aRight.fetch();
}

inline BooleanVar operator== (
       CheckedPtrVar&	aLeft
    ,  void *		aRight
) {
	return aLeft.fetch() == aRight;
}

inline BooleanVar operator!= (
       CheckedPtrVar&	aLeft
    ,  void *		aRight
) {
	return aLeft.fetch() != aRight;
}

inline BooleanVar operator== (
       GlobalStrongPtrVar&	aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft.fetch() == aRight.fetch();
}

inline BooleanVar operator!= (
       GlobalStrongPtrVar&	aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft.fetch() != aRight.fetch();
}

inline BooleanVar operator== (
       void *		aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft == aRight.fetch();
}

inline BooleanVar operator!= (
       void *		aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft != aRight.fetch();
}

inline BooleanVar operator== (
       GlobalStrongPtrVar&	aLeft
    ,  void *		aRight
) {
	return aLeft.fetch() == aRight;
}

inline BooleanVar operator!= (
       GlobalStrongPtrVar&	aLeft
    ,  void *		aRight
) {
	return aLeft.fetch() != aRight;
}

inline BooleanVar operator== (
       CheckedPtrVar&	aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft.fetch() == aRight.fetch();
}

inline BooleanVar operator!= (
       CheckedPtrVar&	aLeft
    ,  GlobalStrongPtrVar&	aRight
) {
	return aLeft.fetch() != aRight.fetch();
}

inline BooleanVar operator== (
       GlobalStrongPtrVar&	aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft.fetch() == aRight.fetch();
}

inline BooleanVar operator!= (
       GlobalStrongPtrVar&	aLeft
    ,  CheckedPtrVar&	aRight
) {
	return aLeft.fetch() != aRight.fetch();
}


#ifdef USE_INLINE
#include "opaquex.ixx"
#endif /* USE_INLINE */

// opaque2x.ixx is included explicitly by tofux.hxx after Heaper's inlines
// are defined.

#endif /* OPAQUEX_HXX */

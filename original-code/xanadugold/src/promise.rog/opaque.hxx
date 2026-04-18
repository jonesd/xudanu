/* ========================================================================== */
/**/
/*	Copyright (c) 1991-2 by Xanadu Operating Company, All Rights Reserved. */
/**/
/* ========================================================================== */
/**/
/* The information contained herein is confidential, proprietary to Xanadu */
/* Operating Company, and considered a trade secret as defined in section */
/* 499C of the penal code of the State of California. */
/**/
/* Use of this information by anyone other than authorized employees of */
/* Xanadu is granted only under a written nondisclosure agreement, */
/* expressly prescribing the scope and manner of such use. */
/**/
/* The above copyright notice is not to be construed as evidence of */
/* publication or the intent to publish. */
/**/
/* ========================================================================== */
/**/
/*				opaquex.hxx */
/**/
/*	This module allows the declaration of the inheritance relationship */
/*	of classes, and the definition of pointers-with-lots-of-behavior-to */
/*	instances of those classes, without exposing the implementation */
/*	of the classes to which the pointers point. */
/**/
/*	It is called "opaque" because such declarations-without-exposure */
/*	are said to be opaque. */
/**/
/* ========================================================================== */

#ifndef XU_OPAQUE_HXX
#define XU_OPAQUE_HXX

#include "compat.hxx"

class XuPtrVar;

class XuIntValueP;
class XuIntValue;

class XuCountedP;
class XuFakeNull;

#define XU_NULL ((XuFakeNull*)0)

class XuCategory;
class XuCategoryP;

class ostream;

#ifndef XU_VTABLE_OK
	class XuVtbl {};
#	define	XU_VTABLE_HACK(Class) \
		public: /* INTERNAL: vtable generation hack */ \
			Class (XuVtbl);
#	define XU_DEFINE_ROOT_VTABLE_HACK(Class) \
		Class::Class (XuVtbl) {}
#	define XU_DEFINE_VTABLE_HACK(Class,Base) \
		Class::Class (XuVtbl vtbl) : Base (vtbl) {}
#else
#	define XU_VTABLE_HACK(Class)
#	define XU_DEFINE_ROOT_VTABLE_HACK(Class)
#	define XU_DEFINE_VTABLE_HACK(Class,Base)
#endif /* XU_VTABLE_OK */

#define XU_PROLOGUE(Class)								\
  XU_VTABLE_HACK(Class) \
  public: /* INTERNAL: types */							\
    static XuCategoryP Cat;							\
  protected:									\
    virtual XuCategoryP getCategory ();						\
  private:
	

class XuCounted XU_ROOTCLASS {
    XU_PROLOGUE(XuCounted)
  public:
    virtual void printOn (ostream& oo);
    virtual void destroy ();
    XuBooleanVar isKindOf (XuCategoryP cat);
    static XuCounted * checkLocalCast (XuCategoryP cat, XuCountedP obj, XuIntVar source);

  private:
    XU_INLINE1 void incRefCt ();
    XU_INLINE1 void decRefCt ();

    /* out-of-line routine called by this->decRefCt() when myRefCt reaches zero */
    void refCtIsZero ();

    friend class XuPtrVar;

  protected:
    XuCounted ();
    virtual ~XuCounted ();

  private:
    XuIntVar myRefCt;
    friend class XuFakeNull;
};


class XuFakeNull : public XuCounted {
  public:
    virtual void printOn (ostream& oo);
    XuFakeNull ();

  protected:
    virtual void destroy ();
};


class XuPtrVar XU_ROOTCLASS {
  public:
    XuCounted * asPointer ();

    XU_INLINE1 XuBooleanVar operator== (XuFakeNull*) ;
    XU_INLINE1 XuBooleanVar operator!= (XuFakeNull*) ;

  protected:
    /* Brings down the world (with an assertion failure) if I'm behaving like a 
       NULL pointer now.  If it returns, it returns with a pointer to a valid XuCounted. */
    XU_INLINE1 XuCounted * deref () ;
    
    /* What assignments turn into */
    XU_INLINE1 void store (XuPtrVar& p);
    
    /* What no-arg constructors turn into */
    XU_INLINE1 XuPtrVar ();
    
    /* What Xu*P args constructors turn into */
    XU_INLINE1 XuPtrVar (XuPtrVar& p);
    
    /* What pointer-arg constructors turn into */
    XuPtrVar (XuCounted * p, XuTCS);
    
    XU_INLINE1 ~XuPtrVar ();
    
    /* What myValue points to to designate NULL (so that myValue->inc/decRefCt() is
       always safe */
    static XuFakeNull TheFakeNullCell;

  private:
    /* out-of-line assertion failure for this->deref(); */
    void derefNull () ;
    
    /* the actual pointer */
    XuCounted * myValue;
};


#define XU_DECLARE_DECLARE_PTRVAR(TYPE,COERCIONS_DECL)			\
									\
class XU_CAT(TYPE,P) : public XuPtrVar {				\
    public:								\
	XU_INLINE1 TYPE* operator-> ();					\
	XU_INLINE1 TYPE* operator-> () ;				\
	XU_INLINE1 TYPE& operator* ();					\
	XU_INLINE1 XU_CAT(TYPE,P)& operator= (XU_CAT(TYPE,P)& other);	\
	COERCIONS_DECL							\
	XU_INLINE1 XU_CAT(TYPE,P) ();					\
	XU_INLINE1 XU_CAT(TYPE,P) (XU_CAT(TYPE,P)& other);		\
	XU_INLINE1 XU_CAT(TYPE,P) (XuPtrVar& other, XuTCS);	\
	XU_INLINE1 XU_CAT(TYPE,P) (TYPE * other);			\
	XU_INLINE1 XU_CAT(TYPE,P) (XuFakeNull *);			\
};


#define XU_DEFINE_INLINE_PTRVAR(TYPE)			       		\
  									\
XU_INLINE1 TYPE * XU_CAT(TYPE,P)::operator-> ()				\
{									\
	return (TYPE*)this->deref();					\
}									\
									\
XU_INLINE1 TYPE * XU_CAT(TYPE,P)::operator-> () 			\
{									\
	return (TYPE*)this->deref();					\
}									\
									\
XU_INLINE1 TYPE& XU_CAT(TYPE,P)::operator* ()				\
{									\
	return *(TYPE*)this->deref();					\
}									\
									\
XU_INLINE1 XU_CAT(TYPE,P)& XU_CAT(TYPE,P)::operator= (XU_CAT(TYPE,P)& other) \
{									\
	this->store(other);						\
	return *this;							\
}									\
									\
XU_CAT(TYPE,P)::XU_CAT(TYPE,P) ()					\
       : XuPtrVar ()							\
{}									\
									\
XU_CAT(TYPE,P)::XU_CAT(TYPE,P) (XU_CAT(TYPE,P)& other)		\
       : XuPtrVar (other)						\
{}									\
									\
XU_CAT(TYPE,P)::XU_CAT(TYPE,P) (XuPtrVar& other, XuTCS)		\
       : XuPtrVar (other)						\
{}									\
									\
XU_CAT(TYPE,P)::XU_CAT(TYPE,P) (TYPE * other)				\
       : XuPtrVar ((XuCounted*)other, xuTCS)				\
{}									\
									\
XU_CAT(TYPE,P)::XU_CAT(TYPE,P) (XuFakeNull *)				\
       : XuPtrVar ()							\
{}


#ifdef XU_USE_INLINE1
#	define XU_DECLARE_PTRVAR(TYPE,CDECLS)				\
		XU_DECLARE_DECLARE_PTRVAR(TYPE,CDECLS)			\
		XU_DEFINE_INLINE_PTRVAR(TYPE)
#	define XU_DEFINE_PTRVAR(TYPE)
#else
#	define XU_DECLARE_PTRVAR(TYPE,CDECLS)				\
		XU_DECLARE_DECLARE_PTRVAR(TYPE,CDECLS)
#	define XU_DEFINE_PTRVAR(TYPE)					\
		XU_DEFINE_INLINE_PTRVAR(TYPE)
#endif /* XU_USE_INLINE1 */



/*
   ===========================================================================

	XU_TYPE_N(TYPE0,...,TYPEn-1); declare opaque pointers

   ========================================================================= 
*/


/* 
We break from our normal convention and include the definition
directly inside the declaration, because the macro hacking to follow
our convention just got too painful.  This means that these two
routines cannot be switched to be defined in only one compilation unit
(and so cannot be fully supported by most debuggers--try setting a
breakpoint in an inline routine).
*/

#define XU_COERCION(TYPE) 						\
      inline operator XU_CAT(TYPE,P) () 				\
	{								\
	    return XU_CAT(TYPE,P) (*this, xuTCS);			\
	}


#define XU_COERCION_1(C0)	/* no coercion for derived class */
#define XU_COERCION_2(C0,C1)						\
	XU_COERCION_1(C0)			XU_COERCION(C1)
#define XU_COERCION_3(C0,C1,C2)						\
	XU_COERCION_2(C0,C1)			XU_COERCION(C2)
#define XU_COERCION_4(C0,C1,C2,C3)					\
	XU_COERCION_3(C0,C1,C2)			XU_COERCION(C3)
#define XU_COERCION_5(C0,C1,C2,C3,C4)					\
	XU_COERCION_4(C0,C1,C2,C3) 		XU_COERCION(C4)
#define XU_COERCION_6(C0,C1,C2,C3,C4,C5) 				\
	XU_COERCION_5(C0,C1,C2,C3,C4)		XU_COERCION(C5)
#define XU_COERCION_7(C0,C1,C2,C3,C4,C5,C6) 				\
	XU_COERCION_6(C0,C1,C2,C3,C4,C5) 	XU_COERCION(C6)
#define XU_COERCION_8(C0,C1,C2,C3,C4,C5,C6,C7)				\
	XU_COERCION_7(C0,C1,C2,C3,C4,C5,C6)	XU_COERCION(C7)


#define XU_TYPE(C0,CDECLS)		 				\
	class	C0;							\
	class	XU_CAT(C0,P);						\
	XU_DECLARE_PTRVAR(C0,CDECLS);

#define XU_TYPE_1(C0)			XU_TYPE(C0,XU_COERCION_1(C0))
#define XU_TYPE_2(C0,C1)		XU_TYPE(C0,XU_COERCION_2(C0,C1))
#define XU_TYPE_3(C0,C1,C2)		XU_TYPE(C0,XU_COERCION_3(C0,C1,C2))
#define XU_TYPE_4(C0,C1,C2,C3)		XU_TYPE(C0,XU_COERCION_4(C0,C1,C2,C3))
#define XU_TYPE_5(C0,C1,C2,C3,C4)	XU_TYPE(C0,XU_COERCION_5(C0,C1,C2,C3,C4))
#define XU_TYPE_6(C0,C1,C2,C3,C4,C5)	XU_TYPE(C0,XU_COERCION_6(C0,C1,C2,C3,C4,C5))
#define XU_TYPE_7(C0,C1,C2,C3,C4,C5,C6)	XU_TYPE(C0,XU_COERCION_7(C0,C1,C2,C3,C4,C5,C6))
#define XU_TYPE_8(C0,C1,C2,C3,C4,C5,C6,C7)				\
					XU_TYPE(C0,XU_COERCION_8(C0,C1,C2,C3,C4,C5,C6,C7))

#define XU_DEFINE_TYPE(C0,C1)	 					\
	XU_DEFINE_PTRVAR(C0);						\
	XuCategoryP C0::getCategory ()					\
	{								\
		return C0::Cat;						\
	}								\
	XuCategoryP C0::Cat = XuCategory::make (&C1::Cat, XU_STR(C0));	\
	XU_DEFINE_VTABLE_HACK(C0,C1)



#include "opaque.oxx"
#include "opaquep.oxx"


#ifdef XU_USE_INLINE1
#	include "opaque.ixx"
#endif /* XU_USE_INLINE1 */

#endif /* XU_OPAQUE_HXX */

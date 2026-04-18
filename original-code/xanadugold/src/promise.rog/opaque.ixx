/* ========================================================================== */
/**/
/*	Copyright (c) 1988, 1989, 1991 by Xanadu Operating Company, All */
/*	Rights Reserved. */
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


#ifndef XU_OPAQUE_IXX
#define XU_OPAQUE_IXX

XU_INLINE1 void XuCounted::incRefCt ()
{
    myRefCt++;
}

XU_INLINE1 void XuCounted::decRefCt ()
{
    if (--myRefCt == 0) {
	this->refCtIsZero ();
    }
}

XU_INLINE1 XuBooleanVar XuPtrVar::operator== (XuFakeNull*) 
{
    return myValue == &XuPtrVar::TheFakeNullCell;
}

XU_INLINE1 XuBooleanVar XuPtrVar::operator!= (XuFakeNull*) 
{
    return myValue != &XuPtrVar::TheFakeNullCell;
}

XU_INLINE1 XuCounted * XuPtrVar::deref () 
{
    if (*this == XU_NULL) {
	this->derefNull ();
    }
    return myValue;
}

XU_INLINE1 void XuPtrVar::store (XuPtrVar& p)
{
    XuCounted * t = p.myValue;
    t->incRefCt();
    myValue->decRefCt();
    myValue = t;
}

XU_INLINE1 XuPtrVar::XuPtrVar ()
{
    myValue = &XuPtrVar::TheFakeNullCell;
}

XU_INLINE1 XuPtrVar::XuPtrVar (XuPtrVar& p)
{
    myValue = p.myValue;
    myValue->incRefCt();
}

XU_INLINE1 XuPtrVar::~XuPtrVar ()
{
    myValue->decRefCt();
}

#endif /* XU_OPAQUE_IXX */

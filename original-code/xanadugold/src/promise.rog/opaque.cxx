/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */


#include <assert.h>

#include "opaque.hxx"
#include "opaque.ixx"
#include "opaquep.hxx"
#include "xanadu.hxx"
#include "xanadu.h"

#include <assert.h>
#include <stream.h>

XU_DEFINE_PTRVAR(XuCounted);

XU_DEFINE_ROOT_VTABLE_HACK(XuCounted)

XuCategoryP XuCounted::getCategory () 
{
    return XuCounted::Cat;
}

XuCategoryP XuCounted::Cat = XuCategory::make (NULL, "XuCounted");

void XuCounted::printOn (ostream& oo)
{
    oo << "<a thing>";
}

void XuCounted::destroy ()
{
    delete this;
}

XuBooleanVar XuCounted::isKindOf (XuCategoryP cat)
{
    return this->getCategory()->isEqualOrSubTypeOf (cat);
}

XuCounted * XuCounted::checkLocalCast (XuCategoryP cat, XuCountedP obj, XuIntVar source)
{
    /* didn't use && to avoid need for crutch */
    if (obj != XU_NULL) {
	if (! obj->isKindOf (cat)) {
	    xuError (XU_CAST_VIOLATION_PROBLEM, source);
	}
    }
    return obj.asPointer();
}

void XuCounted::refCtIsZero ()
{
    this->incRefCt (); /* to prevent infinite recursion if destruction code uses PtrVars */
    this->destroy();
}

XuCounted::XuCounted ()
{
    myRefCt = 0;
}

XuCounted::~XuCounted ()
{}

void XuFakeNull::printOn (ostream& oo)
{
    oo << "XuFakeNull()";
}

XuFakeNull::XuFakeNull ()
{}

void XuFakeNull::destroy ()
{
    this->myRefCt = 32000;
}

XuCounted * XuPtrVar::asPointer ()
{
    if (*this == XU_NULL) {
        return NULL;
    } else {
	return myValue;
    }
}

XuPtrVar::XuPtrVar (XuCounted * p, XuTCS)
{
    myValue = p;
    if (myValue == NULL) {
	myValue = &XuPtrVar::TheFakeNullCell;
    }
    myValue->incRefCt();
}

void XuPtrVar::derefNull () 
{
    assert(*this != XU_NULL);
}

XuFakeNull XuPtrVar::TheFakeNullCell;

	
XU_DEFINE_TYPE(XuCategory,XuCounted)

XuBooleanVar XuCategory::isEqualOrSubTypeOf (XuCategoryP other) 
{
    XuCategoryP cat = this;
    while (cat != NULL) {
	if (cat.asPointer() == other.asPointer()) {
	    return TRUE;
	}
	cat = cat->fetchSuperCat ();
    }
    return FALSE;
}

XuCategory::XuCategory (XuCategoryP * XU_OR_NULL superPP, XuStringVar name)
{
    mySuperCatPP = superPP;
    myName = name;
}

XuCategoryP XuCategory::make (XuCategoryP * XU_OR_NULL superPP, XuStringVar name)
{
    return new XuCategory (superPP, name);
}

XuStringVar XuCategory::name () {
	return myName;
}

XuCategoryP XU_OR_NULL XuCategory::fetchSuperCat ()
{
    if (mySuperCatPP == NULL) {
	return XU_NULL;
    } else {
	return * mySuperCatPP;
    }
}

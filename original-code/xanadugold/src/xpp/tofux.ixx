#ifndef TOFUX_IXX
#define TOFUX_IXX

/* $Id: tofux.ixx,v 2.9 1993/03/01 21:35:40 eric Exp $ */

/* ======================= Tofu =========================== */

INLINE Tofu::Tofu () {
}

/* ====================== Heaper ========================== */

INLINE Heaper::Heaper () {
    myOop = 0;
}

INLINE Heaper::~Heaper () {
}

/* ======================= Heaper Class Changing =========================== */

INLINE void Heaper::changeClassToThatOf (Heaper * anInstance)
{

    /* This struct is only guaranteed to work for cfront compilers.
        We need to see what Zortech does. */
    struct vtblHack
    {
        Int32 myMarked;
        void* vtblPtr;
    };
    ((struct vtblHack*) this)->vtblPtr =
    	((struct vtblHack*) anInstance)->vtblPtr;
}


/* ===================== Category ========================= */

INLINE BooleanVar Category::isEqualOrSubclassOf (Category * aCategory)
{
  return this == aCategory
    || (aCategory->myPreorderNumber <= myPreorderNumber
	&& myPreorderNumber <= aCategory->myDescendantsMax);
}

INLINE Int32 Category::preorderNumber () {
  return myPreorderNumber;
}

INLINE size_t Category::totalSize () {
  return myTotalSize;
}

/* ======================= misc =========================== */

#ifdef HIGHC
INLINE void * operator new (size_t s, void * p) {
	return p;
}
#endif

#endif /* TOFUX_IXX */

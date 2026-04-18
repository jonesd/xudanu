#ifndef SCAVT_HXX
#define SCAVT_HXX

/* $Id$ */

#include "tofux.hxx"
#include "scavx.hxx"
#include "scavp.hxx"
#include "scavt.oxx"
#include "wparrayx.hxx"

/* This cons cell type has side effecting methods so that store checking
   for OldSpace can be tested for non-array types */

class TConsCell : public Heaper {
    CONCRETE(TConsCell)
    AUTO_GC(TConsCell)

 public:
    static RPTR(TConsCell) cons (APTR(TConsCell) car, APTR(TConsCell) cdr);

    INLINE RPTR(TConsCell) car () {
	return myCar;
    }

    INLINE RPTR(TConsCell) cdr () {
	return myCdr;
    }

    INLINE void setCar (APTR(TConsCell) car) {
	myCar = car;
    }

    INLINE void setCdr (APTR(TConsCell) cdr) {
	myCdr = cdr;
    }

    INLINE Int32 token () {
	return myToken;
    }

    TConsCell (APTR(TConsCell) car, APTR(TConsCell) cdr);

    void printOn (ostream& oo);

 private:
    CHKPTR(TConsCell) myCar;
    CHKPTR(TConsCell) myCdr;
    Int32 myToken;

    static Int32 NextToken;

    friend class ScavengerTester;	// to get addresses of ivars
};

class ScavengeTestExecutor : public XnExecutor {
    CONCRETE(ScavengeTestExecutor)
    NO_GC(ScavengeTestExecutor)
 public:
    static RPTR(XnExecutor) make (Int32 arrayID);

    virtual void execute (Int32 estateIndex);

    ScavengeTestExecutor (Int32 arrayID) {
	myArrayID = arrayID;
    }

 private:
    Int32 myArrayID;
};

class ScavengerTester ROOTCLASS {
 private:
    static void printRememberSetOn (ostream& oo,
				    Heaplet * heap,
				    Heaper * obj = NULL);
    static void printArraySetOn (ostream& oo,
				 Heaplet * heap,
				 Heaper * obj = NULL);
    static void printWeakArraySetOn (ostream& oo,
				     Heaplet * heap,
				     Heaper * obj = NULL);
 public:
    static void testHeaplet1On (ostream& oo);
    static void testHeaplet2On (ostream& oo);
    static void testMigrate1On (ostream& oo);
    static void testPtrArrayMigrate1On (ostream& oo);
    static void testStoreCheck1On (ostream& oo);
    static void testStoreCheck2On (ostream& oo);
    static void testWeakArrayOn (ostream& oo);
};

#endif /* SCAVT_HXX */





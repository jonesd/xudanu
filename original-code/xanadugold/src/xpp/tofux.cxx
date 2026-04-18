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
//
//	Changed Transceiver to Xcvr, part of Xcvr reorganization
//		-michael Jun 14 1990
//
//	Exposed sendSelfTo() and makeProxy()
//	Killed sendThingTo() and makeProxyFunc()
//	Removed remaining traces of actualSize()
//		- michael Jun 30 1990
//
//	Merging my changes into wjr's version, which has diverged significantly
//	from alpha-6.
//		- michael Jul 13 1990
//      Removed obsolete Heaper::makeProxy method. Added new
//      Heaper::sendProxyTo method.
//              - wjr Jul 22 1990
//
//      Added Heaper::isByProxy
//              -wjr Jul 26 1990
//
//	Remerged hill's alpha-6 and (wjr/michael)'s alpha-6
//	Non-RPC cases have been removed here.
//		- ech Jul 31 1990
//
//	New constructor bomb stuff
//
//	Made CheckedPtrVar into root class & removed unused comm stuff from
//	CheckedPtrVar.
//		- ech Aug 6 1990
//
//	Retired BABY_THROWN_OUT_WITH_BATH_WATER error, since it incorrectly
//	  judged some situations to be bad.  See Heaper::~Heaper()
//	Retired obsolete routine to sort array of Heaper ptrs by hash value.
//	  (Couldn't even remember how it was used, but know I wrote it)
//		- ech Aug 16 1990
//
//	Started on changes for supporting become:
//	    Size info in Categories
//	    Passing Categories from the CONSTRUCT macros
//		- msm - Aug 8 1990
//
//	Merged above from Markm
//		-ech Sep 1 1990
//
//	Added CONSTRUCT_ON(), RETURN_CONSTRUCT_ON() macros,
//	and a supporting Heaper::operator new()
//		- michael Oct 21 1990  (again Nov 5)
//
//	Got bored with "merged from/with" comments
//		- ech Nov 9 1990
//
//	Renamed fakeGetCategory() to getConcreteCategory()
//		- michael Nov 13 1990
//
//	Changed hashForEqual return type unsigned long -> UInt32
//	(Also hashedName and argument to findCategory(hashedName))
//		- michael Nov 18 1990
//
//	Made Category into a Heaper subclass mindful of the coming removal
//	of EQObject.  Also gave it its own isEqual
//		- ech Nov 30 1990
//
//	Eliminated becomeDestruct()
//		- michael Dec  4 1990
//
//      removed EQObject while merging changes from ech and michael
//      from Oct 21 through December 4
//              - cth   Dec 12
//
//	Added #ifndef NO_RPC around Heaper::<various proxy methods>
//		- ech 1991
//
//	Added UnconstructedHeaper stuff to some Heaper::operator new()s,
//	to prevent crashing if an argument expression to a constructor
//	BLAST()s.
//		- michael Jul 21 1992

#include "tofup.hxx"

#ifdef GNU
 TCSJ tcsj;
 XCSJ xcsj;
 //VTBL VTBL_HACK;// ZZZroger oct 1995
#endif
VERSION_ID(tofux_cxx,
	   "$Id: tofux.cxx,v 2.19 1993/03/24 02:48:27 eric Exp $")

#include "intvarx.hxx"
#include "fhashx.hxx"
#include "allocx.hxx"
#include "initx.hxx"
#include "choosex.hxx"

PERMIT(N,"ALL")
#include <stream.h>
#include <string.h>
PERMIT(0,"ALL")

#include "tofux.ixx"

#include "tofux.sxx"
#include "tofup.sxx"


extern "C" {
  void __pure_virtual_called (Heaper * that);
};

REQUIRE(1,"local static variable")
void __pure_virtual_called (Heaper * that)
{
  static int recursionDepth = 0;
  if (recursionDepth) {
    BLAST(PURE_VIRTUAL);
  }
  recursionDepth++;
  cerr << "\n__pure_virtual_called (" << that << ")\n";
  recursionDepth--;
  BLAST(PURE_VIRTUAL);
}
PERMIT(0,"local static variable")

/* =======================================================================

		Class Tofu

   ======================================================================= */

#ifdef HIGHC // for bug
static Category secret_Tofu =
		Category::make (&secret_Tofu, "Tofu", sizeof (Tofu), NULL);
#else
static Category secret_Tofu =
    Category ("Tofu", sizeof (Tofu), NULL);
#endif
Category * cat_Tofu = &secret_Tofu;


Tofu::Tofu(VTBL) { /* empty */ }

Category * Tofu::getCategory () CONST
{
    return cat_Tofu;
}

BooleanVar Tofu::isKindOf (Category * aCategory) CONST
{
    return this->getCategory()->isEqualOrSubclassOf (aCategory);
}

void Tofu::migrate (void* /* origin */,
		    BooleanVar /* destinationIsOld */)
{}

/* =======================================================================

		Class Heaper

   ======================================================================= */

/* =============== Heaper testing =============== */

UInt32 Heaper::TheOopCounter = 1;

UInt32 Heaper::takeOop () {
    if (TheOopCounter == 0) {
	TheOopCounter = 1;
    }
    return TheOopCounter++;
}

BooleanVar Heaper::isEqual (APTR(Heaper))
     RUN_TIME_DEFERRED_FUNC;

UInt32 Heaper::hashForEqual () {
    if (myOop == 0) {
	myOop = this->actualHashForEqual ();
    }
    return myOop;
}

UInt32 Heaper::actualHashForEqual ()
//    RUN_TIME_DEFERRED_FUNC;
{
return ((UInt32) getCategory());
}
/* ============== Heaper printing ================= */

REQUIRE(4,"reference")
void Heaper::printOn (ostream& oo)
{
    oo << this->getCategory()->name() << "(";
    do {
        INSTALL_SHIELD(pr);
        SHIELD_UP_BEGIN(pr,AllBlastsFilter) {
            oo << "***PRINT BLASTED***";
            break;
        } SHIELD_UP_END(pr);
        this->printContentsOn(oo);
    } while (FALSE);
    oo << ")";
}

void Heaper::printContentsOn (ostream& oo)
{
    oo << "????";
}

ostream& operator<< (ostream& oo, Heaper * item)
{
	if (item) {
	    item->printOn (oo);
	} else {
		oo << "NULL";
	}
    return oo;
}
PERMIT(0,"reference")

/* =============== Heaper non-assignment =========== */

REQUIRE(2,"reference")
Heaper& Heaper::operator= (Heaper&)
{
    BLAST(OBJECT_ASSIGNMENT_NOT_ALLOWED);
    return *this;
}
PERMIT(0,"reference")

/* ================ Heaper allocation ============== */

void * Heaper::operator new (size_t /*s*/)
{
  BLAST(MEM_ALLOC_ERROR);
  return NULL;
}

// called a bunch---INLINE
void * Heaper::operator new (size_t s, void * storage)
{
// !!!! hack: knownBug: removed test because of problem with comm /ravi/7/23/92
//    if (*(Int32*)storage 
//	    && ((Heaper*)storage)->getCategory()->totalSize() < s) {
//	BLAST(BECOME_TOO_SMALL);
//    }
#ifdef HIGHC
    ((Heaper*)storage)->~Heaper(); // make old behavior go away.
#else
    ((Heaper*)storage)->Heaper::~Heaper(); // make old behavior go away.
#endif
    return storage;
}

void * Heaper::operator new (size_t s,
			     XCSJ,
			     Category * cat)
{
    Heaplet::initialize ();
    size_t size = cat->totalSize ();

//#ifndef NDEBUG
    if (s > size) {
	BLAST(MEM_ALLOC_ERROR);
    }
    if (size == 0) {
	BLAST(MEM_ALLOC_ERROR);
    }
//#endif /* NDEBUG */

    /* !!!! Allocation stats collection */
    /*    cat->moreOfThem(); */

    void * result = Heaplet::allocate(size);
    new(result) UnconstructedHeaper();	// Don't crash if ctor arg BLAST()s
    return result;
}

void * Heaper::operator new (size_t s,
			     AllocType type,
			     XCSJ,
			     Category * cat)
{
    Heaplet::initialize ();
    size_t size = cat->totalSize ();

//#ifndef NDEBUG
    if (s > size) {
	BLAST(MEM_ALLOC_ERROR);
    }
    if (size == 0) {
	BLAST(MEM_ALLOC_ERROR);
	size = s;
    }
//#endif /* NDEBUG */

    /* !!!! Allocation stats collection */
    /* cat->moreOfThem(); */

    void * result;
    if (type == YOUR_CHOICE) {
	result = Heaplet::allocate(size);
    } else {
	/* ::operator new returns storage after a zero word.  We use
	the storage starting at, not after the zero for Heapers. */
	result = (UInt32*) ::operator new(size);
    }

    new(result) UnconstructedHeaper();	// Don't crash if ctor arg BLAST()s
    return result;
}

void Heaper::operator delete (void* p)
{
    if (!Heaplet::isScavengeable(p)) {
#ifdef HIGHC
	delete p;
#else
	::operator delete (p);
#endif
    }
}

/* ===================== Heaper finalization ============= */

void Heaper::destroy ()
{
#ifdef HIGHC
    PLANT_DOOMSDAY_BOMB();
    ARM_DOOMSDAY_BOMB();
#endif

    SPTR(Heaper) self = this;
    this->destruct();
    Heaper::operator delete (this);
}

void Heaper::destruct ()
{
    /* Category * cat = this->getCategory();
       if (cat != cat_Heaper) {
	   this->getCategory()->lessOfThem();
       }
    */
#ifdef HIGHC
    this->~Heaper();
#else
    this->Heaper::~Heaper();
#endif
}


/* =====================================================================

		Class Category

   ===================================================================== */

static UInt32 hashOfName (char * name)
{
    return fastHash (name);
}

Category * Category::HashTable[CAT_HASH_TABLE_SIZE];

CategoryList * Category::Becomables = NULL;

static BooleanVar printBecomeDebugInfoFlag = FALSE;


BooleanVar Category::isEqual (APTR(Heaper) other)
{
  return this == other;
}

UInt32 Category::actualHashForEqual ()
{
  return hashOfCategoryName;
}

UInt32 Category::hashedName ()
{
  return hashOfCategoryName;
}

char * Category::name ()
{
    return nameOfCategory;
}

Category * Category::nextHashCategory () {
  return nextHashed;
}

Category * Category::fetchSuperCategory () {
  return baseCategory;
}

Category * Category::getSuperCategory () {
  if (!baseCategory) {
    BLAST(NO_SUPER_CATEGORY);
  }
  return baseCategory;
}

Int32 Category::preorderMax () {
  return myDescendantsMax;
}

/* become support */


void Category::mayBecome (Category * cat)
{
    if (printBecomeDebugInfoFlag) {
      cerr << this->name() << "->mayBecome (" << cat->name() << ");\n";
    }
    myMayBecomes = categoryList (cat, myMayBecomes);
    PERMIT(1,"assignment to global variable")
    Category::Becomables = categoryList (this, Category::Becomables);
}

void Category::mayBecomeAnySubclassOf (Category * cat)
{
  if (printBecomeDebugInfoFlag) {
    cerr << this->name()
    	 << "->mayBecomeAnySubClassOf (" << cat->name() << ");\n";
  }
  this->mayBecome (cat);
  for (cat = cat->myFirstChild; cat; cat = cat->myNextSibling) {
    this->mayBecomeAnySubclassOf (cat);
  }
}


BooleanVar Category::canYouBecome (Category * cat)
{
    for (CategoryList * cl = myMayBecomes; cl; cl = cl->fetchRest()) {
	if (cl->first()->isEqual (cat)) {
	    return TRUE;
	}
    }
    if (!baseCategory) {
	return FALSE;
    } else {
	return baseCategory->canYouBecome (cat);
    }
}

size_t Category::objectSize ()
{
    return myObjectSize;
}

/* Manual comm stuff to take advantage of direct support in xmtrs. */

#include "xfrspecx.hxx"

void Category::sendSelfTo (APTR(Xmtr) xmtr) {
  CAST(SpecialistXmtr,xmtr)->sendCategory(this);
}

void Category::registerWithParent ()
{
    if (baseCategory) {
	myNextSibling = baseCategory->registerChild (this);
    }
}

Category * Category::registerChild (Category * cat)
{
    Category * result;
    result = myFirstChild;
    myFirstChild = cat;
    return result;
}

UInt32 Category::preorder (UInt32 mine)
{
    myPreorderNumber = mine;
    if (myFirstChild == NULL) {
	myDescendantsMax = mine;
    } else {
	myDescendantsMax = myFirstChild->preorder (mine + 1);
    }
    if (myNextSibling == NULL) {
	return myDescendantsMax;
    } else {
	return myNextSibling->preorder (myDescendantsMax + 1);
    }
}


BooleanVar Category::calculateObjectSize ()
{
    BooleanVar result = FALSE;
    if (printBecomeDebugInfoFlag) {
      cerr << this->name() << "->calculateObjectSize();\n";
    }
    for (CategoryList * cl = myMayBecomes; cl; cl = cl->fetchRest()) {
        cl->first ()->checkSuperObjectSize ();
	if (myObjectSize < cl->first()->objectSize ()) {
	    if (printBecomeDebugInfoFlag) {
	      cerr << this->name() << " enlarged to "
		<< cl->first()->name() << "\n";
	    }
	    result = TRUE;
	    myObjectSize = cl->first()->objectSize ();
	}
    }
    myTotalSize = myObjectSize;
    return result;
}

void Category::checkSuperObjectSize ()
{
    for (Category * cat = this->baseCategory; cat; cat = cat->baseCategory) {
	if (myObjectSize < cat->objectSize ()) {
	    if (printBecomeDebugInfoFlag) {
	      cerr << this->name() << " enlarged up to "
		<< cat->name() << "\n";
	    }
	    myObjectSize = cat->objectSize ();
	}
    }
}

Category * Category::fetchNextPreOrder () {
  if (myFirstChild != NULL) {
    return myFirstChild;
  }
  for (Category * next = this; next; next = next->fetchSuperCategory ()) {
    if (next->myNextSibling != NULL) {
      return next->myNextSibling;
    }
  }
  return NULL;
}

PERMIT(1,"reference")
void Category::printInsideOn (ostream& oo)
{
    oo << "\"" << nameOfCategory << "\", ";
    if (baseCategory) {
	oo << "cat_" << baseCategory->name();
    } else {
	oo << "NULL";
    }
}

void Category::printNodeOn (ostream& oo, UInt32 indentation /* = 0 */) {
  while (indentation--) {
    oo << ' ';
  }
  oo << this->name ()
    << " size " << mySelfSize
    << '/' << myObjectSize
    << '/' << myTotalSize;
  if (this->myMayBecomes != NULL) {
    cerr << " becomes ";
    this->myMayBecomes->printOn (cerr);
  }
}

void Category::printTreeOn (ostream& oo, UInt32 indentation /* = 0 */) {
  this->printNodeOn (oo, indentation);
  oo << '\n';
  for (Category * sub = this->myFirstChild; sub; sub = sub->myNextSibling) {
    sub->printTreeOn (oo, indentation + 2);
  }
}

Category::Category (char *name, size_t selfSize, Category * superCategory)
{
    nameOfCategory = name;
    baseCategory = superCategory;

    myFirstChild = NULL;
    myNextSibling = NULL;
    myPreorderNumber = Int0;
    myDescendantsMax = 0;

    UInt32 hashVal = hashOfName (name);
    hashOfCategoryName = hashVal;
    nextHashed = Category::HashTable[hashVal % CAT_HASH_TABLE_SIZE];
    Category::HashTable[hashVal % CAT_HASH_TABLE_SIZE] = this;

    for (Category * cat = nextHashed; cat; cat = cat->nextHashed) {
	if (cat->hashOfCategoryName == hashOfCategoryName) {
	    cerr << name << " hash to "
	      << hashOfCategoryName << " collided with "
		<< cat->nameOfCategory << "\n";
	    BLAST(HASH_COLLISION);
	}
    }

    mySelfSize = selfSize;
    myObjectSize = selfSize;
    myTotalSize = selfSize;
    myMayBecomes = NULL;

    numAllocated = numFreed = numOutstanding = maxOutstanding;
}

/*
		Allocation statistics stuff
*/

void Category::moreOfThem()
{
    ++numAllocated;
    ++numOutstanding;
    if (numOutstanding > maxOutstanding) {
	maxOutstanding = numOutstanding;
    }
    if (this != cat_Tofu) {
	baseCategory->moreOfThem();
    }
}

void Category::lessOfThem()
{
    ++numFreed;
    --numOutstanding;
    if (this != cat_Tofu) {
	baseCategory->lessOfThem();
    }
}

void Category::dumpStatistics(Int32 depth)
{
    if (numAllocated) {
	for (Int32 i = 0; i < depth; i++) {
	    cerr << " ";
	}
	cerr << this->name() << ", size " << this->totalSize()
	<< ": +" << numAllocated
	<< ", -" << numFreed << ", max " << maxOutstanding << "\n";
    }
    if (myFirstChild != NULL) {
	myFirstChild->dumpStatistics(depth + 4);
    }
    if (myNextSibling) {
	myNextSibling->dumpStatistics(depth);
    }
}

BEGIN_EXIT_TIME(Category,exitTimeNonInherited) {
/*    cat_Tofu->dumpStatistics(0);*/
} END_EXIT_TIME(Category,exitTimeNonInherited);

Category * Category::find (char * categoryName)
{
    Category * result = Category::find (hashOfName (categoryName));
    if (strcmp (result->name(), categoryName) != 0) {
	BLAST(CATEGORY_NOT_FOUND);
    }
    return result;
}

Category * Category::find (UInt32 hashedCategoryName) {
  Category * cat =
  	Category::HashTable[hashedCategoryName % CAT_HASH_TABLE_SIZE];
  for (; cat; cat = cat->nextHashCategory()) {
    if (hashedCategoryName == cat->hashedName()) {
      return cat;
    }
  }
  BLAST(CATEGORY_NOT_FOUND);
  return NULL;
}

/* ================ Category initialization ================ */

void initializeCategoryInformation () {
  Category::preorderCategories ();
  Category::registerAllBecomes ();
  Category::calculateObjectSizes ();
}

void Category::preorderCategories () {
  // tell all classes to register with their supers and then
  // number them in pre-order for fast subclass checks
  for (UInt32 i = 0; i < CAT_HASH_TABLE_SIZE; i++) {
    for (Category * cat = Category::HashTable[i];
	 cat != NULL;
	 cat = cat->nextHashCategory()) {
       cat->registerWithParent ();
     }
  }
  cat_Tofu->preorder (1);
}

void Category::registerAllBecomes () {
  /* check for printing debug info for become */
  int ac = mainAC();
  char ** av = mainAV();
  for (int i = 0; i < ac; i++) {
    if (strcmp (av[i], "verbose-test-become") == 0) {
      printBecomeDebugInfoFlag = TRUE;
      cerr << "testing become\n";
    }
  }

  for (BecomeIniter * b = BecomeIniter::allIniters(); b; b = b->fetchNext ()) {
    if (printBecomeDebugInfoFlag) {
      cerr << "registering " << b->becomeable()->name()
	<< " -> " << b->becomee()->name() << "\n";
    }
    b->registerBecome();
  }
}

void Category::calculateObjectSizes ()
{
  // calculate the size of all the objects with becomes
  BooleanVar changeFlag;
  if (printBecomeDebugInfoFlag) {
    cerr << "calculateObjectSizes();\n";
  }
  do {
    changeFlag = FALSE;
    for (CategoryList * cl = Category::Becomables; cl; cl = cl->fetchRest()) {
      changeFlag |= cl->first()->calculateObjectSize();
    }
    if (printBecomeDebugInfoFlag) {
      cerr << "\n";
    }
  } while (changeFlag);
  for (UInt32 i = 0; i < CAT_HASH_TABLE_SIZE; i++) {
    Category * cat = Category::HashTable[i];
    for (; cat; cat = cat->nextHashCategory()) {
      cat->checkSuperObjectSize();
    }
  }
}


/* ================================================================ **

   Become support classes

** ================================================================ */

BecomeIniter * BecomeIniter::AllIniters = NULL;

BecomeIniter * BecomeIniter::allIniters () {
    return BecomeIniter::AllIniters;
}

BecomeIniter::BecomeIniter (Category * becomeable, Category * becomee) {
  myBecomeable = becomeable;
  myBecomee = becomee;
  myNextBecomeIniter = BecomeIniter::AllIniters;
  BecomeIniter::AllIniters = this;
}

Category * BecomeIniter::becomeable () {
  return myBecomeable;
}

Category * BecomeIniter::becomee () {
  return myBecomee;
}

BecomeIniter * BecomeIniter::fetchNext () {
  return myNextBecomeIniter;
}

void MayBecomeIniter::registerBecome () {
  this->becomeable ()->mayBecome (this->becomee ());
}

#ifdef HIGHC
MayBecomeIniter * MayBecomeIniter::make (Category * becomeable,
					 Category * becomee) {
	MayBecomeIniter * result = (MayBecomeIniter *)
		new char [sizeof (MayBecomeIniter)];
	new (result) MayBecomeIniter (becomeable, becomee);
	return result;
}
#endif

MayBecomeIniter::MayBecomeIniter (Category * becomeable, Category * becomee)
  : BecomeIniter (becomeable, becomee) {
}

void MayBecomeAnySubclassOfIniter::registerBecome () {
  this->becomeable ()->mayBecomeAnySubclassOf (this->becomee ());
}

#ifdef HIGHC
MayBecomeAnySubclassOfIniter *
MayBecomeAnySubclassOfIniter::make (Category * becomeable, Category * becomee) {
	MayBecomeAnySubclassOfIniter * result = (MayBecomeAnySubclassOfIniter *)
		new char [sizeof (MayBecomeAnySubclassOfIniter)];
	new (result) MayBecomeAnySubclassOfIniter (becomeable, becomee);
	return result;
}
#endif

MayBecomeAnySubclassOfIniter::MayBecomeAnySubclassOfIniter
	(Category * becomeable, Category * becomee)
  : BecomeIniter (becomeable, becomee) {
}

/* ========================================================================== */
//
//		checkCast(): Support for CAST() macro
//
//	Check whether cast is safe.  If not:
//		do a BLAST(), using the file and line numbers of the CAST()
//
/* ========================================================================== */

extern Category* cat_WeakPtrArray;

RPTR(Heaper) checkCast (
	  Category *	argCategoryObject
	, Heaper *	argObject
#ifdef	BOMB_REPORT_LINE
	, CONST char *	argFileName
	, CONST int	argLineNumber
#endif	/* BOMB_REPORT_LINE */
)
{
    if (!argObject) {
        return NULL;
    }
    if (!argObject->isKindOf (argCategoryObject)) {
	cerr << "Exception: "		// !!!! debug
	     << argObject
	     << " isn't a kind of "
	     << argCategoryObject->name()
	     << "\n";
	cerr << "It's actually a "
	     << argObject->getCategory()->name()
	     << "\n";
#ifdef	BOMB_REPORT_LINE
	cerr << "At file = "	<< argFileName
	     << ", line = "	<< argLineNumber
	     << "\n";
#endif	/* BOMB_REPORT_LINE */
	BLAST_FROM_THE_PASSED(UNSAFE_CAST, 1, argFileName, argLineNumber);
    }
    return argObject;
}


/* ======================= Var ============================================*/

/* definition of standard C routine for accessing category names */

char *getCategoryName( void *oop )
{
	PERMIT(1,"hard cast")
	Category *cat = CAST(Heaper,(Heaper *) oop)->getCategory();

	return cat->name();
}


/* ======================= Stubble definitions =========================== */

void Tofu::sendSelfTo (Xmtr *) /*CONST*/
{
  cerr << "Tofu::sendSelfTo wanted to be "
    << this->getCategory()->name() << "::sendSelfTo\n";
    RUN_TIME_DEFERRED_SUBR;
}

BooleanVar Tofu::isShepherd()
{
	return FALSE;
}

/* ================== CategoryList ==================================== */

Category * CategoryList::first ()
{
    return myFirst;
}

CategoryList * CategoryList::fetchRest ()
{
    return myRest;
}

void CategoryList::printOn (ostream& oo) {
  oo << "{";
  for (CategoryList * cl = this; cl; cl = cl->fetchRest ()) {
    oo << cl->first()->name();
    if (cl->fetchRest ()) {
      oo << ", ";
    }
  }
  oo << "}";
}

CategoryList::CategoryList (Category * first, CategoryList * rest /*= NULL*/)
{
    myFirst = first;
    myRest = rest;
}

CategoryList * categoryList (Category * first, CategoryList * rest /*= NULL*/)
{
    return new CategoryList (first, rest);
}

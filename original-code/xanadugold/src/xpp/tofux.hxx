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
//	Hacked for Transceiver -> Xcvr mod
//		- michael Jun 14 1990
//
//	Eliminated SELF_COPY
//		- michael Jun 28 1990
//
//	Exposed sendSelfTo() and makeProxy()
//	Killed sendThingTo() and makeProxyFunc()
//	Removed remaining traces of actualSize()
//		- michael Jun 30 1990
//
//	Merged to wjr''s alpha-6, which has diverged significantly
//	from hill''s alpha-6 version.
//		- michael Jun 30 1990
//
//      Removed declarations for Heaper::makeProxy (obsolete). Replaced 
//      them with declarations for new Heaper::sendProxyTo message.
//              - wjr Jul 22 1990
//
//      Added declarations for getProxyCategory and isByProxy.
//              - wjr Jul 26 1990
//
//	Remerged hill''s alpha-6 and (wjr/michael)''s alpha-6
//	Non-RPC cases have been removed here.
//		- ech Jul 31 1990
//
//	New constructor bomb stuff
//
//	Made CheckedPtrVar into root class & removed unused comm stuff from
//	CheckedPtrVar.
//		- ech Aug 6 1990
//
//	Started on changes for supporting become:
//	    Size info in Categories
//	    Passing Categories from the CONSTRUCT macros
//		- msm - Aug 8 1990
//
//	Removed Var
//		- msm - Aug 14 1990
//
//	Merged previous two comments+stuff from Markm
//		- ech Sep 1 1990
//
//	Merged markm''s sep19 changes.
//	Introduced "destruct" as replacement for C++ destructors.
//		- ech Sep 25 1990
//
//	Merged markm''s sep19 changes: [into michael''s working copy -ech]
//	 - turned off PRIVATE_PROTECTED_KLUDGE
//	 - made Heaper() and ~Heaper() protected:
//	 - made (Garbage)Heap a friend class of Heaper.
//		- michael Sep 29 1990
//
//	Added CONSTRUCT_ON(), RETURN_CONSTRUCT_ON() macros,
//	and a supporting Heaper::operator new()
//		- michael Oct 21 1990  (again Nov 5)
//
//	Added NOT_A_TYPE versions of CHECKED_CLASS macros, and related support
//		- michael Oct 23 1990  (again Nov 5)
//
//	Got bored with "merged from/with" comments unless merged item was
//	not previously commented.
//		- ech Nov 9 1990
//
//	(Me, too.  But they''re handy when I''m trying to figure out whether
//	 I''ve done the right thing to my compile environment.
//		- michael Nov 12 1990)
//
//	Made isKindOf and destroy virtual, not LEAF, so others may override.
//	Fixed SPTR, CHKPTR, and WPTR macros to have whitespace tails, so that
//	the apparently correct SPTR(FooClass)foo won''t be an error.
//		- ech Nov 11 1990
//
//	Added fakeGetCategory() to DEFINE_CHECKED_CLASS_NOT_A_TYPE()
//	Removed remaining traces of PRIVATE_PROTECTED_KLUDGE
//		- michael Nov 12 1990
//
//	Renamed fakeGetCategory() to getConcreteCategory()
//		- michael Nov 13 1990
//
//	Changed hashForEqual return type unsigned long -> UInt32
//	(Also hashedName and argument to findCategory(hashedName))
//		- michael Nov 18 1990
//
//	Eliminated becomeDestruct()
//		- michael Dec  4 1990
//	Finally removed Aug 21 1991 - ech
//
//	Removed PRIVATE_PROTECTED_KLUDGE
//		- ech Nov 18 1990
//
//	Rearranged and added comments for automatic documentation generating
//	tool.
//		- ech Nov 30 1990
//
//	Merged attribute and changeClass support stuff from Chris.
//		- ech Dec 10 1990
//   Added Package and Hook macros and classes
//		- ravi Feb 15-22 1991
//   Moved above to pkx*xx to separate packageability
//		- ech Mar 19 1991
//
//   Added / merged Jigs
//		- michael Jun 29 1991  (Merged again Jul 22.)
//
//   Wrapped PROXY specific stuff with #ifndef NO_RPC
//		- ech Aug 30 1991
//
//    - Split off opaque2x.ixx from opaquex.ixx (containing only those
//      routines that need to call routines in Heaper.)
//      The routines that need to call heaper inline routines will not be
//      inlined for those pointer classes that must be defined before Tofu
//      and Heaper.  (Currently, that''s destroyIt() in pointer to Heaper,
//      Xmtr, and Rcvr.)
//    - Made corresponding changes in the include directives.
//    This fixes bug MB30 (SPTR()s [to Heaper] aren''t being inlined.)
//            - michael Oct 10 1991
//
//   Changed CONSTRUCT macros to use canonical constructor bomb name
//            - michael Jan 11 1992 (Merged Feb 17)
//
//   Uncommented changes between a16 and a0.4:
//    - Category declaration removed from CLASS() macro.  (.oxx files now
//      take care of this - the CLASS() macro is now reduced to a class
//      declaration and can be retired.)
//    - Statistics collecting variables and member functions were added
//      to the Category class.
//            - detected by michael, Feb 17 1992
//
//    Added PURE_VIRTUAL_BUG to switch RUN_TIME_DEFERRED remotely from the
//    xcompatx.hxx module.  (Mainly for SGI port)
//            michael Aug 29 1991  (Merged Mar 24 1992)
//
//   Added ARG() macro so argument names in deferred contract-defining
//   member functions can be exposed to the documentation tools but
//   hidden from the pure-virtual-bug hack.
//
//   Added InstanceCache as a friend of Heaper so it can call destruct
//   on objects being cached.
//	- ech Feb 16 1993
//
//   Took out packages
//	- ech Feb 27 1993

#ifndef TOFUX_HXX
#define TOFUX_HXX

#include "xcompatx.hxx"

VERSION_ID(tofux_hxx,
	   "$Id: tofux.hxx,v 2.18 1993/03/24 02:48:29 eric Exp $")

#include "xunewx.hxx"
#include "bombx.hxx"

/* Type Conversion Suppression Junk */

class TCSJ {};



#ifdef GNU
 extern TCSJ tcsj;
#else
const TCSJ tcsj;
#endif


class XCSJ {};
#ifdef GNU
 extern XCSJ xcsj;
#else
const XCSJ xcsj;
#endif



/* Used to suppress the annoying C++ habit of interpreting single argument */
/* constructors as implicit type converters */

class Category;
class CategoryList;

/* A standard C routine for accessing category names */
C_DECL_BEGIN
    char * getCategoryName( void *oop );
C_DECL_END


/*  hack to force vtables to appear where we want them */

class VTBL {};
#ifdef GNU
//extern  VTBL VTBL_HACK;//ZZZroger oct 1995

#else
const VTBL VTBL_HACK;
#endif

/*  Class attributes */

#ifndef STUBBLE

#define DEFERRED(className)						\
    public:								\
        className(VTBL VTBL_HACK);					\
    public:								\
        virtual Category * getCategory () CONST;			\
    protected:                                                          \
        virtual void deferredHack () CONST DEFERRED_SUBR;               \
    private:								\
	friend class CAT(className,Jig);

#define CONCRETE(className)						\
    public:								\
        className(VTBL VTBL_HACK);					\
    public:								\
        virtual Category * getCategory () CONST;			\
    protected:                                                          \
        virtual void deferredHack () CONST SAFE;                        \
    private:								\
	friend class CAT(className,Jig);

#define COPY(className,cuisineName) 					\
    protected: 								\
       className (Rcvr * trans, TCSJ);		 			\
       friend void CAT(parseInto_,className) (APTR(Rcvr) rcvr, 		\
					      OUT void * storage);	\
       friend class CAT(className,Recipe); 				\
    public:								\
       virtual void sendSelfTo (APTR(Xmtr) xmtr)/* CONST*/;		\
    private:

#define PSEUDO_COPY(className,cuisineName) 				\
    public:								\
       virtual void sendSelfTo (APTR(Xmtr) xmtr)/* CONST*/;		\
    private:

#define ON_CLIENT(className)
#define CLIENT

#define AUTO_GC(className)						\
    public:								\
       virtual void migrate (void * origin,				\
			     BooleanVar destinationIsOld);		\
    private:

#define EQ(className)							\
    public:								\
	virtual BooleanVar isEqual (APTR(Heaper) other);		\
     protected:								\
	virtual UInt32 actualHashForEqual ();				\
    private:

#define MANUAL_GC(className)
#define NO_GC(className)
#define HAS_DEPENDENTS(className)
#define NOT_A_TYPE(className)
#define OBSOLETE(className)

#define MAY_BECOME(ThisClass,OtherClass)
#define MAY_BECOME_ANY_SUBCLASS_OF(ThisClass,OtherClass)


//      The following attributes are defined elsewhere 
//
//   SHEPHERD_PATRIARCH      [in shephx.hxx]
//   SHEPHERD_ANCESTOR       [in shephx.hxx]
//   DEFERRED_LOCKED         [in shephx.hxx]
//   LOCKED                  [in shephx.hxx]


/* Method Attributes */

#define SEND_HOOK
#define RECEIVE_HOOK

#define SAFE /* SAFE Methods cannot BLAST, do not heap allocate, etc. */

/* instance variable attributes */

#define NOCOPY

#endif /* STUBBLE */

#ifdef STUBBLE
#	define ARG(arg)		arg
#	define RUN_TIME_DEFERRED
#else
#	define ARG(arg)
#	ifdef PURE_VIRTUAL_BUG
#		define RUN_TIME_DEFERRED
#	else
#		define COMPILE_TIME_DEFERRED
#	endif /* PURE_VIRTUAL_BUG */
#endif /* STUBBLE */

#define RUN_TIME_DEFERRED_SUBR { BLAST(SUBCLASS_RESPONSIBILITY); }
#define RUN_TIME_DEFERRED_FUNC { BLAST(SUBCLASS_RESPONSIBILITY); return 0; }
#define RUN_TIME_DEFERRED_DECL

#ifdef RUN_TIME_DEFERRED
#	define DEFERRED_SUBR RUN_TIME_DEFERRED_SUBR
#	define DEFERRED_FUNC RUN_TIME_DEFERRED_FUNC
#	define DEFERRED_DECL RUN_TIME_DEFERRED_DECL
#elif defined(COMPILE_TIME_DEFERRED)
#	define DEFERRED_SUBR = 0
#	define DEFERRED_FUNC = 0
#	define DEFERRED_DECL = 0
#endif

class IntegerVar;
class Heaplet;

#include "scavx.hxx"
#include "opaquex.hxx"
#include "tofux.oxx"

#include "nxcvrx.oxx"


class Tofu ROOTCLASS {
  public:
    Tofu(VTBL);

    /*
    	Dynamic type information to support safe cast and CHOOSE
    */

    virtual Category * getCategory () CONST;
    virtual BooleanVar isKindOf (Category * aCategory) CONST;

    /*
	Comm and disk support (obsolescent)
    */

    /* Not declared until leaf, so not really pure virtual, thus vvvv */
    virtual void sendSelfTo (APTR(Xmtr)) /*CONST*/	RUN_TIME_DEFERRED_DECL;
    virtual BooleanVar isShepherd();

    /*
    	Garbage collection support
    */

    /* Perform the part of object migration that uses special knowledge of
       instance variables. */
    virtual void migrate (void * origin,
			  BooleanVar destinationIsOld);

  protected:

    INLINE Tofu();

};

#ifdef HIGHC
INLINE void * operator new (size_t s, void * p);
#endif

extern Category * cat_Tofu;

#define CONSTRUCT(VAR,TYPE,ARGS) {			\
    VAR = new (xcsj, CAT(cat_,TYPE)) TYPE ARGS;		\
}

#define CONSTRUCT_ON(HEAP,VAR,TYPE,ARGS) {		\
    VAR = new (HEAP, xcsj, CAT(cat_,TYPE)) TYPE ARGS;	\
}

#define CONSTRUCT_ON_NO_ASSIGN(HEAP,TYPE,ARGS) {	\
    (void) new (HEAP, xcsj, CAT(cat_,TYPE)) TYPE ARGS;	\
}

#define RETURN_CONSTRUCT(TYPE,ARGS) 			\
    return new (xcsj, CAT(cat_,TYPE)) TYPE ARGS

#define RETURN_CONSTRUCT_ON(HEAP,TYPE,ARGS)		\
    return new (HEAP, xcsj, CAT(cat_,TYPE)) TYPE ARGS


/* ========================================================================= */


#define CLASS(derived,base) 				\
     class derived : public base

// Stubble puts one of these macro calls in the generated .cxx file
// to provide the definitions for methods that have been declared by
// macro expansions in the header file.

#define DEFINE_CLASS_CATEGORY_INTERNAL(derived,base)			  \
    Category * CAT(cat_,derived) = &CAT(secret_,derived);		  \
    derived::derived(VTBL VTBL_HACK) : base (VTBL_HACK) { /* empty */ }	  \
    Category * derived::getCategory () CONST { return CAT(cat_,derived); }

#ifdef HIGHC // for bug
#define DEFINE_CLASS_CATEGORY(derived,base) 				 \
    static Category CAT(secret_,derived) =				 \
        Category::make (&CAT(secret_,derived), STR(derived),		 \
			sizeof(derived), CAT(cat_,base));		 \
    DEFINE_CLASS_CATEGORY_INTERNAL(derived,base)
#else
#define	DEFINE_CLASS_CATEGORY(derived,base)				\
    static Category CAT(secret_,derived)				\
        = Category (STR(derived), sizeof(derived), CAT(cat_,base));	\
    DEFINE_CLASS_CATEGORY_INTERNAL(derived,base)
#endif

/* ========================================================================== */

class Heaper : public Tofu {
    DEFERRED(Heaper)
    NO_GC(Heaper)

  protected:

    /* Used to produce hashes for EQ objects. */
    static UInt32 takeOop ();

  public:
    /* This must not be pure virtual */
    virtual BooleanVar isEqual (APTR(Heaper) other)	RUN_TIME_DEFERRED_DECL;

    /* The value returned does not change during the life of the object. */
    UInt32 hashForEqual ();

  protected:
    /* Defined by subclasses to produce the value returned by hashForEqual.
       This must not be pure virtual. */
    virtual UInt32 actualHashForEqual ()		RUN_TIME_DEFERRED_DECL;

  public:
    /*
    	Printing -- these print methods are largely intended for diagnostic
		    output, not as display for casual users.
    */

    REQUIRE(2,"reference")

    /* This should rarely be overridden.  In Tofu, it prints ClassName(...),
       where ... is either produced by printInsideOn or is ??? if printInsideOn
       it not overridden.
    */
    virtual void printOn (ostream& oo);

    /* Subclasses override this method to customize their printing. */
    virtual void printContentsOn (ostream& oo);

    PERMIT(0,"reference")

  public:

    /* This is unsafe wrt GC, BLASTs, and BECOMEs.  It shouldn''t be called
       but references are produced during constructor compilation. */
    void * operator new (size_t s);

    /* Use when storage is already otherwise allocated */
    void * operator new (size_t /*s*/, void * storage);

    /* The default invoked from the CONSTRUCT macros.  Has all the safety
        features built in.  */
    void * operator new (size_t s, 
			 XCSJ xcsj,  // instead of calling default new
			 Category * cat);

    /* From CONSTRUCT_AT - use when storage is already otherwise allocated */
    void * operator new (size_t /*s*/, void * storage, Category * cat);

    /* Invoked by the CONSTRUCT_ON macros.  Safety AND choice of heap */
    void * operator new (size_t s, 
			 AllocType,
			 XCSJ xcsj,  // instead of calling default new
			 Category * cat);

  public:

    /* These operators cause all objects allocations to be controlled at
        Heaper by default.  This default heap is the one that performs
        garbage collection. */
    void   operator delete (void *);

    /* to get around various cfront 2.0 bugs with "delete" */
    virtual void destroy (); 

  protected:

      /* Classes should implement this message rather than a destructor. */
      /* We use this so the destruction behavior implemented in abstract */
      /* superclasses can access the vtable of the concrete run-time     */
      /* type in C++.  Using a message makes C++ parallel the Smalltalk  */
      /* semantics for delete.  This  manually calls the destructor.     */
    virtual void destruct ();

      /* These use destruct */
    friend class InstanceCache;

      /* To suppress a silly warning message from the compiler */
    INLINE Heaper ();

      /* To make all destructors virtual */
      /* This should be in Tofu, except that the AT&T cfront compiler      */
      /* doesn''t allow temporary objects with destructors in "for" loop    */
      /* headers. This screws IntegerVar.  Oh well, we only really need it */
      /* for instances of Heaper anyway. */
    INLINE virtual ~Heaper ();

  private:
    REQUIRE(2,"reference")
    /* Objects (as opposed to Tofus) should never be assigned into */
    Heaper& operator= (Heaper&);
    PERMIT(0,"reference")

    REQUIRE(1,"friend")
    friend class CAT(Heaper,Recipe);
    PERMIT(0,"friend")

  public: /* class changing */
    INLINE void changeClassToThatOf (APTR(Heaper) anInstance);

  private: /* oop */

    static UInt32 TheOopCounter;

    UInt32 myOop;
};

REQUIRE(2,"reference")
#ifndef GNU
ostream& operator<< (ostream& oo, Heaper * item);
#endif
PERMIT(0,"reference")

/* ================ Categories ================ */

CLASS(Category,Heaper) {
    CONCRETE(Category)
    NO_GC(Category)
    NOT_A_TYPE(Category)
  public:
    LEAF BooleanVar isEqual (APTR(Heaper) other);

    /* hashForEqual and hashedName happen to yield the same value.  The
       reason for having both is that the contract for "hashForEqual" is
       the weaker one specified above in Heaper.  "hashedName" gives the
       stronger guarantee that there won''t be a hash collision.  In
       addition, "hashForEqual" only has to give consistent results
       inside one address space and for one version of the program.
       "hashedName" must give consistent results between address spaces
       and among compatable versions of the program. */
    LEAF UInt32 actualHashForEqual ();
    LEAF UInt32 hashedName ();

    LEAF char * name ();
    INLINE BooleanVar isEqualOrSubclassOf (Category * aCategory);
    LEAF Category * fetchSuperCategory();
    LEAF Category * getSuperCategory();

    INLINE Int32 preorderNumber ();
    LEAF Int32 preorderMax ();

  public:   /* become support: */

      /* must be called only at initialization time so that my instances
          can be big enough. */
    LEAF void mayBecome (Category * cat);

      /* Like calling 'mayBecome' for cat and each of its subclasses. */
    LEAF void mayBecomeAnySubclassOf (Category * cat);

      /* a query corresponding to the above request. */
    LEAF BooleanVar canYouBecome (Category * cat);

      /* the max of sizes of the transitive closure of this class */
      /* and the classes it may 'become' */
    LEAF size_t objectSize ();
		
  protected: 	/* comm stuff.  Use special hooks in the xmtrs. */
    friend class CategoryRecipe;
  public:
    virtual void sendSelfTo (APTR(Xmtr) xmtr)/* CONST*/;

  private:	/* used for calculations to support become */

    LEAF BooleanVar calculateObjectSize ();
    LEAF void checkSuperObjectSize ();

  private:

    size_t myObjectSize; /* the size of the object with all its becomes */
    CategoryList * myMayBecomes;


  protected: /* Become and isKindOf support */

    /* get the next category in depth-first preorder of the subclass tree */
    LEAF Category * fetchNextPreOrder ();

  public:
    /* this is the amount that actually should be allocated for objects of
       this type */
    INLINE size_t totalSize ();

  private:
    size_t myTotalSize;

  private:    /* isKindOf support */
    LEAF void registerWithParent ();
    LEAF Category * registerChild (Category * cat);
    LEAF UInt32 preorder (UInt32 mine);
    friend BooleanVar Tofu::isKindOf (Category *) CONST;

  public: /* initialization */
    static void registerAllBecomes ();
    static void preorderCategories ();
    static void calculateObjectSizes ();

  public:
    PERMIT(2,"reference")
    LEAF void printInsideOn (ostream& oo);
    virtual void printNodeOn (ostream& oo, UInt32 indentation = 0);
    LEAF void printTreeOn (ostream& oo, UInt32 indentation = 0);

#ifdef HIGHC
    static Category make (void * where,
		char *name, size_t selfSize, Category * superCategory);
#endif
    Category (char *name, size_t selfSize, Category * superCategory);

  private:
    char *	nameOfCategory;
    Category *	baseCategory;
    Category * 	myFirstChild;
    Category * 	myNextSibling;
    UInt32	myPreorderNumber;
    UInt32	myDescendantsMax;
    UInt32	hashOfCategoryName;
    Category *	nextHashed;

    size_t mySelfSize;  /* the sizeof the class this Category corresponds to */

  public:
    void	moreOfThem();
    void	lessOfThem();
    void	dumpStatistics(Int32 depth);

  private:
    Int32	numAllocated;
    Int32	numFreed;
    Int32	numOutstanding;
    Int32	maxOutstanding;

  public:  /* Category lookup */

    static Category * find (char * name);
    static Category * find (UInt32 hashedName);

  private:
    LEAF Category * nextHashCategory ();

#define CAT_HASH_TABLE_SIZE 1333
    static Category * HashTable[CAT_HASH_TABLE_SIZE];
    static CategoryList * Becomables;
};

const long CATEGORY_NAME_HASH_LENGTH = (sizeof(long)+2);

const long MAX_CATEGORY_NAME = 4088; /* From Language Specification */


void initializeCategoryInformation ();

/* ================================================================

   DEFINE_MAY_BECOME(becomable,becomee)

   DEFINE_MAY_BECOME_ANY_SUBCLASS_OF(becomeable,becomee)

   These macros are generated by stubble in response to MAY_BECOME
   and MAY_BECOME_ANY_SUBCLASS_OF macros. They create static objects
   which link themselves onto a list, and then are activated during
   init time to tell the categories about become information

   ================================================================ */

#ifdef HIGHC
#define DEFINE_MAY_BECOME(becomeable,becomee)				\
    static MayBecomeIniter * CAT3(becomeable,_MayBecome_,becomee) =	\
        MayBecomeIniter::make (CAT(cat_,becomeable), CAT(cat_,becomee));

#define DEFINE_MAY_BECOME_ANY_SUBCLASS_OF(becomeable,becomee)		\
    static MayBecomeAnySubclassOfIniter *				\
            CAT3(becomeable,_MayBecomeAnySubclassOf_,becomee) =		\
        MayBecomeAnySubclassOfIniter::make (CAT(cat_,becomeable),	\
					    CAT(cat_,becomee));
#else
#define DEFINE_MAY_BECOME(becomeable,becomee)				\
    static MayBecomeIniter CAT3(becomeable,_MayBecome_,becomee) =	\
        MayBecomeIniter (CAT(cat_,becomeable), CAT(cat_,becomee));

#define DEFINE_MAY_BECOME_ANY_SUBCLASS_OF(becomeable,becomee)		\
    static MayBecomeAnySubclassOfIniter					\
            CAT3(becomeable,_MayBecomeAnySubclassOf_,becomee) =		\
        MayBecomeAnySubclassOfIniter (CAT(cat_,becomeable),CAT(cat_,becomee));
#endif /* HIGHC */

CLASS(BecomeIniter,Heaper) {
  NO_GC(BecomeIniter)
  NOT_A_TYPE(BecomeIniter)
  DEFERRED(BecomeIniter)

  public:
    // register the become information
    virtual void registerBecome () DEFERRED_SUBR;

  protected:
    BecomeIniter (Category *, Category *);
    Category * becomeable ();
    Category * becomee ();

    friend class Category;

    BecomeIniter * fetchNext ();
    static BecomeIniter * allIniters ();

  private:
    Category * myBecomeable;
    Category * myBecomee;
    BecomeIniter * myNextBecomeIniter;

    static BecomeIniter * AllIniters;
};

CLASS(MayBecomeIniter,BecomeIniter) {
  NO_GC(MayBecomeIniter)
  NOT_A_TYPE(MayBecomeIniter)
  CONCRETE(MayBecomeIniter)

  public:
    virtual void registerBecome ();
    MayBecomeIniter (Category *, Category *);
#ifdef HIGHC
    static MayBecomeIniter * make (Category *, Category *);
#endif
};

CLASS(MayBecomeAnySubclassOfIniter,BecomeIniter) {
  NO_GC(MayBecomeAnySubclassOfIniter)
  NOT_A_TYPE(MayBecomeAnySubclassOfIniter)
  CONCRETE(MayBecomeAnySubclassOfIniter)

  public:
    virtual void registerBecome ();
    MayBecomeAnySubclassOfIniter (Category *, Category *);
#ifdef HIGHC
    static MayBecomeAnySubclassOfIniter * make (Category *, Category *);
#endif
};

/* ========================================================================== */
//
//	CAST()
//
//	Cast ptr to (type *), but BLAST() if it isn't safe.
//
//	Symbol UNSAFE_CASTING allows individual modules to turn off checkCast
//	for such purposes as timing measurements.
//
/* ========================================================================== */

#ifdef UNSAFE_CASTING

#define CAST(type,ptr)		((type *)(Heaper*)(ptr))

#else  /* if SAFE_CAST */

#ifdef	BOMB_REPORT_LINE
#define	CAST(type,ptr) (				\
		(type *) (Heaper*) checkCast (		\
			  CAT(cat_,type)		\
			, (ptr)				\
			, __FILE__			\
			, __LINE__			\
		)					\
	)

	extern RPTR(Heaper) checkCast (
		  Category *	argCategoryObject
		, Heaper *	argObject
		, CONST char *	argFileName
		, CONST int	argLineNumber
	);

#else /* BOMB_REPORT_LINE */
#define	CAST(type,ptr) (				\
		(type *) (Heaper*) checkCast (		\
			  CAT(cat_,type)		\
			, (ptr)				\
		)					\
	)

	extern RPTR(Heaper) checkCast (
		  Category *	argCategoryObject
		, Heaper *	argObject
	);

#endif	/* BOMB_REPORT_LINE */

#endif /* UNSAFE_CASTING */


PROBLEM_LIST(AllBlastsFilter,1,(ALL_BUT));


/* ======================================================================== */


#ifdef XLINT
#	undef LEAF
#	undef DEFERRED
#	undef DEFERRED_FUNC
#	undef DEFERRED_SUBR
#	undef CAST
#	undef CLASS
#endif /* XLINT */

#define OUT

#define constFn /* ??? rnp 89/11/24 */

#ifdef USE_INLINE
#	include "tofux.ixx"
#	include "opaque2x.ixx"
#endif /* USE_INLINE */

#endif /* TOFUX_HXX */

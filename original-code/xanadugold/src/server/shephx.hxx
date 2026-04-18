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

#ifndef SHEPHX_HXX
#define SHEPHX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef TOKENSX_OXX
#include "tokensx.oxx"
#endif /* TOKENSX_OXX */


/*  */
/*  */
class ShepFlag {};
#ifdef GNU
extern ShepFlag shepFlag;
#else
const ShepFlag shepFlag;
#endif
#ifndef STUBBLE

/* Prototype Constructor Identification Junk */

class PCIJ {};
#ifdef GNU
extern PCIJ pcij;
#else
const PCIJ pcij;
#endif
/* Used to identify calls on a constructor intended to be used only  */
/* to create prototypes for the use of changeClassToThatOf() */

#define LOCKED(className)						\
  public:								\
    className(PCIJ);							\
  private:

#define DEFERRED_LOCKED(className)					\
  public:								\
    className(PCIJ);							\
  private:

#define NOFAULT

#define NOLOCK

/* ========================================================================== */
//
// Attribute macros.  (Class must also be a COPY() class.)
//
//	SHEPHERD_PATRIARCH()	tells stubble to generate a shepherd stub and
//				falls through to SHEPHERD_ANCESTOR
//
//	SHEPHERD_ANCESTOR()	generates a constructor for passing the
//				hash to Abraham during stub creation
//
// Rules for their use:
//
//	- All (abstract or concrete) classes which inherit from Abraham
//	  are "shepherds".
//
//	- Shepherds must be COPY() classes.
//
//	- Every concrete shepherd class must either be, or inherit from,
//	  a class with the SHEPHERD_PATRIARCH() attribute (called a
//	  SHEPHERD_PATRIARCH class.)
//
//	- Every class between a SHEPHERD_PATRIARCH and Abraham must have
//	  either a SHEPHERD_PATRIARCH() or a SHEPHERD_ANCESTOR() attribute.
//
//	- (Thus, the SHEPHERD_ANCESTOR() attribute is optional in classes
//	  below the last SHEPHERD_PATRIARCH.  Giving them the attribute
//	  causes extra code to be generated, allowing you to define
//	  another SHEPHERD_PATRIARCH which inherits from them.)
//
//  - In order to make becomeStub faster, I've made the stubbing
//    constructor inline.  It has to be here, and not in the sxx file
//    so that subclasses outside of the module defining the ANCESTOR
//    can see it.  Note that for I use the implicit superclass name for
//    the constructor, and therein rely on single inheritance.  An
//    alternative is to have SHEPHERD_ANCESTOR specify its superclass
//		- ech 3-19-92
//
//  - Put back non-inline variant of SHEPHERD_ANCESTOR for use when
//     inlining is turned off.
//		- ech 4-3-92
/* ========================================================================== */

#define SHEPHERD_PATRIARCH(className,baseClassName)					\
        public: 							\
	   SPTR(Category) getShepherdStubCategory() CONST;			\
	   void becomeStub();								\
	SHEPHERD_ANCESTOR(className,baseClassName)

#ifdef USE_INLINE

#define SHEPHERD_ANCESTOR(className,baseClassName)					\
     protected: 							\
	   inline className(ShepFlag /*aFlag*/, UInt32 aHash, APTR(FlockInfo) info) \
	   			: baseClassName(shepFlag, aHash, info) {}				\
	private:

#else
/* the constructor definitition in this case is in the .sxx file */
#define SHEPHERD_ANCESTOR(className)					\
     protected: 							\
	   className(ShepFlag aFlag, UInt32 aHash, APTR(FlockInfo) info);		\
	private:
#endif /* USE_INLINE */

#endif /* STUBBLE */




/* ************************************************************************ *
 * 
 *                    Class Abraham 
 *
 * ************************************************************************ */



/* Initializers for Abraham */



DESIGN_PRIM_FLUID(BooleanVar,InsideTransactionFlag);	/* in Abraham */





/* global: functions */


INLINE BooleanVar  isConstructed (APTR(Heaper) ARG(obj));


INLINE BooleanVar  isDestructed (APTR(Heaper) ARG(obj));



	/* NO CLASS COMMENT */

class Abraham : public Heaper {

/* Attributes for class Abraham */
	DEFERRED(Abraham)
	DEFERRED_LOCKED(Abraham)
	COPY(Abraham,DiskCuisine)
	AUTO_GC(Abraham)

/* Initializers for Abraham */






friend class INIT_TIME_NAME(Abraham,initTimeNonInherited);

  public: /* tokens */

	
	static RPTR(Abraham) fetchShepherd (Int32 ARG(token));
	
	
	static void returnToken (Int32 ARG(token));
	
  protected: /* protected: destruction */

	/* Replace the shepherd in memory with a type compatible stub
		 instance that shares the same hash and flockInfo. */
	/* NOTE: Should this ensure that the flock is not dirty? */
	/* Each subclass of Abraham will have an implementation of the form: 
			new (this) MyStubClass()' or:
			'this->changeClassToThatOf(ProtoStubClass)' */
	
	virtual void becomeStub ();
	
	/* Called when an object is leaving RAM.  Additional behavior 
	for subclasses of Abraham:
		Tell the snarfPacker that I am leaving RAM and should be 
	removed from its tables. */
	
	virtual NOLOCK NOFAULT void destruct ();
	
	/* Disconnect me from the universe and throw me off the disk. 
		
		For GC safety, we keep a strongptr to ourself -- is this 
	still necessary? */
	
	virtual void dismantle ();
	
  protected: /* protected: disk */

	/* The receiver has changed and so must eventually be 
	rewritten to disk. */
	
	virtual void diskUpdate ();
	
	/* Record on disk that there are no more persistent pointers 
	to the receiver.  When the in core pointers go away, the 
	receiver can be dismantled from disk.  That will happen eventually. */
	
	virtual NOFAULT void forget ();
	
	/* The receiver has just been created. Put it on disk. */
	
	virtual NOFAULT void newShepherd ();
	
	/* Record that there are now persistent pointers to the receiver. */
	
	virtual NOFAULT void remember ();
	
  public: /* destruction */

	/* Tell the packer I want to go away. It will mark me 
		as forgotten and actually dismantle me when it next 
		exits a consistent block. This avoids Jackpotting 
		when destroying a tree of objects. */
	/* [myToken < CurrentPacker fluidGet flockTable count 
			ifTrue: [CurrentPacker fluidGet flockTable at: myToken 
	store: NULL]] smalltalkOnly. */
	
	virtual void destroy ();
	
  public: /* testing */

	
	virtual NOFAULT NOLOCK UInt32 actualHashForEqual ();
	
	/* A hash of the contents of this flock */
	
	virtual UInt32 contentsHash ();
	
	
	virtual NOFAULT BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	/* Return false only if the object cannot be flushed to disk. 
	This will probably 
		only be false for Stamps and the like that contain session 
	level pointers. */
	
	virtual NOLOCK BooleanVar isPurgeable ();
	
	/* This should be replaced with an isKindOf: that first checks to see
		  if you're asking about Abraham, and then otherwise 
	possible faults. */
	
	virtual NOFAULT BooleanVar isShepherd ();
	
	/* Distinguish between stubs and shepherds. */
	
	virtual NOFAULT NOLOCK BooleanVar isStub ();
	
	/* All manually generated subclasses are locked.  Automatically
		 defined unlocked classes will reimplement this. */
	
	virtual NOLOCK BooleanVar isUnlocked ();
	
  public: /* accessing */

	/* Return the object that describes the state of this flock 
	wrt disk. */
	/* This should be made protected. */
	
	virtual NOFAULT NOLOCK RPTR(FlockInfo) fetchInfo ();
	
	/* Set the object that knows where this flock is on disk.  
	Change it when the object moves. */
	
	virtual NOFAULT void flockInfo (APTR(FlockInfo) ARG(info));
	
	/* Return the object that describes the state of this flock 
	wrt disk. */
	
	virtual NOFAULT RPTR(FlockInfo) getInfo ();
	
	/* Return the category of stubs used for the receiver. 
	Shepherd Patriarch classes reimplement this to use more 
	specific Stub types. */
	
	virtual NOFAULT RPTR(Category) getShepherdStubCategory ();
	
	/* Return the object that describes the state of this flock 
	wrt disk. */
	
	virtual NOFAULT Int32 token ();
	
  protected: /* protected: create */

	/* New Shepherds must be stored to disk. */
	
	Abraham ();
	
	/* This is the root of the automatically generated 
	constructors for creating Stubs. */
	
	Abraham (
			ShepFlag ARG(ignored), 
			UInt32 ARG(hash), 
			APTR(FlockInfo) ARG(info))
	;
	
	/* This is for shepherds that are becoming from another shepherd. */
	
	INLINE Abraham (UInt32 ARG(hash), TCSJ);
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartAbraham (APTR(Rcvr) ARG(trans) = NULL);
	
  private:
	UInt32 myHash;
	NOCOPY Int32 myToken;
	NOCOPY CHKPTR(FlockInfo) myInfo;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	static GPTR(TokenSource) TheTokenSource;
/* Friends for class Abraham */
friend class SnarfPacker;
friend class TestPacker;
friend class FakePacker;
friend class SnarfRecord;
friend class SnarfHandler;
friend void  unlockFunctionAvoidingDestroy (Abraham *);
friend class RecorderHoister;



};  /* end class Abraham */


#ifdef USE_INLINE
#ifndef SHEPHX_IXX
#include "shephx.ixx"
#endif /* SHEPHX_IXX */


#endif /* USE_INLINE */


#endif /* SHEPHX_HXX */


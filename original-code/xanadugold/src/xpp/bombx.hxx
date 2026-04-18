/* ========================================================================== */
//
//	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
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
//				bombx.hxx
//
//		The bailout bomb macros and their associated objects.
//
//		By Michael McClary		1989
//
/* ========================================================================== */
//
//	NOTE: Taking an error exit in (or in something called by) the
//	constructor of a heap-allocated object causes a memory leak.
//
//	Overloadings of operator new() can be used to solve this problem.
//	(See test file for some examples.)
//
/* ========================================================================== */
//
//
//	Merged:
//	 - alpha-6 (which has a do-nothing BombStringDetonator(int, int) for
//	   constructing the initial detonator, so it wouldn't snip off the
//	   fuse when its turn comes in static construction - safe because
//	   uninitted statics are initted zero and in C++ NULL is zero) with
//	 - my Mar 12 (with SHIELD_{BREAK/CONTINUE/RETURN()/VOID})
//		-michael  Jul 26 1990
//
//	Cleaning up accumulated changes:
//		- michael Apr  9 1991
//
//	Merge with alpha-12:  change const -> CONST
//		-michael Apr 18 1991
//
//	Reorganized for clarity.
//	Added more comments.
//	Added opaque declarations for several classes.
//	Fixed BOOBY_TRAP macro to use SHIELD_BREAK.
//	Changed Shield from a struct to a class.
//		-michael Apr 20 1991
//
//	Adding Doomsday Bombs
//		-michael Apr 21 1991
//
//	Initial inlining
//		- eric Apr 30 1991
//
//	Changed from arming-ordered detonation to construction-ordered
//	detonation.  (This matches the implementation that can be built on
//	the proposed standard, and works natuarally with a single-linked
//	list, eliminating two member variables and considerable overhead
//	in BombSuperclass and its children (i.e. strong pointers).)
//
//	Also "broke" the BombSuperclass default copy constructor (to
//	increase type paranoia).
//		- michael Jun 21 1991
//
//	Added ROOTCLASS for MacSingleInheritance
//		- ech Aug 30 1991
//
//	- Split out bombc.h, containing:
//	   - BOMB_REPORT_LINE switch
//	   - PROBLEM_LIST macros
//	   - SourceOfDetonationSignal enum
//	  which were needed for c bombs.
//	- Added BombStringDetonator::fetchFirstP(), ditto
//	- Eliminated unnecessary setjmp() call etc. from DOOMSDAY_BOMB
//		- michael - Nov 2 1991  (merged Feb 17)
//
//	Modifications for begin/end style:
//	 - Eliminated EXPORT (which was unused)
//	 - Converted DESIGN to equivalent of old EXPORT (more work needed
//	   because this breaks some inlining!!!!  Fixing it will also improve
//	   the performance of the ORDER-in-hxx/BUILD-in-cxx form.)
//	 - Installed begin/end code.
//		- michael Feb 24 1992
//
//	Made bombStringDetonatorP a static member variable (renamed currentP).
//	Made initialBombStringDetonator ditto (renamed firstInstance).
//	Deleted obsolete shield-ordering stub macros.
//		- michael Feb 27 1992
//
//	Switched to inline bombs.  BUILD_BOMB() stuff moved from cxx to ixx
//		- michael Mar 2 1992
//
//	Added BombStringDetonator::previousDetonatorP and fetch...()
//	to fix GC-during-blasting bug.
//		- michael Mar  6 1992
//
//	Removed obsolete DEFINE_BOMB and non BEGIN/END bomb builds.
//	Added TRY/CATCH
//		- michael Mar 12 1992
//
//	Removed LEAF from removeFromMidString
//		- ech Apr 21, 1992
//
//	Changed _shieldList to be a function to suppress defined but not used
//	warnings from 2.1 compiler
//		- ech Oct 1, 1992
//
//	Made DOOMSDAY_shieldList be in C linkage because of 2.1 mismatch rule
//		- ech Oct 2, 1992
//
//	Added print method to Problem that does not require allocation
//		- ech Mar 22, 1993
/* ========================================================================== */
//
//	Repitition suppression switch
//
/* ========================================================================== */

#ifndef BOMBX_HXX
#define BOMBX_HXX

/* ========================================================================== */
//
//	Includes
//
/* ========================================================================== */

#ifndef XCOMPATX_HXX
#include "xcompatx.hxx"
#endif /* XCOMPATX_HXX */

VERSION_ID(bombx_hxx,
	   "$Id: bombx.hxx,v 2.12 1993/03/24 02:48:08 eric Exp $")

PERMIT(N,"ALL")  	/* so xlint doesn't gripe about system includes */

#ifndef	STUBBLE
#ifndef NDEBUG
#       include <stdio.h>	/* this is here because of include nest limit */
#	include <stream.h>		/*!!!!*/
#endif /* NDEBUG */
#	include <setjmp.h>
#else /* STUBBLE */
	typedef	int	jmp_buf[9];	/* !!!! */
#endif	/* STUBBLE */

PERMIT(0,"ALL")

/* ========================================================================== */
//
//	Includes shared with C interface to bombs:
//		BOMB_REPORT_LINE sharp-define
//		SourceOfDetonationSignal enum
//		PROBLEM_LIST() sharp-define
//
/* ========================================================================== */

#include "bombc.h"

/* ========================================================================== */
//
//	Opaque declarations of the major classes defined in this file.
//	(Declared here so they can point at each other.)
//
/* ========================================================================== */

class BombSuperclass;		// The superclass of bombs and bomb-like things
				// which are strung together on a fuse.

class BombStringDetonator;	// The object that inspects and lights the fuse.

class Problem;			// The "flame" that is passed down the "burning
				// fuse" from the BombStringDetonator.

class Shield;			// The lvalue squirreled away in a SHIELD
				// construct.  Contains a pointer to an error
				// list, a jmp_buf, and storage for a copy of
				// a Problem instance.
/* ========================================================================== */
//
//	The Problem class:
//
//	(A token to be passed to whatever does the error processing,
//	 telling it what the problem is and perhaps where it occurred.)
//
//	NOTE:  Bare problem objects live on the stack, and go away
//	       (without destruction) when the longjmp() makes the
//	       stack vanish out from under them.
//
//	       Problem objects also live in Shield objects, which also
//	       live on the stack.
//
//	NOTE:  Max name sizes are for proxy communication only.
/* ========================================================================== */

#define PROBLEM_MAX_PROBLEM_NAME	255
#define PROBLEM_MAX_FILE_NAME		255

REQUIRE(3,"reference")
REQUIRE(2,"pointer to function")
class Problem ROOTCLASS {
    public:
	Problem (			// For Problems in local code.
		  CONST char *	argProblemName
		, CONST int	argVal
#ifdef	BOMB_REPORT_LINE
		, CONST char *	argFileName
		, int		argLineNumber
#endif	/* BOMB_REPORT_LINE */
	);

	Problem (			// For Problems that come in on comm.
		  CONST char *	argProblemName
		, CONST int	argVal
#ifdef	BOMB_REPORT_LINE
		, CONST char *	argFileName
		, int		argLineNumber
#endif	/* BOMB_REPORT_LINE */
		, void		(*argSpecialFree)(CONST char *, CONST char *)
	);

	Problem();				// For copy in Shield object
	void 		copyIn(Problem * argProblem);	// Ditto
	void 		freeStrings();		// Ditto

	void		printOn (ostream& oo);
	void		printError ();
	BooleanVar	checkProblem(CONST char * argProblemName);

	CONST char *	getProblemName();	// Return problemName
	int		getVal();		// Return val
	CONST char *	getFileName();		// Return fileName
	int		getLineNumber();	// Return lineNumber
    private:
	CONST char *		problemName;
	int			val;
#ifdef	BOMB_REPORT_LINE
	CONST char *		fileName;
	int			lineNumber;
#endif	/* BOMB_REPORT_LINE */
	void			(*specialFree)(CONST char *, CONST char *);
};

ostream&	operator<<(ostream& oo, Problem * argProblemP);
PERMIT(0,"pointer to function")
PERMIT(0,"reference")
/* ========================================================================== */
//
//	BOMBs are the objects which do the cleanup actions.  They are strung
//	on a "fuse" which grows or shrinks as the program flow goes deeper
//	or shallower in block/subroutine nesting, and they "detonate"
//	sequentially when an exception exit bypasses ordinary program flow.
//
/* ========================================================================== */
//
//	The superclass of all bomb objects (and of all bomb-like things which
//	are strung together on a fuse).
//
//	(The superclass does the string linkage/unlinkage and most of
//	 the decision-making for the objects.)
//
/* ========================================================================== */

REQUIRE(1,"protected data")

class BombSuperclass ROOTCLASS {

    protected:
	int			bombArmed;

    private:

	BombSuperclass *	nextP;

    protected:
	INLINE BombSuperclass();
    private:
	BombSuperclass(BombSuperclass &){};
    public:
	INLINE ~BombSuperclass();
    private:
	virtual Shield *        inspectFuse();
    public:
	virtual void *          gCHook();
	virtual void		gCHook(void * value);

    protected:
	INLINE void armBomb();	/* NOT virtual! */
    public:
	INLINE void		disarmBomb();
	INLINE virtual void	detonateBomb(SourceOfDetonationSignal SOURCE);

    private:
	void			removeFromMidString();
    public:

	REQUIRE(3,"friend")
	friend class		Heaplet;
	friend class		BombStringDetonator;
	friend class		BombJig;
	PERMIT(0,"friend")
};
PERMIT(0,"protected data")
/* ========================================================================== */
//
//	Internal macros to support the definition of particular BOMBs
//
/* ========================================================================== */

#define	ORDER_BOMB_COMMON(KIND, TYPE, ANINLINE)				\
	class CAT(KIND,_Bomb): public BombSuperclass {			\
	    private:							\
		TYPE		CHARGE;					\
									\
	    public:							\
		ANINLINE void armBomb(TYPE argCHARGE); /* NOT virtual! */ \
		ANINLINE virtual void detonateBomb(SourceOfDetonationSignal); \
		ANINLINE CAT(KIND,_Bomb)();				\
		ANINLINE ~CAT(KIND,_Bomb)();				\
	}

#define	BUILD_BOMB_BEGIN_COMMON(KIND, TYPE, ASOURCE, ANINLINE)		\
									\
	ANINLINE CAT(KIND,_Bomb)::					\
	CAT(KIND,_Bomb)(){};						\
									\
	ANINLINE void CAT(KIND,_Bomb)::					\
	armBomb(TYPE argCHARGE) /* NOT virtual! */			\
	{								\
		this->BombSuperclass::armBomb();			\
		this->CHARGE = argCHARGE;				\
	};								\
									\
	ANINLINE void CAT(KIND,_Bomb)::					\
	detonateBomb(SourceOfDetonationSignal ASOURCE)			\
	{								\
		if (bombArmed) {					\
			this->disarmBomb();

#define	BUILD_BOMB_END_COMMON(KIND,ANINLINE)				\
		}							\
	};								\
									\
	ANINLINE CAT(KIND,_Bomb)::					\
	~CAT(KIND,_Bomb)()						\
	{								\
		this->detonateBomb(LEFT_AREA);				\
	};
/* ======================================================================== */
//
//
//		ORDER_BOMB(KIND, TYPE);
//
//	Declare that a particular KIND of bomb, taking a CHARGE of type TYPE,
//	exists, and may be used in the module which expands or includes the
//	expansion of this macro.
//
//	BUILD_BOMB_BEGIN(KIND,TYPE) {	    BUILD_SMART_BOMB_BEGIN(KIND,TYPE) {
//		action;				    action;
//	} BUILD_BOMB_END(KIND)		    } BUILD_SMART_BOMB_END(KIND)
//
//	Define a subclass of BombSuperclass containing the code to do some
//	particular exception handling.
//
/* ========================================================================== */
//
//	All bombs make CHARGE available within the action.
//	Smart bombs also make available the SOURCE of the detonation signal.
//	The distinction keeps the compiler from complaining about unused
//	variables.
//
/* ========================================================================== */
//
//	Typically, ORDER_BOMB() is expanded in the .hxx file, while
//	BUILD... is expanded in the .ixx.  This makes the bomb available
//	to clients of the .hxx module which defines them, so they can be
//	used in macros which are also defined in said .hxx file.
//
//	Alternatively, both may be expanded in the .cxx file.  This doesn't
//	make the bombs of that KIND available to client modules (though it
//	still uses up a KIND, because KIND is in a global namespace.)
//
/* ========================================================================== */

#define	ORDER_BOMB(KIND, TYPE)						\
	ORDER_BOMB_COMMON(KIND, TYPE,INLINE)

#define	BUILD_BOMB_BEGIN(KIND, TYPE)					\
	BUILD_BOMB_BEGIN_COMMON(KIND, TYPE,,INLINE)

#define	BUILD_BOMB_END(KIND)						\
	BUILD_BOMB_END_COMMON(KIND,INLINE)

#define	BUILD_SMART_BOMB_BEGIN(KIND, TYPE)				\
	BUILD_BOMB_BEGIN_COMMON(KIND, TYPE, SOURCE,INLINE)

#define	BUILD_SMART_BOMB_END(KIND)					\
	BUILD_BOMB_END_COMMON(KIND,INLINE)

/* ========================================================================== */
//
//	PLANT_BOMB()
//
//	Create an (initially disarmed) instance of the subclass.
//
//	(Once armed, it will do its particular bomb operation when
//	its destructor is called, or when and exception that has been
//	given to BLAST() pops the flow out of this object's scope.)
//
//	(Only stack-allocated instances are allowed.  Thus we need not
//	 figure out whether they need to be unlinked and/or deallocated.)
//
/* ========================================================================== */

#define	PLANT_BOMB(KIND, TAG)						\
	CAT(KIND,_Bomb) CAT(TAG,_BombTag);

/* ========================================================================== */
//
//	ARM_BOMB()
//
//	"Arm" the bomb object.
//
/* ========================================================================== */

#define	ARM_BOMB(TAG,value)						\
	CAT(TAG,_BombTag).armBomb(value);

/* ========================================================================== */
//
//	DETONATE_BOMB()
//
//	"Trigger" the bomb object early (and disarm it).
//
/* ========================================================================== */

#define	DETONATE_BOMB(TAG)						\
	CAT(TAG,_BombTag).detonateBomb(LOCAL_DETONATE);

/* ========================================================================== */
//
//	DISARM_BOMB()
//
//	"Disarm" the bomb object without triggering it.
//
/* ========================================================================== */

#define	DISARM_BOMB(TAG)						\
	CAT(TAG,_BombTag).disarmBomb();

/* ========================================================================== */
//
//	Now that ORDER_BOMB() is defined, we can expand it for SHIELDS
//
/* ========================================================================== */

	ORDER_BOMB(ShieldFree, Problem *);
/* ========================================================================== */
//
//	*_SHIELD()
//
//	Catch the detonation propagating up the string of bombs.
//
/* ========================================================================== */
//
//	Shield:  The lvalue squirreled away in a SHIELD construct.
//
/* ========================================================================== */

REQUIRE(3,"public data")

class Shield ROOTCLASS {
    public:
	jmp_buf		jmpBuf;
	char **		errorListP;
	Problem		problem;

	Shield();
};

PERMIT(0,"public data")

/* ========================================================================== */
//
//	SHIELDs and LOUD_SHIELDs are special cases of smart bombs, which
//	addidionally overload the inspectFuse() member function to return
//	the Shield pointer.  (This allows the detonator to inspect the
//	bomb string to see if any shields will catch the blast, and
//	"bomb out" without destroying the state if nobody will.)
//	
//	The bombx.cxx file does the equivalent of DESIGNing these
//	smart bombs.  Clients don't need to ORDER them, because the
//	following code is equivalent to the expansions of appropriate
//	ORDER... macros.
//
/* ========================================================================== */

class _shield_Bomb: public BombSuperclass {
    private:
	Shield *	CHARGE;

    public:
	void armBomb(Shield * argCHARGE); /* NOT virtual! */
	virtual void detonateBomb(SourceOfDetonationSignal);
	virtual Shield * inspectFuse();
	_shield_Bomb();
	~_shield_Bomb();
};

class _lshield_Bomb: public BombSuperclass {
    private:
	Shield *	CHARGE;

    public:
	void armBomb(Shield * argCHARGE); /* NOT virtual! */
	virtual void detonateBomb(SourceOfDetonationSignal SOURCE);
	virtual Shield * inspectFuse();
	_lshield_Bomb();
	~_lshield_Bomb();
};
/* ========================================================================== */
//
//	INSTALL_SHIELD()
//	INSTALL_LOUD_SHIELD()	Instantiate a shield object.
//
/* ========================================================================== */

#define	INSTALL_SHIELD(TAG)						\
		PLANT_BOMB(_shield, CAT(TAG,_shield));			\
		Shield	CAT(TAG,_shield);

#define	INSTALL_LOUD_SHIELD(TAG)					\
		PLANT_BOMB(_lshield, CAT(TAG,_shield));			\
		Shield	CAT(TAG,_shield);

/* ========================================================================== */
//
//	SHIELD_UP()	Raise (activate) the shield.
//
//	(The ShieldFree bomb will be defined after the ORDER_BOMB() macro)
//	(It is needed to free the storage allocated by incoming letter bombs.)
//
/* ========================================================================== */

#define	SHIELD_UP(TAG, LTAG, ACTION)					\
	SHIELD_UP_BEGIN(TAG, LTAG) {					\
		ACTION;							\
	} SHIELD_UP_END(TAG)


#define	SHIELD_UP_BEGIN(TAG, LTAG)					\
		{							\
			int	VAL;					\
			CAT(TAG,_shield).errorListP = CAT(LTAG,_shieldList)(); \
			if ((VAL = setjmp(CAT(TAG,_shield).jmpBuf))) {	\
				PLANT_BOMB(ShieldFree, _shieldFree);	\
				ARM_BOMB(_shieldFree,			\
					&CAT(TAG,_shield).problem);


#define	SHIELD_UP_END(TAG)						\
			}						\
		}							\
		ARM_BOMB(CAT(TAG,_shield),&CAT(TAG,_shield))

/* ========================================================================== */
//
//	SHIELD_DOWN()	Lower (deactivate) the shield.
//
/* ========================================================================== */

#define	SHIELD_DOWN(TAG)						\
		DISARM_BOMB(CAT(TAG,_shield))

/* ========================================================================== */
//
//	Some #defined stuff to be used inside the {ACTION} of a SHIELD_UP()
//
/* ========================================================================== */
//
//	PROBLEM()	Problem object in current shield.
//
/* ========================================================================== */

#define	PROBLEM(TAG)	(CAT(TAG,_shield).problem)

/* ========================================================================== */
//
//	REBLAST()	Problem object in current shield.
//
/* ========================================================================== */

#define	REBLAST(TAG)	blast(CAT(TAG,_shield).problem)

/* ========================================================================== */
//
//		SHIELD_RETURN()
//		SHIELD_VOID
//		SHIELD_BREAK
//		SHIELD_CONTINUE
//
//	Because an unconditional return inside a shield causes the ShieldFree
//	bomb's destructor to be missed, the compiler will warn us that the
//	statement where it lies is not reached.  "SHIELD_RETURN(retval);"
//	may be used in place of "return retval;"  to shut the compiler up.
//
//	Similarly with "break;" and "SHIELD_BREAK;"
//	Similarly with "continue;" and "SHIELD_CONTINUE;"
//
//	SHIELD_VOID is something to be returned in SHIELD_RETURN() when
//	used in a routine that doesn't return anything.
//
/* ========================================================================== */

#define SHIELD_RETURN(RETVAL)	if (&VAL) { return RETVAL; }
#define SHIELD_VOID
#define SHIELD_BREAK		if (&VAL) { break; }
#define SHIELD_CONTINUE		if (&VAL) { continue; }

/* ========================================================================== */
//
//	A construct useful mainly for test files:
//
/* ========================================================================== */
//
//	BOOBY_TRAP()	Do {ACTION}.  It should BLAST(ONE_OF_LTAG).
//			 - If it does, catch it and go on.
//			 - If it doesn't, BLAST(GRIPE).
//			{ Requires an INSTALL_SHIELD(BOOBY_TRAPPING) }
//
/* ========================================================================== */

#define	BOOBY_TRAP(LTAG,GRIPE,ACTION)		\
	BOOBY_TRAP_BEGIN(LTAG,GRIPE) {		\
		ACTION;				\
	} BOOBY_TRAP_END()

#define	BOOBY_TRAP_BEGIN(LTAG,GRIPE)		\
	for (;;) {				\
		SHIELD_UP(BOOBY_TRAPPING,LTAG,{	\
	/**/		SHIELD_BREAK;		\
		});

#define	BOOBY_TRAP_END()			\
		BLAST(GRIPE);			\
	}

/* ========================================================================== */
//
//	TRY:  A variant of SHIELDs with semantics closer to the c++
//	exception handling proposal.
//
//	This code looks very much like a try block with a single catch
//	clause.  Nest them to emulate multiple catch clauses.  (The code
//	generated a multiple-catch version would be about the same.)
//
//	One major difference between try and TRY is that the set of exceptions
//	caught is designated by a PROBLEM_LIST rather than a class type.
//	Another is that this designation occurs near the TRY rather than the
//	CATCH keyword.  A third is that the returned information is accessed
//	by the VAL and PROBLEM mechanism from SHIELDS, rather than the dummy
//	argument of the c++ proposal.
//
//	LOUD_TRY is like LOUD_SHIELD.  It additionally prints an error report.
//
//	TRY(LTAG) {				LOUD_TRY(LTAG) {
//		try action;				try action;
//	} CATCH {				} CATCH {
//		exception handled here;			exception handled here;
//	}					}
//
/* ========================================================================== */

#define	TRY(LTAG)	TRY_COMMON(LTAG,_shield)

#define	LOUD_TRY(LTAG)	TRY_COMMON(LTAG,_lshield)

#define	TRY_COMMON(LTAG,KIND)						\
{									\
	PLANT_BOMB(KIND, _try_shield);					\
	Shield	_try_shield;						\
	{								\
		int	VAL;						\
		_try_shield.errorListP = CAT(LTAG,_shieldList)();	\
		if ((VAL = setjmp(_try_shield.jmpBuf)) == 0) {		\
			ARM_BOMB(_try_shield,&_try_shield);

#define	CATCH								\
		} else {						\
			PLANT_BOMB(ShieldFree, _shieldFree);		\
			ARM_BOMB(_shieldFree, &_try_shield.problem);

#define	TRY_END								\
		}							\
	}								\
}

#define	TRY_PROBLEM		(_try_shield.problem)
#define	TRY_REBLAST		blast(_try_shield.problem)
#define TRY_RETURN(RETVAL)	if (&VAL) { return RETVAL; }
#define TRY_VOID
#define TRY_BREAK		if (&VAL) { break; }
#define TRY_CONTINUE		if (&VAL) { continue; }

/* ========================================================================== */
//
//	DOOMSDAY BOMBs are a special case of SHIELD that brings down the
//	application if the SHIELD would have caught a BLAST().
//
/* ========================================================================== */
//
//	PLANT_DOOMSDAY_BOMB()	Instantiate a doomsday bomb object.
//
/* ========================================================================== */

#define	PLANT_DOOMSDAY_BOMB()	INSTALL_SHIELD(_DOOMSDAY)

/* ========================================================================== */
//
//	ARM_DOOMSDAY_BOMB()
//
//	Logically identical to: SHIELD_UP(_DOOMSDAY, _DOOMSDAY, {;})
//	but it never really gets jumped to, so we simplify it massively
//	(eliminating the setjmp() and the guts) to save time and space.
//
/* ========================================================================== */

#define	ARM_DOOMSDAY_BOMB()						\
	{								\
		CAT(_DOOMSDAY,_shield).errorListP = CAT(_DOOMSDAY,_shieldList)();\
	}								\
	ARM_BOMB(CAT(_DOOMSDAY,_shield),&CAT(_DOOMSDAY,_shield))

/* ========================================================================== */
//
//	DISARM_DOOMSDAY_BOMB()
//
/* ========================================================================== */

#define	DISARM_DOOMSDAY_BOMB()	SHIELD_DOWN(_DOOMSDAY)

C_DECL_BEGIN
extern char **	CAT(_DOOMSDAY,_shieldList)();
C_DECL_END
/* ========================================================================== */
//
//	BombStringDetonator
//
//	BombStringDetonators hold the string of bombs (by the end where new
//	bombs are being strung and unstrung), and mediate the detonation of
//	the bombs when an exception is BLAST()ed.
//
//	BombStringDetonator::currentP designates the BombStringDetonator
//	on which bombs are currently being strung (on the one-way-linked-list
//	rooted at firstP).
//
//	During the stack-unwinding phase of exception handling, a new
//	BombStringDetonator is instantiated on the stack, and currentP
//	is changed to point to it.  This makes the entire exception-handling
//	mechanism available during exception handling, recursively.
//
//	During the stack-unwinding phase, to make the information available
//	to SMART_BOMBs, problemInstanceP in the NEW instance of
//	BombStringDetonator points to the instance of the Problem class that
//	contains the information about the Problem being BLAST()ed.  This
//	may seem off-by-one, but it simplifies access.
//
//	After the stack is unwound, the information is copied into another
//	instance of the Problem class that is a member of the SHIELD catching
//	the error.  Thus it remains available (from another source) until
//	the SHIELD's processing is done.
//
//	In this single-threadded implementation, one BombStringDetonator
//	(firstInstance) is instantiated at static initialization time, and
//	currentP was already pointed to it at load time.  To modify for
//	a lightweight-multithreader, instantiate one initial instance per
//	lightweight task and switch currentP during task switching.
//
// !!!!	NOTE:  A nasty trick is played to allow bombs to be used during
//	static initialization time by those objects that are constructed
//	before firstInstance.  It depends on the assumption that pointers
//	in static objects are initialized by the >loader< to a value that
//	compares equal to the NULL pointer.
//
/* ========================================================================== */

class BombStringDetonator ROOTCLASS {
    public:
	static BombStringDetonator *	currentP;
    private:
	static BombStringDetonator	firstInstance;

	BombSuperclass *		firstP;
	Problem *			problemInstanceP;
	BombStringDetonator *		previousDetonatorP;

    public:

	BombStringDetonator();
	BombStringDetonator(int, int);

	Problem *		getProblemInstanceP();
	void detonateBombString(
		    Problem *	argProblemInstanceP
	);
	BombSuperclass *	fetchFirstP();

    private:
	BombStringDetonator *	fetchPreviousDetonatorP();	// for GC

	REQUIRE(3,"friend")
	friend class		Heaplet;
	friend class		BombSuperclass;
	friend class		BombJig;
	PERMIT(0,"friend")
};

/* ========================================================================== */
//
//	BLAST()
//
//	Detonate a string of bombs, until all blow or one catches the error.
//
//	BLAST_FROM_THE_PASSED() allows _FILE_ and _LINE_ to be passed in,
//	so a subroutine can report the location of the real cause of the error.
//
/* ========================================================================== */

extern void blast(Problem * argProblemInstanceP);

#define	BLAST(argProblemName)	BLAST_WITH_VAL(argProblemName,1)

#ifdef	BOMB_REPORT_LINE
#define	BLAST_WITH_VAL(argProblemName, val) {				\
		Problem problemInstance(				\
			STR(argProblemName), val, __FILE__, __LINE__);	\
		blast(&problemInstance);				\
	}

#define	BLAST_FROM_THE_PASSED(argProblemName, val, argFILE, argLINE) {	\
		Problem problemInstance(				\
			STR(argProblemName), val, argFILE,  argLINE);	\
		blast(&problemInstance);				\
	}

#else /* BOMB_REPORT_LINE */
#define	BLAST_WITH_VAL(argProblemName, val) {				\
		Problem problemInstance(				\
			STR(argProblemName), val);			\
		blast(&problemInstance);				\
	}

#define	BLAST_FROM_THE_PASSED(argProblemName, val, argFILE, argLINE) {	\
		Problem problemInstance(				\
			STR(argProblemName), val);			\
		blast(&problemInstance);				\
	}

#endif	/* BOMB_REPORT_LINE */

#ifdef USE_INLINE
#include "bombx.ixx"
#endif /* USE_INLINE */

#endif /* BOMBX_HXX */

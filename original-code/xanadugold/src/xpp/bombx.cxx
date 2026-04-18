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
//				bombx.cxx
//
//	Executables and globals for the objects supporting the Bomb macros.
//
//		By Michael McClary		1989
//
/* ========================================================================== */
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
//	 - corrected comments to match current regime.
//	 - grouped all functions by classes.
//	 - modified shield support to use BUILD_BOMB()
//		- michael Apr  9 1991
//
//	Merge with alpha-12:  change const -> CONST
//		-michael Apr 18 1991
//
//	Adding Doomsday Bombs
//		-michael Apr 20 1991
//
//	Initial inlining by Eric Hill, incorportated & checked.
//	Fixed assert hak.
//		michael  May  2 1991
//
//	Changed from arming-ordered detonation to construction-ordered
//	detonation.  (This matches the implementation that can be built on
//	the proposed standard, and works natuarally with a single-linked
//	list, eliminating two member variables and considerable overhead
//	in BombSuperclass and its children (i.e. strong pointers).)
//		- michael Jun 21 1991
//
//	Added BombStringDetonator::fetchFirstP() to support cbombs.
//		- michael Nov 2 1992 (merged Feb 17)
//
//	Uncommented change:  ASSERT() was hacked for macintosh compat.
//	This should be checked, moved to ccompatc.h, and corresponding
//	changes made to cbombs.
//		- detected by michael, Feb 17 1992
//
//	Made bombStringDetonatorP a static member variable (renamed currentP).
//	Made initialBombStringDetonator ditto (renamed firstInstance).
//		- michael Feb 27 1992
//
//	Switched to inline bombs.  BUILD_BOMB() stuff moved from cxx to ixx
//		- michael Mar 2 1992
//
//	Added BombStringDetonator::previousDetonatorP and fetch...()
//	to fix GC-during-blasting bug.
//		- michael Mar  6 1992
//
//    Fixed text after #else to deep ANSI preprocessors happy.
//            - michael Mar 24 1992

#include "bombx.hxx"	/* Too little stuff to bother with bombp.hxx */

VERSION_ID(bombx_cxx,
	   "$Id: bombx.cxx,v 2.11 1993/03/24 02:48:05 eric Exp $")

#ifndef BOMBX_IXX
#include "bombx.ixx"
#endif /* BOMBX_IXX */

PERMIT(N,"ALL")
#include <string.h>
#include <stream.h>
#include <assert.h>
#ifdef unix
#ifndef GNU
#include <osfcn.h>
#endif
#endif /* unix */

#ifndef macintosh
#define	ASSERT(x)		\
	PERMIT(1,"hard cast")	\
	assert(x);		\
	PERMIT(0,"hard cast")
#else
#include <segload.h>
#define ASSERT(x)			\
	{debugstr(STR(x) ";sc6;td");	\
	ExitToShell();}
#endif /* macintosh */

#ifdef __sgi
#include "stdlib.h"
#endif

PERMIT(0,"ALL")
/*^L*//* ========================================================================== */
//
//	The Problem object
//
/* ========================================================================== */
//
//	Constructor:  Squirrel away the stuff to report.
//
/* ========================================================================== */

static void writeNumberOnError (int number) {
	char numBuf[16];
        int  numStart = 16;
        int  rest = number;

        while (rest && numStart) {
            numBuf[--numStart] = rest % 10 + '0';
            rest /= 10;
        }

        write(2, numBuf + numStart, 16 - numStart);
}

static void
bogusFree(CONST char *,CONST char *)
{}

Problem::
Problem (
	  CONST char *	argProblemName
	, CONST int	argVal
#ifdef	BOMB_REPORT_LINE
	, CONST char *	argFileName
	, int		argLineNumber
#endif	/* BOMB_REPORT_LINE */
) {
	problemName	= argProblemName;
	val		= argVal;
#ifdef	BOMB_REPORT_LINE
	fileName	= argFileName;
	lineNumber	= argLineNumber;
#endif	/* BOMB_REPORT_LINE */
	specialFree	= bogusFree;
}

REQUIRE(1,"pointer to function")

Problem::
Problem (
	  CONST char *	argProblemName
	, CONST int	argVal
#ifdef	BOMB_REPORT_LINE
	, CONST char *	argFileName
	, int		argLineNumber
#endif	/* BOMB_REPORT_LINE */
	, void		(*argSpecialFree)(CONST char *, CONST char *)
) {
	problemName	= argProblemName;
	val		= argVal;
#ifdef	BOMB_REPORT_LINE
	fileName	= argFileName;
	lineNumber	= argLineNumber;
#endif	/* BOMB_REPORT_LINE */
	specialFree	= argSpecialFree;
}

PERMIT(0,"pointer to function")
/*^L*//* ========================================================================== */
//
//	For the copy in the Shield object:
//
//	Constructor:          Do nothing.
//	copyIn():             Squirrel away the stuff to report.
//	freeStrings():        Maybe free strings stored on heap by letter bomb.
//	Shield::Shield():     Shield constructor uses null Problem constructor.
//
/* ========================================================================== */

Problem::
Problem (){}

void Problem::
copyIn(	Problem *	argProblem)
{
	problemName	= argProblem -> problemName;
	val		= argProblem -> val;
#ifdef	BOMB_REPORT_LINE
	fileName	= argProblem -> fileName;
	lineNumber	= argProblem -> lineNumber;
#endif	/* BOMB_REPORT_LINE */
	specialFree	= argProblem -> specialFree;
}

void Problem::
freeStrings()
{
	(*this->specialFree)(
		  this->problemName
#ifdef	BOMB_REPORT_LINE
		, this->fileName
#else	/* BOMB_REPORT_LINE */
		, NULL
#endif	/* BOMB_REPORT_LINE */
	);
}
/*^L*//* ========================================================================== */
//
//	printOn():  Print the error report.
//
/* ========================================================================== */

REQUIRE(3,"reference")

void Problem::
printOn (ostream& oo)
{
	oo << "Problem("	<< this->problemName
	   << ", val = "	<< this->val
#ifdef	BOMB_REPORT_LINE
	   << ", file = "	<< this->fileName
	   << ", line = "	<< this->lineNumber
#endif	/* BOMB_REPORT_LINE */
	   << ")";
}

ostream& operator<< ( ostream& oo, Problem * argProblemP ) {
	if (argProblemP) {
		argProblemP->printOn(oo);
	} else {
		oo << "NULL";
	}
	return oo;
}

PERMIT(0,"reference")

void Problem::
printError ()
{
	write(2, "Problem(", 8);
        write(2, this->problemName, strlen(this->problemName));
        write(2, ", val = ", 8);
        writeNumberOnError(this->val);
#ifdef	BOMB_REPORT_LINE
        write(2, ", file = ", 9);
        write(2, this->fileName, strlen(this->fileName));
        write(2, ", line = ", 9);
        writeNumberOnError(this->lineNumber);
#endif	/* BOMB_REPORT_LINE */
        write(2, ")\n", 2);
}

/* ========================================================================== */
//
//			checkProblem()
//
//	See if problem suggested matches the one encountered.
//
/* ========================================================================== */

REQUIRE(1,"hard cast")

BooleanVar Problem::
checkProblem(CONST char * argProblemName) {
	return (BooleanVar) strcmp(argProblemName, problemName);
}

PERMIT(0,"hard cast")
/*^L*//* ========================================================================== */
//
//			getProblemName()
//			getVal()
//			getFileName()
//			getLineNumber()
//
//	Return values from Problem object.
//
/* ========================================================================== */

CONST char * Problem::
getProblemName()
{
	return problemName;
}

int Problem::
getVal()
{
	return val;
}

CONST char * Problem::
getFileName()
{
#ifdef	BOMB_REPORT_LINE
	return fileName;
#else	/* BOMB_REPORT_LINE */
	return "NOT_AVAILABLE";
#endif	/* BOMB_REPORT_LINE */
}

int Problem::
getLineNumber()
{
#ifdef	BOMB_REPORT_LINE
	return lineNumber;
#else	/* BOMB_REPORT_LINE */
	return -1;
#endif	/* BOMB_REPORT_LINE */
}
/*^L*//* ========================================================================== */
//
//	Constructor for the Shield structure (which is the VALUE squirreled
//	away by a SHIELD() or LOUD_SHIELD() construct.)
//
//	(Just initialize the contained Problem object.)
//
/* ========================================================================== */

Shield::
Shield():problem(){};

/* ========================================================================== */
//
//	Support for standard exported Bomb and Bomb-like objects:
//	SHIELD()s, LOUD_SHIELD()s, and the ShieldFree bomb.
//
//	(SHIELD()s and LOUD_SHIELD()s are essentially smart bombs, but they
//	 also override the inspectFuse member function.)
//
/* ========================================================================== */

/* ========================================================================== */
//
//	SHIELD:  Catch a set of exceptions.
//
/* ========================================================================== */

Shield * _shield_Bomb::
inspectFuse()
{
	return (bombArmed) ? CHARGE : NULL;
};

/* ========================================================================== */
//
//	LOUD_SHIELD:	Same as SHIELD, but also complain on standard error
//
/* ========================================================================== */

Shield * _lshield_Bomb::
inspectFuse()
{
	return (bombArmed) ? CHARGE : NULL;
};

/*^L*//* ========================================================================== */
//
//	PROBLEM_LIST for Doomsday Bomb
//
/* ========================================================================== */

extern char **   CAT(_DOOMSDAY,_shieldList)() {
    static char * local[] = { ERRLIST(1,(DOOMSDAY)), 0};
    return local;
}
/*^L*//* ========================================================================== */
//
//	BombStringDetonator object.
//
/* ========================================================================== */
//
//	Instantiation of initial instances.  (Single-threading version):
//
/* ========================================================================== */

BombStringDetonator *	BombStringDetonator::currentP =
					&BombStringDetonator::firstInstance;
#ifdef HIGHC
static INLINE void * operator new (size_t s, void * p) {
	return p;
}
/* to get around bug */
static BombStringDetonator fixup (void * where, int a, int b) {
	return * new (where) BombStringDetonator (a, b);
}
BombStringDetonator	BombStringDetonator::firstInstance =
	fixup (&BombStringDetonator::firstInstance,0,0);
#else
BombStringDetonator	BombStringDetonator::firstInstance = 
					BombStringDetonator(0, 0);
#endif

/* ========================================================================== */
//
//	Constructor:  Just clear the pointers.
//
//	A second constructor is used for the initial static instance, because:
//	 - the pointers in a static instance are born cleared, and:
//	 - clearing them at bomb's turn during static initialization time
//	   would blow away the current bomb string.
//
//	!!!! This will break if pointers in uninitialized static objects
//	aren't born with a value that compares equal to NULL.  Examination
//	of various manuals once convinced us that we're safe on this issue,
//	but it should be checked on each platform.
//
/* ========================================================================== */

BombStringDetonator::
BombStringDetonator()
{
	firstP			= NULL;
	problemInstanceP	= NULL;
	previousDetonatorP	= NULL;
}

BombStringDetonator::
BombStringDetonator(int, int)
{
}

/* ========================================================================== */
//
//	getProblemInstanceP():	Return the pointer to the problem instance
//	fetchFirstP():		Return the pointer to the latest bomb
//	fetchPreviousDetonatorP():	Ditto previous detonator (for GC).
//
/* ========================================================================== */

Problem * BombStringDetonator::
getProblemInstanceP()
{
	return problemInstanceP;
}

BombSuperclass * BombStringDetonator::
fetchFirstP()
{
	return firstP;
}

BombStringDetonator * BombStringDetonator::
fetchPreviousDetonatorP()
{
	return previousDetonatorP;
}
/*^L*//* ========================================================================== */
//
//			detonateBombString()
//
//	Activate bomb objects (which remove themselves from the string)
//	until all are gone or one grabs the execution with longjmp().
//
//	 - Provides a new BombStringDetonator object for any bombs
//	   used by things triggered.
//
/* ========================================================================== */

void BombStringDetonator::
detonateBombString (Problem * argProblemInstanceP)
{
	CONST BooleanVar Unexploded_Bomb = FALSE;
	CONST BooleanVar Uncaught_Signal = FALSE;
	CONST BooleanVar Uncaught_Signal_Escaped_Inspection = FALSE;
	CONST BooleanVar Doomsday_Device_Triggered = FALSE;

	Shield *		shieldP;
	BombStringDetonator	newBombStringDetonator;
	BombSuperclass *	tempBombP;
	char **			tempErrorListP;
	BooleanVar		invert;
	BooleanVar		match;

/* ========================================================================== */
//
//	Start a new fuse, so exploding bombs can use bombs, too.
//
/* ========================================================================== */

	currentP = &newBombStringDetonator; // In case more bombs.

	newBombStringDetonator.previousDetonatorP = this;
					// so GC can follow all bomb strings.

	newBombStringDetonator.problemInstanceP = argProblemInstanceP;
					// Remember why (& make available)

/* ========================================================================== */
//
//	Before setting off the bombs, inspect the fuse.
//
//	If no shields would catch the explosion, don't light the fuse.
//	Instead, crash out now, while the in-memory structures are still
//	intact for the post-mortem.
//
//	(This isn't a perfect guarantee:  a bomb COULD knock down the shield.)
//
/* ========================================================================== */

	for (tempBombP = firstP; tempBombP; tempBombP = tempBombP->nextP) {
		if ((shieldP = tempBombP->inspectFuse())) {
			tempErrorListP = shieldP->errorListP;
			if (*tempErrorListP &&
			    strcmp(*tempErrorListP,"DOOMSDAY") == 0) {
                                argProblemInstanceP->printError();
						// Tell humans about it.
//				ASSERT(Doomsday_Device_Triggered);
                                write(2, "Doomsday_Device_Triggered\n", 26);
				abort();
						// Die in flames.
			}
			invert = *tempErrorListP &&
				strcmp(*tempErrorListP,"ALL_BUT") == 0;
			if (invert) {
				    tempErrorListP++;
			}
			match = FALSE;
			while (*tempErrorListP && !match) {
				match = argProblemInstanceP->
				    checkProblem(*tempErrorListP++) == 0;
			}
	/**/		if (match != invert) {goto ickGotcha;}
		}
	}{						// Nobody caught it:
        	argProblemInstanceP->printError();	// Tell humans about it.
//		ASSERT(Uncaught_Signal);		// Die in flames.
                write(2, "Uncaught_Signal\n", 16);
		abort();
	}
ickGotcha:

/* ========================================================================== */
//
//	Now that we've assured ourselves the error will be caught,
//	we'll actually set off the bombs.
//
/* ========================================================================== */

	while (firstP) {			// Set off the Bomb objects
		if ((shieldP = firstP->inspectFuse())) {
			tempErrorListP = shieldP->errorListP;
			invert = *tempErrorListP &&
				strcmp(*tempErrorListP,"ALL_BUT") == 0;
			if (invert) {
				    tempErrorListP++;
			}
			match = FALSE;
			while (*tempErrorListP && !match) {
				match = argProblemInstanceP->
				    checkProblem(*tempErrorListP++) == 0;
			}
			if (match != invert) {
				firstP->detonateBomb(BLASTING_STOPS);
				// Don't check new firstP, we know what it did.
				currentP = this;
							// restore pointer.
				shieldP->problem.copyIn(argProblemInstanceP);
							// copy problem data
				longjmp(shieldP->jmpBuf,
					argProblemInstanceP->getVal()
				);		// and jump.
			}
		}

		firstP->detonateBomb(BLASTING);
		if (newBombStringDetonator.firstP != NULL) {
			ASSERT(Unexploded_Bomb);	//  Oops!  Left trash.
		}

		firstP = firstP->nextP;		// Fake ~BombSuperclass()

	}					// Nobody caught it:
        argProblemInstanceP->printError();	// Tell humans about it.
	ASSERT(Uncaught_Signal_Escaped_Inspection);	// Die in flames.
}

/* ========================================================================== */
//
//		blast(): Support for BLAST() macro
//
//	Forward requests to detonateBombString()
//
/* ========================================================================== */

void blast(Problem * argProblemInstanceP)
{
	BombStringDetonator::currentP->
		detonateBombString(argProblemInstanceP);
}
/*^L*//* ========================================================================== */
//
//			the BombSuperclass
//
/* ========================================================================== */
//
//	Constructor, Destructor, armBomb(), disarmBomb(), and detonateBomb()
//	are in bombx.ixx
//
/* ========================================================================== */
//
//	inspectFuse():  Report whether this is a Shield, and what it catches.
//
//	- (The shield subclasses re-define this to return a pointer to
//	   their errorList.)
//
/* ========================================================================== */

Shield * BombSuperclass::
inspectFuse()
{
		return NULL;
}

/* ========================================================================== */
//
//		gCHook(): Hook for garbage collector, on model of inspectFuse
//
/* ========================================================================== */

void * BombSuperclass::
gCHook()
{
		return NULL;
}

void BombSuperclass::
gCHook(void*)
{
}

/* ========================================================================== */
//
//		removeFromMidString():
//
//	When a bomb is returned from a function, it may live longer than other
//	bombs that were constructed sooner.  Thus, those bombs will not be at
//	the end of the string when they are destroyed.  Their destructors
//	detect this, and call this code to extract them from the string.
//
//	The common case is inlined, but this one is a subroutine.
//
//	If we got here, we already know the bomb is not at the end of
//	the string.
//
/* ========================================================================== */

void BombSuperclass::
removeFromMidString()
{
	
return;
register BombSuperclass *	tempBombP =
			BombStringDetonator::currentP->firstP;

	while(tempBombP && tempBombP->nextP != this) {
		if (tempBombP->nextP == NULL) {
			CONST BooleanVar Bomb_Missing_From_String = FALSE;
			//ASSERT(Bomb_Missing_From_String);
		}
		tempBombP = tempBombP->nextP;
	}
	if(tempBombP){
	    tempBombP->nextP = this->nextP;
	}
}

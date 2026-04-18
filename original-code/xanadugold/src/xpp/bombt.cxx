/* ========================================================================== */
//
//	Copyright (c) 1989, 92 by Xanadu Operating Company, All Rights Reserved.
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
//			bombt.cxx
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
//	Added test of Doomsday Bomb
//		-michael  Apr 20 1991
//
//	Added bogus operator delete()s to shut up warnings.
//	Adding test of gCHook()/things with no overriding of detonateBomb()
//		-michael  May  3 1991
//
//	Changed tests to _BEGIN _END style.  (This leaves the backward-
//	compatability macros untested, but they worked when they were
//	tested before the change.)
//		-michael  Feb 25 1992
//
//	Made bombStringDetonatorP a static member variable (renamed currentP).
//		- michael Feb 27 1992
//
//	Split off bombt.hxx and bombt.ixx during ORDER/BUILD_BOMB / inline
//	upgrage
//		- michael Mar  3 1992
//
//	Added tests for TRY/CATCH
//		- michael Mar 12 1992

/* $Id: bombt.cxx,v 2.8 1993/01/05 17:29:34 ravi Exp $ */

#include <stdlib.h>
#include <stream.h>

#include "bombx.hxx"

#include "bombt.hxx"

#ifndef BOMBT_IXX
#include "bombt.ixx"
#endif /* BOMBT_IXX */

static char *
ptrChanged(void * pointer)
{
	static void *	difref = NULL;

	if (pointer == NULL) {
		return "is NULL.";
	} else {
		if (difref == NULL) {
			difref = pointer;
		}
		if (difref == pointer) {
			return "is in the same place.";
		} else {
			return "is in a different place.";
		}
	}
}

void sub1();
void sub2();
void sub3();
void sub4();
void sub5();
void sub6();
void sub7();
void sub8();
void sub9();
void sub10();
void sub11();
void sub12();

int XU_MAIN(int, char**)
{
	cerr << "Testing Bomb\n";

	sub1();	// Tests arming/firing sequence.

	sub2();	// Tests BLAST() macro and smartbomb source detection.

	sub3();	// Tests plant/arm/fire inside a loop.

	sub4();	// Tests DISARM_BOMB()

//	sub5();	// Tests crash-program-if-bomb-not-caught-on-shield
		// Therefore, turned off in this module.
		// (Failure to catch a PROBLEM is considered a fatal error.
		//  The demolition package previews fuse to see that a SHIELD
		//  will catch the PROBLEM.  If none does, it aborts
		//  [assert failure, core dump] rather than setting
		//  off bombs that might disassemble the stuff you
		//  need for debugging.)

	sub6();	// Tests ALL_BUT in PROBLEM_LIST()

	sub7();	// Tests CONSTRUCTOR_BOMB(), which plugs a memory leak
		// in constructors.

	sub8();	// Tests CONSTRUCTOR_BOMB() interaction with member objects

//	sub9();	// Tests Doomsday Bombs.
		// Therefore, turned off in this module.

	sub10(); // Tests gCHook() and things that don't overload detonateBomb()

	sub11(); // Tests the order that bombs are detonated.  The original
		 // version detonates in the reverse of the order the bombs
		 // were armed, the revision as of June 1991 detonates in the
		 // reverse of the order they were planted.

	sub12(); // Tests TRY macro.

	cerr << "End of test of Bomb\n";
	exit(0);
}


void sub1()
{
	char*	message = "BLAM!.\n";

	cerr << "\nsub1(): Testing arming/firing sequence\n";

	cerr << "About to do PLANT_BOMB()\n";
	PLANT_BOMB(cerr,mess);

	cerr << "About to do ARM_BOMB()\n";
	ARM_BOMB(mess,message);

	cerr << "About to do ARM_BOMB()\n";
	ARM_BOMB(mess, message);

	cerr << "About to do DETONATE_BOMB()\n";
	DETONATE_BOMB(mess);

	cerr << "About to do DETONATE_BOMB()\n";
	DETONATE_BOMB(mess);

	cerr << "About to do ARM_BOMB()\n";
	ARM_BOMB( mess, message);

	cerr << "Leaving sub1()\n";
}

#include <assert.h>
PROBLEM_LIST(FOO,3,(BAR_ERROR,FOO_ERROR,BAZ_ERROR));
PROBLEM_LIST(SNURD,2,(BAR_ERROR,SNURD_ERROR));

void sub2()
{
	char*	message = "BLAM!.\n";

	cerr << "\nsub2(): Testing smartbomb signal source detection, and BLAST() macro\n";

	{
		cerr << "About to do PLANT_BOMB() on smart bomb\n";
		PLANT_BOMB(smart,smart);

		cerr << "About to do ARM_BOMB() on smart bomb\n";
		ARM_BOMB( smart, message);

		cerr << "About to leave area of smart bomb\n";
	}

	cerr << "About to do PLANT_BOMB() on smart bomb\n";
	PLANT_BOMB(smart,smart);

	cerr << "About to do ARM_BOMB() on smart bomb\n";
	ARM_BOMB( smart, message);

	cerr << "About to do DETONATE_BOMB() on smart bomb\n";
	DETONATE_BOMB(smart);
	
	cerr << "About to do ARM_BOMB() on smart bomb\n";
	ARM_BOMB( smart, message);

	cerr << "About to rearm smart bomb\n";
	ARM_BOMB( smart, message);

	cerr << "About to do ARM_BOMB() on smart bomb\n";
	ARM_BOMB( smart, "First bomb message.\n");

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(BAZ);

	cerr << "About to do SHIELD_UP()\n";
	SHIELD_UP_BEGIN(BAZ, FOO) {
		cerr << "Caught it!  VAL = " << VAL << "\n";
		cerr << "problemName = " << PROBLEM(BAZ).getProblemName();
		cerr << ", val = " << PROBLEM(BAZ).getVal();
		cerr << ", fileName = " << PROBLEM(BAZ).getFileName();
		cerr << ", lineNumber = " << PROBLEM(BAZ).getLineNumber();
		cerr << "\n";
		/* assert(FALSE); */
		SHIELD_RETURN( SHIELD_VOID );
	} SHIELD_UP_END(BAZ);

	cerr << "About to do PLANT_BOMB() on second smart bomb\n";
	PLANT_BOMB(smart,smart2);

	cerr << "About to do ARM_BOMB() on second smart bomb\n";
	ARM_BOMB( smart2, "Second bomb message.\n");

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(SNURD);

	cerr << "About to do SHIELD_UP()\n";
	SHIELD_UP_BEGIN(SNURD, SNURD) {
		cerr << "Caught it!  VAL = " << VAL << "\n";
		assert(FALSE);
	} SHIELD_UP_END(SNURD);

	cerr << "About to do PLANT_BOMB() on recursive bomb.\n";
	PLANT_BOMB(recursive,recurs);

	cerr << "About to do ARM_BOMB() on recursive bomb.\n";
	ARM_BOMB(recurs,message);

	cerr << "About to do PLANT_BOMB() on third smart bomb\n";
	PLANT_BOMB(smart,smart3);

	cerr << "About to do ARM_BOMB() on third smart bomb\n";
	ARM_BOMB( smart3, "Third bomb message.\n");

	cerr << "About to do PLANT_BOMB() on disarmer bomb\n";
	PLANT_BOMB(disarmer,disarmer);

	cerr << "About to do ARM_BOMB() on disarmer bomb\n";
	ARM_BOMB( disarmer, &SNURD_shield_BombTag);

	// cerr << "About to do BLAST_WITH_VAL()\n";
	// BLAST_WITH_VAL(X_ERROR, 5);
	// BLAST_WITH_VAL(SNURD_ERROR, 5);	// Uncaught Signal Escaped Detection
	cerr << "About to do BLAST()\n";
	BLAST(FOO_ERROR);

	cerr << "Leaving sub2()\n";
}

void sub3()
{
	int i;
	char*	message = "This is the message.\n";

	cerr << "\nsub3(): Testing plant / arm / fire in loop with local bomb\n";

	for (i=0; i<3; i++) {
		cerr << "Top of loop\n";
		{
			cerr << "About to do PLANT_BOMB()\n";
			PLANT_BOMB(cerr,mess);

			cerr << "Inside scope\n";

			cerr << "About to do ARM_BOMB()\n";
			ARM_BOMB(mess,message);
			cerr << "About to leave scope\n";
		}
		cerr << "Outside scope\n";
	}
	cerr << "Outside loop, leaving sub3()\n";
}

void sub4()
{
	char*	message = "This is the message.\n";

	cerr << "\nsub4(): Testing disarm\n";

	cerr << "About to do PLANT_BOMB()\n";
	PLANT_BOMB(cerr,mess);

	cerr << "About to do ARM_BOMB()\n";
	ARM_BOMB(mess,message);

	cerr << "About to do DISARM_BOMB()\n";
	DISARM_BOMB(mess);

	cerr << "leaving sub4()\n";
}


void sub5()
{
	char*	cheatmes = "fizzle!.\n";

	cerr << "\nsub5(): Testing BLAST_WITH_VAL() test-for-unexploded-bomb\n";

	cerr << "About to do PLANT_BOMB() on cheat bomb\n";
	PLANT_BOMB(cheat,cheat);

	cerr << "About to do ARM_BOMB() on cheat bomb\n";
	ARM_BOMB( cheat, cheatmes);

	cerr << "About to do BLAST_WITH_VAL()\n";
	BLAST_WITH_VAL(FOO_ERROR, 1);

	cerr << "Leaving sub5()\n";
}
/* ========================================================================== */
//
//	sub6():  Test ALL_BUT
//
/* ========================================================================== */

PROBLEM_LIST(EVERY,1,(ALL_BUT));
PROBLEM_LIST(ALLBUT,2,(ALL_BUT,SNURD_ERROR));

void sub6()
{
	char*	message = "BLAM!.\n";

	cerr << "\nsub6(): EVERYTHING and ALL_BUT\n";


	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(EVER);

	cerr << "About to do SHIELD_UP()\n";
	SHIELD_UP_BEGIN(EVER, EVERY) {
		cerr << "Caught it with EVERYTHING!  VAL = " << VAL << "\n";
		SHIELD_RETURN( SHIELD_VOID );
	} SHIELD_UP_END(EVER);

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(ALLB);

	cerr << "About to do SHIELD_UP()\n";
	SHIELD_UP_BEGIN(ALLB, ALLBUT) {
		cerr << "Caught it with ALL_BUT!  VAL = " << VAL << "\n";
		SHIELD_RETURN( SHIELD_VOID );
	} SHIELD_UP_END(ALLB);

	cerr << "About to do BLAST_WITH_VAL()\n";
	// BLAST_WITH_VAL(FOO_ERROR, 1);		// First catches
	BLAST_WITH_VAL(SNURD_ERROR, 2);	// Second catches

	cerr << "Leaving sub6()\n";
}
 /* ========================================================================== */
//
//	Die and DieSub:  Crash in the superclass constructor:
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

Die::
Die() {
	cerr << "Die: Object " << ptrChanged((void *)this) << "\n";
	BLAST_WITH_VAL(DIE,1);
};

Die::
~Die() {
	cerr << "~Die\n";
}

DieSub::
DieSub() {
	cerr << "DieSub: \n";
	BLAST_WITH_VAL(DIE_LATER,1);
};

DieSub::
~DieSub() {
	cerr << "~DieSub: \n";
};

void * DieSub::
operator new(size_t)
{
	BLAST(BOGUS_OPERATOR_NEW_CALLED);
	return NULL;
}

void * DieSub::
operator new(size_t s, DieSubConstructor_Bomb * toBeArmed)
{
	void *	result = ::operator new(s);

	toBeArmed->armBomb((DieSub *) result);
	return result;
}

void DieSub::
operator delete(void* p)
{
#ifdef HIGHC
	delete p;
#else
	::operator delete(p);
#endif
}

DieSub *
dieSub()
{
	PLANT_BOMB(DieSubConstructor,DieSubConstructor);

	return new(&DieSubConstructor_BombTag) DieSub();
}

/* ========================================================================== */
//
//	Croak and CroakSub:  Crash in the subclass constructor:
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

Croak::
Croak() {
	cerr << "Croak: Object " << ptrChanged((void *)this) << "\n";
};

Croak::
~Croak() {
	cerr << "~Croak\n";
};

CroakSub::
CroakSub() {
	cerr << "CroakSub: \n";
	BLAST_WITH_VAL(DIE_LATER,1);
}
CroakSub::
~CroakSub() {
	cerr << "~CroakSub: \n";
}

void * CroakSub::
operator new(size_t)
{
	BLAST(BOGUS_OPERATOR_NEW_CALLED);
	return NULL;
}

void * CroakSub::
operator new(size_t s, CroakSubConstructor_Bomb * toBeArmed)
{
	void *	result = ::operator new(s);

	toBeArmed->armBomb((CroakSub *) result);
	return result;
}

void CroakSub::
operator delete(void* p)
{
#ifdef HIGHC
	delete p;
#else
	::operator delete(p);
#endif
}

CroakSub *
croakSub()
{
	PLANT_BOMB(CroakSubConstructor,CroakSubConstructor);

	return new(&CroakSubConstructor_BombTag) CroakSub();
}

/* ========================================================================== */
//
//	Live and LiveSub:  Don't crash.
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

LiveSub::
LiveSub() {
	cerr << "LiveSub: \n";
}
LiveSub::
~LiveSub() {
	cerr << "~LiveSub: \n";
}

void * LiveSub::
operator new(size_t)
{
	BLAST(BOGUS_OPERATOR_NEW_CALLED);
	return NULL;
}

void * LiveSub::
operator new(size_t s, LiveSubConstructor_Bomb * toBeArmed)
{
	void *	result = ::operator new(s);

	toBeArmed->armBomb((LiveSub *) result);
	return result;
}

void LiveSub::
operator delete(void* p)
{
#ifdef HIGHC
	delete p;
#else
	::operator delete(p);
#endif
}

LiveSub *
liveSub()
{
	PLANT_BOMB(LiveSubConstructor,LiveSubConstructor);

	return new(&LiveSubConstructor_BombTag) LiveSub();
}
 /* ========================================================================== */
//
//	sub7():	Test constructor bombs.
//
/* ========================================================================== */

PROBLEM_LIST(DIE,2,(DIE,DIE_LATER));

void sub7()
{
	DieSub		*dieP;
	CroakSub	*croakP;
	LiveSub		*liveP;

	cerr << "\nsub7(): Testing CONSTRUCTOR_BOMB()\n";

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(DIS);

	do {
		cerr << "\nAbout to do SHIELD_UP()\n";
		SHIELD_UP_BEGIN(DIS, DIE) {
			SHIELD_BREAK;
		} SHIELD_UP_END(DIS);

		cerr << "About to do 'new CroakSub()'\n";
		croakP = croakSub();				////
		cerr << "Oops!\n";
		BLAST_WITH_VAL(CONSTRUCTOR_DIDNT_BLOW,1);
	} while (FALSE);

	do {
		cerr << "\nAbout to do SHIELD_UP()\n";
		SHIELD_UP_BEGIN(DIS, DIE) {
			SHIELD_BREAK;
		} SHIELD_UP_END(DIS);

		cerr << "About to do 'new DieSub()'\n";
		dieP = dieSub();				////
		cerr << "Oops!\n";
		BLAST_WITH_VAL(CONSTRUCTOR_DIDNT_BLOW,1);
	} while (FALSE);

	cerr << "\nAbout to do 'new LiveSub()'\n";
	liveP = liveSub();					////

	cerr << "About to do delete liveP\n";
	delete liveP;

	cerr << "\nAbout to do 'new LiveSub()'\n";
	liveP = liveSub();					////

	cerr << "About to do delete liveP\n";
	delete liveP;

	cerr << "\nLeaving sub7()\n";
}
/* ========================================================================== */
//
//  Member objects, one with a failing constructor.  (To test the inability
//  of the BOMB() package to correctly handle such failures.)
//
/* ========================================================================== */

Cracked::
Cracked() {
	cerr << "Cracked: \n";
}
Cracked::
~Cracked() {
	cerr << "~Cracked: \n";
}

CrackedA::
CrackedA() {
	cerr << "CrackedA: \n";
}
CrackedA::
~CrackedA() {
	cerr << "~CrackedA: \n";
}

CrackedB::
CrackedB() {
	cerr << "CrackedB: \n";
	BLAST_WITH_VAL(BLAP,1);
}
CrackedB::
~CrackedB() {
	cerr << "~CrackedB: \n";
}

CrackedC::
CrackedC() {
	cerr << "CrackedC: \n";
}
CrackedC::
~CrackedC() {
	cerr << "~CrackedC: \n";
}

/* ========================================================================== */
//
//  Class containing member objects, one with a failing constructor, (to test
//  the inability of the BOMB() package to correctly handle such failures.)
//
/* ========================================================================== */

BaseThing::
BaseThing() {
	cerr << "BaseThing: \n";
};
BaseThing::
~BaseThing() {
	cerr << "~BaseThing: \n";
};

void * BaseThing::
operator new(size_t)
{
	BLAST(BOGUS_OPERATOR_NEW_CALLED);
	return NULL;
}

void * BaseThing::
operator new(size_t s, BaseThingConstructor_Bomb * toBeArmed)
{
	void *	result = ::operator new(s);

	toBeArmed->armBomb((BaseThing *) result);
	return result;
}

void BaseThing::
operator delete(void* p)
{
#ifdef HIGHC
	delete p;
#else
	::operator delete(p);
#endif
}

BrokenThing::
BrokenThing() {
	cerr << "BrokenThing: Object " << ptrChanged((void *)this) << "\n";
};
BrokenThing::
~BrokenThing() {
	cerr << "~BrokenThing\n";
};

BrokenDerivedThing::
BrokenDerivedThing() {
	cerr << "BrokenDerivedThing: Object " << ptrChanged((void *)this) << "\n";
};
BrokenDerivedThing::
~BrokenDerivedThing() {
	cerr << "~BrokenDerivedThing\n";
};

BrokenDerivedThing *
brokenDerivedThing()
{
	PLANT_BOMB(BaseThingConstructor,BaseThingConstructor);

	return new(&BaseThingConstructor_BombTag) BrokenDerivedThing();
}

/* ========================================================================== */
//
//  Test of the inability of the BOMB() package to correctly handle failures
//  in the constructors of member objects.
//
//  (Also tests BOOBY_TRAP() macro.)
//
/* ========================================================================== */

PROBLEM_LIST(BLAP,1,(BLAP));

void sub8()
{
	BrokenDerivedThing	*brokenDerivedThingP;

	cerr << "\nsub8(): Testing CONSTRUCTOR_BOMB()\n";

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(BOOBY_TRAPPING);

	cerr << "\nAbout to do BOOBY_TRAP()\n";

	BOOBY_TRAP_BEGIN(BLAP,CONSTRUCTOR_DIDNT_BLOW) {
		cerr << "About to do 'new BrokenDerivedThing()'\n";
		brokenDerivedThingP = brokenDerivedThing();
		cerr << "Oops!\n";
	} BOOBY_TRAP_END();

	cerr << "\nLeaving sub8()\n";
}

/* ========================================================================== */
//
//	Test DOOMSDAY_BOMB()
//
/* ========================================================================== */

void sub9()
{
	cerr << "\nsub9(): Testing Doomsday Bomb.  (YIKE!)\n";

	cerr << "About to do PLANT_DOOMSDAY_BOMB()\n";
	PLANT_DOOMSDAY_BOMB();

	cerr << "About to do ARM_DOOMSDAY_BOMB()\n";
	ARM_DOOMSDAY_BOMB();

	cerr << "About to do BLAST_WITH_VAL()\n";
	BLAST_WITH_VAL(FOO_ERROR, 1);

	cerr << "Leaving sub9()\n";
}

/* ========================================================================== */
//
//	Test gCHook() and pointerish things that don't override detonateBomb()
//
/* ========================================================================== */
//
//	A couple pointer-class-like things
//
/* ========================================================================== */

void * TestPtrThing::
gCHook ()
{
	return this->value;
}

/* ========================================================================== */

void * OptimizedTestPtrThing::
gCHook ()
{
	return this->value;
}

/* ========================================================================== */
//
//	Class for getting hooks into the bomb stuff.
//
/* ========================================================================== */

void BombJig::
printGCHooks()
{
	BombSuperclass *	tempBombP;

	cerr << "gCHooks() return:";
	for (
	    tempBombP = BombStringDetonator::currentP->firstP;
	    tempBombP; 
	    tempBombP = tempBombP->nextP
	) {
		cerr << " " << (int)(tempBombP->gCHook());
	}
	cerr << "\n";
}

/* ========================================================================== */
//
//	The test itself
//
/* ========================================================================== */

void sub10()
{
	cerr << "\nsub10(): Testing gCHook() and pointerish things\n";
	cerr << "           that don't override detonateBomb()\n\n";

	theBombJig.printGCHooks();
	{
		theBombJig.printGCHooks();
		TestPtrThing	aTestPtrThing((void *)1);
		theBombJig.printGCHooks();
		{
			theBombJig.printGCHooks();
			OptimizedTestPtrThing	aTestPtrThing((void *)2);
			theBombJig.printGCHooks();
		}
		theBombJig.printGCHooks();
	}
	theBombJig.printGCHooks();

	cerr << "\nLeaving sub10()\n";
}

/* ========================================================================== */
//
//	sub11(): Test the order of detonation.
//
//	The original version of the bomb package detonated (during BLASTing)
//	in the reverse of the order of arming.  This makes more sense
//	semantically, but can not be built on top of the proposed C++
//	"try" mechanism.  The implementation also used a doubly-linked
//	list and a pointer-to-list-head in each bomb (though it could have
//	used a singly-linked list and a list-walk, since bombs are almost
//	never removed from the list unless they're at its head).
//	
//	In the Jun 1991 revision, the bombs are strung and unstrung during
//	construction and destruction, rather than arming and detonation.
//	ARM/DISARM becomes simply enable/disable, and the detonation order
//	is changed to be the reverse of the order of PLANTing, rather than
//	ARMing.  This makes a singly-linked list the natural idiom (cutting
//	the number of list-related member variables from three to one), and
//	we know how to do a separate implementation of this scheme on top of
//	"try".
//
//	This routine produces output that is sensitive to the detonation
//	order.
//
//	Note that the change also affects the coverage of SHIELDs, which
//	go from exposing only bombs ARMed after they are RAISEd to exposing
//	bombs PLANTED after they are INSTALLED.
//
/* ========================================================================== */

CAT(verbose,_Bomb)::
CAT(verbose,_Bomb)() {
	cerr << "verbose_Bomb constructed.\n";
}

CAT(verbose,_Bomb)::
~CAT(verbose,_Bomb)() {
	cerr << "~verbose_Bomb destructed.\n";
}

CAT(verbose,_Bomb) sub11a();

void sub11()
{
	char*	message1 = "BLAM number 1!\n";
	char*	message2 = "BLAM number 2!\n";
	char*	message3 = "BLAM number 3!\n";
	char*	message4 = "BLAM number 4!\n";

	cerr << "\nsub11(): Testing detection order during BLAST().\n";

	cerr << "About to do PLANT_BOMB() on smart bomb #1\n";
	PLANT_BOMB(smart,smart1);

	cerr << "About to do ARM_BOMB() on smart bomb #1\n";
	ARM_BOMB( smart1, message1);

	cerr << "About to do PLANT_BOMB() on smart bomb #2\n";
	PLANT_BOMB(smart,smart2);

	cerr << "About to do INSTALL_LOUD_SHIELD()\n";
	INSTALL_LOUD_SHIELD(BAZ);

	cerr << "About to do SHIELD_UP()\n";
	SHIELD_UP_BEGIN(BAZ, FOO) {
		cerr << "Caught it!  VAL = " << VAL << "\n";
		cerr << "problemName = " << PROBLEM(BAZ).getProblemName();
		cerr << ", val = " << PROBLEM(BAZ).getVal();
		cerr << ", fileName = " << PROBLEM(BAZ).getFileName();
		cerr << ", lineNumber = " << PROBLEM(BAZ).getLineNumber();
		cerr << "\n";
		/* assert(FALSE); */
		cerr << "Leaving sub11() via SHIELD_RETURN\n";
		SHIELD_RETURN( SHIELD_VOID );
	} SHIELD_UP_END(BAZ);

	cerr << "About to do PLANT_BOMB() on smart bomb #3\n";
	PLANT_BOMB(smart,smart3);

	cerr << "About to do PLANT_BOMB() on smart bomb #4\n";
	PLANT_BOMB(smart,smart4);

	cerr << "About to do ARM_BOMB() on smart bomb #4\n";
	ARM_BOMB( smart4, message4);

	cerr << "About to do ARM_BOMB() on smart bomb #3\n";
	ARM_BOMB( smart3, message3);

	cerr << "About to do ARM_BOMB() on smart bomb #2\n";
	ARM_BOMB( smart2, message2);

	cerr << "About to call sub11a()\n";
	(void) sub11a();

	cerr << "About to do BLAST()\n";
	BLAST(FOO_ERROR);

	cerr << "Leaving sub11() by falling off end.  ERROR!\n";
}

CAT(verbose,_Bomb) sub11a()
{
	char*	message1a = "BLAM number 1a!\n";

	cerr << "\nsub11a(): Testing destruction order returning a bomb.\n";

	cerr << "About to do PLANT_BOMB() on smart bomb #1a\n";
	PLANT_BOMB(smart,smart1a);

	cerr << "About to do ARM_BOMB() on smart bomb #1a\n";
	ARM_BOMB( smart1a, message1a);

	cerr << "Leaving sub11a().\n";

	return CAT(verbose,_Bomb)();
}

// A reminder:
//
// PROBLEM_LIST(FOO,3,(BAR_ERROR,FOO_ERROR,BAZ_ERROR));
// PROBLEM_LIST(SNURD,2,(BAR_ERROR,SNURD_ERROR));

void sub12()
{
	cerr << "\nsub12(): Testing TRY macros\n";

	cerr << "\nOne: do a TRY(FOO) catching a FOO_ERROR\n";
	TRY(FOO) {
		cerr << "One: About to BLAST(FOO_ERROR)\n";
		BLAST(FOO_ERROR);
	} CATCH {
		cerr << "One: Caught it.\n";
	} TRY_END;

	cerr << "\nTwo: Nesting TRY(SNURD) in TRY(FOO), blasting BAR_ERROR\n";
	TRY(FOO) {
		TRY(SNURD) {
			cerr << "Two: About to BLAST(BAR_ERROR)\n";
			BLAST(BAR_ERROR);
		} CATCH {
			cerr << "Two: Caught it in inner TRY.\n";
		} TRY_END;
	} CATCH {
			cerr << "Two: Caught it in outer TRY.\n";
	} TRY_END;

	cerr << "\nThree: Nesting TRY(SNURD) in TRY(FOO), not blasting\n";
	TRY(FOO) {
		TRY(SNURD) {
			cerr << "Three: Error-free inner part\n";
		} CATCH {
			cerr << "Three: Caught it in inner TRY.\n";
		} TRY_END;
	} CATCH {
			cerr << "Three: Caught it in outer TRY.\n";
	} TRY_END;


	cerr << "\nFour: Ditto, with no inner code to try.\n";
	TRY(FOO) {
		TRY(SNURD) {
		} CATCH {
			cerr << "Four: Caught it in inner TRY.\n";
		} TRY_END;
	} CATCH {
			cerr << "Four: Caught it in outer TRY.\n";
	} TRY_END;

	cerr << "\nFive: Nesting TRY(SNURD) in TRY(FOO), blasting SNURD_ERROR\n";
	TRY(FOO) {
		TRY(SNURD) {
			cerr << "Five: About to BLAST(SNURD_ERROR)\n";
			BLAST(SNURD_ERROR);
		} CATCH {
			cerr << "Five: Caught it in inner TRY.\n";
		} TRY_END;
	} CATCH {
			cerr << "Five: Caught it in outer TRY.\n";
	} TRY_END;

	cerr << "\nSix: Nesting TRY(SNURD) in TRY(FOO), blasting FOO_ERROR\n";
	TRY(FOO) {
		TRY(SNURD) {
			cerr << "Six: About to BLAST(FOO_ERROR)\n";
			BLAST(FOO_ERROR);
		} CATCH {
			cerr << "Six: Caught it in inner TRY.\n";
		} TRY_END;
	} CATCH {
			cerr << "Six: Caught it in outer TRY.\n";
	} TRY_END;

	cerr << "\nSeven: Testing LOUD_TRY(), VAL, and PROBLEM\n";
	LOUD_TRY(FOO) {
		cerr << "Seven: About to BLAST_WITH_VAL(FOO_ERROR, 7)\n";
		BLAST_WITH_VAL(FOO_ERROR, 7);
	} CATCH {
		cerr << "Seven: Caught it!  VAL = " << VAL << "\n";
		cerr << "Seven: problemName = " << TRY_PROBLEM.getProblemName();
		cerr << ", val = " << TRY_PROBLEM.getVal();
		cerr << ", fileName = " << TRY_PROBLEM.getFileName();
		cerr << ", lineNumber = " << TRY_PROBLEM.getLineNumber();
		cerr << "\n";
	} TRY_END;

	cerr << "\nLeaving sub12().\n";
}

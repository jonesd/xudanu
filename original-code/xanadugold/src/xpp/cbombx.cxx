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
//				cbombx.cxx
//
//	Executables and globals for the objects supporting the C Bomb macros.
//
//		By Michael McClary		1991
//
/* ========================================================================== */
//
//	Made bombStringDetonatorP a static member variable (renamed currentP).
//		- michael Feb 27 1992

/* $Id: cbombx.cxx,v 1.5 1992/11/25 23:26:03 eric Exp $ */

#include "bombx.hxx"

#include <stddef.h>

#define	IN_CBOMBX_CXX

C_DECL_BEGIN
#include "cbombc.h"
C_DECL_END

PERMIT(N,"ALL")
#include <assert.h>

#define	ASSERT(x)		\
	PERMIT(1,"hard cast")	\
	assert(x);		\
	PERMIT(0,"hard cast")

PERMIT(0,"ALL")
/* ========================================================================== */
//
//		cBlast(): Support for C_BLAST...() macros
//
//	A C-callable routine that constructs a Problem instance and forwards
//	the request to detonateBombString()
//
/* ========================================================================== */


void cBlast(
		  char *	aProblemName
		, int		aVal
#ifdef	BOMB_REPORT_LINE
		, char *	aFileName
		, int		aLineNumber
#endif	/* BOMB_REPORT_LINE */
) {
	Problem problemInstance(
		  aProblemName
		, aVal
#ifdef	BOMB_REPORT_LINE
		, aFileName
		, aLineNumber
#endif	/* BOMB_REPORT_LINE */
	);
	blast(&problemInstance);
}

/* ========================================================================== */
//
//		cReblast(): Support for C_REBLAST macro
//
//	A C-callable routine that forwards an existing problem instance to
//	detonateBombString()
//
/* ========================================================================== */

void cReblast(
		  void *	aProblemInstanceP
) {
	blast((Problem *)aProblemInstanceP);
}


/* ========================================================================== */
//
//	Generic C Bomb and C Shield Bombs.
//
/* ========================================================================== */

class GenericCBomb;

/* ========================================================================== */
//
//	The customization of C Bombs is done by the ActionFunction, which is
//	written in C.  It is passed the SourceOfDetonationSignal and the
//	the CHARGE when the bomb is detonated.
//
//	The CHARGE passed is a union of the limited number of allowable
//	charge types.  (Additional types can be added if necessarily.)
//	It is up to the ActionFunction to select the appropriate type.
//
/* ========================================================================== */

typedef	void (* ActionFuncP)(
	  SourceOfDetonationSignal	aSource
	, CValue			aCharge
);

/* ========================================================================== */
//
//	C bombs connect to the C++ bomb package through a Generic C Bomb.
//	This holds the CHARGE and a pointer to the ActionFunction, and
//	activate the ActionFunction as necessary.
//
//	The Generic C Bomb is constructed in storage provided by the
//	client C routine.  operator new() is overloaded to prevent
//	instantiation on the heap.
//
/* ========================================================================== */

class GenericCBomb: public BombSuperclass {
    protected:
	ActionFuncP	myActionFuncP;
	CValue		myCharge;

    public:
	void armBomb(CValue aCharge) /* NOT virtual! */
	{
		this->BombSuperclass::armBomb();
		this->myCharge = aCharge;
	};
	virtual void detonateBomb(SourceOfDetonationSignal aSource) 
	{
		if (bombArmed) {
			this->disarmBomb();
			(*(this->myActionFuncP))(
				  (SourceOfDetonationSignal)aSource
				, myCharge
			);
		}
	};
	GenericCBomb(ActionFuncP anActionFuncP) {
		myActionFuncP = anActionFuncP;
	};
	~GenericCBomb()
	{
		this->detonateBomb(LEFT_AREA);
	};
	void * operator new (size_t /*s*/, CBomb * aCBombP)
	{
		return (void *) aCBombP;
	};
	void * operator new (size_t /*s*/) {
		BLAST(SHOULDNT_CALL_GENERIC_C_BOMB_DEFAULT_OPERATOR_NEW); 
		return NULL;
	}
	void operator delete(void *) {}
};

/* ========================================================================== */
//
//	C Shields are supported by the Generic C Shield Bomb, which is
//	a subclass of GenericCBomb that also overrides inspectFuse(),
//	to keep the detonator happy.  Its action functions (one for normal
//	and one for loud shields) are also defined in this C++ module.
//
/* ========================================================================== */

class GenericCShieldBomb : public GenericCBomb {
    public:
	GenericCShieldBomb(ActionFuncP anActionFuncP)
		: GenericCBomb(anActionFuncP)
	{
	};
	virtual Shield * inspectFuse()
	{
		return (bombArmed)
		? (Shield *)(void *)(myCharge.cValue_CShieldStar)
		: NULL;
	};
};
/* ========================================================================== */
//
//	C modules can't get to member functions directly, so we have support
//	functions (including "fake", as distinguished from "pseudo",
//	constructors and destructors) which provide a C interface for them.
//
//	Generic C Bomb support functions:
//
//		cBombCtor():		fake constructor
//		cBombDtor():		fake destructor
//		cBombArmType_<type>():	Arming function accessor (one per type).
//		cBombDetonate():	Detonation function accessor.
//		cBombDisarm():		Disarm function accessor.
//
/* ========================================================================== */

C_DECL_BEGIN

void cBombCtor(
	  CBomb *	aCBombP
	, ActionFuncP	anActionFuncP
) {
	new(aCBombP) GenericCBomb(anActionFuncP);
}

void cBombDtor(
	  CBomb *	aCBombP
) {
	if ((BombSuperclass *)aCBombP != (BombStringDetonator::currentP->
						fetchFirstP())){
		CONST BooleanVar
			C_Bomb_not_at_end_of_C_Bomb_string = FALSE;
		ASSERT(C_Bomb_not_at_end_of_C_Bomb_string);
	}
	delete (GenericCBomb *)aCBombP;
}

#define	DEFINE_CBOMB_ARM_FUNCTION(TYPE)				\
extern void CAT(cBombArmType_,TYPE)(				\
	  CBomb *	aCBombP					\
	, TYPE		aCharge					\
) {								\
	CValue		tempCValue;				\
	tempCValue.CAT(cValue_,TYPE) = aCharge;			\
	((GenericCBomb *)aCBombP)->armBomb(tempCValue);		\
}

DEFINE_CBOMB_ARM_FUNCTION(voidStar);
DEFINE_CBOMB_ARM_FUNCTION(int);
DEFINE_CBOMB_ARM_FUNCTION(CShieldStar);

extern void cBombDetonate(
	  CBomb *	aCBombP
) {
	((BombSuperclass *)aCBombP)->detonateBomb(LOCAL_DETONATE);
}

extern void cBombDisarm(
	  CBomb *	aCBombP
) {
	((BombSuperclass *)aCBombP)->disarmBomb();
}

C_DECL_END

/* ========================================================================== */
//
//	Generic C Shield Bombs require a constructors (to get the correct
//	object constructed) and action routines.  The rest of their interface
//	support is inherited from Generic C Bombs.
//
//		c{L}ShieldBombCtor():		fake constructors
//		_c{L}Shield_cBombAction():	action routines
//
/* ========================================================================== */

C_DECL_BEGIN

static void _cShield_cBombAction(
	  SourceOfDetonationSignal	/* aSource */
	, CValue			/* aCharge */
) {
}

void cShieldBombCtor(
	  CBomb *	aCBombP
) {
	new(aCBombP) GenericCShieldBomb(_cShield_cBombAction);
}

static void _cLShield_cBombAction(
	  SourceOfDetonationSignal	aSource
	, CValue			/* aCharge */
) {
	if (aSource == BLASTING_STOPS) {
		cerr << (BombStringDetonator::currentP->getProblemInstanceP())
			<< "\n";
	}
}

void cLShieldBombCtor(
	  CBomb *	aCBombP
) {
	new(aCBombP) GenericCShieldBomb(_cLShield_cBombAction);
}

C_DECL_END

/* ========================================================================== */
//
//	The CHARGE in a Generic C Shield is an ActualCShield.  It also is
//	constructed in space provided by the C program, using a fake
//	constructor called from C.
//
//	Interface routines are provided to return the addresses of its
//	member variables, so we don't have to dig into a c++ object from c.
//
//	  cShieldCtor():		fake constructor.
//	  cSetUpErrorListAndSavedPtr():	set up stuff used when raising shield
//	  cFetchJmpBuf():		fetch address of jmp_buf
//
//	  cFetchProblemP():		fetch address of problem instance
//
//	  cProblemFetchProblemName():	Extract address of problem name
//	  cProblemFetchVal():		Extract address of problem val
//	  cProblemFetchFileName():	Extract address of problem file name
//	  cProblemFetchLineNumber():	Extract address of problem line number
//
/* ========================================================================== */

class ActualCShield : public Shield {
 public:
	void * operator new (size_t /*s*/, CShield * aCShieldP)
	{
		return (void *) aCShieldP;
	};
	void * operator new (size_t /*s*/) {
		BLAST(SHOULDNT_CALL_C_SHIELD_DEFAULT_OPERATOR_NEW);
		return NULL;
	}
	void operator delete(void *) {}
};

C_DECL_BEGIN

void cShieldCtor(
	  CShield *	aCShieldP
) {
	new(aCShieldP) ActualCShield();
}

void cSetUpErrorListAndSavedPtr(
	  CShield *	aCShieldP
	, char **	anErrorListP
) {
	(((ActualCShield *)aCShieldP)->errorListP) = anErrorListP;
}

jmp_buf	* cFetchJmpBuf(
	  CShield *	aCShieldP
) {
	return (jmp_buf *)(/*&*/(((ActualCShield *)aCShieldP)->jmpBuf));
}

void * cFetchProblemP(
	  CShield *	aCShieldP
) {
	return (void *)(&(((ActualCShield *)aCShieldP)->problem));
}

CONST char * cProblemFetchProblemName(
	  void *	aProblemP
) {
	return ((Problem *)aProblemP)->getProblemName();
}

int cProblemFetchVal(
	  void *	aProblemP
) {
	return ((Problem *)aProblemP)->getVal();
}

CONST char * cProblemFetchFileName(
	  void *	aProblemP
) {
	return ((Problem *)aProblemP)->getFileName();
}

int cProblemFetchLineNumber(
	  void *	aProblemP
) {
	return ((Problem *)aProblemP)->getLineNumber();
}


C_DECL_END

/* ========================================================================== */
//
//	The CShieldFree Bomb exists to inform the Problem instance when the
//	C Shield's ACTION is finished, so it may free the __FILE__ and
//	__LINE__ strings if they came in over com.
//
//	This code is its ActionRoutine, and is essentially:
//
//		C_BUILD_BOMB(CShieldFree,voidStar,{
//			((Problem *)CHARGE)->freeStrings();
//		});
//
//	but expanded and c++ified by hand so we don't have to flavor
//	C_BUILD_BOMB() until it is also acceptable to c++ compilers.
//
/* ========================================================================== */

C_DECL_BEGIN

void CShieldFree_cBombAction(
	  SourceOfDetonationSignal	/* SOURCE */
	, CValue			aValueStruct
) {
	voidStar	CHARGE = aValueStruct.CAT(cValue_,voidStar);

	((Problem *)CHARGE)->freeStrings();
}

C_DECL_END
/* ========================================================================== */
//
//	CBombAbandonThrough() is used for exiting from a nest of C bombs
//	and/or shields, to support break, return, and the like.  It walks
//	the BombString, destorying the bombs one-by-one, until it has
//	destroyed the one designated by its second argument (which is the
//	last CBomb it should burn off).
//
//	Unless a strong pointer is being returned through a C function
//	(which isn't possible as of 10/28/91), the bombs should each
//	be the at the end of the true bomb string as well.  (If this
//	becomes possible, the initial sanity check should be deleted and
//	the code replaced by a mechanism to walk the string from *aFreeBombP
//	to *aCBombP)
//
/* ========================================================================== */

C_DECL_BEGIN

void cBombAbandonThrough(
	  CBomb *	aFreeBombP
	, CBomb *	aCBombP
) {
	GenericCBomb *	savedCBombP;

	if ((BombSuperclass *)aFreeBombP !=
			(BombStringDetonator::currentP->fetchFirstP())) {
		CONST BooleanVar
			C_shield_not_at_end_of_main_Bomb_string = FALSE;
		ASSERT(C_shield_not_at_end_of_main_Bomb_string);
	}

	do {
		savedCBombP = (GenericCBomb *)(BombStringDetonator::currentP->
							fetchFirstP());
		if (savedCBombP == NULL) {
			CONST BooleanVar
				C_Bomb_not_found_during_abandonment = FALSE;
			ASSERT(C_Bomb_not_found_during_abandonment);
		}
		delete savedCBombP;
	} while ((GenericCBomb *)aCBombP != savedCBombP);
}

C_DECL_END

/* ========================================================================== */
//
//	Two little functions to extract the sizes of the structures.
//
//	These are used to compute C_BOMB_SIZE and C_SHIELD_SIZE.
//	(Note that those must be defined to get these functions compiled,
//	 but that their actual values don't enter in the computation.)
//
//	These are used in cbombt.c by the test for size correctness, and by
//	an option for printing new declarations to be inserted in cbombc.h.
//
/* ========================================================================== */

C_DECL_BEGIN

int getCBombSize()
{
	return ((sizeof(GenericCShieldBomb)+sizeof(UInt32)) - 1) / sizeof(UInt32);
}

int getCShieldSize()
{
	return ((sizeof(ActualCShield)+sizeof(UInt32)) - 1) / sizeof(UInt32);
}

C_DECL_END

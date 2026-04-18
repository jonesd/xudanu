/* ========================================================================== */
//
//	Copyright (c) 1992 by Xanadu Operating Company, All Rights Reserved.
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
//			bombt.hxx
//
//		By Michael McClary		1992
//
/* ========================================================================== */
//
//	Spawned from bombx.cxx during ORDER/BUILD / inline upgrade.
//		- michael Mar  3 1992

#ifndef BOMBT_HXX
#define BOMBT_HXX

#include "bombx.hxx"


// for sub1()

ORDER_BOMB( cerr, char *);

// for sub2(), sub3(), sub4()

ORDER_BOMB( smart, char *);

ORDER_BOMB( recursive, char *);

ORDER_BOMB( disarmer,_lshield_Bomb *);

// for sub5()

ORDER_BOMB( cheat, char *);

/* ========================================================================== */
// for sub7()
//
//	Die and DieSub:  Crash in the superclass constructor:
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

class Die {
	public:
	Die();
	virtual ~Die();
};

class DieSubConstructor_Bomb;

class DieSub: public Die {
	public:
	DieSub();
	~DieSub();
	void * operator new(size_t);
	void * operator new(size_t, DieSubConstructor_Bomb *);
	void operator delete(void* p);
};

ORDER_BOMB(DieSubConstructor, DieSub *);

/* ========================================================================== */
//
//	Croak and CroakSub:  Crash in the subclass constructor:
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

class Croak {
	public:
	Croak();
	virtual ~Croak();
};

class CroakSubConstructor_Bomb;

class CroakSub: public Croak {
	public:
	CroakSub();
	~CroakSub();
	void * operator new(size_t);
	void * operator new(size_t, CroakSubConstructor_Bomb *);
	void operator delete(void* p);
};

ORDER_BOMB(CroakSubConstructor, CroakSub *);

/* ========================================================================== */
//
//	Live and LiveSub:  Don't crash.
//	 - Superclass unprotected
//	 - Subclass protected.
//
/* ========================================================================== */

static char * ptrChanged(void *);

class Live {
	public:
	Live() {
		cerr << "Live: Object " << ptrChanged((void *)this) << "\n";
	};
	virtual ~Live() {
		cerr << "~Live\n";
	}
};

class LiveSubConstructor_Bomb;

class LiveSub: public Live {
	public:
	LiveSub();
	~LiveSub();
	void * operator new(size_t);
	void * operator new(size_t, LiveSubConstructor_Bomb *);
	void operator delete(void* p);
};

ORDER_BOMB(LiveSubConstructor, LiveSub *);

/* ========================================================================== */
//
//  Member objects, one with a failing constructor.  (To test the inability
//  of the BOMB() package to correctly handle such failures.)
//
/* ========================================================================== */

class Cracked {
	public:
	Cracked();
	virtual ~Cracked();
};

class CrackedA: public Cracked {
	public:
	CrackedA();
	virtual ~CrackedA();
};

class CrackedB: public Cracked {
	public:
	CrackedB();
	virtual ~CrackedB();
};

class CrackedC: public Cracked {
	public:
	CrackedC();
	virtual ~CrackedC();
};

/* ========================================================================== */
// for sub8()
//
//  Class containing member objects, one with a failing constructor, (to test
//  the inability of the BOMB() package to correctly handle such failures.)
//
/* ========================================================================== */

class BaseThingConstructor_Bomb;

class BaseThing {
	public:
	BaseThing();
	virtual ~BaseThing();
	void * operator new(size_t);
	void * operator new(size_t, BaseThingConstructor_Bomb *);
	void operator delete(void* p);
};

ORDER_BOMB(BaseThingConstructor, BaseThing *);

class BrokenThing: public BaseThing {
	public:
	CrackedA	aThing;
	CrackedB	bThing;
	CrackedC	cThing;
	BrokenThing();
	virtual ~BrokenThing();
};

class BrokenDerivedThing: public BrokenThing {
	public:
	CrackedA	aThing;
	CrackedB	bThing;
	CrackedC	cThing;
	BrokenDerivedThing();
	virtual ~BrokenDerivedThing();
};


/* ========================================================================== */
// for sub10()
//
//	Test gCHook() and pointerish things that don't override detonateBomb()
//
/* ========================================================================== */
//
//	A couple pointer-class-like things
//
/* ========================================================================== */

class TestPtrThing : public BombSuperclass {
    private:
	virtual void * gCHook ();
	friend void sub10();
    protected:
	INLINE TestPtrThing (void * p);
	INLINE ~TestPtrThing ();
    private:
	void * value;
};

/* ========================================================================== */

class OptimizedTestPtrThing : public BombSuperclass {
    private:
	virtual void * gCHook ();
	friend void sub10();
    protected:
	INLINE OptimizedTestPtrThing (void * p);
	INLINE ~OptimizedTestPtrThing ();
    private:
	void * value;
};

/* ========================================================================== */
//
//	Class for getting hooks into the bomb stuff.
//
/* ========================================================================== */

class BombJig {
    public:
	void printGCHooks();
} theBombJig;

// for sub11()

class CAT(verbose,_Bomb): public CAT(smart,_Bomb)
{
    public:
	CAT(verbose,_Bomb)();
	~CAT(verbose,_Bomb)();
};

#endif /* BOMBT_HXX */

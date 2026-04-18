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

#ifndef BECOMET_HXX
#define BECOMET_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BECOMET_OXX
#include "becomet.oxx"
#endif /* BECOMET_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/* This module exists purely to test "become" support.  
The implememtation of "become" support is elsewhere (in tofu & init). */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BecomeTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BecomeTester : public Tester {

/* Attributes for class BecomeTester */
	CONCRETE(BecomeTester)
	COPY(BecomeTester,BootCuisine)
	NO_GC(BecomeTester)
  public: /* testing */

	/* BecomeTester runTest */
	
	virtual void allTestsOn (ostream& ARG(oo));
	
	/* BecomeTester runTest: #test1On: */
	
	virtual void test1On (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	BecomeTester();

};  /* end class BecomeTester */



/* ************************************************************************ *
 * 
 *                    Class Chameleon 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Chameleon : public Heaper {

/* Attributes for class Chameleon */
	CONCRETE(Chameleon)
	COPY(Chameleon,XppCuisine)
	AUTO_GC(Chameleon)
  public: /* instance creation */

	
	Chameleon ();
	
	
	Chameleon (
			IntegerVar ARG(a), 
			APTR(Heaper) ARG(b), 
			BooleanVar ARG(c))
	;
	
  public: /* accessing */

	
	virtual void explain (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	IntegerVar myA;
	CHKPTR(Heaper) myB;
	BooleanVar myC;
};  /* end class Chameleon */



/* ************************************************************************ *
 * 
 *                    Class   Butterfly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Butterfly : public Chameleon {

/* Attributes for class Butterfly */
	CONCRETE(Butterfly)
	COPY(Butterfly,XppCuisine)
	AUTO_GC(Butterfly)
  public: /* instance creation */

	
	Butterfly ();
	
  private:
	IntegerVar myE;
	CHKPTR(Heaper) myF;
};  /* end class Butterfly */



/* ************************************************************************ *
 * 
 *                    Class     GoldButterfly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GoldButterfly : public Butterfly {

/* Attributes for class GoldButterfly */
	CONCRETE(GoldButterfly)
	NO_GC(GoldButterfly)

	/* automatic 0-argument constructor */
  public:
	GoldButterfly();

};  /* end class GoldButterfly */



/* ************************************************************************ *
 * 
 *                    Class     IronButterfly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IronButterfly : public Butterfly {

/* Attributes for class IronButterfly */
	CONCRETE(IronButterfly)
	MAY_BECOME_ANY_SUBCLASS_OF(IronButterfly,Chameleon)
	NO_GC(IronButterfly)

	/* automatic 0-argument constructor */
  public:
	IronButterfly();

};  /* end class IronButterfly */



/* ************************************************************************ *
 * 
 *                    Class     LeadButterfly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class LeadButterfly : public Butterfly {

/* Attributes for class LeadButterfly */
	CONCRETE(LeadButterfly)
	MAY_BECOME(LeadButterfly,DeadMoth)
	MAY_BECOME(LeadButterfly,Butterfly)
	NO_GC(LeadButterfly)

	/* automatic 0-argument constructor */
  public:
	LeadButterfly();

};  /* end class LeadButterfly */



/* ************************************************************************ *
 * 
 *                    Class   DeadButterfly 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DeadButterfly : public Chameleon {

/* Attributes for class DeadButterfly */
	CONCRETE(DeadButterfly)
	COPY(DeadButterfly,XppCuisine)
	AUTO_GC(DeadButterfly)
  public: /* instance creation */

	
	DeadButterfly ();
	
  private:
	IntegerVar myJ;
	CHKPTR(Heaper) myK;
	CHKPTR(Heaper) myL;
	CHKPTR(Heaper) myM;
};  /* end class DeadButterfly */



/* ************************************************************************ *
 * 
 *                    Class   DeadMoth 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DeadMoth : public Chameleon {

/* Attributes for class DeadMoth */
	CONCRETE(DeadMoth)
	COPY(DeadMoth,XppCuisine)
	AUTO_GC(DeadMoth)
  public: /* instance creation */

	
	DeadMoth ();
	
  private:
	IntegerVar myG;
	CHKPTR(Heaper) myH;
	BooleanVar myI;
};  /* end class DeadMoth */



/* ************************************************************************ *
 * 
 *                    Class   Moth 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Moth : public Chameleon {

/* Attributes for class Moth */
	CONCRETE(Moth)
	MAY_BECOME(Moth,Butterfly)
	COPY(Moth,XppCuisine)
	NO_GC(Moth)
  public: /* instance creation */

	
	static RPTR(Moth) make ();
	
  public: /* becoming */

	
	virtual void molt ();
	
  public: /* instance creation */

	
	Moth (IntegerVar ARG(d), TCSJ);
	
  private:
	IntegerVar myD;
};  /* end class Moth */



#endif /* BECOMET_HXX */


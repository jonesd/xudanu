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

#ifndef SHEPHT_HXX
#define SHEPHT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef SHEPHT_OXX
#include "shepht.oxx"
#endif /* SHEPHT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ShepherdLocked 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ShepherdLocked : public Abraham {

/* Attributes for class ShepherdLocked */
	CONCRETE(ShepherdLocked)
	SHEPHERD_PATRIARCH(ShepherdLocked,Abraham)
	LOCKED(ShepherdLocked)
	COPY(ShepherdLocked,DiskCuisine)
	NO_GC(ShepherdLocked)
  public: /* instance creation */

	
	static RPTR(ShepherdLocked) makeLocked ();
	
	
	static RPTR(ShepherdLocked) makeUnlocked ();
	
  public: /* instance creation */

	
	ShepherdLocked ();
	
  public: /* accessing */

	
	virtual BooleanVar isReallyUnlocked ();
	
  public: /* testing locks */

	/* self unlock */
	
	virtual NOLOCK void publicUnlock ();
	

/* Friends for class ShepherdLocked */
/* friends for class ShepherdLocked */


};  /* end class ShepherdLocked */



/* ************************************************************************ *
 * 
 *                    Class ShepherdLockTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ShepherdLockTester : public Tester {

/* Attributes for class ShepherdLockTester */
	CONCRETE(ShepherdLockTester)
	COPY(ShepherdLockTester,BootCuisine)
	NO_GC(ShepherdLockTester)
  public: /* testing */

	/* ShepherdLockTester runTest */
	
	virtual void allTestsOn (ostream& ARG(oo));
	
	/* ShepherdLockTester runTest: #test1On: */
	
	virtual void test1On (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	ShepherdLockTester();

};  /* end class ShepherdLockTester */



#endif /* SHEPHT_HXX */


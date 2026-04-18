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

#ifndef DISKMANT_HXX
#define DISKMANT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef DISKMANT_OXX
#include "diskmant.oxx"
#endif /* DISKMANT_OXX */


#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DiskTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DiskTester : public Tester {

/* Attributes for class DiskTester */
	CONCRETE(DiskTester)
	COPY(DiskTester,BootCuisine)
	AUTO_GC(DiskTester)
  public: /* tests */

	/* self runTest: #destroyTest: */
	
	virtual void destroyTest (ostream& ARG(oo));
	
	/* self runTest: #forward1Test: */
	
	virtual void forward1Test (ostream& ARG(oo));
	
	/* self runTest: #forward2Test: */
	
	virtual void forward2Test (ostream& ARG(oo));
	
	/* self runTest: #toDiskAndBackTestOn: */
	/* test writing to disk and reading back */
	
	virtual void toDiskAndBackTestOn (ostream& ARG(aStream));
	
  public: /* running tests */

	/* DiskTester runTest */
	
	virtual void allTestsOn (ostream& ARG(oo));
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartDiskTester (APTR(Rcvr) ARG(rcvr) = NULL);
	

	/* automatic 0-argument constructor */
  public:
	DiskTester();
  private:
	NOCOPY CHKPTR(Counter) myBootCounter;
};  /* end class DiskTester */



/* ************************************************************************ *
 * 
 *                    Class MultiCounter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class MultiCounter : public Abraham {

/* Attributes for class MultiCounter */
	CONCRETE(MultiCounter)
	SHEPHERD_PATRIARCH(MultiCounter,Abraham)
	LOCKED(MultiCounter)
	COPY(MultiCounter,DiskCuisine)
	AUTO_GC(MultiCounter)
  public: /* pseudo constructors  */

	
	static RPTR(MultiCounter) make ();
	
	
	static RPTR(MultiCounter) make (IntegerVar ARG(count));
	
  public: /* accessing */

	
	virtual void decrementBoth ();
	
	
	virtual IntegerVar decrementFirst ();
	
	
	virtual IntegerVar decrementSecond ();
	
	
	virtual IntegerVar firstCount ();
	
	
	virtual void incrementBoth ();
	
	
	virtual IntegerVar incrementFirst ();
	
	
	virtual IntegerVar incrementSecond ();
	
	
	virtual IntegerVar secondCount ();
	
  public: /* creation */

	
	MultiCounter ();
	
	
	MultiCounter (IntegerVar ARG(first), TCSJ);
	
	
	MultiCounter (IntegerVar ARG(first), IntegerVar ARG(second));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(Counter) myFirst;
	CHKPTR(Counter) mySecond;
};  /* end class MultiCounter */



#endif /* DISKMANT_HXX */


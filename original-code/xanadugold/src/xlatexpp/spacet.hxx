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

#ifndef SPACET_HXX
#define SPACET_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef SPACET_OXX
#include "spacet.oxx"
#endif /* SPACET_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class RegionTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RegionTester : public Tester {

/* Attributes for class RegionTester */
	DEFERRED(RegionTester)
	AUTO_GC(RegionTester)
  public: /* deferred: init */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	
	
	virtual void binaryCheck (APTR(XnRegion) ARG(a), APTR(XnRegion) ARG(b));
	
	
	virtual void testBinaryRegionOpsOn (ostream& ARG(oo));
	
	
	virtual void testExtraOn (ostream& ARG(oo));
	
	
	virtual void testUnaryRegionOpsOn (ostream& ARG(oo));
	
	
	virtual void unaryCheck (APTR(XnRegion) ARG(a));
	
  protected: /* protected: accessing */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) exampleRegions ();
	
  protected: /* protected: creation */

	
	RegionTester ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartRegionTester (APTR(Rcvr) ARG(rcvr) = NULL);
	
  private:
	NOCOPY CHKPTR(ImmuSet) OF1(XnRegion) myExampleRegions;
};  /* end class RegionTester */



#endif /* SPACET_HXX */


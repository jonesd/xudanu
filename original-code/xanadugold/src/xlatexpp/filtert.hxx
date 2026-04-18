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

#ifndef FILTERT_HXX
#define FILTERT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef FILTERT_OXX
#include "filtert.oxx"
#endif /* FILTERT_OXX */


#ifndef SPACET_HXX
#include "spacet.hxx"
#endif /* SPACET_HXX */


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
 *                    Class FilterTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FilterTester : public RegionTester {

/* Attributes for class FilterTester */
	CONCRETE(FilterTester)
	COPY(FilterTester,BootCuisine)
	AUTO_GC(FilterTester)
  public: /* creation */

	
	FilterTester ();
	
  public: /* init */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	
  public: /* testing */

	
	virtual void binaryCheck (APTR(XnRegion) ARG(a), APTR(XnRegion) ARG(b));
	
	
	virtual void unaryCheck (APTR(XnRegion) ARG(a));
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartFilterTester (APTR(Rcvr) ARG(rcvr) = NULL);
	
  private:
	NOCOPY CHKPTR(ImmuSet) OF1(XnRegion) myBaseRegions;
};  /* end class FilterTester */



#endif /* FILTERT_HXX */


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

#ifndef SEQUENCT_HXX
#define SEQUENCT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SEQUENCT_OXX
#include "sequenct.oxx"
#endif /* SEQUENCT_OXX */


#ifndef SPACET_HXX
#include "spacet.hxx"
#endif /* SPACET_HXX */


#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SequenceTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SequenceTester : public RegionTester {

/* Attributes for class SequenceTester */
	CONCRETE(SequenceTester)
	COPY(SequenceTester,BootCuisine)
	NO_GC(SequenceTester)
  public: /* init */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	
  public: /* testing */

	
	virtual void testExtraOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	SequenceTester();

};  /* end class SequenceTester */



#endif /* SEQUENCT_HXX */


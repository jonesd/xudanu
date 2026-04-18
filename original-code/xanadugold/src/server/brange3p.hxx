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

#ifndef BRANGE3P_HXX
#define BRANGE3P_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef BRANGE3P_OXX
#include "brange3p.oxx"
#endif /* BRANGE3P_OXX */


#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeEditionDetectorExecutor 
 *
 * ************************************************************************ */




	/* This class notifies its edition when its last detector has gone. */

class BeEditionDetectorExecutor : public XnExecutor {

/* Attributes for class BeEditionDetectorExecutor */
	CONCRETE(BeEditionDetectorExecutor)
	NOT_A_TYPE(BeEditionDetectorExecutor)
	AUTO_GC(BeEditionDetectorExecutor)
  public: /* creation */

	
	static RPTR(XnExecutor) make (APTR(BeEdition) ARG(edition));
	
  protected: /* protected: create */

	
	BeEditionDetectorExecutor (APTR(BeEdition) ARG(edition), TCSJ);
	
  public: /* execute */

	
	virtual void execute (Int32 ARG(arg));
	
  private:
	CHKPTR(BeEdition) myEdition;
};  /* end class BeEditionDetectorExecutor */



#endif /* BRANGE3P_HXX */


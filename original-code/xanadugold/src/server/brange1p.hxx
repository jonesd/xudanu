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

#ifndef BRANGE1P_HXX
#define BRANGE1P_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef BRANGE1P_OXX
#include "brange1p.oxx"
#endif /* BRANGE1P_OXX */


#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FillDetectorExecutor 
 *
 * ************************************************************************ */




	/* This class notifies its place holder when its last fill 
	detector has gone away. */

class FillDetectorExecutor : public XnExecutor {

/* Attributes for class FillDetectorExecutor */
	CONCRETE(FillDetectorExecutor)
	NOT_A_TYPE(FillDetectorExecutor)
	AUTO_GC(FillDetectorExecutor)
  public: /* create */

	
	static RPTR(XnExecutor) make (APTR(BePlaceHolder) ARG(placeHolder));
	
  protected: /* protected: create */

	
	FillDetectorExecutor (APTR(BePlaceHolder) ARG(placeHolder), TCSJ);
	
  public: /* execute */

	
	virtual void execute (Int32 ARG(arg));
	
  private:
	CHKPTR(BePlaceHolder) myPlaceHolder;
};  /* end class FillDetectorExecutor */



#endif /* BRANGE1P_HXX */


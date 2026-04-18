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

#ifndef HLOGGERP_HXX
#define HLOGGERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HLOGGERP_OXX
#include "hloggerp.oxx"
#endif /* HLOGGERP_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SwitchLogger 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SwitchLogger : public Thunk {

/* Attributes for class SwitchLogger */
	CONCRETE(SwitchLogger)
	COPY(SwitchLogger,XppCuisine)
	NOT_A_TYPE(SwitchLogger)
	AUTO_GC(SwitchLogger)
  public: /* operate */

	
	virtual void execute ();
	
  public: /* hooks: */

	
	virtual void restartSwitchLogger (APTR(Rcvr) ARG(rcvr) = NULL);
	

	/* automatic 0-argument constructor */
  public:
	SwitchLogger();
  private:
	char * myLoggerName;
	char * myDirective;
};  /* end class SwitchLogger */



#endif /* HLOGGERP_HXX */


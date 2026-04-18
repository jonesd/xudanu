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

#ifndef RCMAINX_HXX
#define RCMAINX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef RCMAINX_OXX
#include "rcmainx.oxx"
#endif /* RCMAINX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class MainDummy 
 *
 * ************************************************************************ */



/* Initializers for MainDummy */
DESIGN_FLUID(Rcvr,CurrentMainReceiver);	/* in MainDummy */
DESIGN_FLUID(Heaper,MainActiveThunk);	/* in MainDummy */


/* global: booting */


int  XU_MAIN (int ARG(argc), char* * ARG(argv));



	/* A dummy class on which to hang the main that reads in an rc file. */

class MainDummy : public Heaper {

/* Attributes for class MainDummy */
	DEFERRED(MainDummy)
	NO_GC(MainDummy)

/* Initializers for MainDummy */


  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	MainDummy();

/* Friends for class MainDummy */
/* friends for class MainDummy */

friend int  main (int argc, char* * argv);


};  /* end class MainDummy */



#endif /* RCMAINX_HXX */


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

#ifndef SCHUNKP_HXX
#define SCHUNKP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SCHUNKP_OXX
#include "schunkp.oxx"
#endif /* SCHUNKP_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ListenerEmulsion 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ListenerEmulsion : public Emulsion {

/* Attributes for class ListenerEmulsion */
  public: /* accessing */

	
	virtual void * fetchNewRawSpace (size_t ARG(size));
	
	
	virtual void * fetchOldRawSpace ();
	
  public: /* creation */

	
	ListenerEmulsion ();
	
  public:
	char * defaultFluidSpace;
};  /* end class ListenerEmulsion */



#endif /* SCHUNKP_HXX */


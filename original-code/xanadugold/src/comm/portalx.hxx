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

#ifndef PORTALX_HXX
#define PORTALX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PORTALX_OXX
#include "portalx.oxx"
#endif /* PORTALX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Portal 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Portal : public Heaper {

/* Attributes for class Portal */
	DEFERRED(Portal)
	EQ(Portal)
	NO_GC(Portal)
  public: /* pseudo constructors */

	
	static RPTR(Portal) make (char * ARG(host), UInt32 ARG(port));
	
  public: /* accessing */

	
	virtual RPTR(XnReadStream) readStream () DEFERRED_FUNC;
	
	
	virtual RPTR(XnWriteStream) writeStream () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Portal();

};  /* end class Portal */



#endif /* PORTALX_HXX */


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

#ifndef SCHUNKT_HXX
#define SCHUNKT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SCHUNKT_OXX
#include "schunkt.oxx"
#endif /* SCHUNKT_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class TestChunk 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TestChunk : public ServerChunk {

/* Attributes for class TestChunk */
	CONCRETE(TestChunk)
	NO_GC(TestChunk)
  public: /* accessing */

	
	virtual void processInput ();
	
  public: /* execute */

	
	virtual BooleanVar execute ();
	

	/* automatic 0-argument constructor */
  public:
	TestChunk();

};  /* end class TestChunk */



#endif /* SCHUNKT_HXX */


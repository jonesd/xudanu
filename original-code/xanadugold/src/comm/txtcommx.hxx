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

#ifndef TXTCOMMX_HXX
#define TXTCOMMX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TXTCOMMX_OXX
#include "txtcommx.oxx"
#endif /* TXTCOMMX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */


#ifndef NEGOTI8X_OXX
#include "negoti8x.oxx"
#endif /* NEGOTI8X_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */
#define CONVERTSTRLEN 16



/* ************************************************************************ *
 * 
 *                    Class TextyXcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for TextyXcvrMaker */
/* Declaration inherited from XcvrMaker */





	/* NO CLASS COMMENT */

class TextyXcvrMaker : public XcvrMaker {

/* Attributes for class TextyXcvrMaker */
	CONCRETE(TextyXcvrMaker)
	COPY(TextyXcvrMaker,XppCuisine)
	NOT_A_TYPE(TextyXcvrMaker)
	NO_GC(TextyXcvrMaker)

/* Initializers for TextyXcvrMaker */
/* Declaration inherited from XcvrMaker */

friend class INIT_TIME_NAME(TextyXcvrMaker,initTimeInherited);

  public: /* creation */

	
	static RPTR(XcvrMaker) make ();
	
	
	static RPTR(Rcvr) makeReader (APTR(XnReadStream) ARG(stream));
	
	
	static RPTR(Xmtr) makeWriter (APTR(XnWriteStream) ARG(stream));
	
  public: /* xcvr creation */

	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(readStream));
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(writeStream));
	
  public: /* testing */

	
	virtual char * id ();
	

	/* automatic 0-argument constructor */
  public:
	TextyXcvrMaker();

};  /* end class TextyXcvrMaker */



#endif /* TXTCOMMX_HXX */


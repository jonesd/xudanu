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

#ifndef BIN2COMX_HXX
#define BIN2COMX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BIN2COMX_OXX
#include "bin2comx.oxx"
#endif /* BIN2COMX_OXX */


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


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Binary2XcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for Binary2XcvrMaker */
/* Declaration inherited from XcvrMaker */





	/* NO CLASS COMMENT */

class Binary2XcvrMaker : public XcvrMaker {

/* Attributes for class Binary2XcvrMaker */
	CONCRETE(Binary2XcvrMaker)
	COPY(Binary2XcvrMaker,XppCuisine)
	NOT_A_TYPE(Binary2XcvrMaker)
	NO_GC(Binary2XcvrMaker)

/* Initializers for Binary2XcvrMaker */
/* Declaration inherited from XcvrMaker */

friend class INIT_TIME_NAME(Binary2XcvrMaker,initTimeInherited);

  public: /* creation */

	
	static RPTR(XcvrMaker) make ();
	
  public: /* xcvr creation */

	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(readStream));
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(writeStream));
	
  public: /* testing */

	
	virtual char * id ();
	

	/* automatic 0-argument constructor */
  public:
	Binary2XcvrMaker();

};  /* end class Binary2XcvrMaker */



#endif /* BIN2COMX_HXX */


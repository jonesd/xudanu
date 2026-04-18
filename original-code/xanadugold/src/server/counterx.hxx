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

#ifndef COUNTERX_HXX
#define COUNTERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Counter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Counter : public Abraham {

/* Attributes for class Counter */
	DEFERRED(Counter)
	SHEPHERD_PATRIARCH(Counter,Abraham)
	COPY(Counter,DiskCuisine)
	DEFERRED_LOCKED(Counter)
	NO_GC(Counter)
  public: /* pseudo-constructors */

	
	static RPTR(Counter) fakeCounter (
			IntegerVar ARG(count), 
			IntegerVar ARG(batchCount), 
			UInt32 ARG(hash))
	;
	
	
	static RPTR(Counter) make ();
	
	
	static RPTR(Counter) make (IntegerVar ARG(count));
	
	
	static RPTR(Counter) make (IntegerVar ARG(count), IntegerVar ARG(batchCount));
	
  public: /* accessing */

	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual IntegerVar decrement () DEFERRED_FUNC;
	
	
	virtual IntegerVar decrementBy (IntegerVar ARG(count)) DEFERRED_FUNC;
	
	
	virtual IntegerVar increment () DEFERRED_FUNC;
	
	
	virtual IntegerVar incrementBy (IntegerVar ARG(count)) DEFERRED_FUNC;
	
	
	virtual void setCount (IntegerVar ARG(count)) DEFERRED_SUBR;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: creation */

	
	Counter ();
	
	
	Counter (UInt32 ARG(hash), TCSJ);
	

/* Friends for class Counter */
friend class SimpleTurtle;



};  /* end class Counter */



#endif /* COUNTERX_HXX */


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

#ifndef THUNKX_HXX
#define THUNKX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef THUNKX_OXX
#include "thunkx.oxx"
#endif /* THUNKX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Thunk 
 *
 * ************************************************************************ */




	/* Thunk is the abstraction for reified void/0-argument 
	operations.  Therse include Testers, frontend operations, etc. */

class Thunk : public Heaper {

/* Attributes for class Thunk */
	DEFERRED(Thunk)
	EQ(Thunk)
	NO_GC(Thunk)
  public: /* operate */

	/* Execute the action defined by this thunk. */
	
	virtual void execute () DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	Thunk();

};  /* end class Thunk */



/* ************************************************************************ *
 * 
 *                    Class   CommentThunk 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CommentThunk : public Thunk {

/* Attributes for class CommentThunk */
	CONCRETE(CommentThunk)
	COPY(CommentThunk,XppCuisine)
	NOT_A_TYPE(CommentThunk)
	AUTO_GC(CommentThunk)
  public: /* hooks: */

	
	virtual void restartCommentThunk (APTR(Rcvr) ARG(rcvr) = NULL);
	
  public: /* action */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	CommentThunk();
  private:
	char * message;
};  /* end class CommentThunk */



/* ************************************************************************ *
 * 
 *                    Class   EchoThunk 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class EchoThunk : public Thunk {

/* Attributes for class EchoThunk */
	CONCRETE(EchoThunk)
	COPY(EchoThunk,XppCuisine)
	NOT_A_TYPE(EchoThunk)
	AUTO_GC(EchoThunk)
  public: /* action */

	/* Execute the action defined by this thunk. */
	
	virtual void execute ();
	
  public: /* hooks: */

	
	virtual void restartEchoThunk (APTR(Rcvr) ARG(rcvr) = NULL);
	

	/* automatic 0-argument constructor */
  public:
	EchoThunk();
  private:
	char * message;
};  /* end class EchoThunk */



#endif /* THUNKX_HXX */


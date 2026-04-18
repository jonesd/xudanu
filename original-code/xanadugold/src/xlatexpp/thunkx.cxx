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

#ifndef THUNKX_CXX
#define THUNKX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */

#ifndef THUNKX_IXX
#include "thunkx.ixx"
#endif /* THUNKX_IXX */


#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Thunk 
 *
 * ************************************************************************ */


/* Thunk is the abstraction for reified void/0-argument operations.  
Therse include Testers, frontend operations, etc. */


/* operate */

	/* automatic 0-argument constructor */
Thunk::Thunk() {}



/* ************************************************************************ *
 * 
 *                    Class   CommentThunk 
 *
 * ************************************************************************ */


/* hooks: */


void CommentThunk::restartCommentThunk (APTR(Rcvr) /* rcvr *//* = NULL*/){
	DeleteExecutor::registerHolder(this, message);
}
/* action */


void CommentThunk::execute (){
	
}

	/* automatic 0-argument constructor */
CommentThunk::CommentThunk() {}



/* ************************************************************************ *
 * 
 *                    Class   EchoThunk 
 *
 * ************************************************************************ */


/* action */


void EchoThunk::execute (){
	/* Execute the action defined by this thunk. */
	
	cerr << message << "\n";
}
/* hooks: */


void EchoThunk::restartEchoThunk (APTR(Rcvr) /* rcvr *//* = NULL*/){
	DeleteExecutor::registerHolder(this, message);
}

	/* automatic 0-argument constructor */
EchoThunk::EchoThunk() {}

#ifndef THUNKX_SXX
#include "thunkx.sxx"
#endif /* THUNKX_SXX */



#endif /* THUNKX_CXX */


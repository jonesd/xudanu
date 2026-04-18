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

#ifndef PROMANR_HXX
#define PROMANR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROMANX_HXX
#include "promanx.hxx"
#endif /* PROMANX_HXX */

#ifndef PROMANR_OXX
#include "promanr.oxx"
#endif /* PROMANR_OXX */


#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */


#ifndef BOOTPLNX_OXX
#include "bootplnx.oxx"
#endif /* BOOTPLNX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ByteShuffler 
 *
 * ************************************************************************ */




	/* Instances shuffle bytes to convert between byte sexes.  
	Subclasses are defined for each of the various transformations. */

class ByteShuffler : public Heaper {

/* Attributes for class ByteShuffler */
	DEFERRED(ByteShuffler)
	NO_GC(ByteShuffler)
  public: /* shuffle */

	/* Return a shuffler that inverts the receiver's shuffler.  
	This will typically be the same transformation. */
	
	virtual RPTR(ByteShuffler) inverse ();
	
	/* Go from one byte sex to another for representing numbers 
	of the specified precision. */
	
	virtual void shuffle (
			Int32 ARG(precision), 
			void * ARG(buffer), 
			Int32 ARG(size))
	;
	
  private: /* private: shuffle */

	/* Go from one byte sex to another for representing 16 bit numbers. */
	
	virtual void shuffle16 (void * ARG(buffer), Int32 ARG(count)) DEFERRED_SUBR;
	
	/* Go from one byte sex to another for representing 32 bit numbers. */
	
	virtual void shuffle32 (void * ARG(buffer), Int32 ARG(count)) DEFERRED_SUBR;
	
	/* Go from one byte sex to another for representing 64 bit numbers. */
	
	virtual void shuffle64 (void * ARG(buffer), Int32 ARG(count)) DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	ByteShuffler();

};  /* end class ByteShuffler */



/* ************************************************************************ *
 * 
 *                    Class ExecutePromiseFile 
 *
 * ************************************************************************ */




	/* Read client requests from one files and write the results 
	to another file. */

class ExecutePromiseFile : public ServerChunk {

/* Attributes for class ExecutePromiseFile */
	CONCRETE(ExecutePromiseFile)
	COPY(ExecutePromiseFile,BootCuisine)
	AUTO_GC(ExecutePromiseFile)
  public: /* operate */

	/* Execute the action defined by this thunk. */
	
	virtual BooleanVar execute ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartPromises (APTR(Rcvr) ARG(rcvr));
	

	/* automatic 0-argument constructor */
  public:
	ExecutePromiseFile();
  private:
	char * myReadName;
	char * myWriteName;
	NOCOPY CHKPTR(PromiseManager) myManager;
	NOCOPY CHKPTR(Connection) myConnection;
};  /* end class ExecutePromiseFile */



#endif /* PROMANR_HXX */


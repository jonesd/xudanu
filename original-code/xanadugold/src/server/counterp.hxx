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

#ifndef COUNTERP_HXX
#define COUNTERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef COUNTERP_OXX
#include "counterp.oxx"
#endif /* COUNTERP_OXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SEMA4X_OXX
#include "sema4x.oxx"
#endif /* SEMA4X_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BatchCounter 
 *
 * ************************************************************************ */




	/* Instances preallocate a bunch of numbers and record the 
	preallocations to disk.  It then increments purely in memory 
	until the preallocated counts are used up.  It then 
	preallocates another bunch of numbers.  If the system 
	crashes, all numbers between the in-memory count and the 
	on-disk count simply never get used.  This reduces the access 
	to disk for shepherd hashes and GrandMap IDs. */

class BatchCounter : public Counter {

/* Attributes for class BatchCounter */
	CONCRETE(BatchCounter)
	LOCKED(BatchCounter)
	COPY(BatchCounter,DiskCuisine)
	NOT_A_TYPE(BatchCounter)
	AUTO_GC(BatchCounter)
  public: /* pseudo-constructors */

	
	static RPTR(Counter) make (IntegerVar ARG(count), IntegerVar ARG(batchCount));
	
	
	static RPTR(Counter) makeFakeCounter (
			IntegerVar ARG(count), 
			IntegerVar ARG(batchCount), 
			UInt32 ARG(hash))
	;
	
  public: /* accessing */

	
	virtual NOLOCK IntegerVar count ();
	
	
	virtual IntegerVar decrement ();
	
	
	virtual IntegerVar decrementBy (IntegerVar ARG(count));
	
	
	virtual IntegerVar increment ();
	
	
	virtual IntegerVar incrementBy (IntegerVar ARG(count));
	
	
	virtual void setCount (IntegerVar ARG(count));
	
  public: /* receiver: stubble */

	/* re-initialize the non-persistent part */
	
	virtual RECEIVE_HOOK void restartBatchCounter (APTR(Rcvr) ARG(trans) = NULL);
	
  protected: /* protected: create */

	
	BatchCounter (IntegerVar ARG(count), IntegerVar ARG(batchCount));
	
	
	BatchCounter (
			IntegerVar ARG(count), 
			IntegerVar ARG(batchCount), 
			UInt32 ARG(hash))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	NOCOPY IntegerVar myCount;
	IntegerVar myPersistentCount;
	NOCOPY CHKPTR(Sema4) myMutex;
	IntegerVar myBatchCount;
};  /* end class BatchCounter */



/* ************************************************************************ *
 * 
 *                    Class SingleCounter 
 *
 * ************************************************************************ */




	/* This counter separates a very simple state change into 
	another flock so that big objects like GrandMaps and 
	GrandHashTables don't ned to flush their entirety to disk.  
	It localizes the state change of a counter. */

class SingleCounter : public Counter {

/* Attributes for class SingleCounter */
	CONCRETE(SingleCounter)
	LOCKED(SingleCounter)
	COPY(SingleCounter,DiskCuisine)
	NOT_A_TYPE(SingleCounter)
	AUTO_GC(SingleCounter)
  public: /* pseudo-constructors */

	
	static RPTR(Counter) make ();
	
	
	static RPTR(Counter) make (IntegerVar ARG(count));
	
  public: /* accessing */

	
	virtual NOLOCK IntegerVar count ();
	
	
	virtual IntegerVar decrement ();
	
	
	virtual IntegerVar decrementBy (IntegerVar ARG(count));
	
	
	virtual IntegerVar increment ();
	
	
	virtual IntegerVar incrementBy (IntegerVar ARG(count));
	
	
	virtual void setCount (IntegerVar ARG(count));
	
  public: /* receiver: restart */

	/* re-initialize the non-persistent part */
	
	virtual RECEIVE_HOOK void restartSingleCounter (APTR(Rcvr) ARG(trans) = NULL);
	
  protected: /* protected: create */

	
	SingleCounter ();
	
	
	SingleCounter (IntegerVar ARG(count), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	IntegerVar myCount;
	NOCOPY CHKPTR(Sema4) myMutex;
	friend class Counter;
	friend class Counter;
};  /* end class SingleCounter */



#endif /* COUNTERP_HXX */


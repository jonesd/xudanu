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

#ifndef CACHEX_HXX
#define CACHEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CacheManager 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CacheManager : public Heaper {

/* Attributes for class CacheManager */
	DEFERRED(CacheManager)
	NO_GC(CacheManager)
  public: /* accessing */

	/* Return the value associated with the key, if any. */
	
	virtual RPTR(Heaper) OR(NULL) fetch (APTR(Heaper) ARG(key)) DEFERRED_FUNC;
	
	/* Does te cach contain something at the given key? */
	/* Should the key be a Heaper or a Position? */
	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(key)) DEFERRED_FUNC;
	
	/* Remove the cached association with key.  Return true if 
	the cache contained something at that key. */
	
	virtual BooleanVar wipe (APTR(Heaper) ARG(key)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	CacheManager();

};  /* end class CacheManager */



/* ************************************************************************ *
 * 
 *                    Class InstanceCache 
 *
 * ************************************************************************ */




	/* InstanceCache is intended to store a small number of 
	frequently used objects with the intent of reducing memory 
	allocation traffic. */

class InstanceCache : public Heaper {

/* Attributes for class InstanceCache */
	CONCRETE(InstanceCache)
	EQ(InstanceCache)
	AUTO_GC(InstanceCache)
  public: /* create */

	
	static RPTR(InstanceCache) make (Int32 ARG(size));
	
  public: /* accessing */

	
	virtual RPTR(Heaper) fetch ();
	
	
	virtual BooleanVar store (APTR(Heaper) ARG(object));
	
  protected: /* protected: create */

	
	InstanceCache (Int32 ARG(size), TCSJ);
	
  private:
	CHKPTR(PtrArray) myArray;
	Int32 myTop;
};  /* end class InstanceCache */



#endif /* CACHEX_HXX */


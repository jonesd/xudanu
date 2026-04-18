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

#ifndef CACHEX_CXX
#define CACHEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */

#ifndef CACHEX_IXX
#include "cachex.ixx"
#endif /* CACHEX_IXX */

#ifndef CACHEP_HXX
#include "cachep.hxx"
#endif /* CACHEP_HXX */

#ifndef CACHEP_IXX
#include "cachep.ixx"
#endif /* CACHEP_IXX */




/* ************************************************************************ *
 * 
 *                    Class CacheManager 
 *
 * ************************************************************************ */


/* accessing */
/* testing */


UInt32 CacheManager::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
CacheManager::CacheManager() {}



/* ************************************************************************ *
 * 
 *                    Class InstanceCache 
 *
 * ************************************************************************ */


/* create */


RPTR(InstanceCache) InstanceCache::make (Int32 size){
	RETURN_CONSTRUCT(InstanceCache,(size, tcsj));
}
/* InstanceCache is intended to store a small number of frequently 
used objects with the intent of reducing memory allocation traffic. */


/* accessing */


RPTR(Heaper) InstanceCache::fetch (){
	if (myTop >= Int32Zero) {
		SPTR(Heaper) result;
		
		result = myArray->fetch(myTop);
		myArray->store(myTop, NULL);
		myTop -= 1;
		WPTR(Heaper) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar InstanceCache::store (APTR(Heaper) object){
  return FALSE;
	if (myTop < myArray->count() - 1) {
		myTop += 1;
		object->destruct();
		new (object) SuspendedHeaper();
		myArray->store(myTop, object);
		return TRUE;
	} else {
		return FALSE;
	}
}
/* protected: create */


InstanceCache::InstanceCache (Int32 size, TCSJ) {
	myArray = PtrArray::nulls(size);
	myTop = -1;
}



/* ************************************************************************ *
 * 
 *                    Class SuspendedHeaper 
 *
 * ************************************************************************ */


/* Heapers cached to avoid memory allocation overhead are kept as 
SuspendedHeapers to reduce GC overhead. */


/* creation */

#ifndef CACHEX_SXX
#include "cachex.sxx"
#endif /* CACHEX_SXX */


#ifndef CACHEP_SXX
#include "cachep.sxx"
#endif /* CACHEP_SXX */



#endif /* CACHEX_CXX */


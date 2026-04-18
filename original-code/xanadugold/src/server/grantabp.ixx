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

#ifndef GRANTABP_IXX
#define GRANTABP_IXX


#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */


#include "fhashx.hxx"




/* ************************************************************************ *
 * 
 *                    Class ExponentialHashMap 
 *
 * ************************************************************************ */


/* accessing */


INLINE UInt32 ExponentialHashMap::exponentialMap (UInt32 aHash){
	return ExponentialHashMap::TheExponentialMap->of(::fastHash(aHash) & ExponentialHashMap::HashBits) & ExponentialHashMap::HashBits;
}


INLINE UInt32 ExponentialHashMap::hashBits (){
	return ExponentialHashMap::HashBits;
}
/* mapping */
/* creation */
/* private: calculation */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class GrandDataPage 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* protected: creation */
/* private: private */
/* node doubling */
/* special */
/* printing */
/* protected: destruction */
/* testing */
/* private: friendly */



/* ************************************************************************ *
 * 
 *                    Class GrandDataPageStepper 
 *
 * ************************************************************************ */


/* operations */
/* private: create */
/* private: private */
/* create */



/* ************************************************************************ *
 * 
 *                    Class GrandEntry 
 *
 * ************************************************************************ */


/* accessing */
/* protected: creation */
/* deferred: testing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   GrandSetEntry 
 *
 * ************************************************************************ */


/* create */
/* testing */
/* protected: creation */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class   GrandTableEntry 
 *
 * ************************************************************************ */


/* create */
/* printing */
/* accessing */
/* testing */
/* protected: creation */



/* ************************************************************************ *
 * 
 *                    Class GrandHashSetStepper 
 *
 * ************************************************************************ */


/* private: private */
/* operations */
/* protected: create */
/* create */



/* ************************************************************************ *
 * 
 *                    Class GrandHashTableStepper 
 *
 * ************************************************************************ */


/* private: private */
/* operations */
/* special */
/* create */
/* protected: creation */



/* ************************************************************************ *
 * 
 *                    Class GrandNode 
 *
 * ************************************************************************ */


/* create */
/* static functions */


INLINE Int32 GrandNode::primaryPageSize (){
	return 128;
}
/* accessing */
/* printing */
/* protected: creation */
/* node doubling */
/* private: friendly access */
/* testing */
/* overflow */
/* special */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeDoubler 
 *
 * ************************************************************************ */


/* creation */
/* protected: creation */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeReinserter 
 *
 * ************************************************************************ */


/* creation */
/* protected: creation */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeStepper 
 *
 * ************************************************************************ */


/* protected: creation */
/* private: */
/* operations */
/* create */



/* ************************************************************************ *
 * 
 *                    Class GrandOverflow 
 *
 * ************************************************************************ */


/* accessing */
/* creation */
/* private: */
/* node doubling */
/* printing */
/* protected: creation */
/* private: friendly */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class GrandOverflowStepper 
 *
 * ************************************************************************ */


/* private: */
/* operations */
/* create */
/* protected: creation */


#endif /* GRANTABP_IXX */


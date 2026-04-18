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

#ifndef FLKINFOX_IXX
#define FLKINFOX_IXX






/* ************************************************************************ *
 * 
 *                    Class FlockLocation 
 *
 * ************************************************************************ */


/* creation */
/* protected: accessing */
/* accessing */


INLINE Int32 FlockLocation::index (){
	return myIndex;
}


INLINE Int32 FlockLocation::snarfID (){
	return mySnarfID;
}
/* creation */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class   FlockInfo 
 *
 * ************************************************************************ */


/* creation */
/* debugging tools */
/* testing flags */


INLINE UInt32 FlockInfo::contentsDirty (){
	return 4;
}


INLINE UInt32 FlockInfo::destroyed (){
	return 16;
}


INLINE UInt32 FlockInfo::dismantled (){
	return 32;
}


INLINE UInt32 FlockInfo::forgottenMask (){
	return 1;
}


INLINE UInt32 FlockInfo::forgottenStateDirty (){
	return 2;
}


INLINE UInt32 FlockInfo::forwarded (){
	return 128;
}


INLINE UInt32 FlockInfo::isNewMask (){
	return 8;
}


INLINE UInt32 FlockInfo::shepNullInPersistent (){
	return 64;
}
/* flock tables */
/* testing */
/* accessing */
/* tokens */
/* create */
/* printing */


#endif /* FLKINFOX_IXX */


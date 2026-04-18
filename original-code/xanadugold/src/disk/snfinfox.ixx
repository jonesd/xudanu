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

#ifndef SNFINFOX_IXX
#define SNFINFOX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef URDIX_HXX
#include "urdix.hxx"
#endif /* URDIX_HXX */






/* ************************************************************************ *
 * 
 *                    Class SnarfHandler 
 *
 * ************************************************************************ */


/* pcreate */
/* accessing */


INLINE Int32 SnarfHandler::mapCellOverhead (){
	/* Return the number of bytes for a single map record, plus 
	the space for the 
		fence. The fence will be just the index of the flock stored 
	at the beginning and 
		the end of the flock's memory */
	
	return SnarfHandler::mapCellSize() + SnarfHandler::fenceSize() + SnarfHandler::fenceSize();
}


INLINE Int32 SnarfHandler::mapCellSize (){
	/* Return the number of bytes for a single map record. */
	
	return 8;
}


INLINE Int32 SnarfHandler::mapOverhead (){
	/* The map starts just after the basic header.  The basic 
	header currently has
		 the number of entries in the map and total amount of free 
	space remaining. */
	
	return 8;
}
/* private: sorting */


INLINE void SnarfHandler::swap (
		APTR(UInt32Array) array, 
		IntegerVar i, 
		IntegerVar j)
{
	UInt32 temp;
	
	temp = array->uIntAt(i.asLong());
	array->storeUInt(i.asLong(), array->uIntAt(j.asLong()));
	array->storeUInt(j.asLong(), temp);
}
/* reading */
/* writing */
/* initialize */
/* private: operations */
/* private: layout */


INLINE Int32 SnarfHandler::mapCellOffset (Int32 index){
	/* Return the offset into the snarf for the mapCell that has 
	the data for the flock at index. */
	
	return SnarfHandler::mapCellSize() * index + SnarfHandler::mapOverhead();
}
/* protected: destruct */
/* create */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class SnarfInfoHandler 
 *
 * ************************************************************************ */


/* pcreate */
/* accessing */
/* private: */
/* protected: destruct */
/* create */
/* testing */


#endif /* SNFINFOX_IXX */


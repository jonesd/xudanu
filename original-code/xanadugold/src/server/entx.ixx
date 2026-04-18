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

#ifndef ENTX_IXX
#define ENTX_IXX


#ifndef DAGWOODX_HXX
#include "dagwoodx.hxx"
#endif /* DAGWOODX_HXX */






/* ************************************************************************ *
 * 
 *                    Class Ent 
 *
 * ************************************************************************ */


/* instance creation */
/* magic numbers */


INLINE IntegerVar Ent::tableSegmentMaxSize (){
	/* When we are making an orgl out of a table, we break the 
	table up into pieces which should be no larger than this, so 
	that they each fit into a snarf. */
	
	return 16384;
}
/* orgl creation */
/* instance creation */
/* testing */


#endif /* ENTX_IXX */


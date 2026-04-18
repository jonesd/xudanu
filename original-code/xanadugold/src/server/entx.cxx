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

#ifndef ENTX_CXX
#define ENTX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef ENTX_HXX
#include "entx.hxx"
#endif /* ENTX_HXX */

#ifndef ENTX_IXX
#include "entx.ixx"
#endif /* ENTX_IXX */


#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TRACEPX_HXX
#include "tracepx.hxx"
#endif /* TRACEPX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Ent 
 *
 * ************************************************************************ */



/* Initializers for Ent */

BUILD_FLUID(TracePosition,CurrentTrace, NULL, DiskManager::emulsion());	/* in Ent */
BUILD_FLUID(BertCrum,CurrentBertCrum, NULL, DiskManager::emulsion());	/* in Ent */


/* Initializers for Ent */



/* instance creation */


RPTR(Ent) Ent::make (){
	RETURN_CONSTRUCT(Ent,());
}
/* magic numbers */
/* orgl creation */


RPTR(TracePosition) Ent::newTrace (){
	WPTR(TracePosition) 	returnValue;
	returnValue = fulltrace->newPosition();
	return returnValue;
}
/* instance creation */


Ent::Ent () {
	
	CONSTRUCT(fulltrace,DagWood,());
	this->newShepherd();
	this->remember();
}
/* testing */


UInt32 Ent::contentsHash (){
	return this->Abraham::contentsHash() ^ fulltrace->hashForEqual();
}

#ifndef ENTX_SXX
#include "entx.sxx"
#endif /* ENTX_SXX */



#endif /* ENTX_CXX */


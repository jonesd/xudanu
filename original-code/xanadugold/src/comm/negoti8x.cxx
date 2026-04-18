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

#ifndef NEGOTI8X_CXX
#define NEGOTI8X_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NEGOTI8X_IXX
#include "negoti8x.ixx"
#endif /* NEGOTI8X_IXX */

#ifndef NEGOTI8P_HXX
#include "negoti8p.hxx"
#endif /* NEGOTI8P_HXX */

#ifndef NEGOTI8P_IXX
#include "negoti8p.ixx"
#endif /* NEGOTI8P_IXX */


#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ProtocolBroker 
 *
 * ************************************************************************ */



/* Initializers for ProtocolBroker */

GPTR(ProtocolItem) ProtocolBroker::DiskProtocols = NULL;
GPTR(ProtocolItem) ProtocolBroker::CommProtocols = NULL;
GPTR(XcvrMaker) ProtocolBroker::TheCommProtocol = NULL;
GPTR(XcvrMaker) ProtocolBroker::TheDiskProtocol = NULL;


/* Initializers for ProtocolBroker */



/* configuration */


RPTR(XcvrMaker) ProtocolBroker::commProtocol (){
	/* return whichever is the best current protocol. */
	
	if (ProtocolBroker::TheCommProtocol == NULL) {
		ProtocolBroker::TheCommProtocol = CAST(XcvrMaker,ProtocolBroker::CommProtocols->get("binary1"));
	}
	WPTR(XcvrMaker) 	returnValue;
	returnValue = ProtocolBroker::TheCommProtocol;
	return returnValue;
}


RPTR(XcvrMaker) ProtocolBroker::commProtocol (char * id){
	return CAST(XcvrMaker,ProtocolBroker::CommProtocols->get(id));
}


RPTR(XcvrMaker) ProtocolBroker::diskProtocol (){
	/* return whichever is the best current protocol. */
	
	if (ProtocolBroker::TheDiskProtocol == NULL) {
		ProtocolBroker::TheDiskProtocol = CAST(XcvrMaker,ProtocolBroker::DiskProtocols->get("binary1"));
	}
	WPTR(XcvrMaker) 	returnValue;
	returnValue = ProtocolBroker::TheDiskProtocol;
	return returnValue;
}


RPTR(XcvrMaker) ProtocolBroker::diskProtocol (char * id){
	return CAST(XcvrMaker,ProtocolBroker::DiskProtocols->get(id));
}


void ProtocolBroker::registerXcvrProtocol (APTR(XcvrMaker) maker){
	CONSTRUCT(ProtocolBroker::CommProtocols,ProtocolItem,(maker->id(), maker, ProtocolBroker::CommProtocols));
	CONSTRUCT(ProtocolBroker::DiskProtocols,ProtocolItem,(maker->id(), maker, ProtocolBroker::DiskProtocols));
}


void ProtocolBroker::setCommProtocol (APTR(XcvrMaker) maker){
	/* Set the protocol. */
	
	ProtocolBroker::TheCommProtocol = maker;
}


void ProtocolBroker::setDiskProtocol (APTR(XcvrMaker) maker){
	/* Set the protocol. */
	
	ProtocolBroker::TheDiskProtocol = maker;
}

	/* automatic 0-argument constructor */
ProtocolBroker::ProtocolBroker() {}



/* ************************************************************************ *
 * 
 *                    Class ProtocolItem 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Heaper) ProtocolItem::get (char * name){
	if (::strcmp(name, myName) == Int32Zero) {
		return (Heaper*) myItem;
	}
	if (myNext != NULL) {
		WPTR(Heaper) 	returnValue;
		returnValue = myNext->get(name);
		return returnValue;
	} else {
		BLAST(NotInList);
	}
	/* fodder */
	return NULL;
}
/* create */


ProtocolItem::ProtocolItem (
		char * name, 
		APTR(Heaper) item, 
		APTR(ProtocolItem) next) 
{
	myName = name;
	myItem = item;
	myNext = next;
}
/* testing */


UInt32 ProtocolItem::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class SetCommProtocol 
 *
 * ************************************************************************ */


/* When executed, the receiver will set the comm protocol for the 
next connection. */


/* hooks: */


void SetCommProtocol::restartSetCommProtocol (APTR(Rcvr) /* rcvr *//* = NULL*/){
	DeleteExecutor::registerHolder(this, myName);
}
/* thunking */


void SetCommProtocol::execute (){
	/* Execute the action defined by this thunk. */
	
	ProtocolBroker::setCommProtocol(ProtocolBroker::commProtocol(myName));
}

	/* automatic 0-argument constructor */
SetCommProtocol::SetCommProtocol() {}



/* ************************************************************************ *
 * 
 *                    Class SetDiskProtocol 
 *
 * ************************************************************************ */


/* When executed, the receiver will set the disk protocol for the 
next connection. */


/* operate */


void SetDiskProtocol::execute (){
	/* Execute the action defined by this thunk. */
	
	ProtocolBroker::setDiskProtocol(ProtocolBroker::diskProtocol(myName));
}
/* hooks: */


void SetDiskProtocol::restartSetDiskProtocol (APTR(Rcvr) /* rcvr *//* = NULL*/){
	DeleteExecutor::registerHolder(this, myName);
}

	/* automatic 0-argument constructor */
SetDiskProtocol::SetDiskProtocol() {}

#ifndef NEGOTI8X_SXX
#include "negoti8x.sxx"
#endif /* NEGOTI8X_SXX */


#ifndef NEGOTI8P_SXX
#include "negoti8p.sxx"
#endif /* NEGOTI8P_SXX */



#endif /* NEGOTI8X_CXX */


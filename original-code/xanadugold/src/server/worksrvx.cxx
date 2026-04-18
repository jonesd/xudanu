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

#ifndef WORKSRVX_CXX
#define WORKSRVX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef WORKSRVX_HXX
#include "worksrvx.hxx"
#endif /* WORKSRVX_HXX */

#ifndef WORKSRVX_IXX
#include "worksrvx.ixx"
#endif /* WORKSRVX_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeWorksBootMaker 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Category) FeWorksBootMaker::bootCategory (){
	WPTR(Category) 	returnValue;
	returnValue = cat_FeServer;
	return returnValue;
}


RPTR(Connection) FeWorksBootMaker::connection (){
	SPTR(Connection) conn;
	
	conn = Connection::make (cat_FeServer);
	/* ^NestedConnection make: self bootCategory with: 
	(PrGateKeeper make: (conn bootHeaper cast: FeGateKeeper)) with: conn */
	WPTR(Connection) 	returnValue;
	returnValue = conn;
	return returnValue;
}

	/* automatic 0-argument constructor */
FeWorksBootMaker::FeWorksBootMaker() {}



/* ************************************************************************ *
 * 
 *                    Class WorksBootMaker 
 *
 * ************************************************************************ */



/* Initializers for WorksBootMaker */

BUILD_FLUID(Connection,GrandConnection, NULL, ::globalEmulsion());	/* in WorksBootMaker */


/* Initializers for WorksBootMaker */



/* accessing */


RPTR(Category) WorksBootMaker::bootCategory (){
	WPTR(Category) 	returnValue;
	returnValue = cat_FeServer;
	return returnValue;
}
/* protected: */


RPTR(Heaper) WorksBootMaker::bootHeaper (){
	/* CurrentGrandMap fluidFetch == NULL ifFalse: [Heaper BLAST: 
		#GrandMapWithoutConnection]. */
	if (GrandConnection.fluidFetch() == NULL) {
		GrandConnection.fluidSet(Connection::make (cat_BeGrandMap));
		CurrentGrandMap.fluidSet(CAST(BeGrandMap,GrandConnection.fluidGet()->bootHeaper()));
		/* force agenda items to be invoked - they were 
			commented out in getInitialFlock /ravi/10/22/92/ */
		BEGIN_CONSISTENT(-1) {
			
		} END_CONSISTENT;
	}
	WPTR(Heaper) 	returnValue;
	returnValue = FeServer::make ();
	return returnValue;
}

	/* automatic 0-argument constructor */
WorksBootMaker::WorksBootMaker() {}



/* ************************************************************************ *
 * 
 *                    Class WorksIniter 
 *
 * ************************************************************************ */


/* The purpose of WorksIniter is to do the one-time initialization of 
clubs and homedocs to prepare a backend for ordinary client use. It 
is pretty sparse right now, but will eventually have much more stuff */


/* initialization */


void WorksIniter::initializeClubs (){
	SPTR(FeClub) testClub;
	SPTR(ID) testID;
	
	/* Make an autonomous Test club */
	testClub = FeClub::make (FeClubDescription::make (FeSet::make (), FeBooLockSmith::make ())->edition());
	testID = FeServer::iDOf(testClub);
	testClub->setReadClub(testID);
	testClub->setEditClub(testID);
	testClub->setSignatureClub(testID);
	testClub->setOwner(testID);
	FeServer::nameClub(Sequence::string("Test"), testID);
	FeServer::enableAccess(testID);
}


void WorksIniter::initializeSystem (){
	SPTR(Connection) aConnection;
	SPTR(ID) adminID;
	SPTR(FeWaitDetector) wwd;
	
	
	aConnection = Connection::make (cat_FeServer);
	CurrentKeyMaster.fluidSet(CAST(BooLock,FeServer::loginByName(Sequence::string("System Admin")))->boo());
	CurrentKeyMaster.fluidGet()->incorporate(FeKeyMaster::makePublic());
	adminID = FeServer::clubID(Sequence::string("System Admin"));
	InitialOwner.fluidSet(adminID);
	InitialReadClub.fluidSet(adminID);
	InitialEditClub.fluidSet(adminID);
	InitialSponsor.fluidSet(adminID);
	CurrentAuthor.fluidSet(adminID);
	this->initializeClubs();
	CONSTRUCT(wwd,WorksWaitDetector,(cerr, "WorksInit done!"));
	FeServer::waitForWrite(wwd);
	
	CurrentPacker.fluidGet()->purge();
	
	{aConnection->destroy();  aConnection = NULL /* don't want stale (S/CHK)PTRs */;}
}
/* execute */


void WorksIniter::execute (){
	this->initializeSystem();
}

	/* automatic 0-argument constructor */
WorksIniter::WorksIniter() {}



/* ************************************************************************ *
 * 
 *                    Class WorksWaitDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeWaitDetector) WorksWaitDetector::make (ostream& oo, char * tag){
	RETURN_CONSTRUCT(WorksWaitDetector,(oo, tag));
}
/* This class keeps a pointer to an ostream rather than a reference 
since class ios::operator=() is private. */


/* creation */


WorksWaitDetector::WorksWaitDetector (ostream& oo, char * tag) {
	
	myOutput = &oo;
	
	myTag = tag;
}
/* triggering */


NOACK WorksWaitDetector::done (){
	
	*myOutput << myTag << "\n";
	
}

#ifndef WORKSRVX_SXX
#include "worksrvx.sxx"
#endif /* WORKSRVX_SXX */



#endif /* WORKSRVX_CXX */


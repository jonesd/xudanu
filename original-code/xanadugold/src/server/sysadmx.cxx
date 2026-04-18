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

#ifndef SYSADMX_CXX
#define SYSADMX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SYSADMX_HXX
#include "sysadmx.hxx"
#endif /* SYSADMX_HXX */

#ifndef SYSADMX_IXX
#include "sysadmx.ixx"
#endif /* SYSADMX_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SRVLOOPX_HXX
#include "srvloopx.hxx"
#endif /* SRVLOOPX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeAdminer 
 *
 * ************************************************************************ */


/* create */


RPTR(FeAdminer) FeAdminer::make (){
	FeKeyMaster::assertAdminAuthority();
	RETURN_CONSTRUCT(FeAdminer,());
}
/* A client interface for system administration operations. This 
object can only be obtained using a KeyMaster that has System Admin 
authority.  */


/* administrivia */


void FeAdminer::acceptConnections (BooleanVar open){
	/* Essential. Enable or disable the ability of the Server to 
	accept communications connections from client machines. 
	Anyone who has received a GateKeeper or Server object will 
	continue to stay connected, but no new such objects will be 
	handed out */
	
	CurrentGrandMap.fluidGet()->acceptConnections(open);
}


RPTR(Stepper) OF1(FeSession) FeAdminer::activeSessions (){
	/* Essential. Return a list of all active sessions. */
	
	WPTR(Stepper) OF1(FeSession) 	returnValue;
	returnValue = FeSession::allActive();
	return returnValue;
}


void FeAdminer::execute (APTR(PrimIntArray) commands){
	/* Essential. Execute a sequence of server configuration commands. */
	
	SPTR(Rcvr) rc;
	SPTR(Heaper) OR(NULL) next;
	
	/* Known bug !!!! */
	
	/* only accepts UInt8Arrays */
	rc = TextyXcvrMaker::make ()->makeRcvr(TransferSpecialist::make (Cookbook::make ("boot")), XnReadStream::make (CAST(UInt8Array,commands)));
	next = rc->receiveHeaper();
	while (next != NULL) {
		BEGIN_CHOOSE(next) {
			BEGIN_KIND(Thunk,thunk) {
				thunk->execute();
			} END_KIND;
			BEGIN_OTHERS {
				
			} END_OTHERS;
		} END_CHOOSE;
		next = rc->receiveHeaper();
	}
	{rc->destroy();  rc = NULL /* don't want stale (S/CHK)PTRs */;}
}


void FeAdminer::grant (APTR(ID) clubID, APTR(IDRegion) globalIDs){
	/* Essential. Grant a Club the authority to assign global IDs 
	on this Server. */
	
	CurrentGrandMap.fluidGet()->grant(clubID, globalIDs);
}


RPTR(TableStepper) OF2(ID,IDRegion) FeAdminer::grants (APTR(IDRegion) clubIDs/* = NULL*/, APTR(IDRegion) globalIDs/* = NULL*/){
	/* Essential. List who has been granted authority to various 
	regions of the global IDSpace on this Server. */
	
	WPTR(TableStepper) OF2(ID,IDRegion) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->grants(clubIDs, globalIDs);
	return returnValue;
}


BooleanVar FeAdminer::isAcceptingConnections (){
	/* Essential. Whether the Server is accepting communications 
	connections from client machines.  */
	
	return CurrentGrandMap.fluidGet()->isAcceptingConnections();
}


void FeAdminer::shutdown (){
	/* Essential. Shutdown the Server immediately, taking down 
	all the connections and writing all current changes to disk. */
	
	
	CurrentPacker.fluidFetch()->purge();
	ServerLoop::scheduleTermination();
}
/* security */


RPTR(FeLockSmith) FeAdminer::gateLockSmith (){
	/* Essential. The LockSmith which hands out locks when a 
	client tries to login through the GateKeeper with an invalid 
	Club ID or name. */
	
	
	return CAST(FeLockSmith,FeLockSmith::spec()->wrap(CurrentGrandMap.fluidGet()->gateLockSmithEdition()));
}


void FeAdminer::setGateLockSmith (APTR(FeLockSmith) lockSmith){
	/* Essential. Set the LockSmith which creates locks to hand 
	out when a client tries to login with an invalid Club ID or 
	name through the GateKeeper. */
	
	
	CurrentGrandMap.fluidFetch()->setGateLockSmithEdition(lockSmith->edition());
}

	/* automatic 0-argument constructor */
FeAdminer::FeAdminer() {}



/* ************************************************************************ *
 * 
 *                    Class FeArchiver 
 *
 * ************************************************************************ */


/* create */


RPTR(FeArchiver) FeArchiver::make (){
	RETURN_CONSTRUCT(FeArchiver,());
}
/* Used for transferring information to and from external storage 
medium. This protocol is still expected to evolve. */


/* accessing */


RPTR(FeEdition) FeArchiver::archive (APTR(FeEdition) works, APTR(FeEdition) medium){
	/* Essential.  Copy the entire contents of a set of Works 
	onto secondary storage. Requires read permission on all the 
	Works (or the authority of the System Archive Club, which can 
	read anything). The medium is an Edition describing the kind 
	of device on which to write the backup. The result and the 
	list of Works are wrapped as Sets, the medium as a StorageMedium.
		Returns the set of Works which were in fact successfully backed up. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


void FeArchiver::markArchived (APTR(FeEdition) edition){
	/* Essential. Mark the contents of a set of Works as archived 
	so that they can be discarded from the online disk. Requires 
	System Admin authority. */
	
	BLAST(NOT_YET_IMPLEMENTED);
}


RPTR(FeEdition) FeArchiver::restore (APTR(FeEdition) OR(NULL) works, APTR(FeEdition) medium){
	/* Essential.  Restore information from a backup tape. If a 
	set of Works is specified, then restores only them from the 
	backup medium, otherwise just reads the entire contents. Must 
	have edit authority on Works which are restored. (Is this the 
	right authority? What to do about history?)
		Returns the Works which were restored from tape. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}

	/* automatic 0-argument constructor */
FeArchiver::FeArchiver() {}

#ifndef SYSADMX_SXX
#include "sysadmx.sxx"
#endif /* SYSADMX_SXX */



#endif /* SYSADMX_CXX */


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

#ifndef SYSADMX_HXX
#define SYSADMX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SYSADMX_OXX
#include "sysadmx.oxx"
#endif /* SYSADMX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NADMINX_OXX
#include "nadminx.oxx"
#endif /* NADMINX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FeAdminer 
 *
 * ************************************************************************ */




	/* A client interface for system administration operations. 
	This object can only be obtained using a KeyMaster that has 
	System Admin authority.  */

class FeAdminer : public Heaper {

/* Attributes for class FeAdminer */
	CONCRETE(FeAdminer)
	ON_CLIENT(FeAdminer)
	EQ(FeAdminer)
	AUTO_GC(FeAdminer)
  public: /* create */

	
	static CLIENT RPTR(FeAdminer) make ();
	
  public: /* administrivia */

	/* Essential. Enable or disable the ability of the Server to 
	accept communications connections from client machines. 
	Anyone who has received a GateKeeper or Server object will 
	continue to stay connected, but no new such objects will be 
	handed out */
	
	virtual CLIENT void acceptConnections (BooleanVar ARG(open));
	
	/* Essential. Return a list of all active sessions. */
	
	virtual CLIENT RPTR(Stepper) OF1(FeSession) activeSessions ();
	
	/* Essential. Execute a sequence of server configuration commands. */
	
	virtual CLIENT void execute (APTR(PrimIntArray) ARG(commands));
	
	/* Essential. Grant a Club the authority to assign global IDs 
	on this Server. */
	
	virtual CLIENT void grant (APTR(ID) ARG(clubID), APTR(IDRegion) ARG(globalIDs));
	
	/* Essential. List who has been granted authority to various 
	regions of the global IDSpace on this Server. */
	
	virtual CLIENT RPTR(TableStepper) OF2(ID,IDRegion) grants (APTR(IDRegion) ARG(clubIDs) = NULL, APTR(IDRegion) ARG(globalIDs) = NULL);
	
	/* Essential. Whether the Server is accepting communications 
	connections from client machines.  */
	
	virtual CLIENT BooleanVar isAcceptingConnections ();
	
	/* Essential. Shutdown the Server immediately, taking down 
	all the connections and writing all current changes to disk. */
	
	virtual CLIENT void shutdown ();
	
  public: /* security */

	/* Essential. The LockSmith which hands out locks when a 
	client tries to login through the GateKeeper with an invalid 
	Club ID or name. */
	
	virtual CLIENT RPTR(FeLockSmith) gateLockSmith ();
	
	/* Essential. Set the LockSmith which creates locks to hand 
	out when a client tries to login with an invalid Club ID or 
	name through the GateKeeper. */
	
	virtual CLIENT void setGateLockSmith (APTR(FeLockSmith) ARG(lockSmith));
	

	/* automatic 0-argument constructor */
  public:
	FeAdminer();
  private:
	CHKPTR(FeKeyMaster) myAdminKM;
};  /* end class FeAdminer */



/* ************************************************************************ *
 * 
 *                    Class FeArchiver 
 *
 * ************************************************************************ */




	/* Used for transferring information to and from external 
	storage medium. This protocol is still expected to evolve. */

class FeArchiver : public Heaper {

/* Attributes for class FeArchiver */
	CONCRETE(FeArchiver)
	ON_CLIENT(FeArchiver)
	EQ(FeArchiver)
	NO_GC(FeArchiver)
  public: /* create */

	
	static CLIENT RPTR(FeArchiver) make ();
	
  public: /* accessing */

	/* Essential.  Copy the entire contents of a set of Works 
	onto secondary storage. Requires read permission on all the 
	Works (or the authority of the System Archive Club, which can 
	read anything). The medium is an Edition describing the kind 
	of device on which to write the backup. The result and the 
	list of Works are wrapped as Sets, the medium as a StorageMedium.
		Returns the set of Works which were in fact successfully backed up. */
	
	virtual CLIENT RPTR(FeEdition) archive (APTR(FeEdition) ARG(works), APTR(FeEdition) ARG(medium));
	
	/* Essential. Mark the contents of a set of Works as archived 
	so that they can be discarded from the online disk. Requires 
	System Admin authority. */
	
	virtual CLIENT void markArchived (APTR(FeEdition) ARG(edition));
	
	/* Essential.  Restore information from a backup tape. If a 
	set of Works is specified, then restores only them from the 
	backup medium, otherwise just reads the entire contents. Must 
	have edit authority on Works which are restored. (Is this the 
	right authority? What to do about history?)
		Returns the Works which were restored from tape. */
	
	virtual CLIENT RPTR(FeEdition) restore (APTR(FeEdition) OR(NULL) ARG(works), APTR(FeEdition) ARG(medium));
	

	/* automatic 0-argument constructor */
  public:
	FeArchiver();

};  /* end class FeArchiver */



#endif /* SYSADMX_HXX */


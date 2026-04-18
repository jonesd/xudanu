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

#ifndef SRVLOOPX_HXX
#define SRVLOOPX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SRVLOOPX_OXX
#include "srvloopx.oxx"
#endif /* SRVLOOPX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef BOOTPLNX_OXX
#include "bootplnx.oxx"
#endif /* BOOTPLNX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SCHUNKX_OXX
#include "schunkx.oxx"
#endif /* SCHUNKX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ServerLoop 
 *
 * ************************************************************************ */



/* Initializers for ServerLoop */



DESIGN_FLUID(Connection,CurrentServerConnection);	/* in ServerLoop */
DESIGN_FLUID(ServerLoop,CurrentServerLoop);	/* in ServerLoop */







	/*   This is the superclass of all server loops.  There is 
	only one instance of this class in any backend.  Its execute 
	method is the central backend processing loop.  When an 
	instance is created, its creation method must register it 
	with this class.  At that time, all listeners that have been 
	created up to this point will be passed to the new server 
	loop instance.  After this time, new listeners will be passed 
	to the serverloop instance as they register themselves with this class.
	 */

class ServerLoop : public Thunk {

/* Attributes for class ServerLoop */
	DEFERRED(ServerLoop)
	COPY(ServerLoop,BootCuisine)
	AUTO_GC(ServerLoop)

/* Initializers for ServerLoop */






friend class INIT_TIME_NAME(ServerLoop,initTimeNonInherited);

  protected: /* protected: accessing */

	
	static RPTR(MuSet) OF1(ServerChunk) chunks ();
	
  public: /* accessing */

	
	static RPTR(ServerLoop) currentServerLoop ();
	
	
	static void introduceChunk (APTR(ServerChunk) ARG(aChunk));
	
	
	static void registerServerLoop (APTR(ServerLoop) ARG(aLoop));
	
	
	static void removeChunk (APTR(ServerChunk) ARG(aChunk));
	
	
	static RPTR(ServerLoop) removeServerLoop ();
	
	
	static void scheduleTermination ();
	
  protected: /* protected: accessing */

	
	virtual RPTR(MuSet) OF1(ServerChunk) activeChunks ();
	
	/* subclasses should call me too */
	
	virtual void deregisterChunk (APTR(ServerChunk) ARG(aChunk));
	
	/* subclass must call this one first */
	
	virtual void registerChunk (APTR(ServerChunk) ARG(aChunk));
	
	
	virtual void setTerminate (BooleanVar ARG(toBoolean));
	
	
	virtual RPTR(Stepper) stepper ();
	
	
	virtual void stepper (APTR(Stepper) ARG(stepper));
	
	
	virtual BooleanVar terminate ();
	
  public: /* execution */

	
	virtual void execute ();
	
	/* Schedule any chunks that have bnecome active. */
	
	virtual void scheduleChunks () DEFERRED_SUBR;
	
  public: /* creation */

	
	ServerLoop ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartServerLoop (APTR(Rcvr) ARG(rcvr));
	
  private:
	CHKPTR(Category) myCategory;
	NOCOPY CHKPTR(MuSet) OF1(ServerChunk) myActiveChunks;
	NOCOPY BooleanVar myTerminateFlag;
	NOCOPY CHKPTR(Stepper) myStepper;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(ServerLoop) MyServerLoopInstance;
	static GPTR(MuSet) OF1(ServerChunk) TheChunks;
/* Friends for class ServerLoop */
/* friends for class ServerLoop */
friend class TerminateTest;
friend void  registerChunk (APTR(ServerChunk) aChunk);
friend void  registerServerLoop (APTR(ServerLoop) aLoop);
friend void  removeChunk (APTR(ServerChunk) aChunk);
friend void  scheduleTermination ();



};  /* end class ServerLoop */



#endif /* SRVLOOPX_HXX */


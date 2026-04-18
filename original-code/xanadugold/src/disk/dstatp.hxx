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

#ifndef DSTATP_HXX
#define DSTATP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DSTATP_OXX
#include "dstatp.oxx"
#endif /* DSTATP_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SNFINFOX_OXX
#include "snfinfox.oxx"
#endif /* SNFINFOX_OXX */

#ifndef URDIX_OXX
#include "urdix.oxx"
#endif /* URDIX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SnarfStatistics 
 *
 * ************************************************************************ */




	/* Print out some summary of the data currently on disk. */

class SnarfStatistics : public Thunk {

/* Attributes for class SnarfStatistics */
	CONCRETE(SnarfStatistics)
	COPY(SnarfStatistics,BootCuisine)
	NOT_A_TYPE(SnarfStatistics)
	AUTO_GC(SnarfStatistics)
  public: /* running */

	
	virtual void execute ();
	
	
	virtual void snarfAllocInfo ();
	
	
	virtual void tallyFlockTypes ();
	
  public: /* private */

	/* Get the cookbook and protocol-stream maker for the disk. */
	
	virtual void diskCookbook (APTR(UrdiView) ARG(view), APTR(SnarfInfoHandler) ARG(info));
	
	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(XnReadStream) ARG(readStream));
	

	/* automatic 0-argument constructor */
  public:
	SnarfStatistics();
  private:
	char * myFilename;
	NOCOPY CHKPTR(Cookbook) myCookbook;
	NOCOPY CHKPTR(XcvrMaker) myProtocol;
};  /* end class SnarfStatistics */



/* ************************************************************************ *
 * 
 *                    Class SpecialistRcvrJig 
 *
 * ************************************************************************ */




	/* A tool to read partial packets from the disk to measure 
	statistics. */

class SpecialistRcvrJig : public Heaper {

/* Attributes for class SpecialistRcvrJig */
	CONCRETE(SpecialistRcvrJig)
	NO_GC(SpecialistRcvrJig)
  public: /* receiving */

	
	static RPTR(Category) receiveCategory (APTR(Rcvr) ARG(rcvr));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	SpecialistRcvrJig();

};  /* end class SpecialistRcvrJig */



#endif /* DSTATP_HXX */


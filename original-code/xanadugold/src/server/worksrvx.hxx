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

#ifndef WORKSRVX_HXX
#define WORKSRVX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef WORKSRVX_OXX
#include "worksrvx.oxx"
#endif /* WORKSRVX_OXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */


/*  */
/*  */
#define NOACK void



/* ************************************************************************ *
 * 
 *                    Class FeWorksBootMaker 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FeWorksBootMaker : public BootPlan {

/* Attributes for class FeWorksBootMaker */
	CONCRETE(FeWorksBootMaker)
	COPY(FeWorksBootMaker,BootCuisine)
	NOT_A_TYPE(FeWorksBootMaker)
	NO_GC(FeWorksBootMaker)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Connection) connection ();
	

	/* automatic 0-argument constructor */
  public:
	FeWorksBootMaker();

};  /* end class FeWorksBootMaker */



/* ************************************************************************ *
 * 
 *                    Class WorksBootMaker 
 *
 * ************************************************************************ */



/* Initializers for WorksBootMaker */
DESIGN_FLUID(Connection,GrandConnection);	/* in WorksBootMaker */




	/* NO CLASS COMMENT */

class WorksBootMaker : public BootMaker {

/* Attributes for class WorksBootMaker */
	CONCRETE(WorksBootMaker)
	COPY(WorksBootMaker,BootCuisine)
	NOT_A_TYPE(WorksBootMaker)
	NO_GC(WorksBootMaker)

/* Initializers for WorksBootMaker */


  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
  protected: /* protected: */

	
	virtual RPTR(Heaper) bootHeaper ();
	

	/* automatic 0-argument constructor */
  public:
	WorksBootMaker();

};  /* end class WorksBootMaker */



/* ************************************************************************ *
 * 
 *                    Class WorksIniter 
 *
 * ************************************************************************ */




	/* The purpose of WorksIniter is to do the one-time 
	initialization of clubs and homedocs to prepare a backend for 
	ordinary client use. It is pretty sparse right now, but will 
	eventually have much more stuff */

class WorksIniter : public Thunk {

/* Attributes for class WorksIniter */
	CONCRETE(WorksIniter)
	COPY(WorksIniter,BootCuisine)
	NO_GC(WorksIniter)
  public: /* initialization */

	
	virtual void initializeClubs ();
	
	
	virtual void initializeSystem ();
	
  public: /* execute */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	WorksIniter();

};  /* end class WorksIniter */



/* ************************************************************************ *
 * 
 *                    Class WorksWaitDetector 
 *
 * ************************************************************************ */




	/* This class keeps a pointer to an ostream rather than a 
	reference since class ios::operator=() is private. */

class WorksWaitDetector : public FeWaitDetector {

/* Attributes for class WorksWaitDetector */
	CONCRETE(WorksWaitDetector)
	EQ(WorksWaitDetector)
	NOT_A_TYPE(WorksWaitDetector)
	AUTO_GC(WorksWaitDetector)
  public: /* creation */

	
	static RPTR(FeWaitDetector) make (ostream& ARG(oo), char * ARG(tag));
	
  public: /* creation */

	
	WorksWaitDetector (ostream& ARG(oo), char * ARG(tag));
	
  public: /* triggering */

	
	virtual CLIENT NOACK done ();
	
  private:
	char * myTag;
	ostream * myOutput;
};  /* end class WorksWaitDetector */



#endif /* WORKSRVX_HXX */


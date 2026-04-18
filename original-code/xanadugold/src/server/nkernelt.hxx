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

#ifndef NKERNELT_HXX
#define NKERNELT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NKERNELT_OXX
#include "nkernelt.oxx"
#endif /* NKERNELT_OXX */


#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef BOOTPLNX_OXX
#include "bootplnx.oxx"
#endif /* BOOTPLNX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class WorksTester 
 *
 * ************************************************************************ */



/* Initializers for WorksTester */







	/* NO CLASS COMMENT */

class WorksTester : public Tester {

/* Attributes for class WorksTester */
	CONCRETE(WorksTester)
	COPY(WorksTester,BootCuisine)
	AUTO_GC(WorksTester)

/* Initializers for WorksTester */





  public: /* server library */

	/* Looks up the ID of a named Club in the directory 
	maintained by the System Admin Club. Requires read permission 
	on the directory. Blasts if there is no Club with that name. */
	
	static RPTR(ID) clubID (APTR(Sequence) ARG(clubName));
	
	
	static RPTR(IntegerPos) xuInteger (IntegerVar ARG(val));
	
	
	static RPTR(Sequence) sequence (char * ARG(string));
	
	
	static RPTR(PrimArray) string (char * ARG(string));
	
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	
  public: /* tests */

	/* Test the various version comparision operations */
	
	virtual void compareTestOn (ostream& ARG(oo));
	
	
	virtual void crossTestOn (ostream& ARG(oo));
	
	/* Test the simple Edition operations */
	
	virtual void editionTestOn (ostream& ARG(oo));
	
	/* Test endorsing and unendorsing Editions and Works */
	
	virtual void endorseTestOn (ostream& ARG(oo));
	
	/* Test assigning and retrieving by global IDs */
	
	virtual void globalIDTestOn (ostream& ARG(oo));
	
	
	virtual void historyTestOn (ostream& ARG(oo));
	
	/* Test the operation of KeyMasters */
	
	virtual void kmTestOn (ostream& ARG(oo));
	
	
	virtual void labelTestOn (ostream& ARG(oo));
	
	/* Try making Editions in a variety of ways */
	
	virtual void makeEditionTestOn (ostream& ARG(oo));
	
	
	virtual void ownerTestOn (ostream& ARG(oo));
	
	/* Test the sponsoring mechanism */
	
	virtual void sponsorTestOn (ostream& ARG(oo));
	
	
	virtual void transcludersBugTestOn (ostream& ARG(oo));
	
	/* Test the transclusions query */
	
	virtual void transclusionsTestOn (ostream& ARG(oo));
	
	/* Try the various operations on Works */
	
	virtual void workTestOn (ostream& ARG(oo));
	
  private: /* private: */

	/* Print the state and contents of a Work */
	
	virtual void dumpWorkOn (
			ostream& ARG(oo), 
			char * ARG(tag), 
			APTR(FeWork) ARG(work))
	;
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartWorksTester (APTR(Rcvr) ARG(rcvr) = NULL);
	

	/* automatic 0-argument constructor */
  public:
	WorksTester();
  private:
	NOCOPY CHKPTR(Connection) myConnection;
	NOCOPY char * myCR;
	NOCOPY CHKPTR(ID) myTestID;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(WorksTester) TheTester;
};  /* end class WorksTester */



/* ************************************************************************ *
 * 
 *                    Class WorksTestFillDetector 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class WorksTestFillDetector : public FeFillDetector {

/* Attributes for class WorksTestFillDetector */
	CONCRETE(WorksTestFillDetector)
	EQ(WorksTestFillDetector)
	NOT_A_TYPE(WorksTestFillDetector)
	AUTO_GC(WorksTestFillDetector)
  public: /* pseudo constructors */

	
	static RPTR(FeFillDetector) make (ostream& ARG(oo), char * ARG(tag));
	
  public: /* triggering */

	
	virtual void filled (APTR(FeRangeElement) ARG(transclusion));
	
  private: /* private: create */

	
	WorksTestFillDetector (ostream& ARG(oo), char * ARG(tag));
	
  private:
	char * myTag;
	ostream * myOutput;
};  /* end class WorksTestFillDetector */



/* ************************************************************************ *
 * 
 *                    Class WorksTestFillRangeDetector 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class WorksTestFillRangeDetector : public FeFillRangeDetector {

/* Attributes for class WorksTestFillRangeDetector */
	CONCRETE(WorksTestFillRangeDetector)
	EQ(WorksTestFillRangeDetector)
	NOT_A_TYPE(WorksTestFillRangeDetector)
	AUTO_GC(WorksTestFillRangeDetector)
  public: /* pseudo constructors */

	
	static RPTR(FeFillRangeDetector) make (ostream& ARG(oo), char * ARG(tag));
	
  public: /* triggering */

	
	virtual void rangeFilled (APTR(FeEdition) ARG(transclusions));
	
  private: /* private: create */

	
	WorksTestFillRangeDetector (ostream& ARG(oo), char * ARG(tag));
	
  private:
	char * myTag;
	ostream * myOutput;
};  /* end class WorksTestFillRangeDetector */



/* ************************************************************************ *
 * 
 *                    Class WorksTestStatusDetector 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class WorksTestStatusDetector : public FeStatusDetector {

/* Attributes for class WorksTestStatusDetector */
	CONCRETE(WorksTestStatusDetector)
	EQ(WorksTestStatusDetector)
	NOT_A_TYPE(WorksTestStatusDetector)
	AUTO_GC(WorksTestStatusDetector)
  public: /* pseudo constructors */

	
	static RPTR(FeStatusDetector) make (ostream& ARG(oo), char * ARG(tag));
	
  public: /* triggering */

	
	virtual void grabbed (
			APTR(FeWork) ARG(work), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(reason))
	;
	
	
	virtual void released (APTR(FeWork) ARG(work), IntegerVar ARG(reason));
	
  private: /* private: create */

	
	WorksTestStatusDetector (ostream& ARG(oo), char * ARG(tag));
	
  private:
	char * myTag;
	ostream * myOutput;
};  /* end class WorksTestStatusDetector */



#endif /* NKERNELT_HXX */


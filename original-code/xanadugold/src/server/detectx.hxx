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

#ifndef DETECTX_HXX
#define DETECTX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FeDetector 
 *
 * ************************************************************************ */




	/* This generic superclass for detectors is so the comm 
	system can tell what things are detectors. */

class FeDetector : public Heaper {

/* Attributes for class FeDetector */
	DEFERRED(FeDetector)
	EQ(FeDetector)
	NO_GC(FeDetector)

	/* automatic 0-argument constructor */
  public:
	FeDetector();

};  /* end class FeDetector */



/* ************************************************************************ *
 * 
 *                    Class   FeFillDetector 
 *
 * ************************************************************************ */




	/* Client defines subclasses and passes in an instance in 
	order to be notified of new results from Edition::rangeTranscl
	uders () or RangeElement::transcluders (). If passed to 
	Edition::addFillRangeDetector, this subclass merely passes in 
	the Editions in the range one by one, though they may appear 
	in the result in batches. */

class FeFillDetector : public FeDetector {

/* Attributes for class FeFillDetector */
	DEFERRED(FeFillDetector)
	ON_CLIENT(FeFillDetector)
	NO_GC(FeFillDetector)
  public: /* triggering */

	/* A single PlaceHolder has been filled to become another 
	kind of RangeElement */
	
	virtual CLIENT void filled (APTR(FeRangeElement) ARG(newIdentity)) DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	FeFillDetector();

};  /* end class FeFillDetector */



/* ************************************************************************ *
 * 
 *                    Class   FeFillRangeDetector 
 *
 * ************************************************************************ */




	/* Client defines a subclass and passes it in to 
	Edition::addFillRangeDetector, to be notified whenever 
	PlaceHolders become any other kind of RangeElement. */

class FeFillRangeDetector : public FeDetector {

/* Attributes for class FeFillRangeDetector */
	DEFERRED(FeFillRangeDetector)
	ON_CLIENT(FeFillRangeDetector)
	NO_GC(FeFillRangeDetector)
  public: /* triggering */

	/* Essential.  Some of the PlaceHolders in the Edition on 
	which I was placed have become something else. The Edition 
	has their new identies as its RangeElements, though the keys 
	may bear no relationship to those in the original Edition. */
	
	virtual CLIENT void rangeFilled (APTR(FeEdition) ARG(newIdentities)) DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	FeFillRangeDetector();

};  /* end class FeFillRangeDetector */



/* ************************************************************************ *
 * 
 *                    Class   FeRevisionDetector 
 *
 * ************************************************************************ */




	/* Client defines subclasses and passes in an instance in 
	order to be notified of revisions to a Work */

class FeRevisionDetector : public FeDetector {

/* Attributes for class FeRevisionDetector */
	DEFERRED(FeRevisionDetector)
	ON_CLIENT(FeRevisionDetector)
	NO_GC(FeRevisionDetector)
  public: /* triggering */

	/* Essential. The Work has been revised. Gives the Work, the 
	current Edition, the author ID who had it grabbed, the 
	sequence number of the revision to the Work, and the clock 
	time on the Server (note that the clock time is only as 
	reliable as the Server's operating system, which is usually 
	not very). */
	
	virtual CLIENT void revised (
			APTR(FeWork) ARG(work), 
			APTR(FeEdition) ARG(contents), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(time), 
			IntegerVar ARG(sequence))
	 DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	FeRevisionDetector();

};  /* end class FeRevisionDetector */



/* ************************************************************************ *
 * 
 *                    Class   FeStatusDetector 
 *
 * ************************************************************************ */




	/* Is notified of changes in the capability of a Work object. */

class FeStatusDetector : public FeDetector {

/* Attributes for class FeStatusDetector */
	DEFERRED(FeStatusDetector)
	ON_CLIENT(FeStatusDetector)
	NO_GC(FeStatusDetector)
  public: /* constants */

	/* The reason for the change was a change in the permissions 
	required to edit the Work */
	
	static INLINE CLIENT Int32 EDIT_PERMISSION_CHANGED ();
	
	/* The reason for the change was a change in authority of the 
	KeyMaster in the Work */
	
	static INLINE CLIENT Int32 KEYMASTER_CHANGED ();
	
	/* The reason for the change was a change in signature 
	authority of the CurrentAuthor */
	
	static INLINE CLIENT Int32 SIGNATURE_AUTHORITY ();
	
  public: /* triggering */

	/* Essential. The Work has been grabbed, or regrabbed. */
	
	virtual CLIENT void grabbed (
			APTR(FeWork) ARG(work), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(reason))
	 DEFERRED_SUBR;
	
	/* Essential. The revise capability of the Work has been lost. */
	
	virtual CLIENT void released (APTR(FeWork) ARG(work), IntegerVar ARG(reason)) DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	FeStatusDetector();

};  /* end class FeStatusDetector */



/* ************************************************************************ *
 * 
 *                    Class   FeWaitDetector 
 *
 * ************************************************************************ */




	/* Will get sent a single message, once, with no parameters, 
	when something happens. It can be passed in to 
	Server::waitForConsequences and Server::waitForWrite.BY.PROXY  */

class FeWaitDetector : public FeDetector {

/* Attributes for class FeWaitDetector */
	DEFERRED(FeWaitDetector)
	ON_CLIENT(FeWaitDetector)
	NO_GC(FeWaitDetector)
  public: /* triggering */

	/* Essential.  Whatever I was waiting for has happened */
	
	virtual CLIENT void done () DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	FeWaitDetector();

};  /* end class FeWaitDetector */


#ifdef USE_INLINE
#ifndef DETECTX_IXX
#include "detectx.ixx"
#endif /* DETECTX_IXX */


#endif /* USE_INLINE */


#endif /* DETECTX_HXX */


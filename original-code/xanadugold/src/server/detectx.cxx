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

#ifndef DETECTX_CXX
#define DETECTX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DETECTX_IXX
#include "detectx.ixx"
#endif /* DETECTX_IXX */


#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeDetector 
 *
 * ************************************************************************ */


/* This generic superclass for detectors is so the comm system can 
tell what things are detectors. */



	/* automatic 0-argument constructor */
FeDetector::FeDetector() {}



/* ************************************************************************ *
 * 
 *                    Class   FeFillDetector 
 *
 * ************************************************************************ */


/* Client defines subclasses and passes in an instance in order to be 
notified of new results from Edition::rangeTranscluders () or 
RangeElement::transcluders (). If passed to Edition::addFillRangeDetec
tor, this subclass merely passes in the Editions in the range one by 
one, though they may appear in the result in batches. */


/* triggering */

	/* automatic 0-argument constructor */
FeFillDetector::FeFillDetector() {}



/* ************************************************************************ *
 * 
 *                    Class   FeFillRangeDetector 
 *
 * ************************************************************************ */


/* Client defines a subclass and passes it in to Edition::addFillRange
Detector, to be notified whenever PlaceHolders become any other kind 
of RangeElement. */


/* triggering */

	/* automatic 0-argument constructor */
FeFillRangeDetector::FeFillRangeDetector() {}



/* ************************************************************************ *
 * 
 *                    Class   FeRevisionDetector 
 *
 * ************************************************************************ */


/* Client defines subclasses and passes in an instance in order to be 
notified of revisions to a Work */


/* triggering */

	/* automatic 0-argument constructor */
FeRevisionDetector::FeRevisionDetector() {}



/* ************************************************************************ *
 * 
 *                    Class   FeStatusDetector 
 *
 * ************************************************************************ */


/* constants */
/* Is notified of changes in the capability of a Work object. */


/* triggering */

	/* automatic 0-argument constructor */
FeStatusDetector::FeStatusDetector() {}



/* ************************************************************************ *
 * 
 *                    Class   FeWaitDetector 
 *
 * ************************************************************************ */


/* Will get sent a single message, once, with no parameters, when 
something happens. It can be passed in to Server::waitForConsequences 
and Server::waitForWrite.BY.PROXY  */


/* triggering */

	/* automatic 0-argument constructor */
FeWaitDetector::FeWaitDetector() {}

#ifndef DETECTX_SXX
#include "detectx.sxx"
#endif /* DETECTX_SXX */



#endif /* DETECTX_CXX */


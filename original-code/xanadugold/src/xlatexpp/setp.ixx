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

#ifndef SETP_IXX
#define SETP_IXX


#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */






/* ************************************************************************ *
 * 
 *                    Class EmptyImmuSet 
 *
 * ************************************************************************ */


/* rcvr pseudo constructor */
/* enumerating */
/* adding-removing */
/* accessing */
/* operations */
/* conversion */
/* unprotected for initer create */
/* creation */
/* protected: destruct */



/* ************************************************************************ *
 * 
 *                    Class HashSet 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* creation */
/* enumerating */
/* adding-removing */
/* conversion */
/* private: testing access */
/* private: enumerating */



/* ************************************************************************ *
 * 
 *                    Class   ActualHashSet 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* testing */
/* accessing */
/* creation */
/* protected: creation */
/* enumerating */
/* operations */
/* adding-removing */
/* private: housekeeping */


INLINE void ActualHashSet::aboutToWrite (){
	/* If my contents are shared, and I'm about to change them, 
	make a copy of them. */
	
	if (myHashEntries->shareCount() > 1) {
		this->actualAboutToWrite();
	}
}
/* private: hash resolution */
/* private: testing access */
/* hooks: */



/* ************************************************************************ *
 * 
 *                    Class HashSetStepper 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* protected: destruct */
/* protected: creation */
/* creation */
/* private: */



/* ************************************************************************ *
 * 
 *                    Class ImmuSetOnMu 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* enumerating */
/* operations */
/* adding-removing */
/* conversion */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class TinyImmuSet 
 *
 * ************************************************************************ */


/* create */
/* protected: creation */
/* enumerating */
/* adding-removing */
/* accessing */
/* operations */
/* conversion */


#endif /* SETP_IXX */


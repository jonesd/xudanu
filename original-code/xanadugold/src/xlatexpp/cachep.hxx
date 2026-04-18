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

#ifndef CACHEP_HXX
#define CACHEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */

#ifndef CACHEP_OXX
#include "cachep.oxx"
#endif /* CACHEP_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SuspendedHeaper 
 *
 * ************************************************************************ */




	/* Heapers cached to avoid memory allocation overhead are 
	kept as SuspendedHeapers to reduce GC overhead. */

class SuspendedHeaper : public Heaper {

/* Attributes for class SuspendedHeaper */
	CONCRETE(SuspendedHeaper)
	EQ(SuspendedHeaper)
	NOT_A_TYPE(SuspendedHeaper)
	NO_GC(SuspendedHeaper)
  public: /* creation */

	
	INLINE SuspendedHeaper ();
	

};  /* end class SuspendedHeaper */


#ifdef USE_INLINE
#ifndef CACHEP_IXX
#include "cachep.ixx"
#endif /* CACHEP_IXX */


#endif /* USE_INLINE */


#endif /* CACHEP_HXX */


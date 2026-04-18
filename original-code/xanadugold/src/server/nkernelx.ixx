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

#ifndef NKERNELX_IXX
#define NKERNELX_IXX


#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef CRYPTOX_HXX
#include "cryptox.hxx"
#endif /* CRYPTOX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#include "choosex.hxx"




/* ************************************************************************ *
 * 
 *                    Class FeBundle 
 *
 * ************************************************************************ */


/* protected: create */
/* accessing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   FeArrayBundle 
 *
 * ************************************************************************ */


/* create */
/* accessing */
/* private: create */



/* ************************************************************************ *
 * 
 *                    Class   FeElementBundle 
 *
 * ************************************************************************ */


/* create */
/* accessing */
/* private: create */



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolderBundle 
 *
 * ************************************************************************ */


/* create */
/* private: create */



/* ************************************************************************ *
 * 
 *                    Class FeKeyMaster 
 *
 * ************************************************************************ */


/* creation */
/* private: pseudo constructors */
/* assertions */
/* authority */
/* private: create */
/* server accessing */
/* private: */
/* printing */
/* obsolete: */



/* ************************************************************************ *
 * 
 *                    Class FeRangeElement 
 *
 * ************************************************************************ */


/* protected: */
/* creation */
/* accessing */
/* server accessing */
/* labelling */



/* ************************************************************************ *
 * 
 *                    Class   FeDataHolder 
 *
 * ************************************************************************ */


/* creation */
/* client accessing */
/* server accessing */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class   FeEdition 
 *
 * ************************************************************************ */


/* creation */
/* constants */


INLINE Int32 FeEdition::DIRECT_CONTAINERS_ONLY () CONST{
	/* For transcluders and works queries - only return objects 
	which directly contain the sources of the query (i.e. 
	excludes those which only contain it transitively through 
	intermediate Editions) */
	
	return 4;
}


INLINE Int32 FeEdition::FROM_OTHER_TRANSITIVE_CONTENTS () CONST{
	/* For sharedWith/sharedRegion/notSharedWith - look for 
	RangeElements contained transitively within the other Edition */
	
	return 8;
}


INLINE Int32 FeEdition::FROM_TRANSITIVE_CONTENTS () CONST{
	/* For transcluders, and works queries - consider 
	RangeElements contained transitively inside the Edition, as 
	well as just its immediate RangeElements */
	
	return 2;
}


INLINE Int32 FeEdition::IGNORE_ARRAY_ORDERING () CONST{
	/* Used for retrieve.  Allow the ArrayBundles in retrieve to 
	be organized according to a different ordering. */
	
	return 2;
}


INLINE Int32 FeEdition::IGNORE_TOTAL_ORDERING () CONST{
	/* Used for retrieve.  Allow non-contiguous chunks to be 
	grouped together on retrieve, and allow the bundles to be 
	presented in any order. */
	
	return 1;
}


INLINE Int32 FeEdition::LOCAL_PRESENT_ONLY () CONST{
	/* For transcluders and works queries - only guarantee to 
	return items which are currently known to this server */
	
	return 1;
}


INLINE Int32 FeEdition::OMIT_SHARED () CONST{
	/* For cost - omit the cost of shared material */
	
	return 1;
}


INLINE Int32 FeEdition::otherTransitiveContents () CONST{
	/* For sharedWith/sharedRegion/notSharedWith */
	
	return 2;
}


INLINE Int32 FeEdition::PRORATE_SHARED () CONST{
	/* For cost - prorate the cost of shared material among 
	Editions sharing it */
	
	return 2;
}


INLINE Int32 FeEdition::SEPARATE_OWNERS () CONST{
	/* For retrieve - ensure that each Bundle in a retrieve has a 
	single owner */
	
	return 32;
}


INLINE Int32 FeEdition::thisTransitiveContents () CONST{
	/* Used for version comparison. */
	
	return 1;
}


INLINE Int32 FeEdition::TO_TRANSITIVE_CONTENTS () CONST{
	/* For sharedRegion, sharedWith, notSharedWith queries - look 
	down towards transitively contained material */
	
	return 2;
}


INLINE Int32 FeEdition::TOTAL_SHARED () CONST{
	/* For cost - count the entire cost of shared material */
	
	return 3;
}
/* operations */
/* accessing */
/* comparing */
/* endorsing */
/* becoming */
/* labelling */
/* server accessing */
/* client implementation */
/* private: create */
/* printing */
/* obsolete: */
/* destruct */



/* ************************************************************************ *
 * 
 *                    Class   FeIDHolder 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* server accessing */
/* private: create */
/* printing */
/* destruct */



/* ************************************************************************ *
 * 
 *                    Class   FeLabel 
 *
 * ************************************************************************ */


/* creation */
/* server accessing */
/* client accessing */
/* destruct */
/* creation */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolder 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* server accessing */



/* ************************************************************************ *
 * 
 *                    Class   FeWork 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

BUILD_BOMB_BEGIN(ReleaseWork, WPTR(FeWork) ) {
	CAST(FeWork,CHARGE)->release();
} BUILD_BOMB_END(ReleaseWork);


/* creation */
/* grab status */
/* contents */
/* permissions */
/* endorsing */
/* sponsoring */
/* server grab status */
/* server contents */
/* server accessing */
/* protected: create */
/* destruct */
/* printing */
/* accessing */
/* history */
/* private: */



/* ************************************************************************ *
 * 
 *                    Class     FeClub 
 *
 * ************************************************************************ */


/* creation */
/* signing */
/* server */
/* managing storage */
/* private: create */



/* ************************************************************************ *
 * 
 *                    Class FeServer 
 *
 * ************************************************************************ */


/* server library */
/* create */
/* managing clubs */
/* comm requests */
/* global ids */
/* accessing */
/* miscellaneous */
/* create */
/* security */


#endif /* NKERNELX_IXX */


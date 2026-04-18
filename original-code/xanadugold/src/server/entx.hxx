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

#ifndef ENTX_HXX
#define ENTX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef ENTX_OXX
#include "entx.oxx"
#endif /* ENTX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef DAGWOODX_OXX
#include "dagwoodx.oxx"
#endif /* DAGWOODX_OXX */

#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef TRACEPX_OXX
#include "tracepx.oxx"
#endif /* TRACEPX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Ent 
 *
 * ************************************************************************ */



/* Initializers for Ent */
DESIGN_FLUID(TracePosition,CurrentTrace);	/* in Ent */
DESIGN_FLUID(BertCrum,CurrentBertCrum);	/* in Ent */




	/* NO CLASS COMMENT */

class Ent : public Abraham {

/* Attributes for class Ent */
	CONCRETE(Ent)
	SHEPHERD_PATRIARCH(Ent,Abraham)
	LOCKED(Ent)
	COPY(Ent,DiskCuisine)
	AUTO_GC(Ent)

/* Initializers for Ent */


  public: /* instance creation */

	
	static RPTR(Ent) make ();
	
  public: /* magic numbers */

	/* When we are making an orgl out of a table, we break the 
	table up into pieces which should be no larger than this, so 
	that they each fit into a snarf. */
	
	static INLINE IntegerVar tableSegmentMaxSize ();
	
  public: /* orgl creation */

	
	virtual RPTR(TracePosition) newTrace ();
	
  public: /* instance creation */

	
	Ent ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  //private:
	
	CHKPTR(DagWood) fulltrace;
};  /* end class Ent */


#ifdef USE_INLINE
#ifndef ENTX_IXX
#include "entx.ixx"
#endif /* ENTX_IXX */


#endif /* USE_INLINE */


#endif /* ENTX_HXX */


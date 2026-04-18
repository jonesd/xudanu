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

#ifndef CANOPYR_HXX
#define CANOPYR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef CANOPYR_OXX
#include "canopyr.oxx"
#endif /* CANOPYR_OXX */


#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */


#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PropChanger 
 *
 * ************************************************************************ */




	/* Used to propagate some prop(erty) change rootwards in some 
	canopy.  Each step propagates it one step parentwards, until 
	it gets to a local root or no further propagation in necessary. */

class PropChanger : public AgendaItem {

/* Attributes for class PropChanger */
	DEFERRED(PropChanger)
	SHEPHERD_PATRIARCH(PropChanger,AgendaItem)
	COPY(PropChanger,DiskCuisine)
	DEFERRED_LOCKED(PropChanger)
	AUTO_GC(PropChanger)
  public: /* creation */

	
	static RPTR(PropChanger) height (APTR(CanopyCrum) OR(NULL) ARG(crum));
	
	
	static RPTR(PropChanger) make (APTR(CanopyCrum) OR(NULL) ARG(crum));
	
  protected: /* protected: accessing */

	
	virtual NOLOCK RPTR(CanopyCrum) OR(NULL) fetchCrum ();
	
	/* Move our placeholding finger to a new crum, updating 
	refcounts accordingly */
	
	virtual void setCrum (APTR(CanopyCrum) OR(NULL) ARG(aCrum));
	
  public: /* accessing */

	/* propagate some prop(erty) change one step parentwards, 
	until it gets to a local root or no further propagation in 
	necessary. */
	
	virtual BooleanVar step () DEFERRED_FUNC;
	
  public: /* creation */

	
	PropChanger (APTR(CanopyCrum) OR(NULL) ARG(crum), TCSJ);
	
	/* Special constructor for becoming this class */
	
	PropChanger (APTR(CanopyCrum) OR(NULL) ARG(crum), UInt32 ARG(hash));
	
	
	virtual void dismantle ();
	
  private:
	CHKPTR(CanopyCrum) OR(NULL) myCrum;
};  /* end class PropChanger */



/* ************************************************************************ *
 * 
 *                    Class   ActualPropChanger 
 *
 * ************************************************************************ */




	/* Used to propagate some prop(erty) change rootwards in some 
	canopy.  Each step propagates it one step parentwards, until 
	it gets to a local root or no further propagation in necessary. */

class ActualPropChanger : public PropChanger {

/* Attributes for class ActualPropChanger */
	CONCRETE(ActualPropChanger)
	LOCKED(ActualPropChanger)
	COPY(ActualPropChanger,DiskCuisine)
	NO_GC(ActualPropChanger)
  public: /* creation */

	
	ActualPropChanger (APTR(CanopyCrum) ARG(crum), TCSJ);
	
	/* Special constructor for becoming this class */
	
	ActualPropChanger (
			APTR(CanopyCrum) OR(NULL) ARG(crum), 
			UInt32 ARG(hash), 
			APTR(FlockInfo) ARG(info))
	;
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	

	friend class PropChanger;
};  /* end class ActualPropChanger */



#endif /* CANOPYR_HXX */


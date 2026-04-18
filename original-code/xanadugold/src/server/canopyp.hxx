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

#ifndef CANOPYP_HXX
#define CANOPYP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef CANOPYP_OXX
#include "canopyp.oxx"
#endif /* CANOPYP_OXX */


#ifndef CANOPYR_HXX
#include "canopyr.hxx"
#endif /* CANOPYR_HXX */


#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef TABTOOLX_OXX
#include "tabtoolx.oxx"
#endif /* TABTOOLX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CanopyCache 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CanopyCache : public Heaper {

/* Attributes for class CanopyCache */
	CONCRETE(CanopyCache)
	AUTO_GC(CanopyCache)
  public: /* make */

	
	static RPTR(CanopyCache) make ();
	
  protected: /* protected: creation */

	
	CanopyCache ();
	
  public: /* operations */

	/* Clear the cache because the canopy has
		 changed.  This ought to destroy the cachedPath. 
		 This must be cleared after every episode!!! */
	
	virtual void clearCache ();
	
	/* Return the set of all crums from canopyCrum 
		(inclusive) to the top of canopyCrum's canopy. */
	
	virtual RPTR(MuSet) OF1(CanopyCrum) pathFor (APTR(CanopyCrum) ARG(canopyCrum));
	
	/* Return the crum at the top of canopyCrum's canopy. */
	
	virtual RPTR(CanopyCrum) rootFor (APTR(CanopyCrum) ARG(bertCrum));
	
	/* If the cache contains childCrum it must be made 
		to contain childCrum's new parent: parentCrum. 
		Also update CachedRoot. */
	
	virtual void updateCacheForParent (APTR(CanopyCrum) ARG(childCrum), APTR(CanopyCrum) ARG(parentCrum));
	
	/* If the cache contains canopyCrum, it must be updated 
		because canopyCrum has new parents. For now, just 
		invalidate the cache. */
	
	virtual void updateCacheFor (APTR(CanopyCrum) ARG(canopyCrum));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(CanopyCrum) myCachedCrum;
	CHKPTR(CanopyCrum) myCachedRoot;
	CHKPTR(MuSet) OF1(CanopyCrum) myCachedPath;
};  /* end class CanopyCache */



/* ************************************************************************ *
 * 
 *                    Class Heaper2UInt32Cache 
 *
 * ************************************************************************ */



/* Initializers for Heaper2UInt32Cache */




	/* Caches a mapping from Heapers (using isEqual / 
	hashForEqual) to UInt32s. Returns myEmptyValue if there is no 
	cached mapping. */

class Heaper2UInt32Cache : public Heaper {

/* Attributes for class Heaper2UInt32Cache */
	CONCRETE(Heaper2UInt32Cache)
	EQ(Heaper2UInt32Cache)
	AUTO_GC(Heaper2UInt32Cache)

/* Initializers for Heaper2UInt32Cache */
friend class INIT_TIME_NAME(Heaper2UInt32Cache,initTimeNonInherited);

  public: /* create */

	
	static RPTR(Heaper2UInt32Cache) make (Int32 ARG(count), UInt32 ARG(empty) = UInt32Zero);
	
  public: /* accessing */

	/* Cache a value for a key */
	
	virtual void cache (APTR(Heaper) ARG(key), UInt32 ARG(value));
	
	/* Return the cached value for the key, or my empty value if 
	there is none */
	
	virtual UInt32 fetch (APTR(Heaper) ARG(key));
	
	/* Return the cached value for the key, or BLAST if there is none */
	
	virtual UInt32 get (APTR(Heaper) ARG(key));
	
  public: /* create */

	
	Heaper2UInt32Cache (Int32 ARG(count), UInt32 ARG(empty));
	
  private:
	CHKPTR(PtrArray) myKeys;
	CHKPTR(UInt32Array) myValues;
	UInt32 myEmptyValue;
};  /* end class Heaper2UInt32Cache */



/* ************************************************************************ *
 * 
 *                    Class HeightChanger 
 *
 * ************************************************************************ */




	/* Used to propagate some prop(erty) change rootwards in some 
	canopy.  Each step propagates it one step parentwards, until 
	it gets to a local root or no further propagation in necessary. */

class HeightChanger : public PropChanger {

/* Attributes for class HeightChanger */
	CONCRETE(HeightChanger)
	LOCKED(HeightChanger)
	COPY(HeightChanger,DiskCuisine)
	AUTO_GC(HeightChanger)
  public: /* creation */

	
	static RPTR(HeightChanger) make (APTR(CanopyCrum) ARG(crum), APTR(PropChange) ARG(change));
	
  public: /* creation */

	
	HeightChanger (APTR(CanopyCrum) ARG(crum), TCSJ);
	
	/* Special constructor for becoming this class */
	
	HeightChanger (
			APTR(CanopyCrum) OR(NULL) ARG(crum), 
			UInt32 ARG(hash), 
			APTR(FlockInfo) ARG(info))
	;
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  private:
	CHKPTR(PropChange) myChange;
	friend class PropChanger;
};  /* end class HeightChanger */



#endif /* CANOPYP_HXX */


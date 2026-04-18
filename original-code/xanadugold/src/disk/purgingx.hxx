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

#ifndef PURGINGX_HXX
#define PURGINGX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PURGINGX_OXX
#include "purgingx.oxx"
#endif /* PURGINGX_OXX */


#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef PACKERX_OXX
#include "packerx.oxx"
#endif /* PACKERX_OXX */

#ifndef SHEPHX_OXX
#include "shephx.oxx"
#endif /* SHEPHX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class LiberalPurgeror 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class LiberalPurgeror : public RepairEngineer {

/* Attributes for class LiberalPurgeror */
	CONCRETE(LiberalPurgeror)
	AUTO_GC(LiberalPurgeror)
  public: /* create */

	
	static RPTR(LiberalPurgeror) make (APTR(SnarfPacker) ARG(packer));
	
  protected: /* protected: create */

	
	LiberalPurgeror (APTR(SnarfPacker) ARG(packer), TCSJ);
	
  public: /* accessing */

	
	virtual void setMustPurge ();
	
  public: /* invoking */

	
	virtual void repair ();
	
  private:
	BooleanVar myMustPurge;
	CHKPTR(SnarfPacker) myPacker;
};  /* end class LiberalPurgeror */



/* ************************************************************************ *
 * 
 *                    Class Purgeror 
 *
 * ************************************************************************ */



/* Initializers for Purgeror */




	/* We are about to garbage collect.  Every so often, purge 
	the objects that are clean so their flocks can be garbage collected. */

class Purgeror : public SanitationEngineer {

/* Attributes for class Purgeror */
	CONCRETE(Purgeror)
	AUTO_GC(Purgeror)

/* Initializers for Purgeror */


  public: /* creation */

	
	static RPTR(Purgeror) make (APTR(DiskManager) ARG(packer));
	
  public: /* setting */

	
	static void setPurgeRate (IntegerVar ARG(count));
	
  public: /* accessing */

	
	INLINE void clearPurgePending ();
	
	
	INLINE BooleanVar purgePending ();
	
  protected: /* protected: creation */

	
	Purgeror (APTR(DiskManager) ARG(packer), TCSJ);
	
  public: /* invoking */

	
	virtual void recycle (BooleanVar ARG(required));
	
  private:
	IntegerVar myCount;
	CHKPTR(DiskManager) myPacker;
	BooleanVar myPurgePending;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static IntegerVar PurgeRate;
};  /* end class Purgeror */


#ifdef USE_INLINE
#ifndef PURGINGX_IXX
#include "purgingx.ixx"
#endif /* PURGINGX_IXX */


#endif /* USE_INLINE */


#endif /* PURGINGX_HXX */


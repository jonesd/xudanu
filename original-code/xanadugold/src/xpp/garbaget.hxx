/* ===========================================================================
//
//	Copyright (c) 1992 by Xanadu Operating Company
//
// ===========================================================================
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
// ===========================================================================
//
//		garbaget.hxx
//
//      Garbage Collector test class.
//
// ========================================================================== */

#ifndef GARBAGET_HHX
#define GARBAGET_HXX
static char garbaget_hxx_id[] = "$Id: garbaget.hxx,v 2.4 1992/11/25 23:26:23 eric Exp $";

#include "tofux.hxx"

#include "garbaget.oxx"

class ConsCell : public Heaper {
	CONCRETE(ConsCell)
	AUTO_GC(ConsCell)
    public:
	INLINE RPTR(Heaper)	fetchCar();
	INLINE RPTR(ConsCell)	fetchCdr();
	INLINE void		setCar(APTR(Heaper));	// So we can tie knots
	INLINE void		setCdr(APTR(ConsCell));	// So we can tie knots

	INLINE ConsCell(
		  APTR(Heaper)		aCar
		, APTR(ConsCell)	aCdr
	);
    private:
	CHKPTR(Heaper)		myCar;
	CHKPTR(ConsCell)	myCdr;
};

ORDER_BOMB(gc,int);

#ifdef USE_INLINE
#include "garbaget.ixx"
#endif /* USE_INLINE */

#endif /* GARBAGET_HXX */

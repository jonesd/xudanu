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

#ifndef TABENTX_HXX
#define TABENTX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABENTX_OXX
#include "tabentx.oxx"
#endif /* TABENTX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class TableEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TableEntry : public Heaper {

/* Attributes for class TableEntry */
	DEFERRED(TableEntry)
	EQ(TableEntry)
	COPY(TableEntry,XppCuisine)
	AUTO_GC(TableEntry)
  public: /* creation */

	
	static INLINE RPTR(TableStepper) bucketStepper (APTR(SharedPtrArray) ARG(array));
	
	
	static RPTR(TableEntry) make (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	static RPTR(TableEntry) make (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
  public: /* accessing */

	
	virtual RPTR(TableEntry) copy () DEFERRED_FUNC;
	
	
	INLINE RPTR(TableEntry) OR(NULL) fetchNext ();
	
	
	virtual IntegerVar index ();
	
	/* Return true if my key matches key. */
	
	virtual BooleanVar match (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* Return true if my key matches the position associated with index. */
	
	virtual BooleanVar matchInt (IntegerVar ARG(index));
	
	/* Return true if my value matches value.  Note that this 
	*must* test EQ first in
		 case the value is no longer a heaper.  Otherwise we could 
	never remove a 
		 destructed object. */
	
	virtual BooleanVar matchValue (APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Position) position () DEFERRED_FUNC;
	
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	/* The default implementation. */
	
	virtual BooleanVar replaceValue (APTR(Heaper) ARG(newValue));
	
	/* Change my pointer to the rest of the chain in this bucket. */
	
	INLINE void setNext (APTR(TableEntry) OR(NULL) ARG(next));
	
	
	INLINE RPTR(Heaper) value ();
	
  protected: /* protected: creation */

	
	TableEntry (APTR(Heaper) ARG(value), TCSJ);
	
	
	TableEntry (APTR(TableEntry) ARG(next), APTR(Heaper) ARG(value));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* destroy */

	/* temporarily don't destroy. */
	
	virtual void destroy ();
	
  private:
	CHKPTR(TableEntry) myNext;
	CHKPTR(Heaper) myValue;
};  /* end class TableEntry */


#ifdef USE_INLINE
#ifndef TABENTX_IXX
#include "tabentx.ixx"
#endif /* TABENTX_IXX */


#endif /* USE_INLINE */


#endif /* TABENTX_HXX */


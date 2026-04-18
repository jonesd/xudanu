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

#ifndef HASHTABX_HXX
#define HASHTABX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HASHTABX_OXX
#include "hashtabx.oxx"
#endif /* HASHTABX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */


#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TABTOOLX_OXX
#include "tabtoolx.oxx"
#endif /* TABTOOLX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class HashTable 
 *
 * ************************************************************************ */



/* Initializers for HashTable */




	/* NO CLASS COMMENT */

class HashTable : public MuTable {

/* Attributes for class HashTable */
	DEFERRED(HashTable)
	NO_GC(HashTable)

/* Initializers for HashTable */
friend class INIT_TIME_NAME(HashTable,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static INLINE RPTR(HashTable) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(HashTable) make (APTR(CoordinateSpace) ARG(cs), IntegerVar ARG(size));
	
  public: /* accessing */

	/* Associate value with key, whether or not
		 there is a previous association. */
	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value)) DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
	/* Remove a key->value association from the table.
		 Do not blast (or do anything else) if the key is not in my 
	current domain. */
	
	virtual BooleanVar wipe (APTR(Position) ARG(anIdx)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) theOne () DEFERRED_FUNC;
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
  protected: /* protected: create */

	
	HashTable ();
	

};  /* end class HashTable */


#ifdef USE_INLINE
#ifndef HASHTABX_IXX
#include "hashtabx.ixx"
#endif /* HASHTABX_IXX */


#endif /* USE_INLINE */


#endif /* HASHTABX_HXX */


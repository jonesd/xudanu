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

#ifndef PURGINGP_HXX
#define PURGINGP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PURGINGX_HXX
#include "purgingx.hxx"
#endif /* PURGINGX_HXX */

#ifndef PURGINGP_OXX
#include "purgingp.oxx"
#endif /* PURGINGP_OXX */


#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DiskPurgeRate 
 *
 * ************************************************************************ */




	/* Set the number of GCs between purges of the packer. */

class DiskPurgeRate : public Thunk {

/* Attributes for class DiskPurgeRate */
	CONCRETE(DiskPurgeRate)
	COPY(DiskPurgeRate,BootCuisine)
	NOT_A_TYPE(DiskPurgeRate)
	NO_GC(DiskPurgeRate)
  public: /* operate */

	/* Set the number of GCs between packer purges. */
	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	DiskPurgeRate();
  private:
	IntegerVar myCount;
};  /* end class DiskPurgeRate */



#endif /* PURGINGP_HXX */


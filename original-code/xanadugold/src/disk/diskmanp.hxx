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

#ifndef DISKMANP_HXX
#define DISKMANP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef DISKMANP_OXX
#include "diskmanp.oxx"
#endif /* DISKMANP_OXX */


#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Cattleman 
 *
 * ************************************************************************ */




	/* Remove flocks from the snarfpacker */

class Cattleman : public XnExecutor {

/* Attributes for class Cattleman */
	CONCRETE(Cattleman)
	AUTO_GC(Cattleman)
  public: /* create */

	
	static RPTR(Cattleman) make (APTR(DiskManager) ARG(dm));
	
  public: /* create */

	
	Cattleman (APTR(DiskManager) ARG(dm), TCSJ);
	
  public: /* invoking */

	/* [Drops add: token] smalltalkOnly. */
	
	virtual void execute (Int32 ARG(token));
	
  private:
	CHKPTR(DiskManager) myPasture;
};  /* end class Cattleman */



/* ************************************************************************ *
 * 
 *                    Class DiskConnection 
 *
 * ************************************************************************ */




	/* Keep an object from the disk.  For the moment, put the 
	disk connection in a global variable and export a function so 
	that anyone can destroy it.... */

class DiskConnection : public Connection {

/* Attributes for class DiskConnection */
	CONCRETE(DiskConnection)
	NOT_A_TYPE(DiskConnection)
	AUTO_GC(DiskConnection)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Heaper) bootHeaper ();
	
  public: /* creation */

	
	DiskConnection (APTR(Category) ARG(cat), APTR(Heaper) ARG(heaper));
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(Category) myCategory;
	CHKPTR(Heaper) myHeaper;
};  /* end class DiskConnection */



/* ************************************************************************ *
 * 
 *                    Class DiskManagerEmulsion 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DiskManagerEmulsion : public Emulsion {

/* Attributes for class DiskManagerEmulsion */
  public: /* creation */

	
	static DiskManagerEmulsion * make ();
	
  public: /* accessing */

	
	virtual void * fetchNewRawSpace (size_t ARG(size));
	
	
	virtual void * fetchOldRawSpace ();
	
  public: /* creation */

	
	DiskManagerEmulsion ();
	

};  /* end class DiskManagerEmulsion */



/* ************************************************************************ *
 * 
 *                    Class FromDiskPlan 
 *
 * ************************************************************************ */




	/* Instances of this represent the plan for getting a 
	particular kind of object from an urdi on a particular file.  
	They open the urdi, create a packer, retrieve the Turtle from 
	the packer, and pull out the boot object. */

class FromDiskPlan : public BootPlan {

/* Attributes for class FromDiskPlan */
	CONCRETE(FromDiskPlan)
	COPY(FromDiskPlan,BootCuisine)
	NOT_A_TYPE(FromDiskPlan)
	AUTO_GC(FromDiskPlan)
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	virtual RPTR(Connection) connection ();
	
  public: /* creation */

	
	FromDiskPlan (APTR(Category) ARG(cat), char * ARG(filename));
	
  private:
	CHKPTR(Category) myCategory;
	char * myFilename;
};  /* end class FromDiskPlan */



#endif /* DISKMANP_HXX */


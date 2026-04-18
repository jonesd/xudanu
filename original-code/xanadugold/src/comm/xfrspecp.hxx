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

#ifndef XFRSPECP_HXX
#define XFRSPECP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */

#ifndef XFRSPECP_OXX
#include "xfrspecp.oxx"
#endif /* XFRSPECP_OXX */


#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef NEGOTI8X_OXX
#include "negoti8x.oxx"
#endif /* NEGOTI8X_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BogusXcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for BogusXcvrMaker */
/* Declaration inherited from XcvrMaker */





	/* NO CLASS COMMENT */

class BogusXcvrMaker : public XcvrMaker {

/* Attributes for class BogusXcvrMaker */
	CONCRETE(BogusXcvrMaker)
	NOT_A_TYPE(BogusXcvrMaker)
	NO_GC(BogusXcvrMaker)

/* Initializers for BogusXcvrMaker */
/* Declaration inherited from XcvrMaker */

friend class INIT_TIME_NAME(BogusXcvrMaker,initTimeInherited);

  public: /* testing */

	
	virtual char * id ();
	
  public: /* xcvr creation */

	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(readStream));
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(writeStream));
	

	/* automatic 0-argument constructor */
  public:
	BogusXcvrMaker();

};  /* end class BogusXcvrMaker */



/* ************************************************************************ *
 * 
 *                    Class CategoryRecipe 
 *
 * ************************************************************************ */



/* Initializers for CategoryRecipe */




	/* NO CLASS COMMENT */

class CategoryRecipe : public CopyRecipe {

/* Attributes for class CategoryRecipe */
	CONCRETE(CategoryRecipe)
	NO_GC(CategoryRecipe)

/* Initializers for CategoryRecipe */


  public: /* accessing */

	
	virtual RPTR(Heaper) parse (APTR(SpecialistRcvr) ARG(rcvr));
	
	
	virtual void parseInto (APTR(Rcvr) ARG(rcvr), void * ARG(memory));
	
  public: /* creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	CategoryRecipe (APTR(Category) ARG(cat), Recipe* * ARG(cuisine));
	

};  /* end class CategoryRecipe */



/* ************************************************************************ *
 * 
 *                    Class CommIbid 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CommIbid : public Heaper {

/* Attributes for class CommIbid */
	CONCRETE(CommIbid)
	COPY(CommIbid,XppCuisine)
	NO_GC(CommIbid)
  public: /* creation */

	
	static RPTR(CommIbid) make (IntegerVar ARG(number));
	
  public: /* creation */

	
	CommIbid (IntegerVar ARG(number), TCSJ);
	
  public: /* accessing */

	
	virtual IntegerVar number ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	IntegerVar myNumber;
};  /* end class CommIbid */



/* ************************************************************************ *
 * 
 *                    Class TransferGeneralist 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TransferGeneralist : public TransferSpecialist {

/* Attributes for class TransferGeneralist */
	CONCRETE(TransferGeneralist)
	NOT_A_TYPE(TransferGeneralist)
	NO_GC(TransferGeneralist)
  public: /* creation */

	
	static RPTR(TransferSpecialist) make (APTR(Cookbook) ARG(aBook));
	
  public: /* create */

	
	TransferGeneralist (APTR(Cookbook) ARG(aBook), TCSJ);
	
  public: /* communication */

	/* No special cases.  Punt to the rcvr. */
	
	virtual RPTR(Heaper) receiveHeaperFrom (APTR(Category) ARG(cat), APTR(SpecialistRcvr) ARG(rcvr));
	
	/* No special cases.  Punt to the rcvr. */
	
	virtual void receiveHeaperIntoFrom (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(memory), 
			APTR(SpecialistRcvr) ARG(rcvr))
	;
	

	friend class TransferSpecialist;
};  /* end class TransferGeneralist */



#endif /* XFRSPECP_HXX */


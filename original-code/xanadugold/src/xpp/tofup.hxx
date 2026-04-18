/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */
//
//	Added UnconstructedHeaper class for the object to be during the
//	crack between the allocation of its storage and the evaluation of
//	the arguments to its constructor, in case one of those arguments
//	BLAST()s, causing the heaper constructor bomb to call destroy().
//	(Constructing it as this subclass of Heaper also initializes things
//	sufficiently to keep the garbage collector happy if it gets started
//	during that crack.)
//		- michael Jul 21 1992
//

#ifndef TOFUP_HXX
#define TOFUP_HXX

#include "tofux.hxx"

VERSION_ID(tofup_hxx,
	   "$Id: tofup.hxx,v 2.9 1992/12/19 00:53:30 ravi Exp $")

class UnconstructedHeaper : public Heaper {
	CONCRETE(UnconstructedHeaper)
	NO_GC(UnconstructedHeaper)
	NOT_A_TYPE(UnconstructedHeaper)

    public:

		UnconstructedHeaper () {
		}

		void * operator new (size_t) {
			BLAST(INVALID_METHOD);
			return NULL;
		}

		void * operator new (size_t /*s*/, void * storage) {
			return storage;
		}
};


class CategoryList ROOTCLASS {
  public:
    Category * first ();
    CategoryList * fetchRest ();
    CategoryList (Category * first, CategoryList * rest = NULL);
    void printOn (ostream& oo);
  private:
    Category * myFirst;
    CategoryList * myRest;
};

extern CategoryList * 
categoryList (Category * first, CategoryList * rest = NULL);

void preorderCategories ();
void registerAllBecomes ();
void registerAllPackages ();
void calculateObjectSizes ();
void calculateTotalSizes ();

#endif /* TOFUP_HXX */

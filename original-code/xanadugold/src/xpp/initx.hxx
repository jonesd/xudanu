/*
      (C) Copyright 1990 by Xanadu Operating Company, All Rights Reserved.

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

#ifndef INITX_HXX
#define INITX_HXX

#include "tofux.hxx"

VERSION_ID(initx_hxx,
	   "$Id: initx.hxx,v 2.6 1993/03/24 02:48:15 eric Exp $")


/*
	Initers orchestrate the execution of initialization code that
	cannot run prior to the initialization of memory allocation, fluid
	variables, the category structures, or in any other case where the
	code must run after static construction time.  Each module's
	initialization is specified by

		BEGIN_INIT_TIME(cName,iName) {
			code
		} END_INIT_TIME(cName,iName);

	This macro creates a subclass of Initer, along with the
	declaration of an instance of this subClass
	which is associated with the Category cat_cName at static 
	construction time.  In an
	initialization you can say REQUIRES(otherCName) for each other
	initialization that must occur prior to the current one.
	"iName" is only used to keep multiple initers for the same 
	cName unique.
	Initers for the same cName which appear in the same file
	will be executed in the order in which they appear in that file.

	Main() should then instanciate an Initializer object as in:

		Initializer mainInit;

	This will also cause EXIT_TIME (see below) to do its stuff correctly

	Author: Eric C. Hill
	
	Initers given a Category orientation.
	Initializers separated from Initers & Terminators.
		--- MarkM 8/10/90
*/

extern int mainAC ();

extern char ** mainAV ();


/* for testing purposes */

extern void dumpInitState (Category * cat);


typedef enum { NOT_DONE, IN_PROGRESS, ALREADY_DONE } IniterState;

class Initializer ROOTCLASS {
  public:
    Initializer (int ac = 0, char ** av = NULL);
    ~Initializer ();

    static BooleanVar inStaticDestruction ();  // test for single instance destructors

  private:

    static BooleanVar InStaticDestruction;
};

class Initer ROOTCLASS {
  public:

    /* Have to allow this since this file can't have the DEFERRED macro */
    PERMIT(1,"DEFERRED function in wrong section")
    virtual void initialize () DEFERRED_SUBR;

    LEAF Initer * next ();

    PERMIT(1,"reference")
    LEAF void printOn (ostream& oo);
    LEAF IniterState initState();

  protected:
    PERMIT(1,"single argument constructor")
    Initer (Category * cat);
    LEAF void requires (Category * cat);
    LEAF void initState (IniterState iState);
  
#ifdef macintosh
    friend void force_initializers ();
#endif /* macintosh */

  private:
    friend void dumpInitState (Category * cat);
    LEAF void next (Initer * newNext);
    LEAF BooleanVar matches (Category * cat);

    IniterState myInitState;
    Initer * myNext;
    Category * myCat;
};

#define INIT_TIME_NAME(cName,iName) CAT3(cName,iName,_Initer)

#define BEGIN_INIT_TIME(cName,iName)					\
	class CAT3(cName,iName,_Initer) : public Initer {		\
	  public:							\
	    CAT3(cName,iName,_Initer) () 				\
	      : Initer (CAT(cat_,cName)) {}				\
	    void initialize () {					\
		  this->initState (IN_PROGRESS);

#define END_INIT_TIME(cName,iName)					\
		  this->initState (ALREADY_DONE);			\
	    }								\
	};								\
	static CAT3(cName,iName,_Initer) CAT3(theIniter_,cName,iName);

#define REQUIRES(cName)  this->requires(CAT(cat_,cName))



/*
	Terminators are to be executed on exit from main(), but prior to the
	destruction of static data.  For each termination function, you specify:

		BEGIN_EXIT_TIME(cName,eName) {
			code
		} END_EXIT_TIME(cName,eName);

	When main() exits, the destructor for mainExit causes all of the
	terminate functions to execute.

	To do eventually: During dynamic initialization time, keep track of the
	order in which REQUIRES between Categories worked out, and then do
	the Terminators in reverse order also according to the associated 
	Categories, and in reverse file order among those in the same file for
	the same Category.  Right now we just do Terminators in the same file in 
	reverse order of their appearance. 
*/

class Terminator ROOTCLASS {
  public:

    /* Have to allow this since this file can't have the DEFERRED macro */
    REQUIRE(1,"DEFERRED function in wrong section")
    virtual void terminate () DEFERRED_SUBR;
    PERMIT(0,"DEFERRED function in wrong section")

    LEAF Terminator * next ();

  protected:
    REQUIRE(1,"single argument constructor")
    Terminator (Category * cat);
    PERMIT(0,"single argument constructor")

  private:
    Category * myCat;
    Terminator * myNext;
};


#define BEGIN_EXIT_TIME(cName,eName)				\
	class CAT3(cName,eName,_Arnie) : public Terminator {	\
          public:						\
	    CAT3(cName,eName,_Arnie) () 			\
	      : Terminator (CAT(cat_,cName)) {}			\
	    void terminate () {

#define END_EXIT_TIME(cName,eName)				\
		}						\
	};							\
	static CAT3(cName,eName,_Arnie) CAT3(theArnie_,cName,eName);


#endif /* INITX_HXX */

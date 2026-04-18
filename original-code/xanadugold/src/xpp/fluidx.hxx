/*=========================================================================
  |
  |   Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
  |
  =========================================================================
  |
  | The information contained herein is confidential, proprietary to Xanadu
  | Operating Company, and considered a trade secret as defined in section
  | 499C of the penal code of the State of California.
  |
  | Use of this information by anyone other than authorized employees of
  | Xanadu is granted only under a written nondisclosure agreement,
  | expressly prescribing the scope and manner of such use.
  |
  | The above copyright notice is not to be construed as evidence of
  | publication or the intent to publish.
  |
  =========================================================================
  |
  |         fluidx.hxx - Fluid Variables
  |
  ========================================================================= */

//
//	Merged BUILD_PRIM_FLUID from ravi.  Zortech does not support
//	constructor style initialization of primitive types.
//		- ech Sep 7 1990
//
//	add destruction of class types for fluid space deletion.
//		- ech Sep 23 1991
//
//	Added ech's hack for doing the moral equivalent of moving the
//	build to the .ixx file without actually doing so, and without
//	hacking the smalltalk->c++ translator.
//		- michael Mar 11 1992
//
//	Remove FLUID_VAR lvalue and replaced with fluidFetch/Get/Set
//		- ech May 18 1992
//
//	Removed fluidGet from PRIM_FLUIDs
//	Normal fluids are now only for pointing at Heapers; the fluid variables
//	provide GC roots, and they interface through '*' pointers to avoid
//	needing crutch.  To this end, PRIM_BOMB_BUILD and COMMON_PRIM_BUILD
//	were added.
//		- ech Dec 8 1992

#ifndef FLUID_HXX
#define FLUID_HXX

#ifndef STUBBLE
//#include "new.h"
#endif /* STUBBLE */
#ifndef XCOMPATX_HXX
#include "xcompatx.hxx"
#endif /* XCOMPATX_HXX */

VERSION_ID(fluidx_hxx,
	   "$Id: fluidx.hxx,v 2.15 1993/03/16 22:29:53 eric Exp $")

#ifndef BOMBX_HXX
#include "bombx.hxx"
#endif /* BOMBX_HXX */
#ifndef XUNEWX_HXX
#include "xunewx.hxx"
#endif /* XUNEWX_HXX */

#include "fluidx.oxx"

/* ======================================================================== */
//
//	Switching for the pseudo-.ixx hack.
//
/* ======================================================================== */

#ifdef	USE_INLINE

#define	CXX_BOMB_BUILD(varName,Type)
#define	HXX_BOMB_BUILD(varName,Type)		BOMB_BUILD(varName,Type)
#define	CXX_PRIM_BOMB_BUILD(varName,Type)
#define	HXX_PRIM_BOMB_BUILD(varName,Type)	PRIM_BOMB_BUILD(varName,Type)

#else	/* USE_INLINE */

#define	CXX_BOMB_BUILD(varName,Type)		BOMB_BUILD(varName,Type)
#define	HXX_BOMB_BUILD(varName,Type)
#define	CXX_PRIM_BOMB_BUILD(varName,Type)	PRIM_BOMB_BUILD(varName,Type)
#define	HXX_PRIM_BOMB_BUILD(varName,Type)

#endif	/* USE_INLINE */

/********************************************************************

  		   Fluid Initialization Time

Fluid initialization time is when the space for fluids storage gets
allocated, and when all the fluids which live in that space get
initialized.  There is a global fluids space, and a per-session
fluids space.  (The global fluids space can be considered to be
the space for the "main-session".)  Fluid initialization time
must happen after static initialization time, but may happen
before, during, or after dynamic initialization time.  The global 
space gets initialized on first use of a fluid, so dynamic initialers
can safely use fluids, but fluid initializers can only safely assume
static initialization.  Fluid initialization for each session happens
as part of the act of creating the session.

********************************************************************/

/*=======================================================================
  |
  |  class FluidVarDescription  -- the superclass of all fluid variable 
  |			  descriptions. Only for use by the macros below
  |
  =======================================================================*/

class FluidVarDescription ROOTCLASS {

  public:

    virtual void init () = 0 /* DEFERRED_FUNC */;

    virtual void destructIt () = 0 /* DEFERRED_FUNC */;

    /* LEAF */ FluidVarDescription * fetchNext ();

    /* LEAF */ unsigned nextOffset ();
      /* offset + size() + alignment stuff */

    INLINE Emulsion * emulsion ();

  protected:
    virtual unsigned size () = 0 /* DEFERRED_FUNC */;
    INLINE void * space ();
    FluidVarDescription (Emulsion * emulsion);

  private:
    unsigned myOffset;
    FluidVarDescription * myNext;
    Emulsion * myEmulsion;
};


/*=======================================================================
  |
  |  DESIGN_FLUID(Type,varName) -- Once per header file, declare that the 
  |                          fluid variable varName of Type will be used.
  |
  =======================================================================*/

#define DESIGN_FLUID(Type,varName)				\
    class CAT(Fluid_,varName) : public FluidVarDescription {	\
      public:							\
	/* LEAF */ Type * fluidFetch ();			\
	/* LEAF */ Type * fluidGet ();				\
	/* LEAF */ void fluidSet (Type*);			\
	/* LEAF */ unsigned size ();				\
	/* LEAF */ void init ();				\
	/* LEAF */ void destructIt ();				\
	CAT(Fluid_,varName) ();					\
    };								\
								\
    extern CAT(Fluid_,varName) varName;				\
								\
    ORDER_BOMB(varName,Type*);					\
								\
    HXX_BOMB_BUILD(varName,Type)


/*=======================================================================
  |
  |  DESIGN_PRIM_FLUID(Type,varName) -- Once per header file, declare that the 
  |                          fluid variable varName of Type will be used.
  |
  =======================================================================*/
#define DESIGN_PRIM_FLUID(Type,varName)				\
    class CAT(Fluid_,varName) : public FluidVarDescription {	\
      public:							\
	/* LEAF */ Type fluidFetch ();				\
	/* LEAF */ void fluidSet (Type);			\
	/* LEAF */ unsigned size ();				\
	/* LEAF */ void init ();				\
	/* LEAF */ void destructIt ();				\
	CAT(Fluid_,varName) ();					\
    };								\
								\
    extern CAT(Fluid_,varName) varName;				\
								\
    ORDER_BOMB(varName,Type);					\
								\
    HXX_PRIM_BOMB_BUILD(varName,Type)

/*=======================================================================
  |
  |  DEFINE_FLUID(Type,varName,emulsion) -- DEFINE_FLUID is to DESIGN_FLUID
  |  				as DEFINE_CLASS is to CLASS
  |	Invokes 0-parameter constructor to initialize the variable's
  |      storage.  Initialization happens at the time the fluid space
  |      is created--Fluid initialization time.  
  |  DEFINE_PRIM_FLUID is just like DEFINE_FLUID except for use on non-class
  |	types.  It exists because cfront 2.0 doesn't support calling
  |	destructors on primitive types (in violation of the Annotated
  |	Reference Manual, I think -- MarkM).
  |
  =======================================================================*/

#define DEFINE_FLUID(Type,varName,emulsion)			\
    void CAT(Fluid_,varName)::init ()				\
    {								\
	new (this->space()) CAT(GP2_,Type) ();			\
    }								\
								\
    COMMON_BUILD(Type,varName,emulsion)
#define DEFINE_PRIM_FLUID(Type,varName,emulsion)		\
    void CAT(Fluid_,varName)::init ()				\
    {								\
    }								\
								\
    COMMON_PRIM_BUILD(Type,varName,emulsion)

/*=======================================================================
  |
  |  BUILD_FLUID(Type,varName,initExpr,emulsion)
  |					-- BUILD_FLUID is like DEFINE_FLUID
  |	except that the storage is initialized by using the object's
  |	1-parameter constructor passing (initExpr) as the one argument.
  |	(initExpr) is also evaluated at fluid initialization time.
  |	Given the constraints of fluid initialization time, one should
  |	typically initialize fluids to simple constants (like IntegerVar0 
  |	or NULL).
  |  BUILD_PRIM_FLUID is just like BUILD_FLUID except for use on non-class
  |	types.  It exists because Zortech C++ doesn't support calling
  |	constructors on primitive types (in violation of the Annotated
  |	Reference Manual).
  |
  =======================================================================*/

#define BUILD_FLUID(Type,varName,initExpr,emulsion)		\
    void CAT(Fluid_,varName)::init ()				\
    {								\
	new (this->space()) CAT(GP2_,Type) ((initExpr));	\
    }								\
								\
    COMMON_BUILD(Type,varName,emulsion)

#define BUILD_PRIM_FLUID(Type,varName,initExpr,emulsion)	\
    void CAT(Fluid_,varName)::init ()				\
    {								\
	* ((Type*) this->space()) = (initExpr);			\
    }								\
    COMMON_PRIM_BUILD(Type,varName,emulsion)

#define COMMON_BUILD(Type,varName,emulsion)			\
    void CAT(Fluid_,varName)::destructIt ()			\
    {								\
    	((CAT(GP2_,Type)*) this->space())->    			\
	     CAT(GP2_,Type)::~CAT(GP2_,Type)();			\
    }								\
    Type * CAT(Fluid_,varName)::fluidFetch ()			\
    {								\
	return *((CAT(GP2_,Type)*) this->space());		\
    }								\
								\
    Type * CAT(Fluid_,varName)::fluidGet ()			\
    {								\
	Type * result = * ((CAT(GP2_,Type)*) this->space());	\
	if (result == NULL) {					\
		BLAST(NULL_FLUID);				\
	}							\
	return result;						\
    }								\
								\
    void CAT(Fluid_,varName)::fluidSet (Type * value)		\
    {								\
	* ((CAT(GP2_,Type)*) this->space()) = value;		\
    }								\
								\
    unsigned CAT(Fluid_,varName)::size ()			\
    {								\
	return sizeof (CAT(GP2_,Type));				\
    }								\
								\
    CAT(Fluid_,varName)::CAT(Fluid_,varName) ()			\
      : FluidVarDescription (emulsion)				\
    {}								\
    CXX_BOMB_BUILD(varName,Type)				\
								\
    CAT(Fluid_,varName) varName;
#define COMMON_PRIM_BUILD(Type,varName,emulsion)		\
    void CAT(Fluid_,varName)::destructIt ()			\
    {								\
    }								\
    Type CAT(Fluid_,varName)::fluidFetch ()			\
    {								\
	return *((Type*) this->space());			\
    }								\
								\
    void CAT(Fluid_,varName)::fluidSet (Type value)		\
    {								\
	* ((Type*) this->space()) = value;			\
    }								\
								\
    unsigned CAT(Fluid_,varName)::size ()			\
    {								\
	return sizeof (Type);					\
    }								\
								\
    CAT(Fluid_,varName)::CAT(Fluid_,varName) ()			\
      : FluidVarDescription (emulsion)				\
    {}								\
								\
    CXX_PRIM_BOMB_BUILD(varName,Type)				\
    CAT(Fluid_,varName) varName;
#define BOMB_BUILD(varName,Type)				\
	BUILD_BOMB_BEGIN(varName,Type*) {			\
		varName.fluidSet(CHARGE);			\
	} BUILD_BOMB_END(varName)
#define PRIM_BOMB_BUILD(varName,Type)				\
	BUILD_BOMB_BEGIN(varName,Type) {			\
		varName.fluidSet(CHARGE);			\
	} BUILD_BOMB_END(varName)
/*=======================================================================
  |
  |  FLUID_BIND(varName,initExpr) -- start new dynamic scope of fluid variable
  |                                    varName with initial value initExpr.
  |
  =======================================================================*/

#define FLUID_BIND(varName,initExpr) 				\
	  PLANT_BOMB(varName,varName); 				\
	  ARM_BOMB(varName,varName.fluidFetch()); 		\
	  varName.fluidSet(initExpr);


/*=======================================================================
  |
  |	An Emulsion represents a group of fluid variable declarations
  |	There should be exactly one static instance of a concrete
  |	Emulsion for each group of fluid variable declarations.
  |	The Emulsion's response to the rawSpace messages defines when
  |	the Emulsion switches the values of those variables.
  |	For example, we may have a single global Emulsion, a per session
  |	emulsion, a per thread emulsion, and a per backend emulsion.
  |	Each fluid variable declaration must be associated with exactly
  |	one Emulsion instance.
  |
  |	Note that rawSpace switching may not happen in such a way that
  |	the rawSpace in effect when a fluid value is saved by a FLUID_BIND
  |	is not the same as that in effect when the FLUID_BIND restores
  |	this value.  There are probably some other constraints on
  |	coordinating with stacking behavior.  If these rules are violated,
  |	havok will result (and therefore we will need to state the rules
  |	more clearly).
  |
  =======================================================================*/

class Emulsion ROOTCLASS {

  public:

    Emulsion ();

    char * fluidsSpace ();

    /* Assure that all class objects in the fluid space get destructed.
       This is vital to maintain the integrity of the StrongPtrVar list
       as transient session emulsions are recovered. */

    /* LEAF */ void destructAll ();

  protected:

    /* Allocate a new raw space for the current fluid scope (e.g. the 
       current session).  Probably best to avoid allocating with
       operator new.  It itself uses fluids, and so may hit an
       infinite regress.  fcalloc should be fine. */

    virtual void * fetchNewRawSpace (size_t size) = 0 /* DEFERRED_FUNC */;

    /* If the current fluid scope (e.g. session) has never had "newRawSpace" 
       called on it, then this must return NULL.  In that case, class Emulsion
       will call "fetchNewRawSpace" and initialize the fluids in the space.  
       Afterwards, "fetchOldRawSpace" must return that same space whenever we
       are in the same fluid scope.  It is by this behavior that subclasses
       of Emulsion define what is meant by "the same fluid scope" */

    virtual void * fetchOldRawSpace () = 0 /* DEFERRED_FUNC */;

  private:

    /* LEAF */ char * getNewFluidsSpace ();

    friend class FluidVarDescription;
    FluidVarDescription * addToEmulsion (FluidVarDescription * fvd);

    FluidVarDescription * myFluidsList;
};


extern Emulsion * globalEmulsion ();

#ifdef USE_INLINE
#include "fluidx.ixx"
#endif /* USE_INLINE */

#endif /* FLUID_HXX */

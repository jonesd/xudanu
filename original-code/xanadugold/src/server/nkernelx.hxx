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

#ifndef NKERNELX_HXX
#define NKERNELX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE2X_OXX
#include "brange2x.oxx"
#endif /* BRANGE2X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef CRYPTOX_OXX
#include "cryptox.oxx"
#endif /* CRYPTOX_OXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NADMINX_OXX
#include "nadminx.oxx"
#endif /* NADMINX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */

#ifndef SCHUNKX_OXX
#include "schunkx.oxx"
#endif /* SCHUNKX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */
#define NOACK void



/* ************************************************************************ *
 * 
 *                    Class FeBundle 
 *
 * ************************************************************************ */




	/* Describes a single chunk of information from an Edition */

class FeBundle : public Heaper {

/* Attributes for class FeBundle */
	DEFERRED(FeBundle)
	ON_CLIENT(FeBundle)
	AUTO_GC(FeBundle)
  protected: /* protected: create */

	
	FeBundle (APTR(XnRegion) ARG(region), TCSJ);
	
  public: /* accessing */

	/* Essential. The positions in the Edition for which I 
	describe the contents */
	
	virtual CLIENT RPTR(XnRegion) region ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(XnRegion) myRegion;
};  /* end class FeBundle */



/* ************************************************************************ *
 * 
 *                    Class   FeArrayBundle 
 *
 * ************************************************************************ */




	/* Describes a chunk of information represented as an array. 
	The number of elements in the array are the same as my 
	region, and they are ordered according to OrderSpec given to 
	the retrieve operation which produced me. */

class FeArrayBundle : public FeBundle {

/* Attributes for class FeArrayBundle */
	CONCRETE(FeArrayBundle)
	ON_CLIENT(FeArrayBundle)
	AUTO_GC(FeArrayBundle)
  public: /* create */

	
	static RPTR(FeArrayBundle) make (
			APTR(XnRegion) ARG(region), 
			APTR(PrimArray) ARG(array), 
			APTR(OrderSpec) ARG(order))
	;
	
  public: /* accessing */

	/* Essential. The array of elements in this bundle */
	
	virtual CLIENT RPTR(PrimArray) array ();
	
	/* Essential. The order relating the elements in the array to 
	the positions in the region. */
	
	virtual CLIENT RPTR(OrderSpec) ordering ();
	
  private: /* private: create */

	
	FeArrayBundle (
			APTR(XnRegion) ARG(region), 
			APTR(PrimArray) ARG(array), 
			APTR(OrderSpec) ARG(order))
	;
	
  private:
	CHKPTR(PrimArray) myArray;
	CHKPTR(OrderSpec) myOrder;
};  /* end class FeArrayBundle */



/* ************************************************************************ *
 * 
 *                    Class   FeElementBundle 
 *
 * ************************************************************************ */




	/* Describes a region of an Edition in which all indices in 
	my region hold the same RangeElement. */

class FeElementBundle : public FeBundle {

/* Attributes for class FeElementBundle */
	CONCRETE(FeElementBundle)
	ON_CLIENT(FeElementBundle)
	AUTO_GC(FeElementBundle)
  public: /* create */

	
	static RPTR(FeElementBundle) make (APTR(XnRegion) ARG(region), APTR(FeRangeElement) ARG(element));
	
  public: /* accessing */

	/* Essential. The RangeElement which is at every position in 
	my region */
	
	virtual CLIENT RPTR(FeRangeElement) element ();
	
  private: /* private: create */

	
	FeElementBundle (APTR(XnRegion) ARG(region), APTR(FeRangeElement) ARG(element));
	
  private:
	CHKPTR(FeRangeElement) myElement;
};  /* end class FeElementBundle */



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolderBundle 
 *
 * ************************************************************************ */




	/* Describes a region of an Edition in which all indices in 
	my region have a distinct PlaceHolder. */

class FePlaceHolderBundle : public FeBundle {

/* Attributes for class FePlaceHolderBundle */
	CONCRETE(FePlaceHolderBundle)
	ON_CLIENT(FePlaceHolderBundle)
	NO_GC(FePlaceHolderBundle)
  public: /* create */

	
	static RPTR(FePlaceHolderBundle) make (APTR(XnRegion) ARG(region));
	
  private: /* private: create */

	
	FePlaceHolderBundle (APTR(XnRegion) ARG(region), TCSJ);
	

};  /* end class FePlaceHolderBundle */



/* ************************************************************************ *
 * 
 *                    Class FeKeyMaster 
 *
 * ************************************************************************ */




	/* A KeyMaster provides the authority, or "holds the keys", 
	for a client`s activities on the BackEnd. A client can have 
	any number of different KeyMasters, each with different 
	authority. FeServer_login (if successful) gives you back a 
	KeyMaster with the authority of a single Club (along with all 
	the Clubs of which it is a member, directly or indirectly). 
	This will give you appropriate authority to do anything 
	permitted to that Club. You can incorporate the authority of 
	other KeyMasters into it, so that it will additionally enable 
	you to do anything the other KeyMasters would have enabled. */

class FeKeyMaster : public Heaper {

/* Attributes for class FeKeyMaster */
	CONCRETE(FeKeyMaster)
	ON_CLIENT(FeKeyMaster)
	EQ(FeKeyMaster)
	AUTO_GC(FeKeyMaster)
  public: /* creation */

	/* Make a KeyMaster initially logged in to the given Club */
	
	static RPTR(FeKeyMaster) make (APTR(ID) ARG(clubID));
	
	/* Make a KeyMaster initially logged in to the given Clubs */
	
	static RPTR(FeKeyMaster) makeAll (APTR(IDRegion) ARG(clubIDs));
	
	/* Make a KeyMaster logged in to the Universal Public Club. */
	
	static RPTR(FeKeyMaster) makePublic ();
	
  private: /* private: pseudo constructors */

	
	static RPTR(FeKeyMaster) make (APTR(IDRegion) ARG(loginAuthority), APTR(IDRegion) ARG(actualAuthority));
	
  public: /* assertions */

	/* Blast if the CurrentKeyMaster doesn't have Admin authority. */
	
	static void assertAdminAuthority ();
	
	/* Blast if the CurrentKeyMaster doesn't have signature 
	authority for the CurrentAuthor. */
	
	static void assertSignatureAuthority ();
	
	/* If there is a currentSponsor, then the CurrentKeyMaster 
	must have authority for it. */
	
	static void assertSponsorship ();
	
  public: /* authority */

	/* Essential.  The Clubs whose authority is actually being 
	held right now. This may change asynchronously when you or 
	others change the membership lists of clubs.  It is my 
	loginAuthority plus all clubs that list any of these clubs as 
	members, transitively. */
	
	virtual CLIENT RPTR(IDRegion) actualAuthority ();
	
	/* Essential.  A different KeyMaster with the same login and 
	actual authority as this one. */
	
	virtual CLIENT RPTR(FeKeyMaster) copy ();
	
	/* Whether this KeyMaster is currently holding the authority 
	of the given Club. Equivalent to
			this->actualAuthority ()->hasMember (clubID) */
	
	virtual CLIENT BooleanVar hasAuthority (APTR(ID) ARG(clubID));
	
	/* Essential.  Add the other KeyMaster's login and actual 
	authorities to my own respective authorities. */
	
	virtual CLIENT void incorporate (APTR(FeKeyMaster) ARG(other));
	
	/* Essential.  The Clubs whose authority was obtained 
	directly, by logging in to them. They are the ones from which 
	all other authority is derived. */
	
	virtual CLIENT RPTR(IDRegion) loginAuthority ();
	
	/* Essential.  Remove the listed IDs from the set of Clubs 
	whose login authority I exercise.  All authority derived from 
	them that cannot be derived from the remaining login 
	authority will also disappear.  Listed Clubs for which I do 
	not hold login authority will be silently ignored. */
	
	virtual CLIENT void removeLogins (APTR(IDRegion) ARG(oldLogins));
	
  private: /* private: create */

	
	FeKeyMaster (APTR(IDRegion) ARG(loginAuthority), APTR(IDRegion) ARG(actualAuthority));
	
  public: /* server accessing */

	/* Whether this KeyMaster has signature authority for the given Club */
	
	virtual BooleanVar hasSignatureAuthority (APTR(ID) ARG(club));
	
	/* Notify the Work whenever my authority changes */
	
	virtual void registerWork (APTR(FeWork) ARG(work));
	
	/* Notify the Work whenever my authority changes */
	
	virtual void unregisterWork (APTR(FeWork) ARG(work));
	
	/* Recompute the actual authority of this KeyMaster based on 
	the set of login Clubs */
	
	virtual void updateAuthority ();
	
  private: /* private: */

	/* Notify all my dependents of a change in authority */
	
	virtual void authorityChanged ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* obsolete: */

	/* A filter for things which can be read by this KeyMaster */
	
	virtual RPTR(Filter) permissionsFilter ();
	
  private:
	CHKPTR(IDRegion) myLoginAuthority;
	CHKPTR(IDRegion) myActualAuthority;
	CHKPTR(PrimSet) OF1(FeWork) OR(NULL) myRegisteredWorks;
};  /* end class FeKeyMaster */



/* ************************************************************************ *
 * 
 *                    Class FeRangeElement 
 *
 * ************************************************************************ */




	/* The kinds of objects which can be in the range of Editions. */

class FeRangeElement : public Heaper {

/* Attributes for class FeRangeElement */
	DEFERRED(FeRangeElement)
	ON_CLIENT(FeRangeElement)
	EQ(FeRangeElement)
	NO_GC(FeRangeElement)
  protected: /* protected: */

	/* Check whether the endorsements are valid and authorized.
		 Blast appropriately if not. */
	
	static void validateEndorsement (APTR(CrossRegion) ARG(endorsements), APTR(FeKeyMaster) ARG(km));
	
	/* Check whether the signatures are valid and authorized.
		 Blast appropriately if not. */
	
	static void validateSignature (APTR(IDRegion) ARG(clubs), APTR(FeKeyMaster) ARG(km));
	
  public: /* creation */

	/* Make a single PlaceHolder. */
	
	static CLIENT RPTR(FeRangeElement) placeHolder ();
	
  public: /* accessing */

	/* Essential.  When this PlaceHolder becomes any other kind 
	of RangeElement, then the Detector will be triggered with the 
	new RangeElement. If this is already not a PlaceHolder, then 
	the Detector is triggered immediately with this RangeElement.
		See FillRangeDetector::filled (RangeElement * newIdentity). */
	
	virtual void addFillDetector (APTR(FeFillDetector) ARG(detector));
	
	/* Essential.  An object reflecting the current identity of 
	this object, in case it is a PlaceHolder that has become 
	something else since it was received from the Server. */
	
	virtual CLIENT RPTR(FeRangeElement) again () DEFERRED_FUNC;
	
	/* Essential.  Whether the identity of this object could be 
	changed to the other.
		Does not check whether the CurrentKeyMaster has authority to do it.
		The restrictions on this operation depend on which subclass 
	this is, but in general (except for PlaceHolders) an object 
	can only become another of the same type with the same content. */
	
	virtual CLIENT BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Essential.  Return a FillDetector that will be triggered 
	when this RangeElement becomes something other than a 
	PlaceHolder, or immeditely if this RangeElement is not 
	currently a PlaceHolder.
		See FillRangeDetector::filled (RangeElement * newIdentity). */
	
	virtual CLIENT RPTR(FeFillDetector) fillDetector ();
	
	/* Essential.  Return whether two objects have the same 
	identity on the Server.  Note that this can change over time, 
	if makeIdentical is used.  However, for a given pair of 
	FeRangeElements, it can only change from not being the same 
	to being the same while you are holding onto them. */
	
	virtual CLIENT BooleanVar isIdentical (APTR(FeRangeElement) ARG(other));
	
	/* Essential.  Change the identity of this object to the 
	other. BLAST if unsuccessful.
		Requires authority of the current owner; if the operation is 
	successful, the owner will appear to change to that of the 
	other object.
		Also requires enough permission on newIdentity to determine, 
	by comparing content, whether the operation would succeed.
		The restrictions on this operation depend on which subclass 
	this is, but in general (except for PlaceHolders) an object 
	can only become another of the same type with the same content. */
	
	virtual CLIENT void makeIdentical (APTR(FeRangeElement) ARG(newIdentity)) DEFERRED_SUBR;
	
	/* Essential.  The Club which owns this RangeElement, and has 
	the authority to make it become something else, and to 
	transfer ownership to someone else. */
	
	virtual CLIENT RPTR(ID) owner ();
	
	/* Essential.  Remove a Detector which had been added to this 
	RangeElement. You should remove every Detector you add, 
	although they will go away automatically when a client 
	session terminates. */
	
	virtual void removeFillDetector (APTR(FeFillDetector) ARG(detector));
	
	/* Essential.  Change the owner; must have the authority of 
	the current owner. */
	
	virtual CLIENT void setOwner (APTR(ID) ARG(clubID));
	
	/* All Editions which the CurrentKeyMaster can see, which 
	transclude this RangeElement.
		If a directFilter is given, then the visibleEndorsements on 
	a Edition must match the filter.
		If an indirectFilter is given, then a resulting Edition must 
	be contained in some readable Edition whose 
	visibleEndorsements match the filter.
		If the directContainersOnly flag is set, then a resulting 
	Edition must contain this directly as a RangeElement; 
	otherwise, indirect containment through Editions is allowed.
		If the localPresentOnly flag is set, then only Editions 
	currently known to this Server are guaranteed to end up in 
	the result; otherwise, Editions which come to satisfy the 
	conditions in the future, and those on other Servers, may 
	also be found.
		Equivalent to
			FeServer::current ()->newEditionWith (<any position>, this)
				->rangeTranscluders (NULL, directFilter, indirectFilter, 
	flags, otherTranscluders). */
	
	virtual CLIENT RPTR(FeEdition) transcluders (
			APTR(Filter) ARG(directFilter) = NULL, 
			APTR(Filter) ARG(indirectFilter) = NULL, 
			Int32 ARG(flags) = Int32Zero, 
			APTR(FeEdition) ARG(otherTranscluders) = NULL)
	;
	
	/* Essential.  Works which contain this RangeElement and can 
	be read by the CurrentKeyMaster. Returns an IDSpace Edition 
	full of PlaceHolders, which will be filled with Works as 
	results come in.
		If a filter is given, then only Works whose endorsements 
	pass the Filter are returned.
		If localPresentOnly flag is set, then only Works currently 
	known to this Server are returned; otherwise, as new Works 
	come to be known to the Server, they are filled into the 
	resulting Edition.
		If directContainersOnly is set, and this is an Edition, then 
	only Works which are directly on this Edition are returned 
	(and not Works which are on Editions which have this one as 
	sub-Editions).
		{ <k,l,w> | w's contains self, w passes filter} */
	
	virtual CLIENT RPTR(FeEdition) works (
			APTR(Filter) ARG(filter) = NULL, 
			Int32 ARG(flags) = Int32Zero, 
			APTR(FeEdition) ARG(otherTranscluders) = NULL)
	;
	
  public: /* server accessing */

	/* Return an object that wraps up any run-time state that 
	might be needed inside the Be system.  Right now that means labels. */
	
	virtual RPTR(BeCarrier) carrier ();
	
	/* If this has a reified Be object, then return it, else NULL */
	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe () DEFERRED_FUNC;
	
	/* An individual BeRangeElement for this identity. If the 
	object is virtualized, then de-virtualizes it. */
	
	virtual RPTR(BeRangeElement) getOrMakeBe () DEFERRED_FUNC;
	
  public: /* labelling */

	/* Essential. Return the label attached to this 
	FeRangeElement. (An FeRangeElement holds a BeRangeElement and 
	a label.)  All FeRangeElements have a label attached to them 
	when they are created (in the various Server::newRangeElement 
	operations).  Derived Editions have the same the label as the 
	Edition they were derived from (e.g. the receiver of copy, 
	combine, replace, transformedBy, etc.)  Labels may be 
	available only on Editions in 1.0.  (While this is in force, 
	label() will blast if sent to other kinds of FeEditions.) */
	
	virtual CLIENT RPTR(FeLabel) label ();
	
	/* Essential. Return a new FeRangeElement with the same 
	identity and contents (i.e. holding the same BeRangeElement), 
	but with a different label.  (Get new labels from 
	FeServer::newLabel()) */
	
	virtual CLIENT RPTR(FeRangeElement) relabelled (APTR(FeLabel) ARG(label));
	

	/* automatic 0-argument constructor */
  public:
	FeRangeElement();

};  /* end class FeRangeElement */



/* ************************************************************************ *
 * 
 *                    Class   FeDataHolder 
 *
 * ************************************************************************ */




	/* The kind of FeRangeElement that represents a piece of data 
	in the Server, along with its identity. */

class FeDataHolder : public FeRangeElement {

/* Attributes for class FeDataHolder */
	DEFERRED(FeDataHolder)
	ON_CLIENT(FeDataHolder)
	NO_GC(FeDataHolder)
  public: /* creation */

	
	static RPTR(FeDataHolder) fake (
			APTR(PrimValue) ARG(value), 
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition))
	;
	
	/* Make a single DataHolder with the given value */
	
	static CLIENT RPTR(FeDataHolder) make (APTR(PrimValue) ARG(value));
	
	
	static RPTR(FeDataHolder) on (APTR(BeDataHolder) ARG(be));
	
  public: /* client accessing */

	
	virtual RPTR(FeRangeElement) again () DEFERRED_FUNC;
	
	/* Check that it is data with the same value,
			and check permissions,
			and forward the operation after coercing the newIdentity to 
	a persistent RangeElement. */
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Allow consolidation of data in 1st product. */
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Essential.  The actual data value */
	
	virtual CLIENT RPTR(PrimValue) value () DEFERRED_FUNC;
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe () DEFERRED_FUNC;
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	FeDataHolder();

};  /* end class FeDataHolder */



/* ************************************************************************ *
 * 
 *                    Class   FeEdition 
 *
 * ************************************************************************ */




	/* The kind of FeRangeElement that consists of an immutable 
	organization of RangeElements, indexed by Positions in some 
	CoordinateSpace.
	 R1 prohibits cyclic containment.
	
	Set notation is used in the comments documenting some of the 
	methods of this class.  In each case the cleartext 
	explanation stands alone, and the set notation is a separate, 
	more formal, expression of the actions of the method, in 
	terms of key(position)/label/value triples ("<k,l,v>"). */

class FeEdition : public FeRangeElement {

/* Attributes for class FeEdition */
	CONCRETE(FeEdition)
	ON_CLIENT(FeEdition)
	AUTO_GC(FeEdition)
  public: /* creation */

	/* An empty Edition, with the given CoordinateSpace but no contents. */
	
	static CLIENT RPTR(FeEdition) empty (APTR(CoordinateSpace) ARG(keySpace));
	
	/* Essential.  A singleton Edition mapping from a Region of 
	keys (potentially infinite) to a single value. */
	
	static CLIENT RPTR(FeEdition) fromAll (APTR(XnRegion) ARG(keys), APTR(FeRangeElement) ARG(value));
	
	/* Essential.  Creates an Edition mapping from a Region of 
	keys to the values in an array. The ordering specifies the 
	correspondance between  the keys and the indices in the array.
		If a Region is given, then it must have the same count as 
	the array.  If no Region is given, then it is taken to be the 
	IntegerRegion from 0  to the size of the array. If no 
	OrderSpec is given, then it is the default ascending full 
	ordering for that CoordinateSpace. */
	
	static CLIENT RPTR(FeEdition) fromArray (
			APTR(PrimArray) OF1(FeRangeElement) ARG(values), 
			APTR(XnRegion) ARG(keys) = NULL, 
			APTR(OrderSpec) ARG(ordering) = NULL)
	;
	
	/* A singleton Edition mapping from a single key to a single value. */
	
	static CLIENT RPTR(FeEdition) fromOne (APTR(Position) ARG(key), APTR(FeRangeElement) ARG(value));
	
	
	static RPTR(FeEdition) on (APTR(BeEdition) ARG(be));
	
	
	static RPTR(FeEdition) on (APTR(BeEdition) ARG(be), APTR(FeLabel) ARG(label));
	
	/* Essential.  Create a new Edition mapping from each key in 
	the Region to a new, unique PlaceHolder. The owner will have 
	the capability to make them become something else. */
	
	static CLIENT RPTR(FeEdition) placeHolders (APTR(XnRegion) ARG(keys));
	
  public: /* constants */

	/* For transcluders and works queries - only return objects 
	which directly contain the sources of the query (i.e. 
	excludes those which only contain it transitively through 
	intermediate Editions) */
	
	static CLIENT INLINE Int32 DIRECT_CONTAINERS_ONLY () CONST;
	
	/* For sharedWith/sharedRegion/notSharedWith - look for 
	RangeElements contained transitively within the other Edition */
	
	static CLIENT INLINE Int32 FROM_OTHER_TRANSITIVE_CONTENTS () CONST;
	
	/* For transcluders, and works queries - consider 
	RangeElements contained transitively inside the Edition, as 
	well as just its immediate RangeElements */
	
	static CLIENT INLINE Int32 FROM_TRANSITIVE_CONTENTS () CONST;
	
	/* Used for retrieve.  Allow the ArrayBundles in retrieve to 
	be organized according to a different ordering. */
	
	static CLIENT INLINE Int32 IGNORE_ARRAY_ORDERING () CONST;
	
	/* Used for retrieve.  Allow non-contiguous chunks to be 
	grouped together on retrieve, and allow the bundles to be 
	presented in any order. */
	
	static CLIENT INLINE Int32 IGNORE_TOTAL_ORDERING () CONST;
	
	/* For transcluders and works queries - only guarantee to 
	return items which are currently known to this server */
	
	static CLIENT INLINE Int32 LOCAL_PRESENT_ONLY () CONST;
	
	/* For cost - omit the cost of shared material */
	
	static CLIENT INLINE Int32 OMIT_SHARED () CONST;
	
	/* For sharedWith/sharedRegion/notSharedWith */
	
	static CLIENT INLINE Int32 otherTransitiveContents () CONST;
	
	/* For cost - prorate the cost of shared material among 
	Editions sharing it */
	
	static CLIENT INLINE Int32 PRORATE_SHARED () CONST;
	
	/* For retrieve - ensure that each Bundle in a retrieve has a 
	single owner */
	
	static CLIENT INLINE Int32 SEPARATE_OWNERS () CONST;
	
	/* Used for version comparison. */
	
	static CLIENT INLINE Int32 thisTransitiveContents () CONST;
	
	/* For sharedRegion, sharedWith, notSharedWith queries - look 
	down towards transitively contained material */
	
	static CLIENT INLINE Int32 TO_TRANSITIVE_CONTENTS () CONST;
	
	/* For cost - count the entire cost of shared material */
	
	static CLIENT INLINE Int32 TOTAL_SHARED () CONST;
	
  public: /* operations */

	/* Essential.  Return a new FeEdition containing the contents 
	of boththe receiver and the argument Editions, and with the 
	label of the receiving edition; where they share positions, 
	they must have the same RangeElement.  Currently the two may 
	not share positions.  It is unclear whether to elevate this 
	from an implementation restriction to a specification.  The 
	advantage of so specifying is that 'combine' becomes timing 
	independent, i.e. a failing combine could otherwise succeed 
	after the differing range elements were unified (by 
	FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnt
	o and FeEdition::transformedBy.
		
		{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
		requires:
			currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
			eventually maybe: { k | v1 not same as v2 
										and <k,la,v1> in self and <k,lb,v2> in other } is empty */
	
	virtual CLIENT RPTR(FeEdition) combine (APTR(FeEdition) ARG(other));
	
	/* Return a new FeEdition which is the subset of this Edition 
	with the domain restricted to the given set of positions  The 
	new edition has the same label as this edition.
		
		{ <k,l,v> | k in positions and <k,l,v> in self } */
	
	virtual CLIENT RPTR(FeEdition) copy (APTR(XnRegion) ARG(positions));
	
	/* Return a new FeEdition with the label of the current 
	Edition and the contents of both Editions; where they share 
	positions, use the contents and labels of the other Edition. 
	Equivalent to
			this->copy (other->domain ()->complement ())->combine (other).
			
		{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and 
	<k,l2,v2> not in other } */
	
	virtual CLIENT RPTR(FeEdition) replace (APTR(FeEdition) ARG(other));
	
	/* Essential.  Return a new FeEdition containing the contents 
	and label of the current Edition with the positions 
	transformed according to the given Mapping. Where the Mapping 
	takes several positions in the domain to a single position in 
	the range, this Edition must have the same RangeElement and 
	label at all the domain positions.  Currently the mapping 
	must be 'onto', i.e., no more that one domain position may 
	map onto any given range position.  It is unclear whether to 
	elevate this from an implementation restriction to a 
	specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
		
		{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
		requires:
			Currently: not exists k1a, k1b : k1a != k1b and <k1a,k2> in 
	mapping and <k1b,k2> in mapping.
			Maybe eventually: for all v1, v2 : <k,l1,v1> in result and 
	<k,l2,v2> in result, v1 is same as v2 */
	
	virtual CLIENT RPTR(FeEdition) transformedBy (APTR(Mapping) ARG(mapping));
	
	/* Return a new FeEditionwith the same contents and label as 
	this Edition, except for the addition or substitution of a 
	RangeElement at a specified position.
		(The difference between with() and rebind() is exactly that 
	rebind() preserves the old label at position, while with() 
	installs the label attached to the value argument.)
		Equivalent to:
			this->replace (FeServer::current ()->makeEditionWith 
	(position, value)) */
	
	virtual CLIENT RPTR(FeEdition) with (APTR(Position) ARG(position), APTR(FeRangeElement) ARG(value));
	
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified set of positions, where 
	the old values and labels, if there are any, are superceded 
	by the value argument.
		Equivalent to:
			this->replace (FeServer::current ()->makeEditionWithAll 
	(positions, value)) */
	
	virtual CLIENT RPTR(FeEdition) withAll (APTR(XnRegion) ARG(positions), APTR(FeRangeElement) ARG(value));
	
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified position, where the old 
	value and label, if there is one, is removed.
		Equivalent to:
			this->copy (position->asRegion ()->complement ()) */
	
	virtual CLIENT RPTR(FeEdition) without (APTR(Position) ARG(position));
	
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified set of positions, where 
	the old values and labels, if there are any, are removed.
		Equivalent to
			this->copy (positions->complement ()) */
	
	virtual CLIENT RPTR(FeEdition) withoutAll (APTR(XnRegion) ARG(positions));
	
  public: /* accessing */

	/* Return the space in which the positions of this Edition 
	are positions. Equivalent to
			this->domain ()->coordinateSpace () */
	
	virtual CLIENT RPTR(CoordinateSpace) coordinateSpace ();
	
	/* Essential. Retiurn how much space this Edition is taking 
	up on the disk, in bytes (but the precision may exceed the 
	accuracy; it's simply a well-known unit). The method 
	determines how material shared with other Editions is 
	treated: if omitShared, it is not counted at all; if 
	prorateShared, then it is divided evenly among the Editions 
	sharing it; if totalShared, its entire cost is counted. This 
	figure is only approximate, and may vary with time.
		(No permissions are required to obtain this informiation, 
	even though it exposes sharing by Editions you can't read to 
	traffic analysis.) */
	
	virtual CLIENT IntegerVar cost (Int32 ARG(method));
	
	/* Return the number of positions in this Edition. Blasts if 
	infinite. Equivalent to
			this->domain ()->count () */
	
	virtual CLIENT IntegerVar count ();
	
	/* Essential.  Return the region consisting of all the 
	positions in this Edition. May be infinite, or empty.
		
		{ k | <k,l,v> in self } */
	
	virtual CLIENT RPTR(XnRegion) domain ();
	
	/* Return the value at the given position, or blast if there 
	is no such position (i.e. if ! this->domain ()->hasMember (position)).
		
		v : <position,l,v> in self
		requires: <position,l,v> in self */
	
	virtual CLIENT RPTR(FeRangeElement) get (APTR(Position) ARG(position));
	
	/* Return whether the given position is in the Edition. Equivalent to
			this->domain ()->hasMember (position) */
	
	virtual CLIENT BooleanVar hasPosition (APTR(Position) ARG(position));
	
	/* Return whether there are any positions in this Edition. 
	Equivalent to
			this->domain ()->isEmpty () */
	
	virtual CLIENT BooleanVar isEmpty ();
	
	/* Return whether there are a finite number of positions in 
	this Edition. Equivalent to
			this->domain ()->isFinite () */
	
	virtual CLIENT BooleanVar isFinite ();
	
	/* Essential.  This is the fundamental retrieval operation.  
	Return a stepper of bundles.  Each bundle is an association 
	between a region in the domain and the range elements 
	associated with that region.  Where the region is associated 
	with data, for instance, the bundle contains a PrimArray of 
	the data elements.
		If a region is given, only that subset of the Edition's 
	contents will be returned.  If it is not given, the entire 
	content of the Edition will be returned.
		if the ignoreTotalOrdering flag is set, then the operation 
	can group non-contiguous regions, and can supply the bundles 
	in any order.
		if the ignoreArrayOrdering flag is set, then ArrayBundles 
	returned by the operation can be ordered differently from the 
	supplied order.
		If an OrderSpec is not supplied, then the ordering will be 
	the default order for the coordinate space, if one exists, 
	and if none exists the returned data will be completely 
	unordered and the Ordering flags will be ignored. */
	
	virtual CLIENT RPTR(Stepper) OF1(Bundle) retrieve (
			APTR(XnRegion) ARG(region) = NULL, 
			APTR(OrderSpec) ARG(order) = NULL, 
			Int32 ARG(flags) = Int32Zero)
	;
	
	/* Return a stepper for iterating over the positions and 
	RangeElements of this Edition. If a region is specified, then 
	it only iterates over the domain positions which are in the 
	given region. If no ordering is specified, then the default 
	ascending full ordering of the CoordinateSpace is used, or a 
	random order chosen if there is no default. */
	
	virtual CLIENT RPTR(TableStepper) OF1(FeRangeElement) stepper (APTR(XnRegion) ARG(region) = NULL, APTR(OrderSpec) ARG(ordering) = NULL);
	
	/* If this Edition has a single position, then return the 
	RangeElement at that position; if not, blasts. Equivalent to
			this->get (this->domain ()->theOne ()) */
	
	virtual CLIENT RPTR(FeRangeElement) theOne ();
	
  public: /* comparing */

	/* Whether the two Editions have the same domains, and each 
	RangeElement isIdentical to the corresponding RangeElement in 
	the other Edition. */
	
	virtual CLIENT BooleanVar isRangeIdentical (APTR(FeEdition) ARG(other), APTR(XnRegion) ARG(region) = NULL);
	
	/* Return a mapping such that for each range element that 
	appears in both editions, the mapping maps each of its 
	appearances in the argument edition to some appearance in 
	this one.  (Some of the appearances in this edition may be 
	unmapped or mapped to multiple appearances in the argument 
	edition.)  Like 'mapSharedTo' except that the resulting 
	mapping is 'onto'.  This means that each range position of 
	the resulting mapping inverse maps to at most one domain 
	position.  Such a mapping is suitable as an argument to 
	'transformedBy', and represents the minimal transformation 
	needed to make the shared part of 'other' from self.  Note 
	that there is no unique answer.
		
		result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in 
	other and v1 is same as v2
								and not exists k11 : k11 != k1 and <k11,k2> in result }
		
	Note that this is useful for optimization of FeBe 
	communication and Frontend display updating. */
	
	virtual CLIENT RPTR(Mapping) mapSharedOnto (APTR(FeEdition) ARG(other));
	
	/* Essential.  Return a Mapping from each of the positions in 
	this Edition to all of the positions in the other Edition 
	which have the same RangeElement.
		
		{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and 
	v1 is same as v2 } */
	
	virtual CLIENT RPTR(Mapping) mapSharedTo (APTR(FeEdition) ARG(other));
	
	/* Return a new FeEdition containing exactly the subset of 
	this Edition whose RangeElements are not in the other Edition.
		Equivalent to:
			this->copy (this->sharedRegion (other)->complement ()).
			
		{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other 
	and v1 is same as v2 }
		
	Note that this is useful for optimization of FeBe 
	communication and Frontend display updating. */
	
	virtual CLIENT RPTR(FeEdition) notSharedWith (APTR(FeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
	/* Return the region consisting of all the positions in this 
	Edition at which the given RangeElement can be found.
		Equivalent to:
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)).
			
		{ k | <k,l,v> in self and v is same as value } */
	
	virtual CLIENT RPTR(XnRegion) positionsOf (APTR(FeRangeElement) ARG(value));
	
	/* Essential.  Return a new FeEdition containing all Editions 
	which can be read with the authority of the CurrentKeyMaster, 
	and which transclude RangeElements in this Edition. 
	Immediately returns with an Edition full of PlaceHolders, 
	which will be filled in as results appear; the lookup 
	proceeds asynchronously.
		The Server will attempt to avoid placing duplicate copies in 
	the result, but it may still happen.
		If a Region is given, then the request only considers the 
	subset at those positions (i.e. equivalent to this->copy 
	(positions)->rangeTransclusions (...))
		If a directFilter is given, then the endorsements on the 
	resulting Editions, unioned with the endorsements on any 
	Works directly on those Editions to which the 
	CurrentKeyMaster has read permission, must pass the filter.
		If an indirectFilter is given, then the resulting Editions 
	must be contained, directly or indirectly, by an Edition 
	whose endorsements (unioned with its readable Works 
	endorsements) pass the filter. (Giving a non-NULL 
	indirectFilter will probably not be supported in version 1.0.)
		If the directContainersOnly flag is set, then the result 
	only includes Editions which have the material as 
	RangeElements; otherwise, the result includes Editions which 
	indirectly contain the material through other Editions. 
	(Setting this flag will probably not be supported in version 1.0.)
		If the fromTransitiveContents flag is set, then the result 
	includes transclusions of RangeElements of sub-Editions of 
	this one, in addition to the RangeElements in this Edition. 
	(Setting ths flag will probably not be supported in version 1.0.)
		If localPresentOnly flag is clear, a persistent request will 
	be created, and the new FeEdition will continue to be filled 
	in in the future.  If it is set, only those Editions which 
	are currently known to transclude by this Backend are sure to 
	be recorded into the Trail.  (Some, but not all, Editions 
	which come to transclude while this request is being 
	processed may be recorded.  If the request is followed by a 
	FeServer::waitForConsequences(), no Editions which come to 
	transclude after the wait completes will be recorded.)
		If otherTranscluders is given, then the results will be 
	recorded into it. (This may increase the chance of the same 
	Edition being recorded twice.)
		(For convenience, you can attach a TransclusionDetector to 
	the result Edition.  See FeEdition::addFillRangeDetector()  
	See also FeServer::waitForConsequences().) */
	
	virtual CLIENT RPTR(FeEdition) rangeTranscluders (
			APTR(XnRegion) ARG(positions) = NULL, 
			APTR(Filter) ARG(directFilter) = NULL, 
			APTR(Filter) ARG(indirectFilter) = NULL, 
			Int32 ARG(flags) = Int32Zero, 
			APTR(FeEdition) ARG(otherTranscluders) = NULL)
	;
	
	/* Essential.  Return a new FeEdition containing all Works 
	which contain RangeElements of this Edition and can be read 
	by the CurrentKeyMaster. Returns an IDSpace Edition full of 
	PlaceHolders, which will be filled with Works as results come in.
		If a filter is given, then only Works whose endorsements 
	pass the Filter are returned.
		If the localPresentOnly flag is clear, a persistent request 
	will be created, and as new Works come to be known to the 
	Server, they will be filled into the resulting Edition.  If 
	it is set, only Works currently known to this Server are sure 
	to be recorded into the Trail.  (Some, but not all, Works 
	which become known while this request is being processed may 
	be recorded.  If the request is followed by a 
	FeServer::waitForConsequences(), no Works which become known 
	after the wait completes will be recorded.)
		If the fromTransitiveContents flag is set, then the result 
	includes Works which contain RangeElements transitively 
	contained in this Edition. (This may not be supported in 1.0)
		If directContainersOnly is set, then only Works which are 
	directly on Editions which are RangeElements of this Edition 
	are returned (and not Works which are on Editions which have 
	them as sub-Editions).
		If otherTranscluders is given, this records works into that trail.
		(For convenience, you can attach a TransclusionDetector to 
	the result Edition.  See FeEdition::addFillRangeDetector()  
	See also FeServer::waitForConsequences().)
		
		{ <k,l,w> | w's contains self, w passes filter} */
	
	virtual CLIENT RPTR(FeEdition) rangeWorks (
			APTR(XnRegion) ARG(positions) = NULL, 
			APTR(Filter) ARG(filter) = NULL, 
			Int32 ARG(flags) = Int32Zero, 
			APTR(FeEdition) ARG(otherTranscluders) = NULL)
	;
	
	/* Return the subset of the positions of this Edition which  
	have RangeElements that are in the other Edition.
		If nestThis flag is set, then returns not only positions of 
	RangeElements which are in the other, but also positions of 
	Editions which have RangeElements which are in the other, or 
	which have other such Editions, recursively.  (This searches 
	down to, but not across, work boundaries.)
		If nestOther flag is set, then looks not only for 
	RangeElements which are values of the other Edition, but also 
	those which are values of sub-Editions of the other Edition. 
	(This option will probably not be supported in version 1.0).
		If both flags are false, then equivalent to:
			this->mapSharedTo (other)->domain ()
		
		{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is 
	same as v2 } */
	
	virtual CLIENT RPTR(XnRegion) sharedRegion (APTR(FeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
	/* Essential.  Return a new FeEdition consisting of the 
	subset of this Edition whose RangeElements are in the other 
	Edition. If the same RangeElement is in this Edition at 
	several different positions, all positions will be in the 
	result (provided the RangeElement is also in the other Edition).
		Equivalent to:
			this->copy (this->sharedRegion (other, flags)).
			
		{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other 
	and v1 is same as v2 } */
	
	virtual CLIENT RPTR(FeEdition) sharedWith (APTR(FeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
  public: /* endorsing */

	/* Essential.  Adds to the endorsements on this Edition.  The 
	region of additionalEndorsements must consist of a finite 
	number of (club ID, token ID) pairs.  CurrentKeyMaster must 
	hold the signature authority of all the Clubs used to 
	endorse; the request will blast and do nothing if any of the 
	required authority is lacking.  (Redoing an endorse() undoes 
	a retract()) */
	
	virtual CLIENT void endorse (APTR(CrossRegion) ARG(additionalEndorsements));
	
	/* Essential.  Return all of the endorsements which have been 
	placed on this Edition and not retracted. */
	
	virtual CLIENT RPTR(CrossRegion) endorsements ();
	
	/* Essential.  Removes endorsements from this Edition.  This 
	requires that the CurrentKeyMaster hold signature authority 
	for all of the Clubs whose endorsements are in the list; will 
	blast and do nothing if any of the required authority is 
	lacking, even if the endorsements weren't there to be 
	retracted.  Ignores all endorsements which you could have 
	removed, but which don't happen to be there right now.
		
		In the current release removed endorsements aren't 
	preserved, so they vanish forever.  Beginning in some future 
	release removed endorsements will become inactive, but it 
	will be possible to detect that they once had been present.  
	The intent is for a removed endorsement to be analogous to a 
	signature that has been struck out.  You can express that you 
	changed your mind, but you can't undo the past. */
	
	virtual CLIENT void retract (APTR(CrossRegion) ARG(endorsements));
	
	/* Essential.  Return all the unretracted endorsements on 
	this Edition along with those on any Works directly on it 
	which the CurrentKeyMaster has permission to read. */
	
	virtual CLIENT RPTR(CrossRegion) visibleEndorsements ();
	
  public: /* becoming */

	/* Essential.  Connect a FillRangeDetector to the underlying 
	BeEdition so that when any of the PlaceHolders in that 
	Edition become any other kind of RangeElement, then the 
	Detector will be triggered with an Edition containing the new 
	RangeElements (but not necessarily at the same positions, or 
	even in the same CoordinateSpace). If there already are 
	non-PlaceHolders, then the Detector is triggered immediately 
	with those RangeElements.
		See FillRangeDetector::allFilled (Edition * newIdentities). */
	
	virtual void addFillRangeDetector (APTR(FeFillRangeDetector) ARG(detector));
	
	/* Essential.  Return the region consisting of all locations 
	at which my RangeElements can NOT be made identical to the 
	corresponding RangeElements in the other Edition. (This seems 
	like the opposite of what you want, but in fact it makes it 
	easy to check for success.)
		Does not check whether you have permissions to do so, just 
	whether it could be done by someone with the appropriate 
	permissions. See rangeOwners. */
	
	virtual CLIENT RPTR(XnRegion) canMakeRangeIdentical (APTR(FeEdition) ARG(newIdentities), APTR(XnRegion) ARG(positions) = NULL);
	
	/* Essential.  Return a FillRangeDetector so that when any of 
	the PlaceHolders in this Edition become any other kind of 
	RangeElement, then the Detector will be triggered with an 
	Edition containing the new RangeElements (but not necessarily 
	at the same positions, or even in the same CoordinateSpace). 
	If there already are non-PlaceHolders, then the Detector is 
	triggered immediately with those RangeElements.
		See FillRangeDetector::allFilled (Edition * newIdentities). */
	
	virtual CLIENT RPTR(FeFillRangeDetector) fillRangeDetector ();
	
	/* Essential.  Try to change the identity of each 
	RangeElements of this Edition which are in the Region (or all 
	if no Region supplied) to that of the RangeElement at the 
	same position in the other Edition. Returns the subset of 
	this Edition which did not end up with the new identities, because of
			- lack of ownership authority
			- different contents
			- contents of other edition unreadable
			- incompatible types
			- no corresponding new identity
			
	Note that the labels on the RangeElements need not match and 
	will NOT be changed. */
	
	virtual CLIENT RPTR(FeEdition) makeRangeIdentical (APTR(FeEdition) ARG(newIdentities), APTR(XnRegion) ARG(positions) = NULL);
	
	/* The owners of all the RangeElements in the given Region, 
	or in the entire 
		Edition if no Region is specified. */
	
	virtual CLIENT RPTR(IDRegion) rangeOwners (APTR(XnRegion) ARG(positions) = NULL);
	
	/* Essential.  Remove a Detector which had been added to this 
	Edition. You should remove every Detector you add, although 
	they will go away automatically when a client session terminates. */
	
	virtual void removeFillRangeDetector (APTR(FeFillRangeDetector) ARG(detector));
	
	/* Changes the owner of all RangeElements in the Edition (but 
	not the Edition itself!); requires the authority of the 
	current owner of each range element. If a Region is supplied, 
	then only sets those in the region.
		Returns the subset of this Edition which is in the Region 
	whose owners did not end up being the new Owner because of 
	lack of authority. */
	
	virtual CLIENT RPTR(FeEdition) setRangeOwners (APTR(ID) ARG(newOwner), APTR(XnRegion) ARG(region) = NULL);
	
  public: /* labelling */

	
	virtual RPTR(FeLabel) label ();
	
	/* Return a region consisting of exactly the positions in 
	this Edition which are associated with the given label.
		
		{ k | <k,label,v> in self } */
	
	virtual CLIENT RPTR(XnRegion) positionsLabelled (APTR(FeLabel) ARG(label));
	
	/* Return a new FeEdition which is a copy of this Edition 
	with the contained Edition at the given position replaced by 
	the given Edition, but with the Label at that position 
	unchanged.  Equivalent to
			this->with (position, edition->relabelled (this->get 
	(position)->label ())).
	
		Note that rebind() is useless (and blasts) when a 
	non-edition RangeElement is at the given position.
			
		{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
					or (<k,l,v> in self and k != position) } */
	
	virtual CLIENT RPTR(FeEdition) rebind (APTR(Position) ARG(position), APTR(FeEdition) ARG(edition));
	
	
	virtual RPTR(FeRangeElement) relabelled (APTR(FeLabel) ARG(label));
	
  public: /* server accessing */

	
	virtual RPTR(BeEdition) beEdition ();
	
	/* Return an object that wraps up any run-time state that 
	might be needed inside the Be system.  Right now that means labels. */
	
	virtual RPTR(BeCarrier) carrier ();
	
	/* The value at the position, or NULL if there is none */
	
	virtual RPTR(FeRangeElement) fetch (APTR(Position) ARG(position));
	
	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  public: /* client implementation */

	/* These don't change as long as someone has a handle on them. */
	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
  private: /* private: create */

	
	FeEdition (APTR(BeEdition) ARG(beEdition), APTR(FeLabel) ARG(label));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* obsolete: */

	/* Whether the given position is in the Edition. Equivalent to
			this->domain ()->hasMember (position) */
	
	virtual BooleanVar includesKey (APTR(Position) ARG(position));
	
	/* All of the keys in this Edition at which the given 
	RangeElement can be found. Equivalent to
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)).
			
		{ k | <k,l,v> in self and v is same as value } */
	
	virtual RPTR(XnRegion) keysOf (APTR(FeRangeElement) ARG(value));
	
  public: /* destruct */

	
	virtual void destruct ();
	
  private:
	CHKPTR(BeEdition) myBeEdition;
	CHKPTR(FeLabel) myLabel;
};  /* end class FeEdition */



/* ************************************************************************ *
 * 
 *                    Class   FeIDHolder 
 *
 * ************************************************************************ */




	/* An object for having an ID in the range of an Edition. 
	Tentative feature. */

class FeIDHolder : public FeRangeElement {

/* Attributes for class FeIDHolder */
	CONCRETE(FeIDHolder)
	ON_CLIENT(FeIDHolder)
	AUTO_GC(FeIDHolder)
  public: /* creation */

	/* Essential. Make a single IDHolder with the given ID. 
	Tentative feature. */
	
	static CLIENT RPTR(FeIDHolder) make (APTR(ID) ARG(iD));
	
	
	static RPTR(FeIDHolder) on (APTR(BeIDHolder) ARG(be));
	
  public: /* accessing */

	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	/* Essential.  The ID in this holder. */
	
	virtual CLIENT RPTR(ID) iD ();
	
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  private: /* private: create */

	
	FeIDHolder (APTR(BeIDHolder) ARG(be), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* destruct */

	
	virtual void destruct ();
	
  private:
	CHKPTR(BeIDHolder) myBeIDHolder;
};  /* end class FeIDHolder */



/* ************************************************************************ *
 * 
 *                    Class   FeLabel 
 *
 * ************************************************************************ */




	/* An identity attached to a RangeElement within an Edition. */

class FeLabel : public FeRangeElement {

/* Attributes for class FeLabel */
	CONCRETE(FeLabel)
	ON_CLIENT(FeLabel)
	AUTO_GC(FeLabel)
  public: /* creation */

	/* The label will be made on demand. */
	
	static RPTR(FeLabel) fake ();
	
	/* Essential. Create a new unique Label */
	
	static CLIENT RPTR(FeLabel) make ();
	
	
	static RPTR(FeLabel) on (APTR(BeLabel) OR(NULL) ARG(label));
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  public: /* client accessing */

	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
  public: /* destruct */

	
	virtual void destruct ();
	
  public: /* creation */

	
	FeLabel (APTR(BeLabel) OR(NULL) ARG(label), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(BeLabel) OR(NULL) myBeLabel;
};  /* end class FeLabel */



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolder 
 *
 * ************************************************************************ */




	/* Represents a piece of pure identity in the Server. */

class FePlaceHolder : public FeRangeElement {

/* Attributes for class FePlaceHolder */
	DEFERRED(FePlaceHolder)
	NO_GC(FePlaceHolder)
  public: /* creation */

	
	static RPTR(FePlaceHolder) fake (APTR(BeEdition) ARG(edition), APTR(Position) ARG(key));
	
	
	static RPTR(FePlaceHolder) on (APTR(BeRangeElement) ARG(be));
	
  public: /* accessing */

	
	virtual void addFillDetector (APTR(FeFillDetector) ARG(detector));
	
	
	virtual RPTR(FeRangeElement) again () DEFERRED_FUNC;
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity)) DEFERRED_FUNC;
	
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity)) DEFERRED_SUBR;
	
  public: /* server accessing */

	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe () DEFERRED_FUNC;
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	FePlaceHolder();

};  /* end class FePlaceHolder */



/* ************************************************************************ *
 * 
 *                    Class   FeWork 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

ORDER_BOMB(ReleaseWork, WPTR(FeWork) );

;



	/* A persistent identity for a changeable object. */

class FeWork : public FeRangeElement {

/* Attributes for class FeWork */
	CONCRETE(FeWork)
	ON_CLIENT(FeWork)
	AUTO_GC(FeWork)
  public: /* creation */

	/* Essential.  Create a new Work whose initial contents are 
	the given Edition. The reader, editor, owner, sponsor, and 
	KeyMaster come from the fluid environment. If the KeyMaster 
	has edit permission, then the Work is initially grabbed by it.
		Note: This does not assign it a global ID; that must be done 
	separately (see Server::assignID). */
	
	static CLIENT RPTR(FeWork) make (APTR(FeEdition) ARG(contents));
	
	
	static RPTR(FeWork) on (APTR(BeWork) ARG(be));
	
  public: /* grab status */

	/* Essential.  Add a detector which will be notified whenever 
	the locking status of this Work object changes.
		See FeStatusDetector::grabbed (Work *, ID *) / released (Work *). */
	
	virtual void addStatusDetector (APTR(FeStatusDetector) ARG(detector));
	
	/* Return whether you have read permission.  If grabbed, 
	returns TRUE (because a grabber can always read); if 
	released, then returns whether the CurrentKeyMaster has 
	sufficient permission to read the work.  (Read or Edit 
	permission is required.)  Does not check any other KeyMasters 
	you may be holding.
		Note: Be careful of synchronization problems, since the 
	permissions may change between when you ask this question and 
	when you try to actually read the Work. */
	
	virtual CLIENT BooleanVar canRead ();
	
	/* Return whether the BeWork is grabbed by you through this FeWork.
		Note: Be careful of synchronization problems, since the 
	permissions may change before you try to actually revise it, 
	causing you to lose your grab. */
	
	virtual CLIENT BooleanVar canRevise ();
	
	/* Essential.  Grab the Work to prevent other clients from 
	revising it.  Requires edit permission. Snapshots the 
	CurrentKeyMaster and CurrentAuthor (to be used to maintain 
	the grab and report what was done with it). Fails if
			- someone else has it grabbed
			- the CurrentKeyMaster does not have edit permission
			- the CurrentKeyMaster does not have signature authority of 
	the CurrentAuthor
		If this Work was already grabbed by you, then it updates the 
	KeyMaster and Author it holds. (If the regrab fails, the old 
	grab will remain in effect.)
		The grab will be released
			- upon a release request
			- if the KeyMaster loses authority to edit
			- if the KeyMaster loses the signature authority of the Author
			- at the end of the session
			- when the FeWork object is deallocated (if an FeWork was 
	dropped while grabbed, {by destroying the promise for it, or 
	by loss of connection} it will be deallocated 'eventually') */
	
	virtual CLIENT void grab ();
	
	/* Essential.  If you have edit authority, and someone has 
	the BeWork grabbed, then return the Club ID that was the 
	value of his CurrentAuthor when he grabbed it; otherwise blast.
		Requiring edit authority is appropriate here, because it is 
	exactly editors who are affected by competing grabs, and need 
	to know who has the grab.  Once the BeWork is revised, anyone 
	who can read the current trail can see the revision, but the 
	grab state doesn't necessarily imply that the BeWork will be 
	revised soon, or ever. */
	
	virtual CLIENT RPTR(ID) grabber ();
	
	/* Essential.  Release the grab on this Work; if a 
	requestGrab had been pending, remove it. Does nothing if it 
	is already unlocked. */
	
	virtual CLIENT void release ();
	
	/* Essential.  Last detector has gone away */
	
	virtual void removeLastStatusDetector ();
	
	/* Essential.  Registers a request so that the next time this 
	Work would have been released and no other grab requests are 
	outstanding the CurrentKeyMaster (as of making the request) 
	has edit permission, and has signature authority of the 
	CurrentAuthor (as of making the request), it will be grabbed 
	by this FeWork.  If this FeWork already has the Work grabbed, 
	then the request has no effect.  To find out when the grab 
	succeeds, place Status Detectors on the Work.  (If there are 
	competing requestGrabs for a BeWork, the queueing of the 
	requests may not be FIFO, but is starvation-free.)  Note that 
	if you have a requestGrab outstanding on a BeWork through one 
	FeWork, and release a grab you have through another, your 
	requestGrab has no special priority over those of other users. */
	
	virtual CLIENT void requestGrab ();
	
	/* Essential.  Return a detector which will be notified 
	whenever the locking status of this Work changes.
		See FeStatusDetector::grabbed (Work *, ID *) / released (Work *). */
	
	virtual CLIENT RPTR(FeStatusDetector) statusDetector ();
	
  public: /* contents */

	/* Essential.  Return the current Edition.  Succeeds if the 
	Work is already grabbed, or if the CurrentKeyMaster has 
	either Read or Edit permission.
		Note: If this is an unsponsored Work, the Edition might have 
	been discarded, in which case this operation will blast. */
	
	virtual CLIENT RPTR(FeEdition) edition ();
	
	/* Essential.  Change the current Edition of this work to 
	newEdition. The Work must be grabbed  The grabber is recorded 
	as the author who made the revision.
		 (This is the fundamental write operation.) */
	
	virtual CLIENT void revise (APTR(FeEdition) ARG(newEdition));
	
  public: /* permissions */

	/* Essential.  Return the club which has permission to revise 
	this Work.  Blasts if noone can (i.e. editor has been removed). */
	
	virtual CLIENT RPTR(ID) editClub ();
	
	/* Essential. Return the club which will be recorded as the 
	initial club for frozen Works in the history trail.  Blasts 
	if there is no trail being generated. */
	
	virtual CLIENT RPTR(ID) historyClub ();
	
	/* Essential.  Return the club which has permission to read 
	this Work.  Blasts if the read Club has been removed (in that 
	case, only those who have edit permission can read the Work). */
	
	virtual CLIENT RPTR(ID) readClub ();
	
	/* Essential.  Irrevocably remove edit permission. Requires 
	ownership authority. */
	
	virtual CLIENT void removeEditClub ();
	
	/* Essential.  Irrevocably remove read permission (although 
	you should note that editors are still able to read, if there 
	are any). Requires ownership authority. */
	
	virtual CLIENT void removeReadClub ();
	
	/* Essential.  Change who has edit permission. Requires 
	ownership authority.
		 Aborts if the Work doesn't have an edit Club. */
	
	virtual CLIENT void setEditClub (APTR(ID) OR(NULL) ARG(club));
	
	/* Essential.  Change the initial read Club for frozen Works 
	in the trail. Requires ownership authority. Setting it to 
	NULL turns off the recording of history. */
	
	virtual CLIENT void setHistoryClub (APTR(ID) OR(NULL) ARG(club));
	
	/* Essential.  Change who has read permission. Requires 
	ownership authority.
		 Aborts if the works doesn't have a read Club. */
	
	virtual CLIENT void setReadClub (APTR(ID) OR(NULL) ARG(club));
	
  public: /* endorsing */

	/* Essential.  Adds to the endorsements on this Work. The set 
	of endorsements must be a finite number of (club ID, token 
	ID) pairs. This requires the signature authority of all of 
	the Clubs used to endorse; will blast and do nothing if any 
	of the required authority is lacking. The token IDs must not 
	be named IDs. */
	
	virtual CLIENT void endorse (APTR(CrossRegion) ARG(additionalEndorsements));
	
	/* Essential.  Return all of the endorsements which have been 
	placed on this Work and are not currently retracted.
		(Endorsements are used to filter various operations which 
	return sets of Works.  See FeEdition::rangeTranscluders() for 
	one way to find this work by filtering for its endorsements.) */
	
	virtual CLIENT RPTR(CrossRegion) endorsements ();
	
	/* Essential.  Removes endorsements from this Work. This 
	requires the signature authority of all of the Clubs whose 
	endorsements are in the list; will blast and do nothing if 
	any of the required authority is lacking. Ignores all 
	endorsements which you could have removed, but which don't 
	happen to be there right now. */
	
	virtual CLIENT void retract (APTR(CrossRegion) ARG(removedEndorsements));
	
  public: /* sponsoring */

	/* Essential.  Add to the list of sponsors of this Work. 
	Requires signature authority of all of the Clubs in the set. */
	
	virtual CLIENT void sponsor (APTR(IDRegion) ARG(clubs));
	
	/* Essential.  All of the Clubs which are sponsoring this 
	Work to keep it from being discarded.
		What sort of permissions does this require? */
	
	virtual CLIENT RPTR(IDRegion) sponsors ();
	
	/* Essential.  End sponsorship of this Work by all of the 
	listed Clubs. Requires signature authority of all of the 
	Clubs in the set, even if they are not currently sponsors.
		Should this use the CurrentKeyMaster? Or the internal 
	KeyMaster if it is grabbed? */
	
	virtual CLIENT void unsponsor (APTR(IDRegion) ARG(clubs));
	
  public: /* server grab status */

	/* The authority of my KeyMaster has changed and I need to 
	update my status */
	/* If I was grabbing and lost permission to edit, or 
	signature authority for the author,
			evict myself
		else if I was waiting for a grab and gained permission to do so
			and the Work is ungrabbed
				grab it */
	
	virtual void updateStatus ();
	
  public: /* server contents */

	/* Trigger all my immediate RevisionDetectors who can read the Work */
	
	virtual void triggerRevisionDetectors (
			APTR(FeEdition) ARG(contents), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(time), 
			IntegerVar ARG(sequence))
	;
	
  public: /* server accessing */

	
	virtual RPTR(ID) OR(NULL) fetchAuthor ();
	
	
	virtual RPTR(BeRangeElement) OR(NULL) fetchBe ();
	
	
	virtual RPTR(ID) getAuthor ();
	
	
	virtual RPTR(BeRangeElement) getOrMakeBe ();
	
  protected: /* protected: create */

	
	FeWork (APTR(BeWork) ARG(be), TCSJ);
	
  public: /* destruct */

	
	virtual void destruct ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	virtual RPTR(FeRangeElement) again ();
	
	
	virtual BooleanVar canMakeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
	
	virtual void makeIdentical (APTR(FeRangeElement) ARG(newIdentity));
	
  public: /* history */

	/* Essential. Trigger a Detector whenever there is a revision 
	to the Work which the CurrentKeyMaster can see. If this 
	detector has already been added, then the old KeyMaster 
	associated with it is replaced with the CurrentKeyMaster.
		See RevisionDetector::revised (Edition * contents,
			ID * author,
			IntegerVar sequence,
			IntegerVar time). */
	
	virtual void addRevisionDetector (APTR(FeRevisionDetector) ARG(detector));
	
	/* The ID of the author of the last revision of this Work to 
	its current Edition, or its creation if it hasn't been 
	revised since. The Work must be grabbed, or the 
	CurrentKeyMaster must be able to exercise the authority of 
	the Read, Edit, or History Club. */
	
	virtual CLIENT RPTR(ID) lastRevisionAuthor ();
	
	/* The sequence number of the last revision of this Work to 
	its current Edition, or its creation if it hasn't been 
	revised since. The Work must be grabbed, or the 
	CurrentKeyMaster must be able to exercise the authority of 
	the Read, Edit, or History Club. */
	
	virtual CLIENT IntegerVar lastRevisionNumber ();
	
	/* The time of the last revision of this Work to its current 
	Edition, or its creation if it hasn't been revised since. The 
	Work must be grabbed, or the CurrentKeyMaster must be able to 
	exercise the authority of the Read, Edit, or History Club. */
	
	virtual CLIENT IntegerVar lastRevisionTime ();
	
	/* Essential. Inform the work that its last revision detector 
	has gone away. */
	
	virtual void removeLastRevisionDetector ();
	
	/* Essential. Return a detector tht will trigger whenever 
	there is a revision to the Work which the CurrentKeyMaster can see.
		See RevisionDetector::revised (Edition * contents,
			ID * author,
			IntegerVar sequence,
			IntegerVar time). */
	
	virtual CLIENT RPTR(FeRevisionDetector) revisionDetector ();
	
	/* Return the revision trail of the receiver.  The trail will 
	be empty if no revisions have been recorded. The trail is 
	updated immediately when the Work is revised.
		In order to get the trail, either the Work must be grabbed, 
	or you must be a member of the Read, Edit, or History Clubs. */
	
	virtual CLIENT RPTR(FeEdition) revisions ();
	
  private: /* private: */

	/* self canRead or CurrentKeyMaster has authority of the historyClub */
	
	virtual BooleanVar canReadHistory ();
	
  private:
	CHKPTR(FeKeyMaster) OR(NULL) myKeyMaster;
	CHKPTR(ID) myAuthor;
	BooleanVar amWaiting;
	CHKPTR(BeWork) myBeWork;
	CHKPTR(PrimSet) OF1(FeStatusDetector) OR(NULL) myStatusDetectors;
	CHKPTR(PrimSet) OF1(FeRevisionDetector) OR(NULL) myRevisionDetectors;
};  /* end class FeWork */



/* ************************************************************************ *
 * 
 *                    Class     FeClub 
 *
 * ************************************************************************ */




	/* A persistent Club on the Server. */

class FeClub : public FeWork {

/* Attributes for class FeClub */
	CONCRETE(FeClub)
	ON_CLIENT(FeClub)
	NO_GC(FeClub)
  public: /* creation */

	/* Essential.  Create a new Club whose initial status is 
	described in the given ClubDescription Edition. The reader, 
	editor and owner are taken from the current settings. If the 
	KeyMaster has edit permission, then the Club Work is 
	initially grabbed by it. The Club Work is initially sponsored 
	by the CurrentSponsor.
		Note: Unlike ordinary Works, a newly created Club is 
	assigned a global ID. */
	
	static CLIENT RPTR(FeClub) make (APTR(FeEdition) ARG(status));
	
	
	static RPTR(FeClub) on (APTR(BeClub) ARG(be));
	
  public: /* signing */

	/* Essential.  Irrevocably remove signature authority for 
	this Club. Requires ownership authority. */
	
	virtual CLIENT void removeSignatureClub ();
	
	/* Essential.  Change who has signature authority for this 
	Club. Requires ownership authority.
		 Aborts if the Work doesn't have a signature Club. */
	
	virtual CLIENT void setSignatureClub (APTR(ID) OR(NULL) ARG(club));
	
	/* Essential. The Club which has 'signature authority' for 
	this Club. Members of this Club are allowed to endorse with 
	the ID of this Club, and are allowed to use it to sponsor 
	resources. BLASTs if it has been removed */
	
	virtual CLIENT RPTR(ID) signatureClub ();
	
  public: /* server */

	
	virtual RPTR(BeClub) beClub ();
	
  public: /* managing storage */

	/* Essential.  All of the Works sponsored by this Club. If a 
	Filter is given, then restricts the result to Works which 
	pass the filter. The result can be wrapped with a Set. This 
	does not require any permissions. */
	
	virtual CLIENT RPTR(FeEdition) sponsoredWorks (APTR(Filter) ARG(filter) = NULL);
	
  private: /* private: create */

	
	FeClub (APTR(BeClub) ARG(be), TCSJ);
	

/* Friends for class FeClub */
/* friends for class FeClub */

friend class BeClub;



	friend class FeWork;
};  /* end class FeClub */



/* ************************************************************************ *
 * 
 *                    Class FeServer 
 *
 * ************************************************************************ */



/* Initializers for FeServer */
extern Recipe * FebeCuisine;	/* in FeServer */



DESIGN_FLUID(FeServer,CurrentServer);	/* in FeServer */
DESIGN_FLUID(FeKeyMaster,CurrentKeyMaster);	/* in FeServer */
DESIGN_FLUID(ID,CurrentAuthor);	/* in FeServer */
DESIGN_FLUID(ID,InitialReadClub);	/* in FeServer */
DESIGN_FLUID(ID,InitialEditClub);	/* in FeServer */
DESIGN_FLUID(ID,InitialOwner);	/* in FeServer */
DESIGN_FLUID(ID,InitialSponsor);	/* in FeServer */




	/* The fundamental Server object. Used for managing the 
	global name space, creating Works, Editions, and Clubs, and 
	other general server management operations.
	
	Many operations in the protocol use fluidly bound parameters. 
	The possible parameters are:
		FeServer defineClientFluid: #CurrentServer with: Listener 
	emulsion with: [NULL].
	
	CurrentKeyMaster - a KeyMaster for providing authority to 
	read and/or edit
	CurrentAuthor - the ID of the Club under whose name Work 
	revisions are being done; requires signature authority
	InitialReadClub - the ID of the initial read Club of all 
	newly created Works and Clubs
	InitialEditClub - the ID of the initial edit Club of all 
	newly created Works and Clubs
	InitialOwner - the ID of the Club which owns newly created 
	RangeElements
	InitialSponsor - the ID of the Club which sponsors newly 
	created Works and Clubs; requires signature authority */

class FeServer : public Heaper {

/* Attributes for class FeServer */
	CONCRETE(FeServer)
	ON_CLIENT(FeServer)
	EQ(FeServer)
	AUTO_GC(FeServer)

/* Initializers for FeServer */





  public: /* server library */

	/* Looks up the ID of a named Club in the directory 
	maintained by the System Admin Club. Requires read permission 
	on the directory. Blasts if there is no Club with that name. */
	
	static RPTR(ID) clubID (APTR(Sequence) ARG(clubName));
	
	/* Finds the name of a Club in the global directory 
	maintained by the System Admin Club. Blasts if there is no 
	name for that Club, or if there is more than one. Requires 
	read permission on the clubDirectory Work */
	
	static RPTR(Sequence) clubName (APTR(ID) ARG(iD));
	
	/* The names of all global Clubs. Requires read permission on 
	the clubDirectory Work */
	
	static RPTR(SequenceRegion) clubNames ();
	
	/* Disable login access to a Club, by revoking its direct 
	membership of the System Access Club */
	
	static void disableAccess (APTR(ID) ARG(clubID));
	
	/* Enable login access to a Club, by listing it as a direct 
	member of the System Access Club */
	
	static void enableAccess (APTR(ID) ARG(clubID));
	
	/* The CoordinateSpace used for filtering endorsements on 
	this Server. Equivalent to
			this->filterSpace (this->endorsementSpace ()) */
	
	static RPTR(FilterSpace) endorsementFilterSpace ();
	
	/* A set of endorsements for each Club endorsing with each token */
	
	static RPTR(CrossRegion) OF2(IDRegion,IDRegion) endorsementRegion (APTR(IDRegion) OR(NULL) ARG(clubs), APTR(IDRegion) OR(NULL) ARG(tokens));
	
	/* A set of endorsements for each Club endorsing with each token */
	
	static RPTR(CrossSpace) OF2(IDSpace,IDSpace) endorsementSpace ();
	
	/* The Work mapping names to global Club Works */
	
	static RPTR(FeWork) globalClubs ();
	
	/* Return true if the current session has successfully logged 
	into the Server yet. */
	
	static BooleanVar isAdmitted ();
	
	/* Add a Club to the global list of club names. Blasts if 
	there is already a Club by that name. */
	
	static void nameClub (APTR(Sequence) ARG(clubName), APTR(ID) ARG(clubID));
	
	/* Changes the name of an existing Club. Blasts if there is 
	no Club with the old name, or there already is a Club with 
	the new name. */
	
	static void renameClub (APTR(Sequence) ARG(oldName), APTR(Sequence) ARG(newName));
	
	/* Removes a naming for a Club. Blasts if there is no Club by 
	that clubName. */
	
	static void unnameClub (APTR(Sequence) ARG(clubName));
	
  public: /* create */

	/* Get the receiver for wire requests. */
	
	static RPTR(FeServer) implicitReceiver ();
	
	
	static RPTR(FeServer) make ();
	
  public: /* managing clubs */

	/* Essential.  The ID of the System Access Club. */
	
	static CLIENT RPTR(ID) accessClubID ();
	
	/* Essential.  The ID of the System Admin Club. */
	
	static CLIENT RPTR(ID) adminClubID ();
	
	/* Essential.  The ID of the System Archive Club. */
	
	static CLIENT RPTR(ID) archiveClubID ();
	
	/* Essential.  The ID of the Universal Empty Club. */
	
	static CLIENT RPTR(ID) emptyClubID ();
	
	/* Essential. The encryption scheme to be used for sending 
	sensitive parameters to the Server. (e.g. 
	MatchLock::encryptedPassword ()) */
	
	static CLIENT RPTR(Sequence) encrypterName ();
	
	/* Essential.  Return a lock which, if satisfied, will give a 
	KeyMaster logged in to that Club. It will be able to exercise 
	the authority of all of its superClubs.
		 The club must be in the System Access Club or another club 
	must have been logged in during this session.
		 If that doesn't hold, or there is no such club, returns the 
	gateLockSpec chosen by the Administrator if there is no such Club */
	
	static CLIENT RPTR(Lock) login (APTR(ID) ARG(clubID));
	
	/* Essential.  Return a lock which, if satisfied, will give a 
	KeyMaster logged in to the named Club. It will be able to 
	exercise the authority of all of its superClubs.
			 The club must be in the System Access Club or another club 
	must have been logged in during this session.
		 If that doesn't hold, or there is no such club, returns the 
	gateLockSpec chosen by the Administrator if there is no such Club */
	
	static CLIENT RPTR(Lock) loginByName (APTR(Sequence) ARG(clubName));
	
	/* Essential.  The ID of the Universal Public Club. */
	
	static CLIENT RPTR(ID) publicClubID ();
	
	/* Essential. The public key to be used for sending sensitive 
	parameters to the Server. (e.g. MatchLock::encryptedPassword ()) */
	
	static CLIENT RPTR(UInt8Array) publicKey ();
	
  public: /* comm requests */

	/* Flush the Server's output buffers. */
	
	static CLIENT NOACK force ();
	
	/* Set the Server side fluid for the CurrentAuthor. */
	
	static CLIENT NOACK setCurrentAuthor (APTR(ID) ARG(iD));
	
	/* Set the Server side fluid for the CurrentKeyMaster. */
	
	static CLIENT NOACK setCurrentKeyMaster (APTR(FeKeyMaster) ARG(km));
	
	/* Set the Server side fluid for the InitialEditClub. */
	
	static CLIENT NOACK setInitialEditClub (APTR(ID) ARG(iD));
	
	/* Set the Server side fluid for the InitialOwner. */
	
	static CLIENT NOACK setInitialOwner (APTR(ID) ARG(iD));
	
	/* Set the Server side fluid for the InitialReadClub. */
	
	static CLIENT NOACK setInitialReadClub (APTR(ID) ARG(iD));
	
	/* Set the Server side fluid for the InitialSponsor. */
	
	static CLIENT NOACK setInitialSponsor (APTR(ID) ARG(iD));
	
  public: /* global ids */

	/* Essential.  Assign a new global ID to a RangeElement. If 
	NULL, then a new unique ID is generated for it, and this 
	requires no permissions. If an ID is supplied, the 
	CurrentKeyMaster must have been granted authority to assign 
	this ID by the Adminer. Returns the newly assigned ID. */
	
	static CLIENT RPTR(ID) assignID (APTR(FeRangeElement) ARG(range), APTR(ID) ARG(iD) = NULL);
	
	/* The ID of a Work mapping Club names to FeClubs */
	
	static CLIENT RPTR(ID) clubDirectoryID ();
	
	/* Essential.  Get the object associated with the given 
	global ID. Typically, it will be a Work. Blast if there is 
	nothing there */
	
	static CLIENT RPTR(FeRangeElement) get (APTR(ID) ARG(iD));
	
	/* Find the unique global ID on this Server that has been 
	assigned to this RangeElement. Blast if there is none, or 
	more than one.
		Equivalent to
			CAST(ID, this->iDsOf (value)->theOne ()) */
	
	static CLIENT RPTR(ID) iDOf (APTR(FeRangeElement) ARG(value));
	
	/* Essential.  Find all the global IDs on this Server that 
	have been assigned to this RangeElement */
	
	static CLIENT RPTR(IDRegion) iDsOf (APTR(FeRangeElement) ARG(value));
	
	/* Find all the global IDs on this Server that have been 
	assigned to any of the RangeElements in an Edition */
	
	static CLIENT RPTR(IDRegion) iDsOfRange (APTR(FeEdition) ARG(edition));
	
  public: /* accessing */

	/* The current clock time on the Server, in seconds since the 
	'beginning of time' */
	
	static CLIENT IntegerVar currentTime ();
	
	/* The LockSmith which hands out locks when a client tries to 
	login through the GateKeeper with an invalid Club ID or name. */
	
	static RPTR(FeLockSmith) gateLockSmith ();
	
	/* Essential. A sequence of numbers uniquely identifying this Server */
	
	static CLIENT RPTR(Sequence) identifier ();
	
	/* This is currently a no-op. */
	
	static void removeWaitDetector (APTR(FeWaitDetector) ARG(detector));
	
	/* Essential.  The Detector will be triggered when the 
	consequences of all previous local requests have finished 
	propagating through this Server. (e.g. Edition::transclusions 
	may take a while to collect all of the results.)
		If you want to remove the Detector before it is triggered, destroy it.
		Note that this is NOT a request to speed up the completion 
	of the outstanding requests.
		See WaitDetector::done () */
	
	static CLIENT RPTR(FeWaitDetector) waitForConsequences ();
	
	/* Essential.  The Detector will be triggered when the 
	consequences of all previous local requests have finished 
	propagating through this Server. (e.g. Edition::transclusions 
	may take a while to collect all of the results.)
		If you want to remove the Detector before it is triggered, destroy it.
		Note that this is NOT a request to speed up the completion 
	of the outstanding requests.
		See WaitDetector::done () */
	
	static void waitForConsequences (APTR(FeWaitDetector) ARG(detector));
	
	/* Essential.  The Detector will be triggered when the 
	current state of the Server has been reliably written to disk.
		If you want to remove the Detector before it is triggered, destroy it.
		See WaitDetector::done () */
	
	static CLIENT RPTR(FeWaitDetector) waitForWrite ();
	
	/* Essential.  The Detector will be triggered when the 
	current state of the Server has been reliably written to disk.
		If you want to remove the Detector before it is triggered, destroy it.
		See WaitDetector::done () */
	
	static void waitForWrite (APTR(FeWaitDetector) ARG(detector));
	
  public: /* miscellaneous */

	/* Essential. A specification for arrays of pointers. */
	
	virtual RPTR(PrimPointerSpec) pointerSpec ();
	
  public: /* create */

	
	FeServer (APTR(Sequence) ARG(encrypterName), APTR(Encrypter) ARG(encrypter));
	
  public: /* security */

	/* Return the Encrypter used for sending sensitive parameters 
	to the Server. (e.g. MatchLock::encryptedPassword ()) */
	
	virtual RPTR(Encrypter) encrypter ();
	
	/* Essential. The encryption scheme to be used for sending 
	sensitive parameters to the Server. (e.g. 
	MatchLock::encryptedPassword ()) */
	
	virtual RPTR(Sequence) getEncrypterName ();
	
  private:
	CHKPTR(Sequence) myEncrypterName;
	CHKPTR(Encrypter) myEncrypter;
};  /* end class FeServer */


#ifdef USE_INLINE
#ifndef NKERNELX_IXX
#include "nkernelx.ixx"
#endif /* NKERNELX_IXX */


#endif /* USE_INLINE */


#endif /* NKERNELX_HXX */


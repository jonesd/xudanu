'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:09 pm'!

CoordinateSpace subclass: #CrossSpace
	instanceVariableNames: 'mySubSpaces {PtrArray of: CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
CrossSpace comment:
'Represents the cross of several coordinate spaces.  '!

(CrossSpace getOrMakeCxxClassDescription)
	friends:
'friend class BoxAccumulator;
friend class BoxStepper;
friend class GenericCrossSpace;
friend class GenericCrossRegion;
friend class BoxProjectionStepper;';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossSpace methodsFor: 'accessing'!

{PtrArray CLIENT of: CoordinateSpace} axes
	"Essential.  The base spaces that I am a cross of."

	^mySubSpaces copy cast: PtrArray!

{CoordinateSpace CLIENT} axis: dimension {Int32}
	"The sub coordinate space on the given axis"
	
	^(mySubSpaces fetch: dimension) cast: CoordinateSpace!

{Int32 CLIENT INLINE} axisCount
	"The number of dimensions in this space"
	
	^mySubSpaces count! !

!CrossSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^mySubSpaces contentsHash bitXor: #cat.U.CrossSpace hashForEqual!

{BooleanVar} isEqual: other {Heaper}
	
	other 
		cast: CrossSpace into: [:cross |
			^cross secretSubSpaces contentsEqual: mySubSpaces]
		others: [^false].
	^ false "compiler fodder"! !

!CrossSpace methodsFor: 'making'!

{Mapping CLIENT} crossOfMappings: subMappings {(PtrArray of: Mapping | NULL) default: NULL}
	"Essential.  Map each coordinate according to the mapping from its space.  NULLs mean 'use the identity mapping'"
	
	self subclassResponsibility!

{CrossOrderSpec CLIENT} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL) default: NULL}
	with: subSpaceOrdering {PrimIntArray default: NULL}
	"Essential.  Make a lexical ordering of all elements in the space, using the given ordering for each sub space. If no sub space ordering is given, then it is in the order they are in the array.
	
	subSpaceOrdering lists the lexicographic order in which each dimension should be processed.  Every dimension should be listed exactly one, from most significant (at index 0) to least significant.

	subOrderings are indexed by *dimension*, not by lexicographic order.  In order to index by lex order, look up the dimension in subSpaceOrdering, and then look up the resulting dimension number in subOrderings."
	
	self subclassResponsibility!

{Tuple CLIENT} crossOfPositions: coordinates {PtrArray of: Position}
	"Essential. Make an individual position"
	
	self subclassResponsibility!

{CrossRegion CLIENT} crossOfRegions: subRegions {PtrArray of: XnRegion | NULL}
	"Essential. Make a 'rectangular' region as a cross of all the given regions"
	
	self subclassResponsibility!

{CrossRegion CLIENT} extrusion: dimension {Int32} with: subRegion {XnRegion}
	"Return a region whose projection is 'subRegion' along 'dimension', but is full on all other dimensions"
	
	self subclassResponsibility! !

!CrossSpace methodsFor: 'smalltalk: passe'!

{IntegerVar} count

	self passe "axisCount"!

{Int32} intCount

	self passe "axisCount"!

{CrossMapping} makeCrossMapping: subMappings {PtrArray of: Mapping}
	
	self passe!

{CrossOrderSpec} makeCrossOrderSpec: subOrderings {PtrArray of: OrderSpec | NULL}
	with: subSpaceOrdering {Int32Array default: NULL}
	"Make a lexical ordering of all elements in the space, using the given ordering for each sub space. If no sub space ordering is given, then it is in the order they are in the array"
	
	self passe!

{CrossRegion} makeCrossRegion: subRegions {PtrArray of: XnRegion | NULL}
	"Make a 'rectangular' region as a cross of all the given regions"
	
	self passe!

{Tuple} makeTuple: coordinates {PtrArray of: Position}
	"Make an individual position"
	
	self passe!

{CoordinateSpace} subSpace: dimension {Int32}

	self passe "axis"!

{PtrArray of: CoordinateSpace} subSpaces

	self passe "axes"! !

!CrossSpace methodsFor: 'smalltalk: defaults'!

{Mapping CLIENT} crossOfMappings

	^self crossOfMappings: NULL!

{CrossOrderSpec CLIENT} crossOfOrderSpecs

	^self crossOfOrderSpecs: NULL with: NULL!

{CrossOrderSpec CLIENT} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL) default: NULL}


	^self crossOfOrderSpecs: subOrderings with: NULL! !

!CrossSpace methodsFor: 'protected: accessing'!

{PtrArray INLINE of: CoordinateSpace} secretSubSpaces
	"The actual array of sub spaces. DO NOT MODIFY"
	
	^mySubSpaces! !

!CrossSpace methodsFor: 'protected: creation'!

create
	
	super create.
	mySubSpaces := NULL.!

create: subSpaces {PtrArray of: CoordinateSpace}
	
	super create.
	mySubSpaces := subSpaces.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CrossSpace class
	instanceVariableNames: ''!

(CrossSpace getOrMakeCxxClassDescription)
	friends:
'friend class BoxAccumulator;
friend class BoxStepper;
friend class GenericCrossSpace;
friend class GenericCrossRegion;
friend class BoxProjectionStepper;';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossSpace class methodsFor: 'creation'!

{CrossSpace CLIENT} make: subSpaces {PtrArray of: CoordinateSpace}
	"Make a cross space with the given list of subspaces"
	 "Should use middlemen.  Just hard code special cases for now"
	 
	^GenericCrossSpace make: (subSpaces copy cast: PtrArray)!

make: zeroSpace {CoordinateSpace} with: oneSpace {CoordinateSpace}
	"Cross two sub spaces"
	
	^GenericCrossSpace create: ((PrimSpec pointer
		arrayWithTwo: zeroSpace with: oneSpace) cast: PtrArray)! !

!CrossSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PtrArray CLIENT of: CoordinateSpace} axes
{CoordinateSpace CLIENT} axis: dimension {Int32}
{Int32 CLIENT} axisCount
{Mapping CLIENT} crossOfMappings
{Mapping CLIENT} crossOfMappings: subMappings {(PtrArray of: Mapping | NULL)
		default: NULL}
{CrossOrderSpec CLIENT} crossOfOrderSpecs
{CrossOrderSpec CLIENT} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL)
		default: NULL}
{CrossOrderSpec CLIENT} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL)
		default: NULL} with: subSpaceOrdering {Int32Array default: NULL}
{Tuple CLIENT} crossOfPositions: coordinates {PtrArray of: Position}
{CrossRegion CLIENT} crossOfRegions: subRegions {PtrArray of: XuRegion | NULL}
{CrossRegion CLIENT} extrusion: dimension {Int32} with: subRegion {XuRegion}
"! !
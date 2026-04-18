'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:53 pm'!

Heaper subclass: #CoordinateSpace
	instanceVariableNames: '
		myEmptyRegion {XnRegion}
		myFullRegion {XnRegion}
		myIdentityDsp {Dsp}
		myAscending {OrderSpec | NULL}
		myDescending {OrderSpec | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
CoordinateSpace comment:
'A coordinate space represents (among other things) the domain space of a table. Corresponding to each coordinate space will be a set of objects of the following kinds:
	
	Position -- The elements of the coordinate space.
	Mapping -- (Add a description.)
	OrderSpec -- The ways of specifying partial orders of this coordinate space''s Positions.
	XuRegion -- An XuRegion represents a set of Positions.  The domain of a table is an XuRegion.
	
	When defining a new coordinate space class, one generally defines new corresponing subclasses of each of the above classes.  A kind of any of the above classes knows what coordinate space it is a part of (the "coordinateSpace()" message will yield an appropriate kind of CoordinateSpace).  CoordinateSpace objects exist mostly just to represent this commonality.  Coordinate spaces are disjoint--it is an error to use any of the generic protocol of any of the above classes if the objects in question are of two different coordinate spaces.  For example, "dsp->of (pos)" is not an error iff "dsp->coordinateSpace()->isEqual (pos->coordinateSpace())".
	
Note that this class is not COPY or even PSEUDO_COPY.  All of the instance variables for CoordinateSpace are basically cached
quantities that require vary little actual state from the derived classes in order to be constructed.  This realization allows a knot
to be untangled when reading these objects from external storage.'!

(CoordinateSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CoordinateSpace methodsFor: 'accessing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{OrderSpec CLIENT INLINE} ascending
	"Essential.  The natural full-ordering of the coordinate space."
	
	^self getAscending!

{Mapping CLIENT INLINE} completeMapping: range {XnRegion}
	"Essential. A Mapping which maps each position in this space to every position in the range region. The region can be from any CoordinateSpace."
	
	^Mapping make.CoordinateSpace: self with.Region: range!

{OrderSpec CLIENT INLINE} descending
	"The mirror image of the partial order returned by 'CoordinateSpace::ascending'."
	
	^self getDescending!

{XnRegion CLIENT INLINE} emptyRegion
	"Essential.  An empty region in this coordinate space"
	
	^myEmptyRegion!

{(OrderSpec | NULL) INLINE} fetchAscending
	"The natural full-ordering of the coordinate space."

	^myAscending!

{(OrderSpec | NULL) INLINE} fetchDescending
	"The mirror image of the partial order returned by 
	'CoordinateSpace::fetchAscending'."

	^myDescending!

{XnRegion CLIENT INLINE} fullRegion
	"A full region in this coordinate space"
	
	^myFullRegion!

{OrderSpec} getAscending
	"Essential.  The natural full-ordering of the coordinate space."
	
	| result {OrderSpec | NULL} |
	result := self fetchAscending.
	result == NULL ifTrue:
		[Heaper BLAST: #NoFullOrder].
	^result!

{OrderSpec} getDescending
	"The mirror image of the partial order returned by 'CoordinateSpace::getAscending'."
	
	| result {OrderSpec | NULL} |
	result := self fetchDescending.
	result == NULL ifTrue:
		[Heaper BLAST: #NoFullOrder].
	^result!

{Dsp INLINE} identityDsp
	"A Dsp which maps all positions in the coordinate space onto themselves"
	
	^myIdentityDsp!

{Mapping CLIENT INLINE} identityMapping
	"Essential.  A Mapping which maps all positions in the coordinate space onto themselves"
	
	^self identityDsp!

{BooleanVar} isEqual: other{Heaper}

	self subclassResponsibility!

{BooleanVar} verify: thing {Heaper}
	"tell whether this is a valid Position/XuRegion/Dsp/OrderSpec for this space"

	thing cast: (Position | XnRegion | Dsp | OrderSpec) into: [:t |
			^self isEqual: t coordinateSpace].
	"cast into blasts here."
	^false! !

!CoordinateSpace methodsFor: 'smalltalk: defaults'!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	
	self create: emptyRegion with: fullRegion with: identityDsp with: NULL with: NULL!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	with: ascending {OrderSpec default: NULL}
	
	self create: emptyRegion with: fullRegion with: identityDsp with: ascending with: NULL! !

!CoordinateSpace methodsFor: 'protected: create followup'!

{void} finishCreate: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	with: ascending {OrderSpec default: NULL}
	with: descending {OrderSpec default: NULL}
	
	myEmptyRegion := emptyRegion.
	myFullRegion := fullRegion.
	myIdentityDsp := identityDsp.
	myAscending := ascending.
	(descending == NULL and: [ascending ~~ NULL]) ifTrue:
		[myDescending := ascending reversed]
	ifFalse:
		[myDescending := descending].! !

!CoordinateSpace methodsFor: 'create'!

create
	
	super create.
	myEmptyRegion := NULL.
	myFullRegion := NULL.
	myIdentityDsp := NULL.
	myAscending := NULL.
	myDescending := NULL.!

create: emptyRegion {XnRegion}
	with: fullRegion {XnRegion}
	with: identityDsp {Dsp}
	with: ascending {OrderSpec default: NULL}
	with: descending {OrderSpec default: NULL}
	
	super create.
	myEmptyRegion := emptyRegion.
	myFullRegion := fullRegion.
	myIdentityDsp := identityDsp.
	myAscending := ascending.
	(descending == NULL and: [ascending ~~ NULL]) ifTrue:
		[myDescending := ascending reversed]
	ifFalse:
		[myDescending := descending].! !

!CoordinateSpace methodsFor: 'smalltalk: passe'!

{Mapping} importMapping: data {PrimArray} with: rangeSpace {CoordinateSpace default: NULL}

	self passe!

{OrderSpec} importOrderSpec: data {PrimArray}

	self passe!

{XnRegion} importRegion: data {PrimArray}

	self passe!

{Mapping} mapping: data {PrimArray}

	self passe!

{Mapping} mapping: data {PrimArray} with: rangeSpace {CoordinateSpace default: NULL}

	self passe!

{OrderSpec} orderSpec: data {PrimArray}

	self passe!

{XnRegion} region: data {PrimArray}

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CoordinateSpace class
	instanceVariableNames: ''!

(CoordinateSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CoordinateSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{OrderSpec CLIENT} ascending
{Mapping CLIENT} completeMapping: range {XuRegion}
{OrderSpec CLIENT} descending
{XuRegion CLIENT} emptyRegion
{XuRegion CLIENT} fullRegion
{Mapping CLIENT} identityMapping
"! !
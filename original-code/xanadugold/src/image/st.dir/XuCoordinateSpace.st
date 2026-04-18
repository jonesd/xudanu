'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:59 pm'!

XuPromise subclass: #XuCoordinateSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
XuCoordinateSpace comment:
'A coordinate space represents (among other things) the domain space of a table. Corresponding to each coordinate space will be a set of objects of the following kinds:
	
	Position -- The elements of the coordinate space.
	Mapping -- (Add a description.)
	OrderSpec -- The ways of specifying partial orders of this coordinate space''s Positions.
	XuRegion -- An XuRegion represents a set of Positions.  The domain of a table is an XuRegion.
	
	When defining a new coordinate space class, one generally defines new corresponing subclasses of each of the above classes.  A kind of any of the above classes knows what coordinate space it is a part of (the "coordinateSpace()" message will yield an appropriate kind of CoordinateSpace).  CoordinateSpace objects exist mostly just to represent this commonality.  Coordinate spaces are disjoint--it is an error to use any of the generic protocol of any of the above classes if the objects in question are of two different coordinate spaces.  For example, "dsp->of (pos)" is not an error iff "dsp->coordinateSpace()->isEqual (pos->coordinateSpace())".
	
Note that this class is not COPY or even PSEUDO_COPY.  All of the instance variables for CoordinateSpace are basically cached
quantities that require vary little actual state from the derived classes in order to be constructed.  This realization allows a knot
to be untangled when reading these objects from external storage.'!

(XuCoordinateSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCoordinateSpace methodsFor: 'accessing'!

{XuOrderSpec} ascending

	"Essential.  The natural full-ordering of the coordinate space."
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualCoordinateSpace ascending)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} completeMapping: range {XuRegion} 

	"Essential. A Mapping which maps each position in this space to every position in the range region. The region can be from any CoordinateSpace."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(range isBroken) ifTrue:
		[^XuMapping makeBrokenBy: range].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualCoordinateSpace completeMapping: ((XuPromise getActual: range) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuOrderSpec} descending

	"The mirror image of the partial order returned by 'CoordinateSpace::ascending'."
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualCoordinateSpace descending)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} emptyRegion

	"Essential.  An empty region in this coordinate space"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualCoordinateSpace emptyRegion)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} fullRegion

	"A full region in this coordinate space"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualCoordinateSpace fullRegion)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} identityMapping

	"Essential.  A Mapping which maps all positions in the coordinate space onto themselves"
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualCoordinateSpace identityMapping)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCoordinateSpace methodsFor: 'promise access'!

{CoordinateSpace} getActualCoordinateSpace
	self isBroken
		ifFalse: [^super actualThing cast: CoordinateSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCoordinateSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anCoordinateSpace {CoordinateSpace}
	super create: anCoordinateSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCoordinateSpace class
	instanceVariableNames: ''!

(XuCoordinateSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCoordinateSpace class methodsFor: 'pseudo-constructors'!

make: anCoordinateSpace {CoordinateSpace}
	^self create: anCoordinateSpace!

{XuCoordinateSpace} makeBroken: problem {Problem star}
	| broke {XuCoordinateSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCoordinateSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
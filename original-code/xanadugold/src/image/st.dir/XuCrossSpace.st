'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:12 pm'!

XuCoordinateSpace subclass: #XuCrossSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
XuCrossSpace comment:
'Represents the cross of several coordinate spaces.  '!

(XuCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossSpace methodsFor: 'accessing'!

{XuPtrArray} axes

	"Essential.  The base spaces that I am a cross of."
	
	| retVal {XuPtrArray} |
	(self isBroken) ifTrue:
		[^XuPtrArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPtrArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPtrArray make: (self getActualCrossSpace axes)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCoordinateSpace} axis: dimension {XuIntValue} 

	"The sub coordinate space on the given axis"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].
	(dimension isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: dimension].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualCrossSpace axis:dimension getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} axisCount

	"The number of dimensions in this space"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualCrossSpace axisCount)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCrossSpace methodsFor: 'making'!

{XuMapping} crossOfMappings: subMappings {XuPtrArray default: DefaultNull} 

	"Essential.  Map each coordinate according to the mapping from its space.  NULLs mean 'use the identity mapping'"
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(subMappings isBroken) ifTrue:
		[^XuMapping makeBrokenBy: subMappings].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualCrossSpace crossOfMappings: ((XuPromise getActual: subMappings) cast: PtrArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossOrderSpec} crossOfOrderSpecs: subOrderings {XuPtrArray default: DefaultNull} with: subSpaceOrdering {XuIntArray default: DefaultNull} 

	"Essential.  Make a lexical ordering of all elements in the space, using the given ordering for each sub space. If no sub space ordering is given, then it is in the order they are in the array.
	
	subSpaceOrdering lists the lexicographic order in which each dimension should be processed.  Every dimension should be listed exactly one, from most significant (at index 0) to least significant.

	subOrderings are indexed by *dimension*, not by lexicographic order.  In order to index by lex order, look up the dimension in subSpaceOrdering, and then look up the resulting dimension number in subOrderings."
	
	| retVal {XuCrossOrderSpec} |
	(self isBroken) ifTrue:
		[^XuCrossOrderSpec makeBrokenBy: self].
	(subOrderings isBroken) ifTrue:
		[^XuCrossOrderSpec makeBrokenBy: subOrderings].
	(subSpaceOrdering isBroken) ifTrue:
		[^XuCrossOrderSpec makeBrokenBy: subSpaceOrdering].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossOrderSpec make: (self getActualCrossSpace crossOfOrderSpecs: ((XuPromise getActual: subOrderings) cast: PtrArray) with: ((XuPromise getActual: subSpaceOrdering) cast: PrimIntArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuTuple} crossOfPositions: coordinates {XuPtrArray} 

	"Essential. Make an individual position"
	
	| retVal {XuTuple} |
	(self isBroken) ifTrue:
		[^XuTuple makeBrokenBy: self].
	(coordinates isBroken) ifTrue:
		[^XuTuple makeBrokenBy: coordinates].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuTuple makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuTuple make: (self getActualCrossSpace crossOfPositions: ((XuPromise getActual: coordinates) cast: PtrArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} crossOfRegions: subRegions {XuPtrArray} 

	"Essential. Make a 'rectangular' region as a cross of all the given regions"
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].
	(subRegions isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: subRegions].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualCrossSpace crossOfRegions: ((XuPromise getActual: subRegions) cast: PtrArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossRegion} extrusion: dimension {XuIntValue} with: subRegion {XuRegion} 

	"Return a region whose projection is 'subRegion' along 'dimension', but is full on all other dimensions"
	
	| retVal {XuCrossRegion} |
	(self isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: self].
	(dimension isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: dimension].
	(subRegion isBroken) ifTrue:
		[^XuCrossRegion makeBrokenBy: subRegion].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossRegion make: (self getActualCrossSpace extrusion:dimension getActualInt32 with: ((XuPromise getActual: subRegion) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCrossSpace methodsFor: 'promise access'!

{CrossSpace} getActualCrossSpace
	self isBroken
		ifFalse: [^super actualThing cast: CrossSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCrossSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anCrossSpace {CrossSpace}
	super create: anCrossSpace.! !

!XuCrossSpace methodsFor: 'smalltalk: defaults'!

{XuMapping} crossOfMappings

	"This method has no comment."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualCrossSpace crossOfMappings)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCrossOrderSpec} crossOfOrderSpecs

	^self  crossOfOrderSpecs: DefaultNull!

{XuCrossOrderSpec} crossOfOrderSpecs: subOrderings {XuPtrArray default: DefaultNull} 

	"This method has no comment."
	
	| retVal {XuCrossOrderSpec} |
	(self isBroken) ifTrue:
		[^XuCrossOrderSpec makeBrokenBy: self].
	(subOrderings isBroken) ifTrue:
		[^XuCrossOrderSpec makeBrokenBy: subOrderings].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCrossOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCrossOrderSpec make: (self getActualCrossSpace crossOfOrderSpecs: ((XuPromise getActual: subOrderings) cast: PtrArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCrossSpace class
	instanceVariableNames: ''!

(XuCrossSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossSpace class methodsFor: 'pseudo-constructors'!

make: anCrossSpace {CrossSpace}
	^self create: anCrossSpace!

{XuCrossSpace} makeBroken: problem {Problem star}
	| broke {XuCrossSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCrossSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
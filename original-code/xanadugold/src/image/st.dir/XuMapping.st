'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:59 pm'!

XuPromise subclass: #XuMapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
XuMapping comment:
'A mapping is a general mapping from one coordinate space to another, with few of the guarantees provided by Dsps.  In particular, the source and destination coordinate spaces can be different, and the mapping doesn''t have to be everywhere defined (but it has to say where it is defined via "domain" and "range" messages).  A mapping doesn''t have to be unique--the same domain position may map to multiple range positions and vice versa.  A mapping of a XuRegion must yield another XuRegion, but a mapping of a simple region doesn''t have to yield a simple region.
	
	A useful and valid way to think of a Mapping is as a (possibly infinite) set of pairs (a mathematical set, not a ScruSet).  The domain region consists of the first elements of each pair, and the range region consists of the second elements.
	
	A mapping is most useful as a representation of a version comparison of two different organizations of common elements.  The mapping would tell how positions in one organization correspond to positions in the other.'!

(XuMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMapping methodsFor: 'mapping'!

{XuPosition} of: before {XuPosition} 

	"Transform a position. 'before' must be a Position of my domain space. Iff 'before' is in the domain region over which I am defined and it maps to a unique range Position then the result will be that Position. Otherwise BLAST. For example, if I map 1 to 4, 1 to 5, and 2 to 5 (and nothing else), then this method will yield 5 given 2, but BLAST given anything else. To find all the values 1 maps to, use the 'ofAll' operation on the singleton region whose member is 1."
	
	| retVal {XuPosition} |
	(self isBroken) ifTrue:
		[^XuPosition makeBrokenBy: self].
	(before isBroken) ifTrue:
		[^XuPosition makeBrokenBy: before].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPosition make: (self getActualMapping of: ((XuPromise getActual: before) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} ofAll: before {XuRegion} 

	"Essential.  Transform a region. The result region has exactly those positions which are the mappings of the positions in 'before'. This must be the case even if these positions cannot be enumerated. If the mapping for a given position is multiply defined, then (if that position is in 'before') all position it maps to must be in the result. Because of this property, the behavior of this method must be taken as really defining the nature of a particular mapping (with other method's behavior being defined in terms of this one), despite the fact that it would have been more natural to take Mapping::of(Position *) as the defining behavior."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(before isBroken) ifTrue:
		[^XuRegion makeBrokenBy: before].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualMapping ofAll: ((XuPromise getActual: before) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuMapping methodsFor: 'accessing'!

{XuRegion} domain

	"Essential.  region in which it is valid."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualMapping domain)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCoordinateSpace} domainSpace

	"The coordinate space of the domain of the Mapping"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualMapping domainSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isComplete

	"Essential. Return true if each Position in the domain is mapped to every Position in the range."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualMapping isComplete)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isIdentity

	"Essential. True if this is the identify mapping on the entire space."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualMapping isIdentity)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRegion} range

	"Essential.  region in which inverse is valid.  Same as the region that the domain region maps to. For you mathematicians, it is the image of the domain under the mapping."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualMapping range)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCoordinateSpace} rangeSpace

	"The coordinate space of the range of the transformation"
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualMapping rangeSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} simplerMappings

	"Essential. Break this Mapping up into simpler Mappings which can be combined together to get this one."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualMapping simplerMappings)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} unrestricted

	"Essential. If this is a 'simpler' Mapping, and not isFull, then return a yet simpleMapping of some class from which you can get more information. Note that m->restrict (region)->unrestricted () is not necessarily the same as m, since information may be lost."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualMapping unrestricted)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuMapping methodsFor: 'promise access'!

{Mapping} getActualMapping
	self isBroken
		ifFalse: [^super actualThing cast: Mapping.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMapping methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anMapping {Mapping}
	super create: anMapping.! !

!XuMapping methodsFor: 'operations'!

{XuMapping} combine: other {XuMapping} 

	"Essential.  Result will do both mine and other's mappings.  It will do my mapping where I am defined, and it will do the other's where his is defined.  If we are both defined over some domain positions, then the result is a multi-valued mapping.  If you think of a Mapping simply as a set of pairs (see class comment), then 'combine' yields a Mapping consisting of the union of these two sets."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMapping makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualMapping combine: ((XuPromise getActual: other) cast: Mapping))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} inverse

	"Essential. Return the inverse of this transformation. Considering the Mapping as a set of pairs (see class comment), return the Dsp which has the mirror image of all my pairs."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualMapping inverse)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMapping} restrict: region {XuRegion} 

	"Essential.  Restrict the domain.  The domain of the result will be the intersection of my domain and 'region'.  Otherwise we are the same."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuMapping makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualMapping restrict: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMapping class
	instanceVariableNames: ''!

(XuMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMapping class methodsFor: 'pseudo-constructors'!

make: anMapping {Mapping}
	^self create: anMapping!

{XuMapping} makeBroken: problem {Problem star}
	| broke {XuMapping} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMapping} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
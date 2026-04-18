'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:17 pm'!

XuCoordinateSpace subclass: #XuFilterSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!
XuFilterSpace comment:
'A FilterSpace can be described mathematically as a power space of its baseSpace, i.e. the set of all subsets of the baseSpace. Each position in a FilterSpace is a Region in the baseSpace, and each Filter is a set of Regions taken from the baseSpace. See Filter for more detail.'!

(XuFilterSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilterSpace methodsFor: 'promise access'!

{FilterSpace} getActualFilterSpace
	self isBroken
		ifFalse: [^super actualThing cast: FilterSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFilterSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFilterSpace {FilterSpace}
	super create: anFilterSpace.! !

!XuFilterSpace methodsFor: 'making'!

{XuFilter} allFilter: region {XuRegion} 

	"Essential. A region that matches any region that contains all the Positions in, i.e. is a superset of, the given region."
	
	| retVal {XuFilter} |
	(self isBroken) ifTrue:
		[^XuFilter makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuFilter makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFilter makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFilter make: (self getActualFilterSpace allFilter: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuFilter} anyFilter: baseRegion {XuRegion} 

	"Essential. A filter that matches any region that intersects the given region."
	
	| retVal {XuFilter} |
	(self isBroken) ifTrue:
		[^XuFilter makeBrokenBy: self].
	(baseRegion isBroken) ifTrue:
		[^XuFilter makeBrokenBy: baseRegion].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFilter makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFilter make: (self getActualFilterSpace anyFilter: ((XuPromise getActual: baseRegion) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuFilterPosition} position: baseRegion {XuRegion} 

	"Essential. Given a Region in the baseSpace, make a Position which corresponds to it, so that
		filter->hasMember (this->position (baseRegion)) iff filter->match (baseRegion)"
	
	| retVal {XuFilterPosition} |
	(self isBroken) ifTrue:
		[^XuFilterPosition makeBrokenBy: self].
	(baseRegion isBroken) ifTrue:
		[^XuFilterPosition makeBrokenBy: baseRegion].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFilterPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFilterPosition make: (self getActualFilterSpace position: ((XuPromise getActual: baseRegion) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuFilterSpace methodsFor: 'accessing'!

{XuCoordinateSpace} baseSpace

	"Essential.  The CoordinateSpace of the Regions that are the input to Filters in this FilterSpace."
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualFilterSpace baseSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFilterSpace class
	instanceVariableNames: ''!

(XuFilterSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilterSpace class methodsFor: 'pseudo-constructors'!

make: anFilterSpace {FilterSpace}
	^self create: anFilterSpace!

{XuFilterSpace} makeBroken: problem {Problem star}
	| broke {XuFilterSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFilterSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
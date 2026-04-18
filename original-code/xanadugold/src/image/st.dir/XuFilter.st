'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:16 pm'!

XuRegion subclass: #XuFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!
XuFilter comment:
'A position in a FilterSpace is a region in the baseSpace, and a filter is a set of regions in the baseSpace. It is often more useful to think of a Filter as a Boolean function whose input is a region in the baseSpace, and of unions, intersections, and complements of filters as ORs, ANDs, and NOTs of functions. Not all possible such functions can be represented as Filters, since there is an uncountable infinity of them for any non-finite CoordinateSpace. There are representations for some basic filters, and any filters resulting from a finite sequence of unions, intersections, and complements among them. The basic filters are:
	subsetFilter(cs,R) -- all subsets of R (i.e. all R1 such that R1->isSubsetOf(R))
	supersetFilter(cs,R) -- all supersets of R (i.e. all R1 such that R->isSubsetOf(R1))
Mathematically, this is all that is necessary, since other useful filters like intersection filters can be generated from these. (e.g. intersectionFilter(R) is subsetFilter(R->complement())->complement()). However, there are several more pseudo constructors provided as shortcuts, including intersectionFilters, closedFilters, emptyFilters, and intersections and unions of sets of filters.'!

(XuFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilter methodsFor: 'filtering'!

{XuIntValue} match: region {XuRegion} 

	"Whether a region is inside this filter."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(region isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: region].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFilter match: ((XuPromise getActual: region) cast: XnRegion))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuFilter methodsFor: 'promise access'!

{Filter} getActualFilter
	self isBroken
		ifFalse: [^super actualThing cast: Filter.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFilter methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFilter {Filter}
	super create: anFilter.! !

!XuFilter methodsFor: 'accessing'!

{XuRegion} baseRegion

	"Essential. A region in the base space identifying what kind of filter this is. Succeeds only if this isAnyFilter or isAllFilter."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFilter baseRegion)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuFilter methodsFor: 'enumerating'!

{XuStepper} intersectedFilters

	"Essential. Break this up into a bunch of Filters which when intersected (anded) together give this one. If there is only one sub Filter it will be the receiver; otherwise, the sub Filters will be simple enough that either they or their complements will return true from at least one of isAndFilter or isOrFilter. If this is full (i.e. an open filter) then the stepper will have no elements."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFilter intersectedFilters)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} unionedFilters

	"Essential. Break this up into a bunch of Filters which when unioned (ored) together give this one. If there is only one sub Filter it will be the receiver; otherwise, the sub Filters will be simple enough that either they or their complements will return true from at least one of isAndFilter or isOrFilter. The sub Filters might not be disjoint Regions. If this is empty (i.e. a closed filter) then the stepper will have no elements."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFilter unionedFilters)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuFilter methodsFor: 'testing'!

{XuIntValue} isAllFilter

	"Essential. Whether this is an 'all' Filter, i.e. it only matches Regions which contain everything in the baseRegion"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFilter isAllFilter)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isAnyFilter

	"Essential. Whether this is an 'any' Filter, i.e. it matches Regions which contain anything in the baseRegion"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFilter isAnyFilter)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFilter class
	instanceVariableNames: ''!

(XuFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilter class methodsFor: 'pseudo-constructors'!

make: anFilter {Filter}
	^self create: anFilter!

{XuFilter} makeBroken: problem {Problem star}
	| broke {XuFilter} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFilter} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
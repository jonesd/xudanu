'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:00 pm'!

XuPromise subclass: #XuOrderSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
XuOrderSpec comment:
'[documentation note: we need to hide the documentation about partial orders, but still warn that the orders may become partial]. An OrderSpec for a given coordinate space represents a partial ordering of all the Positions of that coordinate space.  The fundamental ordering relationship is "follows".  The response of Positions to isGE defines the natural, "ascending" partial order among the positions.  Every coordinate space will have at least this ascending and the corresponding descending OrderSpecs.  OrderSpecs are useful to specify in what order a stepper produced for stepping over positions should do so.'!

(XuOrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuOrderSpec methodsFor: 'accessing'!

{XuCoordinateSpace} coordinateSpace

	"Essential.  Like Positions, Dsps, and XuRegions, an OrderSpec is specific to one coordinate space.  It is an error to use the generic protocol on objects from different coordinate spaces."
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualOrderSpec coordinateSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuOrderSpec} reversed

	"Returns an OrderSpec representing the mirror image of my ordering.
	o->follows(a, b) iff o->reverse()->follows(b, a)"
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualOrderSpec reversed)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuOrderSpec methodsFor: 'promise access'!

{OrderSpec} getActualOrderSpec
	self isBroken
		ifFalse: [^super actualThing cast: OrderSpec.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuOrderSpec methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anOrderSpec {OrderSpec}
	super create: anOrderSpec.! !

!XuOrderSpec methodsFor: 'testing'!

{XuIntValue} follows: x {XuPosition} with: y {XuPosition} 

	"Essential.  Compare the two and return true if x is known to follow y in the ordering.  This message is the 'greater than or equal to' equivalent for this ordering.  It must have those properties a mathematician would demand of a '>=' on a partial order:
		os->follows(a, a)   (reflexivity)
		os->follows(a, b) && os->follows(b, c) implies os->follows(a, c)  (transitivity)
		os->follows(a, b) && os->follows(b, a) implies a->isEqual(b)  (what's the name for this?)"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(x isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: x].
	(y isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: y].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualOrderSpec follows: ((XuPromise getActual: x) cast: Position) with: ((XuPromise getActual: y) cast: Position))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuOrderSpec class
	instanceVariableNames: ''!

(XuOrderSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuOrderSpec class methodsFor: 'pseudo-constructors'!

make: anOrderSpec {OrderSpec}
	^self create: anOrderSpec!

{XuOrderSpec} makeBroken: problem {Problem star}
	| broke {XuOrderSpec} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuOrderSpec} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
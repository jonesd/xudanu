'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:59 pm'!

XuCoordinateSpace subclass: #XuRealSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuRealSpace comment:
'Non-arithmetic space of real numbers in which only certain positions are explicitly representable.  In this release, the only exactly representable numbers are those real numbers which can be represented in IEEE64 (double precision) format.  Future releases may make more real numbers representable.'!

(XuRealSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRealSpace methodsFor: 'making'!

{XuRealRegion} above: val {XuReal} with: inclusive {XuIntValue} 

	"The region consisting of all positions >= val if inclusive, or all > val if not inclusive."
	
	| retVal {XuRealRegion} |
	(self isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: self].
	(val isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: val].
	(inclusive isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRealRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRealRegion make: (self getActualRealSpace above: ((XuPromise getActual: val) cast: RealPos) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRealRegion} below: val {XuReal} with: inclusive {XuIntValue} 

	"The region consisting of all positions <= val if inclusive, or all < val if not inclusive."
	
	| retVal {XuRealRegion} |
	(self isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: self].
	(val isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: val].
	(inclusive isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRealRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRealRegion make: (self getActualRealSpace below: ((XuPromise getActual: val) cast: RealPos) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRealRegion} interval: start {XuReal} with: stop {XuReal} 

	"Return a region of all numbers >= lower and < upper."
	
	| retVal {XuRealRegion} |
	(self isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: self].
	(start isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: start].
	(stop isBroken) ifTrue:
		[^XuRealRegion makeBrokenBy: stop].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRealRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRealRegion make: (self getActualRealSpace interval: ((XuPromise getActual: start) cast: RealPos) with: ((XuPromise getActual: stop) cast: RealPos))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuReal} position: val {XuFloatValue} 

	"The XuReal representing the same real number as that exactly represented by 'val'.  If 'val' doesn't represent a real number (i.e., it is an infinity or a NAN), then this message BLASTs.  If 'val' is a negative zero, it is silently converted to a positive zero"
	
	| retVal {XuReal} |
	(self isBroken) ifTrue:
		[^XuReal makeBrokenBy: self].
	(val isBroken) ifTrue:
		[^XuReal makeBrokenBy: val].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuReal makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuReal make: (self getActualRealSpace position:val getActualIEEE64)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRealSpace methodsFor: 'promise access'!

{RealSpace} getActualRealSpace
	self isBroken
		ifFalse: [^super actualThing cast: RealSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRealSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anRealSpace {RealSpace}
	super create: anRealSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRealSpace class
	instanceVariableNames: ''!

(XuRealSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRealSpace class methodsFor: 'pseudo-constructors'!

make: anRealSpace {RealSpace}
	^self create: anRealSpace!

{XuRealSpace} makeBroken: problem {Problem star}
	| broke {XuRealSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRealSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
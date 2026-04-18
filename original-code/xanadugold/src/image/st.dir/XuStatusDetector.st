'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:30 pm'!

XuPromise subclass: #XuStatusDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
XuStatusDetector comment:
'Is notified of changes in the capability of a Work object.'!

(XuStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuStatusDetector methodsFor: 'promise access'!

{FeStatusDetector} getActualFeStatusDetector
	self isBroken
		ifFalse: [^super actualThing cast: FeStatusDetector.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuStatusDetector methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeStatusDetector {FeStatusDetector}
	super create: anFeStatusDetector.! !

!XuStatusDetector methodsFor: 'triggering'!

{XuVoid} grabbed: work {XuWork} with: author {XuID} with: reason {XuIntValue} 

	"Essential. The Work has been grabbed, or regrabbed."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(work isBroken) ifTrue:
		[^XuVoid makeBrokenBy: work].
	(author isBroken) ifTrue:
		[^XuVoid makeBrokenBy: author].
	(reason isBroken) ifTrue:
		[^XuVoid makeBrokenBy: reason].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeStatusDetector grabbed: ((XuPromise getActual: work) cast: FeWork) with: ((XuPromise getActual: author) cast: ID) with:reason getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} released: work {XuWork} with: reason {XuIntValue} 

	"Essential. The revise capability of the Work has been lost."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(work isBroken) ifTrue:
		[^XuVoid makeBrokenBy: work].
	(reason isBroken) ifTrue:
		[^XuVoid makeBrokenBy: reason].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeStatusDetector released: ((XuPromise getActual: work) cast: FeWork) with:reason getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuStatusDetector class
	instanceVariableNames: ''!

(XuStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuStatusDetector class methodsFor: 'pseudo-constructors'!

make: anFeStatusDetector {FeStatusDetector}
	^self create: anFeStatusDetector!

{XuStatusDetector} makeBroken: problem {Problem star}
	| broke {XuStatusDetector} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuStatusDetector} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
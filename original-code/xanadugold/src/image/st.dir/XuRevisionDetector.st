'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:30 pm'!

XuPromise subclass: #XuRevisionDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
XuRevisionDetector comment:
'Client defines subclasses and passes in an instance in order to be notified of revisions to a Work'!

(XuRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRevisionDetector methodsFor: 'promise access'!

{FeRevisionDetector} getActualFeRevisionDetector
	self isBroken
		ifFalse: [^super actualThing cast: FeRevisionDetector.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRevisionDetector methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeRevisionDetector {FeRevisionDetector}
	super create: anFeRevisionDetector.! !

!XuRevisionDetector methodsFor: 'triggering'!

{XuVoid} revised: work {XuWork} with: contents {XuEdition} with: author {XuID} with: time {XuIntValue} with: sequence {XuIntValue} 

	"Essential. The Work has been revised. Gives the Work, the current Edition, the author ID who had it grabbed, the sequence number of the revision to the Work, and the clock time on the Server (note that the clock time is only as reliable as the Server's operating system, which is usually not very)."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(work isBroken) ifTrue:
		[^XuVoid makeBrokenBy: work].
	(contents isBroken) ifTrue:
		[^XuVoid makeBrokenBy: contents].
	(author isBroken) ifTrue:
		[^XuVoid makeBrokenBy: author].
	(time isBroken) ifTrue:
		[^XuVoid makeBrokenBy: time].
	(sequence isBroken) ifTrue:
		[^XuVoid makeBrokenBy: sequence].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeRevisionDetector revised: ((XuPromise getActual: work) cast: FeWork) with: ((XuPromise getActual: contents) cast: FeEdition) with: ((XuPromise getActual: author) cast: ID) with:time getActualIntegerVar with:sequence getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRevisionDetector class
	instanceVariableNames: ''!

(XuRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRevisionDetector class methodsFor: 'pseudo-constructors'!

make: anFeRevisionDetector {FeRevisionDetector}
	^self create: anFeRevisionDetector!

{XuRevisionDetector} makeBroken: problem {Problem star}
	| broke {XuRevisionDetector} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRevisionDetector} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
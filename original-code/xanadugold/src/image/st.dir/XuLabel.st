'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:16 pm'!

XuRangeElement subclass: #XuLabel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuLabel comment:
'An identity attached to a RangeElement within an Edition.'!

(XuLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLabel methodsFor: 'promise access'!

{FeLabel} getActualFeLabel
	self isBroken
		ifFalse: [^super actualThing cast: FeLabel.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuLabel methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeLabel {FeLabel}
	super create: anFeLabel.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuLabel class
	instanceVariableNames: ''!

(XuLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLabel class methodsFor: 'pseudo-constructors'!

make: anFeLabel {FeLabel}
	^self create: anFeLabel!

{XuLabel} makeBroken: problem {Problem star}
	| broke {XuLabel} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuLabel} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
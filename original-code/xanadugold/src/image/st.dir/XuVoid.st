'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:07 pm'!

XuPromise subclass: #XuVoid
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-promise'!

(XuVoid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuVoid methodsFor: 'creation'!

create

 	super create.!

create.Problem: problem {Problem}

	super create.Problem: problem.!

create.Promise: promise {XuPromise}

	super create.Promise: promise.! !

!XuVoid methodsFor: 'accessing'!

{void} value

	self isForced ifFalse: [ Heaper BLAST: #UnforcedValue].
	self isBroken ifTrue: [self explode].
	^VOID.! !

!XuVoid methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'Xu(Void)'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuVoid class
	instanceVariableNames: ''!

(XuVoid getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuVoid class methodsFor: 'pseudo-constructors'!

make

	^self create.!

{XuVoid} makeBroken: problem {Problem}

	^self create.Problem: problem.!

{XuVoid} makeBrokenBy: broken {XuPromise}

	^self create.Promise: broken.! !

!XuVoid class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ true! !
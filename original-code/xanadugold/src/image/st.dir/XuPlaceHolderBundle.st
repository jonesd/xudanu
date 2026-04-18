'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:16 pm'!

XuBundle subclass: #XuPlaceHolderBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuPlaceHolderBundle comment:
'Describes a region of an Edition in which all indices in my region have a distinct PlaceHolder.'!

(XuPlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPlaceHolderBundle methodsFor: 'promise access'!

{FePlaceHolderBundle} getActualFePlaceHolderBundle
	self isBroken
		ifFalse: [^super actualThing cast: FePlaceHolderBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuPlaceHolderBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFePlaceHolderBundle {FePlaceHolderBundle}
	super create: anFePlaceHolderBundle.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPlaceHolderBundle class
	instanceVariableNames: ''!

(XuPlaceHolderBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPlaceHolderBundle class methodsFor: 'pseudo-constructors'!

make: anFePlaceHolderBundle {FePlaceHolderBundle}
	^self create: anFePlaceHolderBundle!

{XuPlaceHolderBundle} makeBroken: problem {Problem star}
	| broke {XuPlaceHolderBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPlaceHolderBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
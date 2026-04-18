'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:47 pm'!

XuStepper subclass: #XuTableStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
XuTableStepper comment:
'For enumerating the key->value associations of a table.  A typical use (for a table whose range elements were all Foos) might be:
	
	SPTR(TableStepper) stomp = table->stepper();
	FOR_EACH(Foo,f,stomp, {
		doSomethingWith(stomp->key(), z);
	});
	
	Each iteration of the loop would correspond to an association of the table (snapshotted at the time "->stepper()" was sent).  For each association, "f" (a pointer to Foo) points at the range element, while "stomp->key()" provides the domain element.  See ScruTable::stepper.'!

(XuTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuTableStepper methodsFor: 'promise access'!

{TableStepper} getActualTableStepper
	self isBroken
		ifFalse: [^super actualThing cast: TableStepper.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuTableStepper methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anTableStepper {TableStepper}
	super create: anTableStepper.! !

!XuTableStepper methodsFor: 'operations'!

{XuArray} stepManyPairs: count {XuIntValue default: DefaultMinusOne} 

	"An array of the remaining elements in alternating positions in the array
		[k1, v1, k2, v2, k3, v3, ...]
	Returns an array of up to count * 2 elements (or some arbitrary number if count is negative), and steps the stepper the corresponding number of times. You should check whether the stepper is atEnd, since it can stop before the number you give it because of some internal limit or grouping issue."
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].
	(count isBroken) ifTrue:
		[^XuArray makeBrokenBy: count].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualTableStepper stepManyPairs:count getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuTableStepper methodsFor: 'smalltalk: defaults'!

{XuArray} stepManyPairs

	"This method has no comment."
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualTableStepper stepManyPairs)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuTableStepper methodsFor: 'special'!

{XuPosition} position

	"A TableStepper actually enumerates the associations of a table. Through the normal Stepper protocol, it makes available the range element of the current association. Through this additional protocol, it make accessible the key of the current association.  This message returns the same object as TwoStepper::other, the only difference being the static knowledge that it's a Position."
	
	| retVal {XuPosition} |
	(self isBroken) ifTrue:
		[^XuPosition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPosition make: (self getActualTableStepper position)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuTableStepper class
	instanceVariableNames: ''!

(XuTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuTableStepper class methodsFor: 'pseudo-constructors'!

make: anTableStepper {TableStepper}
	^self create: anTableStepper!

{XuTableStepper} makeBroken: problem {Problem star}
	| broke {XuTableStepper} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuTableStepper} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
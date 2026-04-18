'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:19 pm'!

XuPosition subclass: #XuInteger
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
XuInteger comment:
'Because of the constraints of C++, we have two very different types representing integers in our system.  
	
	XuInteger is the boxed representation which must be used in any context which only knows that it is dealing with a Position.  XuInteger is a Heaper with all that implies.  Specifically, one can take advantage of all the advantages of polymorphism (leading to uses by code that only knows it is dealing with a Position), but at the cost of representing each value by a heap allocated object to which pointers are passed.  Such a representation is referred to as "boxed" because the pointer combined with the storage structure overhead of maintaining a heap allocated object constitutes a "box" between the user of the data (the guy holding onto the pointer), and the actual data (which is inside the Heaper).
	
	In contrast, IntegerVar is the efficient, unboxed representation of an integer.  (actually, it is only unboxed so long as it fits within some size limit such as 32 bits.  Those IntegerVars that exceed this limit pay their own boxing cost to store their representation on the heap.  This need not concern us here.)  See "The Var vs Heaper distinction" and IntegerVar.  When we know that we are dealing specifically with an integer, we`d like to be able to stick with IntegerVars without having to convert them to XuIntegers.  However, we`d like to be able to do everything that we could normally do if we had an XuInteger.
	
	For this purpose, many messages (such as Position * Dsp::of(Position*)) have an additional overloading (IntegerVar Dsp::of(IntegerVar)) whose semantics is defined in terms of converting the argument to an XuInteger, applying the original operation, and converting the result (which is asserted to be an XuInteger) back to an IntegerVar.  Dsp even provides a default implementation to do exactly that.  However, if we actually rely on this default implementation then we are defeating the whole purpose of avoiding boxing overhead.  Instead, IntegerDsp overrides this to provide an efficient implementation.  
	
	Any particular case may at the moment simply be relying on the default.  The point is to get interfaces defined early which allow efficiency tuning to proceed in a modular fashion later.  Should any particular reliance on the default actually prove to be an efficiency issue, we will deal with it then.'!

(XuInteger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuInteger methodsFor: 'promise access'!

{IntegerPos} getActualIntegerPos
	self isBroken
		ifFalse: [^super actualThing cast: IntegerPos.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuInteger methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anIntegerPos {IntegerPos}
	super create: anIntegerPos.! !

!XuInteger methodsFor: 'accessing'!

{XuIntValue} value

	"Essential.  Unboxed version.  See class comment"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualIntegerPos value)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuInteger class
	instanceVariableNames: ''!

(XuInteger getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuInteger class methodsFor: 'pseudo-constructors'!

make: anIntegerPos {IntegerPos}
	^self create: anIntegerPos!

{XuInteger} makeBroken: problem {Problem star}
	| broke {XuInteger} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuInteger} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:22 pm'!

Stepper subclass: #RealStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-id'!

(RealStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!RealStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	"If I am exhausted (i.e., if (!! this->hasValue())), then return NULL. Else return 
	current element.  I return wimpily since most items returned are held by collections.
	If I create a new object, I should cache it."

	MarkM shouldImplement.
	^NULL "fodder"!

{BooleanVar} hasValue
	"Iff I have a current value (i.e. this message returns true), then I am not 
	exhasted. 'fetch' and 'get' will both return this value, and I can be 'step'ped to 
	my next state. As I am stepped, eventually I may become exhausted (the 
	reverse of all the above), which is a permanent condition. 
	
	Note that not all steppers have to be exhaustable. A Stepper which 
	enumerates all primes is perfectly reasonable. Assuming otherwise will create 
	infinite loops.  See class comment."

	MarkM shouldImplement.
	^false "fodder"!

{void} step
	"Essential.  If I am currently exhausted (see Stepper::hasValue()), then it is an error to step me. The result of doing so isn't currently specified (we probably should specify it to BLAST, but I know that the implementation doesn't currently live up to that spec). 
	
	If I am not exhausted, then this advances me to my next state. If my current value (see Stepper::get()) was my final value, then I am now exhausted, otherwise my new current value is the next value."

	MarkM shouldImplement! !

!RealStepper methodsFor: 'create'!

{Stepper} copy
	"Return a new stepper which steps independently of me, but whose current 
	value is the same as mine, and which must produce a future history of values 
	which satisfies the same obligation that my contract obligates me to produce 
	now. Typically, this will mean that he must produce the same future history 
	that I'm going to produce. However, let's say that I am enumerating the 
	elements of a partial order in some full order which is consistent with the 
	partial order. If a copy of me is made after I'm part way through, then me 
	and my copy may produce any future history compatable both with the partial 
	order and the elements I've already produced by the time of the copy. Of 
	course, a subclass or a Stepper creating message (like 
	IntegerRegion::stepper()) may specify the more stringent requirement (that a 
	copy must produce the same sequence). 
	
	To prevent aliasing, Steppers should typically be passed by copy. See class 
	comment."

	MarkM shouldImplement.
	^NULL "fodder"!

create: transitions {PtrArray}! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:46 pm'!

XuPromise subclass: #XuStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
XuStepper comment:
'Steppers provide a common way to enumerate the elements of any abstraction which acts as a collection.  This simplifies the protocols of the various collection classes, as they now merely have to provide messages to create the appropriate steppers, which then handle the rest of the job.  Also, the Stepper steps over the set of elements which existed *at the time* the stepper was returned.  If you''re stepping over the elements of a changable collection, and the elements are changing while you are stepping, any other rule could lead to confusion.
	
	Smalltalk''s collections provide the protocol to enumerate their elements directly.  Having the collection change during stepping is the source of a famous Smalltalk bug. Clu and Alphard both have "Iterators" which are much like our Steppers, but these other languages both specify (as a pre-condition) that the collection not be changed while the Iterator is active.  This burdens the programmer with ensuring a non-local property that we know of know way of robustly checking for in real programs.
	
	Steppers and Accumulators are sort of duals.  Steppers are typically used in loops as a source of values to be consumed by the loop body.  Accumulators are typically used as a sink for values which are produced in the loop body.  One can (and sometimes does) interact with a Stepper explicitly through its protocol.  However, for the typical case of just executing a loop body in turn for each successive element should be written using the FOR_EACH macro.  The syntax of the macro is:
	
	FOR_EACH(ElementType,varName, (stepperValuedExpr), {
		Loop body (varName is in scope)
		});
	
	For example:
	
	FOR_EACH(Position,each,(reg->stepper()), {
		doSomethingWith (each);
		});
		
	is roughly equivalent to (see macro definition for exact equivalence):
	
	for(SPTR(Stepper) stomp = reg->stepper(); stomp->hasValue(); stomp->step()) {
		SPTR(Position) each = CAST(Position,stomp->fetch());
		doSomethingWith (each);
	}
	stomp->destroy();
	
	Since the Stepper is necessarily exhausted if we fall out the end of a FOR_EACH, and there isn''t anything useful we can do with an exhausted stepper, it''s no great loss for FOR_EACH to destroy it.  Doing so substantially unburdens the garbage collector.  In addition, the means we are planning to use to lower the overhead of having the Stepper step over a snapshot of the collection depends on (for its efficiency) the Stepper being destroyed promptly if it is dropped without stepping it to exhaustion.
	
	Not all Steppers will eventually terminate.  For example, a Stepper which enumerates all the primes is perfectly reasonable.  When using Steppers (and especially FOR_EACH), you should be confident that you haven''t just introduced an infinite loop into your program.  See Stepper::hasValue().
	
	It is normally considered bad style for two methods/functions to be pointing at the same Stepper.  As long as Steppers are used locally and without aliasing (i.e., as if they were pass-by-value Vars), these implementationally side-effecty objects can be understood applicatively.  If a copy of an Stepper can be passed instead of a pointer to the same one, this is to be prefered.  See Accumulator.
	
	Subclasses of Stepper can provide more protocol.  See TableStepper.'!

(XuStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuStepper methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anStepper {Stepper}
	super create: anStepper.! !

!XuStepper methodsFor: 'operations'!

{XuIntValue} atEnd

	"Iff I have a current value (i.e. this message returns FALSE), then I am not exhasted. 'fetch' and 'get' will both return this value, and I can be 'step'ped to my next state. As I am stepped, eventually I may become exhausted (the reverse of all the above), which is a permanent condition. 
	
	Note that not all steppers have to be exhaustable. A Stepper which enumerates all primes is perfectly reasonable. Assuming otherwise will create infinite loops.  See class comment."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualStepper atEnd)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPromise} get

	"Essential.  BLAST if exhasted.  Else return current element. I return wimpily since most items returned are held by collections. If I create a new object, I should cache it."
	
	| retVal {XuPromise} |
	(self isBroken) ifTrue:
		[^XuPromise makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPromise makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPromise make: (self getActualStepper get)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} step

	"Essential.  If I am currently exhausted (see Stepper::hasValue()), then it is an error to step me. The result of doing so isn't currently specified (we probably should specify it to BLAST, but I know that the implementation doesn't currently live up to that spec). 
	
	If I am not exhausted, then this advances me to my next state. If my current value (see Stepper::get()) was my final value, then I am now exhausted, otherwise my new current value is the next value."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualStepper step)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuArray} stepMany: count {XuIntValue default: DefaultMinusOne} 

	"Collects the remaining elements in the stepper into an array. Returns an array of no more than count elements (or some arbitrary chunk if the count is negative). The fact that you got fewer elements that you asked for does not mean that the stepper is atEnd, since there may be some reason to break the result up into smaller chunks; you should always check."
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].
	(count isBroken) ifTrue:
		[^XuArray makeBrokenBy: count].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualStepper stepMany:count getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPromise} theOne

	"If there is precisely one element in the stepper return it; if not, blast without changing the state of the Stepper"
	
	| retVal {XuPromise} |
	(self isBroken) ifTrue:
		[^XuPromise makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPromise makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPromise make: (self getActualStepper theOne)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuStepper methodsFor: 'promise access'!

{Stepper} getActualStepper
	self isBroken
		ifFalse: [^super actualThing cast: Stepper.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuStepper methodsFor: 'smalltalk: defaults'!

{XuArray} stepMany

	^self  stepMany: DefaultMinusOne! !

!XuStepper methodsFor: 'create'!

{XuStepper} copy

	"Return a new stepper which steps independently of me, but whose current value is the same as mine, and which must produce a future history of values which satisfies the same obligation that my contract obligates me to produce now. Typically, this will mean that he must produce the same future history that I'm going to produce. However, let's say that I am enumerating the elements of a partial order in some full order which is consistent with the partial order. If a copy of me is made after I'm part way through, then me and my copy may produce any future history compatable both with the partial order and the elements I've already produced by the time of the copy. Of course, a subclass or a Stepper creating message (like IntegerRegion::stepper()) may specify the more stringent requirement (that a copy must produce the same sequence). 
	To prevent aliasing, Steppers should typically be passed by copy. See class comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualStepper copy)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuStepper class
	instanceVariableNames: ''!

(XuStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuStepper class methodsFor: 'pseudo-constructors'!

make: anStepper {Stepper}
	^self create: anStepper!

{XuStepper} makeBroken: problem {Problem star}
	| broke {XuStepper} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuStepper} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !
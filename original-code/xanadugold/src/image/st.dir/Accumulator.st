'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:37 pm'!

Heaper subclass: #Accumulator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!
Accumulator comment:
'An Accumulator is a thing which collects a sequence of objects one at a time for some purpose.  Typically, this purpose is to construct a new object out of all the collected objects.  When used in this way, one can think of the Accumulator as being sort of like a pseudo-constructor which is spread out in time, and whose arguments are identified by the sequence they occur in.  Accumulators are typically used in loops.
	
	A (future) example of an Accumulator which is not like "a pseudo-constructor spread out in time" is a communications stream between two threads (or even coroutines) managed by an Accumulator / Stepper pair.  The producer process produces by putting objects into his Accumulator, and the consuming process consumes by pulling values out of his Stepper.  If you want to stretch the analogy, I suppose you can see the Accumulator of the pair as a pseudo-constructor which constructs the Stepper, but *overlapped* in time.
	
	It is normally considered bad style for two methods/functions to be pointing at the same Acumulator.  As long as Accumulators are used locally and without aliasing (i.e., as if they were pass-by-value Vars), these implementationally side-effecty objects can be understood applicatively.  If a copy of an Accumulator can be passed instead of a pointer to the same one, this is to be prefered.  This same comment applies even more so for Steppers.
	
	Example:  To build a set consisting of some transform of the elements of an existing set (what Smalltalk would naturally do with "collect:"), a natural form for the loop would be:
	
	SPTR(Accumulator) acc = setAccumulator();
	FOR_EACH(Heaper,each,oldSet->stepper(), {
		acc->step (transform (each));
	});
	return CAST(ImmuSet,acc->value());
	
	See class Stepper for documentation of FOR_EACH.'!

(Accumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Accumulator methodsFor: 'deferred operations'!

{void} step: someObj {Heaper}
	"Accumulate a new object into the Accumulator"
	
	self subclassResponsibility!

{Heaper} value
	"Return the object that results from accumulating all those objects"

	self subclassResponsibility! !

!Accumulator methodsFor: 'deferred creation'!

{Accumulator} copy
	"Return a new Accumulator just like the current one, except that 
	from now on they accumulate separately"

	self subclassResponsibility! !

!Accumulator methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Accumulator class
	instanceVariableNames: ''!

(Accumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Accumulator class methodsFor: 'creation'!

{Accumulator INLINE} ptrArray
	"An accumulator that returns a PtrArray of the object put into it, in sequence"
	
	^PtrArrayAccumulator create! !
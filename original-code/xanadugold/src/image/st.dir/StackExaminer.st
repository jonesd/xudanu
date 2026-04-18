'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:27 pm'!

Heaper subclass: #StackExaminer
	instanceVariableNames: ''
	classVariableNames: '
		StackEnd {Int32 star} 
		TheStackSet {PrimPtrTable} '
	poolDictionaries: ''
	category: 'Xanadu-stacker'!
StackExaminer comment:
'main() routines that are going to invoke garbage collection should
call StackExaminer::stackEnd(&stackObj), where stackObj is an Int32
local to main''s stack frame.  This should be called before anything
else, even invoking the Initializer object.'!

(StackExaminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StackExaminer class
	instanceVariableNames: ''!

(StackExaminer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!StackExaminer class methodsFor: 'accessing'!

{PrimPtrTable} pointersOnStack
	"Do NOT destroy the result table.  It is reused to avoid allocation during purgeClean."
	| result {PrimPtrTable} |
	TheStackSet == NULL ifTrue: [TheStackSet := PrimPtrTable make: 1024].
	result _ TheStackSet.
	result clearAll.
	[| context |
	context _ thisContext.
	[context ~~ nil] whileTrue: [
		context stack do: [:p |
			(p == nil or: [p isInteger]) ifFalse: [
				result at: p asOop store: result
			]
		].
		result at: context receiver store: result].
	] smalltalkOnly.
	'Int32 stack;
	Int32 * stackPtr = & stack;
	if (StackExaminer::stackEnd() == NULL) {
		BLAST(StackEndUninitialized);
	}
	for (; stackPtr < (Int32 *) StackExaminer::stackEnd(); stackPtr++) {
		if (*stackPtr !!= 0 && (*stackPtr & 3) == 0) {
			result->store((Int32)(void*)*stackPtr, result);
		}
	}' translateOnly.
	^ result!

{Int32 star INLINE} stackEnd
	^ StackEnd!

{void} stackEnd: end {Int32 star}
	StackEnd _ end! !

!StackExaminer class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	StackEnd := NULL.
	TheStackSet := NULL.! !
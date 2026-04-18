'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:04 pm'!

TableStepper subclass: #BucketArrayStepper
	instanceVariableNames: '
		myEntry {TableEntry | NULL}
		myEntries {SharedPtrArray of: TableEntry}
		myNextBucket {Int4}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(BucketArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BucketArrayStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	myEntry == NULL ifTrue: [^NULL] ifFalse: [^myEntry value]!

{BooleanVar} hasValue
	^myEntry ~~ NULL!

{void} step
	myEntry ~~ NULL ifTrue: [
		myEntry _ myEntry fetchNext.
		self verifyEntry]! !

!BucketArrayStepper methodsFor: 'private:'!

{void} verifyEntry
	"Step through the bucket till we find something with a matching key."
	| bucket {Int32} |
	"use a local index to avoid pointer refs in loop"
	myEntry ~~ NULL ifTrue: [^VOID].
	bucket _ myNextBucket.
	[bucket < myEntries count] whileTrue:
		[|nextEntry {Heaper wimpy}|
		nextEntry _ myEntries fetch: bucket.
		bucket _ bucket + 1.
		nextEntry ~~ NULL ifTrue:
			[myEntry _ nextEntry cast: TableEntry.
			myNextBucket _ bucket.
			^VOID]].
	myEntries := NULL.! !

!BucketArrayStepper methodsFor: 'special'!

{IntegerVar} index
	myEntry ~~ NULL assert: 'Illegal access'.
	^myEntry index!

{Position} position
	myEntry ~~ NULL assert: 'Illegal access'.
	^myEntry position! !

!BucketArrayStepper methodsFor: 'protected: create'!

create: entries {SharedPtrArray} with: entry {TableEntry | NULL} with: nextBucket {Int32}
	super create.
	myEntry _ entry.
	myEntries _ entries.
	myNextBucket _ nextBucket.
	myEntries shareMore.
	self verifyEntry!

{void} destruct
	myEntries ~~ NULL ifTrue: [
		myEntries shareLess].
	super destruct! !

!BucketArrayStepper methodsFor: 'create'!

{Stepper} copy
	| result {Heaper} |
	result := SomeSteppers fetch.
	result ==  NULL
		ifTrue: [^BucketArrayStepper create: myEntries with: myEntry with: myNextBucket]
		ifFalse: [^(BucketArrayStepper new.Become: result) create: myEntries with: myEntry with: myNextBucket]!

{void} destroy
	(SomeSteppers store: self) ifFalse: [super destroy]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BucketArrayStepper class
	instanceVariableNames: ''!

(BucketArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BucketArrayStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 8!

linkTimeNonInherited
	SomeSteppers := NULL! !

!BucketArrayStepper class methodsFor: 'creation'!

{TableStepper} make: entries {SharedPtrArray}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^self create: entries with: NULL with: Int32Zero]
		ifFalse: [^(self new.Become: result) create: entries with: NULL with: Int32Zero]! !
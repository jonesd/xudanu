'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:23 pm'!

Heaper subclass: #PrimIndexTable
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndices {IntegerVarArray}
		myTally {Int4}
		amWimpy {BooleanVar}
		myOriginalSize {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimIndexTable comment:
'Map possibly wimpy pointers to integers.  Common usage almost never does a
remove on this class, therefore we rehash in order to save time on other ops.'!

(PrimIndexTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimIndexTable */
friend SPTR(PrimIndexTable) primIndexTable (Int4 size);
friend SPTR(PrimIndexTable) wimpyIndexTable (Int4 size);
friend class PrimIndexTableTester;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimIndexTable methodsFor: 'accessing'!

{void} at: ptr {Heaper} introduce: index {IntegerVar}
	| loc {Int32} |
	"redundant code for sake of speed"
	loc := self hashFind: ptr.
	(myPtrs fetch: loc) == NULL ifTrue: [
		myIndices at: loc storeIntegerVar: index.
		myPtrs at: loc store: ptr]
	ifFalse:
			[Heaper BLAST: #AlreadyInTable].
	myTally := myTally + 1.
	myTally > (myPtrs count bitShiftRight: 1) ifTrue: [ self grow ]!

{void} at: ptr {Heaper} store: index {IntegerVar}
	| loc {Int32} |
	loc := self hashFind: ptr.
	(myPtrs fetch: loc) ~~ NULL ifFalse:
		[ myTally := myTally + 1 ].
	myIndices at: loc storeIntegerVar: index.
	myPtrs at: loc store: ptr.
	myTally > (myPtrs count bitShiftRight: 1) ifTrue: [ self grow ]!

{void} clearAll
	"Clear all entries from the table. I know this looks like a hack, but the 
	alternative is to throw away the table and build a new one: an expensive 
	prospect for comm."

	myPtrs count > myOriginalSize
		ifTrue:
			[myPtrs destroy.
			amWimpy 
				ifTrue: [myPtrs := WeakPtrArray make: XnExecutor noopExecutor with: myOriginalSize]
				ifFalse: [myPtrs := PtrArray nulls: myOriginalSize]]
		ifFalse:
			[myPtrs storeAll].
	myTally _ Int32Zero!

{Int32 INLINE} count
	^myTally!

{IntegerVar} fetch: ptr {Heaper}
	"return -1 on not found."
	| loc {Int32} |
	loc _ self hashFindFetch: ptr.
	loc == -1 ifTrue: [ ^ -1 ].
	^ myIndices integerVarAt: loc!

{IntegerVar} get: ptr {Heaper}
	| loc {Int32} |
	loc _ self hashFind: ptr.
	(myPtrs fetch: loc) == NULL ifTrue:
		[ Heaper BLAST: #NotInTable ].
	^ myIndices integerVarAt: loc!

{void} remove: ptr {Heaper}
	| loc {Int32} |
	loc := self hashFind: ptr.
	(myPtrs fetch: loc) == NULL ifTrue:
		[ Heaper BLAST: #NotInTable ].
	myPtrs at: loc store: NULL.
	myTally := myTally - 1.
	self rehash: myPtrs with: myIndices with: myPtrs count! !

!PrimIndexTable methodsFor: 'protected:'!

create: size {Int32} with: wimpy {BooleanVar}
	super create.
	amWimpy := wimpy.
	amWimpy ifTrue: [myPtrs := WeakPtrArray make: XnExecutor noopExecutor with: size]
		ifFalse: [myPtrs := PtrArray nulls: size].
	myIndices := IntegerVarArray zeros: size.
	myTally := Int32Zero.
	myOriginalSize := size.!

{void} destruct
	myPtrs destroy.
	myIndices destroy.
	super destruct! !

!PrimIndexTable methodsFor: 'private:'!

{void} grow
	self rehash: myPtrs with: myIndices with: 5 * myPtrs count // 3!

{Int32} hashFind: value {Heaper}
	| loc {Int32} start {Int32} top {Int32} tmp {Heaper wimpy} |
	loc := value hashForEqual.
	top := myPtrs count.
	loc :=  (FHash fastHash.UInt32: loc) \\ top.
	start := loc.
	[(tmp _ myPtrs fetch: loc) ~~ NULL] whileTrue:
		[tmp == value ifTrue: [ ^ loc ].
		loc := loc + 1.
		loc = start ifTrue: [ Heaper BLAST: #SanityViolation ].
		loc >= top ifTrue: 
			[loc := Int32Zero]].
	^ loc!

{Int32} hashFindFetch: value {Heaper}
	| hashLoc {Int32} loc {Int32} top {Int32} tmp {Heaper wimpy} |
	hashLoc := value hashForEqual.
	top := myPtrs count.
	hashLoc :=  (FHash fastHash.UInt32: hashLoc) \\ top.
	loc := hashLoc.
	[(tmp _ myPtrs fetch: loc) ~~ NULL] whileTrue:
		[tmp == value ifTrue: [ ^ loc ].
		loc := loc + 1.
		loc == hashLoc ifTrue: [^ -1].
		loc >= top ifTrue: 
			[loc := Int32Zero]].
	^ -1!

{void} rehash: oldPtrs {PtrArray} with: oldIndices {IntegerVarArray} with: newSize {Int32}
	amWimpy ifTrue: [myPtrs := WeakPtrArray make: XnExecutor noopExecutor with: newSize]
		ifFalse: [myPtrs := PtrArray nulls: newSize].
	myIndices := IntegerVarArray zeros: newSize.
	Int32Zero almostTo: oldPtrs count do: [:i {Int32} |
		| loc {Int32} |
		(oldPtrs fetch: i) ~~ NULL ifTrue:
			[loc := self hashFind: (oldPtrs fetch: i).
			myIndices at: loc storeIntegerVar: (oldIndices integerVarAt: i).
			myPtrs at: loc store: (oldPtrs fetch: i)]].
	oldPtrs destroy.
	oldIndices destroy! !

!PrimIndexTable methodsFor: 'enumerating'!

{PrimIndexTableStepper} stepper
	^ PrimIndexTableStepper create: myPtrs with: myIndices with: Int32Zero! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimIndexTable class
	instanceVariableNames: ''!

(PrimIndexTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimIndexTable */
friend SPTR(PrimIndexTable) primIndexTable (Int4 size);
friend SPTR(PrimIndexTable) wimpyIndexTable (Int4 size);
friend class PrimIndexTableTester;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimIndexTable class methodsFor: 'create'!

make: size {Int32}
	^ self create: size with: false!

{PrimIndexTable} wimpyIndexTable: size {Int32}
	^ self create: size with: true! !
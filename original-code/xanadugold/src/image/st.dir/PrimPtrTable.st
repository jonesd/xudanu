'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:25 pm'!

Heaper subclass: #PrimPtrTable
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndices {IntegerVarArray}
		myTally {Int4}
		myExecutor {XnExecutor | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimPtrTable comment:
'Map integers to strong or weak pointers'!

(PrimPtrTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtrTable */
friend class PrimPtrTableExecutor;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtrTable methodsFor: 'accessing'!

{void} at: index {IntegerVar} introduce: ptr {Heaper}
	| loc {Int32} tmp {Heaper wimpy} |
	loc := self hashFind: index.
	((tmp _ myPtrs fetch: loc) ~~ NULL and: [tmp ~~ PrimRemovedObject make]) ifTrue:
		[ Heaper BLAST: #AlreadyInTable ].
	myIndices at: loc storeIntegerVar: index.
	myPtrs at: loc store: ptr.
	myTally := myTally + 1.
	myTally > (2 * myPtrs count / 3) ifTrue: [ self grow ]!

{void} at: index {IntegerVar} store: ptr {Heaper}
	| loc {Int32} tmp {Heaper wimpy} |
	loc := self hashFind: index.
	((tmp _ myPtrs fetch: loc) ~~ NULL and: [tmp ~~ PrimRemovedObject make]) ifFalse:
		[myTally := myTally + 1].
	myIndices at: loc storeIntegerVar: index.
	myPtrs at: loc store: ptr.
	myTally > (2 * myPtrs count / 3) ifTrue: [ self grow ]!

{void} clearAll
	"Clear all entries from the table. I know this looks like a hack, but the 
	alternative is to throw away the table and build a new one: an expensive 
	prospect for comm."

	myPtrs storeAll.
	myTally _ Int32Zero!

{Int32 INLINE} count
	^myTally!

{Heaper | NULL} fetch: index {IntegerVar}
	| loc {Int32} tmp {Heaper wimpy} |
	loc _ self hashFind: index.
	tmp _ myPtrs fetch: loc.
	(tmp == NULL or: [tmp == PrimRemovedObject make]) ifTrue:
		[ ^NULL ].
	^ tmp!

{Heaper} get: index {IntegerVar}
	| loc {Int32} tmp {Heaper wimpy} |
	loc _ self hashFind: index.
	tmp _ myPtrs fetch: loc.
	(tmp == NULL or: [tmp == PrimRemovedObject make]) ifTrue:
		[ Heaper BLAST: #NotInTable ].
	^ tmp!

{void} remove: index {IntegerVar}
	| loc {Int32} |
	loc := self hashFind: index.
	((myPtrs fetch: loc) == NULL or: [(myPtrs fetch: loc) == PrimRemovedObject make]) ifTrue:
		[ Heaper BLAST: #NotInTable ].
	myPtrs at: loc store: PrimRemovedObject make.
	myTally := myTally - 1.!

{void} wipe: index {IntegerVar}
	| loc {Int32} |
	loc := self hashFind: index.
	((myPtrs fetch: loc) == NULL or: [(myPtrs fetch: loc) == PrimRemovedObject make]) ifTrue: [ ^ VOID ].
	myPtrs at: loc store: PrimRemovedObject make.
	myTally := myTally - 1.! !

!PrimPtrTable methodsFor: 'protected: destruct'!

{void} destruct
	myPtrs destroy.
	myIndices destroy.
	super destruct! !

!PrimPtrTable methodsFor: 'private:'!

{void} grow
	| oldPtrs {PtrArray} oldIndices {IntegerVarArray} newIndices {IntegerVarArray} tmp {Heaper wimpy} removed {Heaper wimpy} |
	oldPtrs := myPtrs.
	oldIndices := myIndices.
	"To be GC safe, instance variables are not modified until all allocations are complete."
	newIndices := IntegerVarArray zeros: 5 * myPtrs count // 3.
	myExecutor == NULL
		ifTrue: [myPtrs := PtrArray nulls: newIndices count]
		ifFalse: [myPtrs := WeakPtrArray make: myExecutor with: newIndices count].
	myIndices := newIndices.
	removed _ PrimRemovedObject make.
	Int32Zero almostTo: oldPtrs count do: [:i {UInt32} |
		| loc {Int32} |
		((tmp _ oldPtrs fetch: i) ~~ NULL and: [tmp ~~ removed]) ifTrue:
			[loc := self hashFind: (oldIndices integerVarAt: i).
			myIndices at: loc storeIntegerVar: (oldIndices integerVarAt: i).
			myPtrs at: loc store: (oldPtrs fetch: i)]].
	oldPtrs destroy.
	oldIndices destroy!

{Int32} hashFind: value {IntegerVar}
	| loc {Int32}firstRemoved {Int32} tmp {Heaper wimpy} removed {Heaper wimpy} looped {BooleanVar} |
	firstRemoved _ -1.
	loc :=  (FHash fastHash.UInt32: value DOTasLong) \\ myPtrs count.
	removed _ PrimRemovedObject make.
	looped _ false.
	[(tmp _ myPtrs fetch: loc) ~~ NULL] whileTrue:
		[(myIndices integerVarAt: loc) == value ifTrue: [ ^ loc ].
		tmp == removed ifTrue:
			[firstRemoved == -1 ifTrue: [firstRemoved _ loc]].
		loc := loc + 1.
		loc >= myPtrs count ifTrue: 
			[looped ifTrue: [^firstRemoved] ifFalse: [looped _ true].
			loc := Int32Zero]].
	firstRemoved ~~ -1
		ifTrue: [ ^ firstRemoved ]
		ifFalse: [ ^ loc ]! !

!PrimPtrTable methodsFor: 'protected: create'!

create: size {Int32}
	super create.
	myPtrs := PtrArray nulls: size.
	myIndices := IntegerVarArray zeros: size.
	myTally := Int32Zero.
	myExecutor := NULL!

create: size {Int32} with: executor {XnExecutor | NULL}
	super create.
	"Create weak array last to be GC safe"
	myIndices := IntegerVarArray zeros: size.
	myTally := Int32Zero.
	myExecutor := PrimPtrTableExecutor make: self with: executor.
	myPtrs := WeakPtrArray make: myExecutor with: size.! !

!PrimPtrTable methodsFor: 'enumerating'!

{PrimPtrTableStepper} stepper
	^ PrimPtrTableStepper create: myIndices with: myPtrs with: Int32Zero! !

!PrimPtrTable methodsFor: 'private: weakness'!

{void} weakRemove: index {Int32} with: follower {XnExecutor | NULL}
	"By way of a weird kluge, this passes the index that the item was stored at in this table
	to the follow up executor"
	| virtualIndex {Int32} |
	myPtrs at: index store: PrimRemovedObject make.
	virtualIndex := (myIndices integerAt: index) DOTasLong.
	myTally := myTally - 1.
	follower ~~ NULL ifTrue:
		[follower execute: virtualIndex].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimPtrTable class
	instanceVariableNames: ''!

(PrimPtrTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtrTable */
friend class PrimPtrTableExecutor;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtrTable class methodsFor: 'smalltalk: defaults'!

{PrimPtrTable} weak: size {Int32}
	^ self create: size with: NULL! !

!PrimPtrTable class methodsFor: 'create'!

make: size {Int32}
	^ self create: size!

{PrimPtrTable} weak: size {Int32} with: executor {XnExecutor default: NULL}
	^ self create: size with: executor! !
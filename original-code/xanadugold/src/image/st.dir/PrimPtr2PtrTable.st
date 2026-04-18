'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:24 pm'!

Heaper subclass: #PrimPtr2PtrTable
	instanceVariableNames: '
		myFromPtrs {PtrArray}
		myToPtrs {PtrArray}
		myTally {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimPtr2PtrTable comment:
'Map wimpy pointers to strong ptrs'!

(PrimPtr2PtrTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtr2PtrTable */
friend SPTR(PrimPtr2PtrTable)  primPtr2PtrTable (Int4 size);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtr2PtrTable methodsFor: 'enumerating'!

{PrimPtr2PtrTableStepper} stepper
	^ PrimPtr2PtrTableStepper create: myFromPtrs with: myToPtrs with: Int32Zero! !

!PrimPtr2PtrTable methodsFor: 'accessing'!

{void} at: key {Heaper} introduce: value {Heaper}
	| loc {Int32} tmp {Heaper wimpy} |
	loc := self hashFind: key.
	((tmp _ myToPtrs fetch: loc) ~~ NULL and: [tmp ~~ PrimRemovedObject make]) ifTrue:
		[ Heaper BLAST: #AlreadyInTable ].
	myToPtrs at: loc store: value.
	myFromPtrs at: loc store: key.
	myTally := myTally + 1.
	myTally > (2 * myFromPtrs count / 3) ifTrue: [ self grow ]!

{void} at: key {Heaper} store: value {Heaper}
	| loc {Int32} |
	loc := self hashFind: key.
	(myToPtrs fetch: loc) == NULL ifTrue: [ myTally := myTally + 1].
	myToPtrs at: loc store: value.
	myFromPtrs at: loc store: key.
	myTally > (2 * myFromPtrs count / 3) ifTrue: [ self grow ]!

{Int32 INLINE} count
	^myTally!

{Heaper} fetch: key {Heaper}
	| tmp {Heaper wimpy} |
	tmp _ myToPtrs fetch: (self hashFind: key).
	tmp == PrimRemovedObject make
		ifTrue: [  ^ NULL ]
		ifFalse: [ ^ tmp ]!

{Heaper} get: ptr {Heaper}
	| result {Heaper} |
	((result _ myToPtrs fetch: (self hashFind: ptr)) == NULL
		or: [(result basicCast: Heaper star) == (PrimRemovedObject make basicCast: Heaper star)])
		ifTrue: [ Heaper BLAST: #NotInTable ].
	^ result!

{void} remove: key {Heaper}
	| loc {Int32} |
	loc := self hashFind: key.
	(myToPtrs fetch: loc) == NULL ifTrue: [ Heaper BLAST: #NotInTable ].
	myToPtrs at: loc store: PrimRemovedObject make.
	myTally := myTally - 1.! !

!PrimPtr2PtrTable methodsFor: 'protected: destruct'!

{void} destruct
	myFromPtrs destroy.
	myToPtrs destroy.
	super destruct! !

!PrimPtr2PtrTable methodsFor: 'protected: create'!

create: size {Int32}
	super create.
	myFromPtrs := WeakPtrArray make: XnExecutor noopExecutor with: size.
	myToPtrs := PtrArray nulls: size.
	myTally := Int32Zero.! !

!PrimPtr2PtrTable methodsFor: 'private:'!

{void} grow
	| oldFromPtrs {PtrArray} oldToPtrs {PtrArray} tmp {Heaper wimpy} removed {Heaper wimpy} |
	oldFromPtrs := myFromPtrs.
	oldToPtrs := myToPtrs.
	myFromPtrs := WeakPtrArray make: XnExecutor noopExecutor with: 5 * myFromPtrs count // 3.
	myToPtrs := PtrArray nulls: myFromPtrs count.
	removed _ PrimRemovedObject make.
	Int32Zero almostTo: oldFromPtrs count do: [:i {Int32} |
		| loc {Int32} |
		((tmp _ oldToPtrs fetch: i) ~~ NULL and: [tmp ~~ removed]) ifTrue:
			[loc := self hashFind: (oldFromPtrs fetch: i).
			myFromPtrs at: loc store: (oldFromPtrs fetch: i).
			myToPtrs at: loc store: (oldToPtrs fetch: i)]].
	oldFromPtrs destroy.
	oldToPtrs destroy!

{Int32} hashFind: key {Heaper}
	| loc {Int32} firstRemoved {Int32} tmp {Heaper wimpy} removed {Heaper wimpy} looped {BooleanVar} |
	firstRemoved _ -1.
	loc := key hashForEqual.
	loc :=  (FHash fastHash.UInt32: loc) \\ myFromPtrs count.
	removed _ PrimRemovedObject make.
	looped _ false.
	[(tmp _ myToPtrs fetch: loc) ~~ NULL] whileTrue:
		[((myFromPtrs fetch: loc) basicCast: Heaper star) == key ifTrue: [ ^ loc ].
		tmp == removed ifTrue:
			[firstRemoved == -1 ifTrue: [firstRemoved _ loc]].
		loc := loc + 1.
		loc >= myFromPtrs count ifTrue: 
			[looped ifTrue: [^firstRemoved] ifFalse: [looped _ true].
			loc := Int32Zero]].
	firstRemoved ~~ -1
		ifTrue: [ ^ firstRemoved ]
		ifFalse: [ ^ loc ]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimPtr2PtrTable class
	instanceVariableNames: ''!

(PrimPtr2PtrTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtr2PtrTable */
friend SPTR(PrimPtr2PtrTable)  primPtr2PtrTable (Int4 size);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtr2PtrTable class methodsFor: 'create'!

make: size {Int32}
	^ self create: size! !
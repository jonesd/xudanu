'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:27 pm'!

Heaper subclass: #PrimSet
	instanceVariableNames: '
		myPtrs {PtrArray}
		myTally {Int4}
		myWeakness {BooleanVar}
		myExecutor {XnExecutor | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimSet comment:
'A set of pointers.  May be strong or weak.  If we have a separate executor, it is called with the remaining size after removal.'!

(PrimSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimSet */
friend class PrimSetExecutor;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSet methodsFor: 'enumerating'!

{Stepper} stepper
	^ PrimSetStepper make: myPtrs! !

!PrimSet methodsFor: 'adding-removing'!

{void} introduce: value {Heaper}
	| loc {Int32} |
	loc := self hashFind: value.
	loc == -1 ifTrue: [
		self hack.
		self grow.
		loc := self hashFind: value].
	(myPtrs fetch: loc) == value
		ifTrue: [ Heaper BLAST: #AlreadyInSet ]
		ifFalse: [
			myPtrs at: loc store: value.
			myTally := myTally + 1.
			myTally > (2 * myPtrs count / 3) ifTrue: [ self grow ]]!

{void} remove: value {Heaper}
	| loc {Int32} |
	loc := self hashFind: value.
	(myPtrs fetch: loc) ~~ value ifTrue: [ Heaper BLAST: #NotInSet ].
	myPtrs at: loc store: PrimRemovedObject make.
	myTally := myTally - 1.!

{void} store: value {Heaper}
	| loc {Int32} |
	loc := self hashFind: value.
	loc == -1 ifTrue: [
		self hack.
		self grow.
		loc := self hashFind: value].
	(myPtrs fetch: loc) ~= value ifTrue: [
		myPtrs at: loc store: value.
		myTally := myTally + 1.
		myTally > (2 * myPtrs count / 3) ifTrue: [ self grow ]]!

{void} wipe: value {Heaper}
	| loc {Int32} |
	loc := self hashFind: value.
	(myPtrs fetch: loc) == value ifTrue: [
		myPtrs at: loc store: PrimRemovedObject make.
		myTally := myTally - 1].!

{void} wipeAll
	myPtrs storeAll.
	myTally := Int32Zero.! !

!PrimSet methodsFor: 'accessing'!

{Int32 INLINE} count
	^myTally!

{BooleanVar} hasMember: element {Heaper}
	| tmp {Heaper wimpy} |
	tmp _ myPtrs fetch: (self hashFind: element).
	^ tmp == element!

{BooleanVar} isEmpty
	^myTally == Int32Zero! !

!PrimSet methodsFor: 'private:'!

{void} grow
	| oldPtrs {PtrArray} removed {Heaper wimpy} |
	oldPtrs := myPtrs.
	myWeakness
		ifTrue: [myPtrs := WeakPtrArray make: (PrimSetExecutor make: self) with: 5 * oldPtrs count // 3]
		ifFalse: [myPtrs := PtrArray nulls: 5 * oldPtrs count // 3].
	removed := PrimRemovedObject make.
	Int32Zero almostTo: oldPtrs count do: [:i {Int32} |
		| tmp {Heaper wimpy} |
		tmp := oldPtrs fetch: i.
		(tmp ~~ NULL and: [tmp ~~ removed]) ifTrue:
			[|loc {Int32} |
			loc := self hashFind: tmp.
			myPtrs at: loc store: tmp]].
	oldPtrs destroy!

{Int32} hashFind: value {Heaper}
	| loc {Int32} firstRemoved {Int32} tmp {Heaper wimpy} removed {Heaper wimpy} looped {BooleanVar} |
	firstRemoved _ -1.
	loc := value hashForEqual.
	loc :=  (FHash fastHash.UInt32: loc) \\ myPtrs count.
	removed _ PrimRemovedObject make.
	looped _ false.
	[(tmp _ myPtrs fetch: loc) ~~ NULL] whileTrue:
		[tmp == value ifTrue: [ ^ loc ].
		tmp == removed ifTrue:
			[firstRemoved == -1 ifTrue: [firstRemoved _ loc]].
		loc := loc + 1.
		loc >= myPtrs count ifTrue: 
			[looped ifTrue: [^firstRemoved] ifFalse: [looped _ true].
			loc := Int32Zero]].
	firstRemoved ~~ -1
		ifTrue: [ ^ firstRemoved ]
		ifFalse: [ ^ loc ]! !

!PrimSet methodsFor: 'protected: create'!

create: size {Int32} with.Executor: exec {XnExecutor}
	super create.
	myWeakness := true.
	myExecutor := exec.
	myPtrs := WeakPtrArray make: (PrimSetExecutor make: self) with: size.
	myTally := Int32Zero.!

create: size {Int32} with: weakness {BooleanVar}
	super create.
	myWeakness := weakness.
	myExecutor := NULL.
	weakness
		ifTrue: [myPtrs := WeakPtrArray make: (PrimSetExecutor make: self) with: size]
		ifFalse: [myPtrs := PtrArray nulls: size].
	myTally := Int32Zero.! !

!PrimSet methodsFor: 'private: weakness'!

{void} weakRemove: index {Int32}
	myPtrs at: index store: PrimRemovedObject make. "NULL will mess up hashFind"
	myTally := myTally - 1.
	myExecutor ~~ NULL ifTrue: [
		myExecutor execute: myTally].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimSet class
	instanceVariableNames: ''!

(PrimSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimSet */
friend class PrimSetExecutor;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSet class methodsFor: 'create'!

make
	^ self create: 7 with: false!

make: size {Int32}
	^ self create: size with: false!

{PrimSet} weak
	^ self create: 7 with: true!

{PrimSet} weak: size {Int32}
	^ self create: size with: true!

{PrimSet} weak: size {Int32} with: exec {XnExecutor}
	^ self create: size with.Executor: exec! !
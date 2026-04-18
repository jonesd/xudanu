'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:39 pm'!

FeLockSmith subclass: #FeMultiLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheMultiLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeMultiLockSmith comment:
'Makes MultiLocks; see the comment there'!

(FeMultiLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMultiLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID | NULL}

	| result {MuTable of: Lock} |
	result := MuTable make: SequenceSpace make.
	self edition stepper forPositions: [ :name {Sequence} :smith {FeEdition} |
		result at: name
			introduce: (((FeLockSmith spec wrap: smith) cast: FeLockSmith) newLock: clubID)].
	^MultiLock make: clubID with: self with: result asImmuTable! !

!FeMultiLockSmith methodsFor: 'accessing'!

{FeLockSmith CLIENT} lockSmith: name {Sequence}
	"The named LockSmith"
	
	^(FeLockSmith spec wrap: ((self edition get: name) cast: FeEdition)) cast: FeLockSmith!

{SequenceRegion CLIENT of: Sequence} lockSmithNames
	"The names of all the Locksmiths this uses."
	
	^self edition domain cast: SequenceRegion!

{FeMultiLockSmith CLIENT} with: name {Sequence} with: smith {FeLockSmith}
	"Add or change a LockSmith"
	
	^(FeMultiLockSmith construct: (self edition
		with: name
		with: smith edition)) cast: FeMultiLockSmith!

{FeMultiLockSmith CLIENT} without: name {Sequence}
	"Add or change a LockSmith"
	
	^(FeMultiLockSmith construct: (self edition without: name)) cast: FeMultiLockSmith! !

!FeMultiLockSmith methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeMultiLockSmith class
	instanceVariableNames: ''!

(FeMultiLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMultiLockSmith class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	^(SequenceSpace make isEqual: edition coordinateSpace)
		and: [FeWrapper checkSubEditions: edition
			with: edition domain
			with: FeLockSmith spec
			with: true]!

{FeMultiLockSmith} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^ (self makeWrapper: edition) cast: FeMultiLockSmith!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheMultiLockSmithSpec := wrap.! !

!FeMultiLockSmith class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'MultiLockSmith'
		with: 'LockSmith'
		with: #FeMultiLockSmith.!

linkTimeNonInherited

	TheMultiLockSmithSpec := NULL.! !

!FeMultiLockSmith class methodsFor: 'pseudo constructors'!

{FeMultiLockSmith CLIENT} make

	^self construct: (FeEdition empty: SequenceSpace make)!

{FeWrapperSpec} spec

	^TheMultiLockSmithSpec! !

!FeMultiLockSmith class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeLockSmith CLIENT} lockSmith: name {Sequence}
{SequenceRegion CLIENT of: Sequence} lockSmithNames
{FeMultiLockSmith CLIENT} with: name {Sequence} with: smith {FeLockSmith}
{FeMultiLockSmith CLIENT} without: name {Sequence}
"! !
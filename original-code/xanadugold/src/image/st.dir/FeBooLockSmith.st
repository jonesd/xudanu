'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:37 pm'!

FeLockSmith subclass: #FeBooLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheBooLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeBooLockSmith comment:
'Makes BooLocks; see the comment there'!

(FeBooLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeBooLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID | NULL}
	"Make a WallLock if clubID is NULL"
	clubID == NULL
		ifTrue: [^FeWallLockSmith make newLock: NULL]
		ifFalse: [^BooLock make: clubID with: self]! !

!FeBooLockSmith methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeBooLockSmith class
	instanceVariableNames: ''!

(FeBooLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeBooLockSmith class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	Ravi hack.
	^(edition domain isEqual: (IntegerRegion make: IntegerVarZero with: 3))
		"and: [((edition zoneOf: PrimSpec uInt8) domain
			isEqual: (IntegerRegion make: IntegerVarZero with: 3))"
		and: [((edition retrieve theOne cast: FeArrayBundle) array cast: PrimIntegerArray)
			contentsEqual: (UInt8Array string: 'boo')]"]"!

{FeBooLockSmith} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^ (self makeWrapper: edition) cast: FeBooLockSmith!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheBooLockSmithSpec := wrap.! !

!FeBooLockSmith class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'BooLockSmith'
		with: 'LockSmith'
		with: #FeBooLockSmith.!

linkTimeNonInherited

	TheBooLockSmithSpec := NULL.! !

!FeBooLockSmith class methodsFor: 'pseudo constructors'!

{FeBooLockSmith CLIENT} make

	^self construct: (FeEdition fromArray: (UInt8Array string: 'boo'))!

{FeWrapperSpec} spec

	^TheBooLockSmithSpec! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:40 pm'!

FeLockSmith subclass: #FeWallLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheWallLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeWallLockSmith comment:
'Makes WallLocks; see the comment there'!

(FeWallLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeWallLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID | NULL}

	^WallLock make: clubID with: self! !

!FeWallLockSmith methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWallLockSmith class
	instanceVariableNames: ''!

(FeWallLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeWallLockSmith class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	Ravi hack.
	^(edition domain isEqual: (IntegerRegion make: IntegerVarZero with: 4))
		"and: [((edition zoneOf: PrimSpec uInt8) domain
			isEqual: (IntegerRegion make: IntegerVarZero with: 4))"
		and: [((edition retrieve theOne cast: FeArrayBundle) array cast: PrimIntegerArray)
			contentsEqual: (UInt8Array string: 'wall')]"]"!

{FeWallLockSmith} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^ (self makeWrapper: edition) cast: FeWallLockSmith!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheWallLockSmithSpec := wrap.! !

!FeWallLockSmith class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'WallLockSmith'
		with: 'LockSmith'
		with: #FeWallLockSmith.!

linkTimeNonInherited

	TheWallLockSmithSpec := NULL.! !

!FeWallLockSmith class methodsFor: 'pseudo constructors'!

{FeWallLockSmith CLIENT} make

	^self construct: (FeEdition fromArray: (UInt8Array string: 'wall'))!

{FeWrapperSpec} spec

	^TheWallLockSmithSpec! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:37 pm'!

FeLockSmith subclass: #FeChallengeLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheChallengeLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeChallengeLockSmith comment:
'Makes ChallengeLocks; see the comment there'!

(FeChallengeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeChallengeLockSmith methodsFor: 'accessing'!

{UInt8Array CLIENT} encrypterName
	"The type of encrypter used to create encrypted challenges."

	^((((self edition get: (Sequence string: 'ChallengeLockSmith:EncrypterName'))
		cast: FeEdition) retrieve theOne) cast: FeArrayBundle) array cast: UInt8Array!

{UInt8Array CLIENT} publicKey
	"The public key used to construct challenges."

	^((((self edition get: (Sequence string: 'ChallengeLockSmith:PublicKey'))
		cast: FeEdition) retrieve theOne) cast: FeArrayBundle) array cast: UInt8Array! !

!FeChallengeLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID | NULL}

	self thingToDo. "Make this random"
	^ChallengeLock make: clubID
		with: self
		with: (UInt8Array string: 'random')! !

!FeChallengeLockSmith methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeChallengeLockSmith class
	instanceVariableNames: ''!

(FeChallengeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeChallengeLockSmith class methodsFor: 'pseudo constructors'!

{FeChallengeLockSmith CLIENT} make: publicKey {PrimIntArray}
	with: encrypterName {Sequence}
	
	| result {FeEdition} |
	result := FeEdition fromOne: (Sequence string: 'ChallengeLockSmith:PublicKey')
		with: (FeEdition fromArray: (publicKey cast: UInt8Array)).
	result := result
		with: (Sequence string: 'ChallengeLockSmith:EncrypterName')
		with: (FeEdition fromArray: encrypterName integers).
	^self construct: result!

{FeWrapperSpec} spec

	^TheChallengeLockSmithSpec! !

!FeChallengeLockSmith class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	^(edition domain isEqual: ((Sequence string: 'ChallengeLockSmith:EncrypterName') asRegion
			with: (Sequence string: 'ChallengeLockSmith:PublicKey')))
		and: [(FeWrapper checkSubSequence: edition
			with: (Sequence string: 'ChallengeLockSmith:EncrypterName')
			with: true)
		and: [FeWrapper checkSubSequence: edition
			with: (Sequence string: 'ChallengeLockSmith:PublicKey')
			with: true]]!

{FeChallengeLockSmith} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^ (self makeWrapper: edition) cast: FeChallengeLockSmith!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheChallengeLockSmithSpec := wrap.! !

!FeChallengeLockSmith class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'ChallengeLockSmith'
		with: 'LockSmith'
		with: #FeChallengeLockSmith.!

linkTimeNonInherited

	TheChallengeLockSmithSpec := NULL.! !

!FeChallengeLockSmith class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimIntegerArray CLIENT} encrypterName
{UInt8Array CLIENT} publicKey
"! !
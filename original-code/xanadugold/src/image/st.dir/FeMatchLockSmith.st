'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:38 pm'!

FeLockSmith subclass: #FeMatchLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheMatchLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeMatchLockSmith comment:
'Makes MatchLocks; see the comment there'!

(FeMatchLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMatchLockSmith methodsFor: 'accessing'!

{UInt8Array CLIENT} scrambledPassword
	"The password in scrambled form. If the scrambler is any good, this should be meaningless."

	^((((self edition get: (Sequence string: 'MatchLockSmith:ScrambledPassword'))
		cast: FeEdition) retrieve theOne) cast: FeArrayBundle) array cast: UInt8Array!

{UInt8Array CLIENT} scramblerName
	"The name of scrambler being used to scramble the password."

	^((((self edition get: (Sequence string: 'MatchLockSmith:ScramblerName'))
		cast: FeEdition) retrieve theOne) cast: FeArrayBundle) array cast: UInt8Array! !

!FeMatchLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID | NULL}

	^MatchLock make: clubID with: self! !

!FeMatchLockSmith methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeMatchLockSmith class
	instanceVariableNames: ''!

(FeMatchLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeMatchLockSmith class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	^(edition domain isEqual: ((Sequence string: 'MatchLockSmith:ScramblerName') asRegion
			with: (Sequence string: 'MatchLockSmith:ScrambledPassword')))
		and: [(FeWrapper checkSubSequence: edition
			with: (Sequence string: 'MatchLockSmith:ScramblerName')
			with: true)
		and: [FeWrapper checkSubSequence: edition
			with: (Sequence string: 'MatchLockSmith:ScrambledPassword')
			with: true]]!

{FeMatchLockSmith} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^ (self makeWrapper: edition) cast: FeMatchLockSmith!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheMatchLockSmithSpec := wrap.! !

!FeMatchLockSmith class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'MatchLockSmith'
		with: 'LockSmith'
		with: #FeMatchLockSmith.!

linkTimeNonInherited

	TheMatchLockSmithSpec := NULL.! !

!FeMatchLockSmith class methodsFor: 'pseudo constructors'!

{FeMatchLockSmith CLIENT} make: scrambledPassword {PrimIntArray}
	with: scramblerName {Sequence}
	
	| result {FeEdition} |
	result := FeEdition fromOne: (Sequence string: 'MatchLockSmith:ScrambledPassword')
		with: (FeEdition fromArray: (scrambledPassword cast: UInt8Array)).
	result := result
		with: (Sequence string: 'MatchLockSmith:ScramblerName')
		with: (FeEdition fromArray: scramblerName integers).
	^self construct: result!

{FeWrapperSpec} spec

	^TheMatchLockSmithSpec! !

!FeMatchLockSmith class methodsFor: 'smalltalk: system'!

info.stProtocol
"{UInt8Array CLIENT} scrambledPassword
{PrimIntegerArray CLIENT} scramblerName
"! !
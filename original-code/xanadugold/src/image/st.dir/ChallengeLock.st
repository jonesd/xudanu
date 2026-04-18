'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:16 pm'!

Lock subclass: #ChallengeLock
	instanceVariableNames: '
		myChallenge {UInt8Array}
		myResponse {UInt8Array}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
ChallengeLock comment:
'A ChallengeLock challenges the client with a random piece of data that has been encrypted with a publicKey, using an algorithm identified by the encrypterName. The client must decrypt it using the corresponding private key and respond with the decrypted challenge. If it matches the original random data, then the lock will open. The encrypterName and the publicKey are stored in the club`s ChallengeLockSmith. '!

(ChallengeLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!ChallengeLock methodsFor: 'private: create'!

create: allegedID {ID}
	with: lockSmith {FeLockSmith}
	with: challenge {UInt8Array}
	with: response {UInt8Array}

	super create: allegedID with: lockSmith.
	myChallenge := challenge.
	myResponse := response.! !

!ChallengeLock methodsFor: 'accessing'!

{UInt8Array CLIENT login} challenge
	"Essential.  The challenge which must be signed correctly to open the lock."

	^myChallenge copy cast: UInt8Array!

{FeKeyMaster CLIENT login} response: signedChallenge {PrimIntArray}
	"Essential.  The correctly signed challenge will open the lock."
	
	(self fetchLoginClubID ~~ NULL
			and: [myResponse contentsEqual: (signedChallenge cast: UInt8Array)]) ifFalse:
		[Heaper BLAST: #NotCorrectlySigned].
	^self makeKeyMaster! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChallengeLock class
	instanceVariableNames: ''!

(ChallengeLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!ChallengeLock class methodsFor: 'pseudo constructors'!

make: loginID {ID | NULL}
	with: lockSmith {FeChallengeLockSmith}
	with: response {UInt8Array}
	
	^self create: loginID
		with: lockSmith
		with: ((Encrypter 
				make: (Sequence numbers: lockSmith encrypterName)
				with: lockSmith publicKey)
			encrypt: response)
		with: (response copy cast: UInt8Array)! !

!ChallengeLock class methodsFor: 'smalltalk: system'!

info.stProtocol
"{UInt8Array CLIENT} challenge
{FeKeyMaster CLIENT} response: signedChallenge {UInt8Array}
"! !
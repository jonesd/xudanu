'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:18 pm'!

Lock subclass: #MatchLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
MatchLock comment:
'The correct password will open the lock. The password is actually stored in the club`s MatchLockSmith in scrambled form, using a Scrambler identified by scramblerName(). The scrambled cleartext supplied as a password is compared to the scrambledPassword in the MatchLockSmith. If they match, the lock is opened. 

The actual process is a bit more complicated than this. The user supplies a password in clear, which is encrypted with the current system public key and then sent to the server. There, it is first decrypted with the private key known only to the server. It is then scrambled and compared with the scrambled password stored in the MatchLockSmith of the club. This procedure both avoids sending passwords in clear over the network, and also allows the MatchLockSmith to be made readable without compromising security.'!

(MatchLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!MatchLock methodsFor: 'accessing'!

{FeKeyMaster CLIENT login} encryptedPassword: encrypted {PrimIntArray}
	"Send the encrypted password to the server to be checked.
	NOTE: (for protocol review) The password must have been encrypted using a (yet-to-be-defined) front end library function, since this sort of front end computation can't be done with Promises."
	| cs {FeServer} |
	cs := CurrentServer fluidGet.
	(self fetchLoginClubID ~~ NULL
			and: [(self lockSmith cast: FeMatchLockSmith) scrambledPassword
				contentsEqual: (cs encrypter decrypt: (encrypted cast: UInt8Array))])
		ifFalse: [Heaper BLAST: #DoesNotMatch].
	^self makeKeyMaster! !

!MatchLock methodsFor: 'private: create'!

create: loginID {ID} with: lockSmith {FeMatchLockSmith}

	super create: loginID with: lockSmith! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MatchLock class
	instanceVariableNames: ''!

(MatchLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!MatchLock class methodsFor: 'exceptions: exceptions'!

problems.PasswordDoesNotMatch


	^self signals: #(PasswordDoesNotMatch)! !

!MatchLock class methodsFor: 'pseudo constructors'!

make: clubID {ID | NULL} with: lockSmith {FeMatchLockSmith}

	^self create: clubID with: lockSmith! !

!MatchLock class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeKeyMaster CLIENT} encryptedPassword: encrypted {UInt8Array}
"! !
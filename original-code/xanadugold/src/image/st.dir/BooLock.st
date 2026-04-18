'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:16 pm'!

Lock subclass: #BooLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
BooLock comment:
'A BooLock is very easy to open. Just say "boo". 

Since anyone can get in, only public clubs with little authority, such as System Public, should have BooLockSmiths.'!

(BooLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!BooLock methodsFor: 'accessing'!

{FeKeyMaster CLIENT login} boo
	"Essential.  This is a very easy lock to open. Just say `boo'."

	^self makeKeyMaster! !

!BooLock methodsFor: 'private: create'!

create: clubID {ID} with: lockSmith {FeLockSmith}

	super create: clubID with: lockSmith! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BooLock class
	instanceVariableNames: ''!

(BooLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!BooLock class methodsFor: 'pseudo constructors'!

make: clubID {ID} with: lockSmith {FeLockSmith}

	^self create: clubID with: lockSmith! !

!BooLock class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeKeyMaster CLIENT} boo
"! !
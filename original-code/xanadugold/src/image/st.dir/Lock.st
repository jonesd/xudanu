'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:17 pm'!

Heaper subclass: #Lock
	instanceVariableNames: '
		myLoginClubID {ID}
		myLockSmith {FeLockSmith}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
Lock comment:
'To login to a club, you ask the server for a Lock. If you send the right message to the Lock, it will return you a new KeyMaster with the authority of the club. Each subclass of Lock defines its own protocol for opening. 

For each kind of Lock, there is a corresponding kind of LockSmith which creates it. Each ClubManager has a LockSmith sub-document, and when you ask the server for a Lock to that club, it asks the club`s LockSmith document Wrapper to create a newLock. The LockSmith then creates the corresponding kind of Lock. It may also use information stored in the LockSmith document, such as a password or scramblerName.'!

(Lock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!Lock methodsFor: 'create'!

create: loginID {ID} with: lockSmith {FeLockSmith}

	super create.
	myLoginClubID := loginID.
	myLockSmith := lockSmith.! !

!Lock methodsFor: 'server accessing'!

{FeKeyMaster} makeKeyMaster
	"The lock is opened - make the right KeyMaster"
	
	self hack. "This should eventually be done by manipulating the cookbooks"
	FeSession current isLoggedIn ifFalse:
		[FeSession current setInitialLogin: myLoginClubID].
	^FeKeyMaster make: myLoginClubID! !

!Lock methodsFor: 'protected:'!

{ID} fetchLoginClubID
	"The ID of the club whose authority you can get by opening this lock."
	
	^myLoginClubID!

{FeLockSmith} lockSmith
	"Essential. The LockSmith which made this Lock."
	
	^myLockSmith! !

!Lock methodsFor: 'smalltalk: passe'!

{ID} loginClubID

	self passe "fetch"! !

!Lock methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:18 pm'!

Lock subclass: #WallLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
WallLock comment:
'A Wall cannot be opened. Sorry, dude!!!!

Clubs can have WallLockSmiths for a variety of reasons. Clubs that represent groups of users, and to which noone should be able to login directly (only as a member using loginToSuperClub), will have WallLockSmiths. Or, if you want to make a document read-only, remove all the members from its editClub, make it self-reading, and put a WallLockSmith on it; then, noone can login to the club, either directly or as a member, and noone can change it. '!

(WallLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!WallLock methodsFor: 'private: create'!

create: loginID {ID} with: lockSmith {FeLockSmith}

	super create: loginID with: lockSmith! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WallLock class
	instanceVariableNames: ''!

(WallLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!WallLock class methodsFor: 'pseudo constructors'!

make: clubID {ID | NULL} with: lockSmith {FeLockSmith}

	^self create: clubID with: lockSmith! !
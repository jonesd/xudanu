'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:18 pm'!

Lock subclass: #MultiLock
	instanceVariableNames: 'myLocks {ImmuTable of: Sequence and: Lock}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
MultiLock comment:
'A MultiLock allows the client to open the lock with any of a list of Locks. This allows a Club to have different passwords for different people; or, the Locks can use different kinds of native authentication systems such as NIS or Kerberos.'!

(MultiLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!MultiLock methodsFor: 'create'!

create: loginID {ID} with: lockSmith {FeMultiLockSmith} with: locks {ImmuTable of: Lock}

	super create: loginID with: lockSmith.
	myLocks := locks! !

!MultiLock methodsFor: 'accessing'!

{Lock CLIENT login} lock: name {Sequence}
	"Get the named lock. You don't get any authority through a MultiLock directly, you merely get a Lock from which you can get authority."
	
	^(myLocks get: name) cast: Lock!

{SequenceRegion CLIENT login} lockNames
	"Essential. The names identifying the locks in the list"
	
	^(self lockSmith cast: FeMultiLockSmith) lockSmithNames! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiLock class
	instanceVariableNames: ''!

(MultiLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!MultiLock class methodsFor: 'create'!

make: loginID {ID | NULL} with: lockSmith {FeMultiLockSmith} with: locks {ImmuTable of: Lock}

	^self create: loginID with: lockSmith with: locks! !

!MultiLock class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Lock CLIENT} lock: name {Sequence}
{SequenceSpace CLIENT} lockNames
"! !
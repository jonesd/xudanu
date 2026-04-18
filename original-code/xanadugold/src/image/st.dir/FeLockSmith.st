'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:38 pm'!

FeWrapper subclass: #FeLockSmith
	instanceVariableNames: ''
	classVariableNames: 'TheLockSmithSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
FeLockSmith comment:
'Describes how to obtain the authority of a Club.'!

(FeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeLockSmith methodsFor: 'server locks'!

{Lock} newLock: clubID {ID unused | NULL}
	"Create a new lock which, if satisfied, will give access to this club. If Club is NULL, then the lock will never be satisfied."

	self subclassResponsibility! !

!FeLockSmith methodsFor: 'protected: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeLockSmith class
	instanceVariableNames: ''!

(FeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeLockSmith class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	FeWrapperSpec ABSTRACTWRAPPER: 'LockSmith' with: 'Wrapper' with: #FeLockSmith!

linkTimeNonInherited

	TheLockSmithSpec := NULL.! !

!FeLockSmith class methodsFor: 'private: wrapping'!

{void} setSpec: spec {FeWrapperSpec}

	TheLockSmithSpec := spec.! !

!FeLockSmith class methodsFor: 'pseudo constructors'!

{FeWrapperSpec} spec

	^TheLockSmithSpec! !
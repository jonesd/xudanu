'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:30 pm'!

ChunkCleaner subclass: #PersistentCleaner
	instanceVariableNames: ''
	classVariableNames: 'ThePersistentCleaner {PersistentCleaner} '
	poolDictionaries: ''
	category: 'Xanadu-packer'!
PersistentCleaner comment:
'This does a makePersistent when ServerChunks go away'!

(PersistentCleaner getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PersistentCleaner methodsFor: 'invoking'!

{void} cleanup
	CurrentPacker fluidGet purge! !

!PersistentCleaner methodsFor: 'protected: create'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PersistentCleaner class
	instanceVariableNames: ''!

(PersistentCleaner getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PersistentCleaner class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	ThePersistentCleaner := NULL! !

!PersistentCleaner class methodsFor: 'create'!

make
	ThePersistentCleaner == NULL ifTrue: [ThePersistentCleaner := self create].
	^ ThePersistentCleaner! !
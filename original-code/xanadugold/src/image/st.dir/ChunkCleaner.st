'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:32 pm'!

Heaper subclass: #ChunkCleaner
	instanceVariableNames: 'myNext {ChunkCleaner}'
	classVariableNames: 'FirstCleaner {ChunkCleaner} '
	poolDictionaries: ''
	category: 'Xanadu-schunk'!
ChunkCleaner comment:
'Chunk cleaners perform end-of-session cleanup work.  This includes making sure that session level objects are released.'!

(ChunkCleaner getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ChunkCleaner methodsFor: 'private: accessing'!

{ChunkCleaner} next
	^ myNext! !

!ChunkCleaner methodsFor: 'invoking'!

{void} cleanup
	self subclassResponsibility! !

!ChunkCleaner methodsFor: 'protected: create'!

create
	super create.
	myNext := FirstCleaner.
	FirstCleaner := self.! !

!ChunkCleaner methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChunkCleaner class
	instanceVariableNames: ''!

(ChunkCleaner getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ChunkCleaner class methodsFor: 'cleanup'!

{void} beClean
	| cleaner {ChunkCleaner} |
	cleaner := FirstCleaner.
	[cleaner ~~ NULL] whileTrue: [
		cleaner cleanup.
		cleaner := cleaner next].! !

!ChunkCleaner class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	FirstCleaner := NULL! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:54 pm'!

XnExecutor subclass: #Cattleman
	instanceVariableNames: 'myPasture {DiskManager}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-diskman'!
Cattleman comment:
'Remove flocks from the snarfpacker'!

(Cattleman getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Cattleman methodsFor: 'create'!

create: dm {DiskManager}
	super create.
	myPasture := dm! !

!Cattleman methodsFor: 'invoking'!

{void} execute: token {Int32}
	"[Drops add: token] smalltalkOnly."
	(Heaper isConstructed: myPasture) ifTrue: [
		[Heaper setGC: true] smalltalkOnly.
		myPasture dropFlock: token.
		[Heaper setGC: false] smalltalkOnly]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Cattleman class
	instanceVariableNames: ''!

(Cattleman getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Cattleman class methodsFor: 'create'!

make: dm {DiskManager}
	^ self create: dm! !
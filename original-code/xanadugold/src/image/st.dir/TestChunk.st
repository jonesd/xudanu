'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:48 pm'!

ServerChunk subclass: #TestChunk
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-srvloop'!

(TestChunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestChunk methodsFor: 'accessing'!

{void} processInput! !

!TestChunk methodsFor: 'execute'!

{BooleanVar} execute
	^ false! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:45 pm'!

ServerChunk subclass: #MacListener
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-macsrv'!

(MacListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MacListener methodsFor: 'accessing'!

{BooleanVar} hasTraffic

	^self subclassResponsibility!

{void} processInput

	self subclassResponsibility.!

{void} registerFor

	ServerLoop introduceChunk: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacListener class
	instanceVariableNames: ''!

(MacListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MacListener class methodsFor: 'exceptions: exceptions'!

problems.MacTCPERRS
	^self signals: #(MacTCP.U.ERRS)! !
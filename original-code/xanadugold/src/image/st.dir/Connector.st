'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:23 pm'!

Heaper subclass: #Connector
	instanceVariableNames: 'myWrapped '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Builders'!


!Connector methodsFor: 'creation'!

create: wrapped {Connector}
	super create.
	myWrapped _ wrapped.! !

!Connector methodsFor: 'proxy accessing'!

{Connector} inner
	"the innermost connector I wrap"
	myWrapped == NULL
		ifTrue: [^self]
		ifFalse: [^myWrapped inner]!

{Connector} outer
	"the outermost connector I wrap"
	self subclassResponsibility!

{Connector} wrap: wrapped {Connector}
	"wrap another connector"
	self subclassResponsibility!

{Connector} wrapBy: wrapper {Connector default: NULL}
	"return a new instance for wrapper to wrap"
	"NULL wrapper implies I have been unwrapped"
	^self builder materialize: wrapper!

{Connector} wrapped
	"the connector I wrap"
	self subclassResponsibility! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:55 pm'!

MethodChange subclass: #MethodOtherChange
	instanceVariableNames: 'type '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
MethodOtherChange comment:
'Class MethodOtherChange represents a change to a method other than new definition or removal.

Instance Variables:
	type <Symbol>
	'!


!MethodOtherChange methodsFor: 'accessing'!

name
	^type, ' ', className, ' ', selector!

type
	^type!

type: aSymbol
	type _ aSymbol! !

!MethodOtherChange methodsFor: 'checking'!

checkWith: aChecker
	aChecker changesAt: self name add: self.
	aChecker addDoIt: self! !
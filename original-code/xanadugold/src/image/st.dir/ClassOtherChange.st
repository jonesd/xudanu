'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:53 pm'!

ClassChange subclass: #ClassOtherChange
	instanceVariableNames: 'type '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
ClassOtherChange comment:
'Class ClassOtherChange represents a change to a class, other than a class definition. 

Instance Variables:
	type	<String>   Possible types are:  comment, initialize, inst vars for, rename, and rename to.'!


!ClassOtherChange methodsFor: 'accessing'!

name
	^'  ', type, ' ', className!

type
	^type!

type: aSymbol
	type _ aSymbol! !

!ClassOtherChange methodsFor: 'checking'!

checkWith: aChecker 
	type == #initialize ifFalse: [aChecker changesAt: className add: self].
	type == #'inst vars for' ifFalse: [aChecker addDoIt: self]! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:59 pm'!

ChangeRecord subclass: #DoItCR
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!DoItCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ' DOIT'! !

!DoItCR methodsFor: 'storing'!

{Boolean} isPersistent
	"whether this should persist in standard file outs"
	^ false! !
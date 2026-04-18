'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:06 pm'!

Object subclass: #Magnitude
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-General'!
Magnitude comment:
'The abstract class Magnitude provides common protocol for objects that have the ability to be compared along a linear dimension like dates or times. Subclasses of Magnitude include Date, ArithmeticValue, and Time, as well as Character, LookupKey, and MessageTally.

Subclasses must implement methods for 
	comparing
		<
		=
		hash'!


!Magnitude methodsFor: 'comparing'!

< aMagnitude 
	"Answer whether the receiver is less than the argument."

	^self subclassResponsibility!

<= aMagnitude 
	"Answer whether the receiver is less than or equal to the argument."

	^(self > aMagnitude) not!

= aMagnitude 
	"Answer whether the receiver is equal to the argument."

	^self subclassResponsibility!

> aMagnitude 
	"Answer whether the receiver is greater than the argument."

	^aMagnitude < self!

>= aMagnitude 
	"Answer whether the receiver is greater than or equal to the argument."

	^(self < aMagnitude) not!

between: min and: max 
	"Answer whether the receiver is less than or equal to the argument, max,
	and greater than or equal to the argument, min."

	^self >= min and: [self <= max]!

hash
	"Answer a SmallInteger unique to the receiver."

	^self subclassResponsibility!

max: aMagnitude 
	"Answer the receiver or the argument, whichever has the greater magnitude."

	self > aMagnitude
		ifTrue: [^self]
		ifFalse: [^aMagnitude]!

min: aMagnitude 
	"Answer the receiver or the argument, whichever has the lesser magnitude."

	self < aMagnitude
		ifTrue: [^self]
		ifFalse: [^aMagnitude]! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:46 pm'!

Heaper subclass: #NotSoTextyXmtr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Never Never Land'!



!NotSoTextyXmtr methodsFor: 'specialist sending'!

{void} sendUInt4: word {UInt4}
	self startThing.
	self putByte: $u uint8.
	self putUInt4: word.
	self endThing! !
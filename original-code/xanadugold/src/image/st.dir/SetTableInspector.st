'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:40 pm'!

HashTableInspector subclass: #SetTableInspector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!



!SetTableInspector methodsFor: 'field'!

fieldValue
	| set {Collection} |
	set _ Set new.
	field = #self ifTrue: [^object].
	(object stepperAt: (self fieldIndex)) forEach: [:obj |
		set add: obj].
	^set! !
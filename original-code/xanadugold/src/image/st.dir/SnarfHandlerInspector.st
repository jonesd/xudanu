'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:46 pm'!

Inspector subclass: #SnarfHandlerInspector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!



!SnarfHandlerInspector methodsFor: 'field list'!

fieldIndex
	"Answer the index of the currently selected field, or nil if no index is selected."

	field isNil ifTrue: [^nil].
	field = 'self' ifTrue: [^nil].
	^Integer readFromString: field!

fieldList
	^(Array with: 'self') , ((0 to: object mapCount-1) collect: [:i | i printString])!

fieldValue
	| result |
	field = 'self' ifTrue: [^object].
	result _ object fetchForward: self fieldIndex.
	result == NULL ifTrue:
		[result _ object readStream: self fieldIndex].
	(object checkFence: self fieldIndex) ifTrue: [^result]
		ifFalse: [^Array with: 'Broken Fence
'				with: result]! !
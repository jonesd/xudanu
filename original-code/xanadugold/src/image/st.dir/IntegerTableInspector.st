'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:38 pm'!

Inspector subclass: #IntegerTableInspector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!


!IntegerTableInspector methodsFor: 'menu commands'!

addField
	field == nil
		ifTrue: [object atInt: (object domain stop) introduce: #nothing]	"nothing selected"
		ifFalse: [self fieldIndex isNil
				ifTrue: [object addFirst: nil]	"self selected"
				ifFalse: [object add: nil beforeIndex: self fieldIndex]].
	self changed: #field!

inspectFrame
	object basicInspect!

removeField
	| waldo |
	self fieldIndex isNil ifTrue: [^self].
	waldo _ IntegerTableWaldo make: object.
	waldo deflate: (IntegerRegion make: self fieldIndex).
	self changed: #field! !

!IntegerTableInspector methodsFor: 'field'!

acceptText: aText from: aController 
	| val |
	self fieldIndex isNil ifTrue: [^false].
	val _ self evaluateText: aText string
				from: aController
				ifFail: [^false].
	(val = NULL or: [val = nil])
		ifTrue: [object intWipe: (Integer readFromString: field)]
		ifFalse: [object at: (Integer readFromString: field)
				store: val].
	self changed: #text.
	^true!

fieldIndex
	"Answer the index of the currently selected field, or nil if no index is selected."

	field isNil ifTrue: [^nil].
	field = 'self' ifTrue: [^nil].
	^Integer readFromString: field!

fieldList
	"Answer a collection of strings with 'self' and the keys of 
	the inspected IntegerTable."

	| res stp |
	res _ Array with: 'self'.
	stp _ object stepper.
	[stp hasValue]
		whileTrue: [res _ res , (Array with: stp key asIntegerVar printString).
			stp step].
	^res!

fieldMenu
	"Menu for inspector on an integer table.  (Xanadu)"
	
	self fieldIndex isNil ifTrue:
		[^PopUpMenu fromArray:  #(
			('discard'			removeField		'Xu: Remove the selected key/value association.  Bug????')
			('inspect frame'		inspectFrame	'Xu: Bring up the default inspector on this HashTable (to view the underlying implementation).') )].
			
	^PopUpMenu fromArray:  #(
		('inspect'			inspectField		'Xu: Bring up an inspector on the value of the selected key/value pair.')
		-
		('discard'			removeField		'Xu: Remove the selected key/value association.') ).!

fieldValue
	field = 'self' ifTrue: [^object].
	^ object intFetch: (self fieldIndex)! !
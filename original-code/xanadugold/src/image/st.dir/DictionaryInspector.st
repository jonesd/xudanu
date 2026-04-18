'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:10 pm'!

Inspector subclass: #DictionaryInspector
	instanceVariableNames: 'ok '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
DictionaryInspector comment:
'A DictionaryInspector is an Inspector that provides the special modelling whereby the name list of the inspector are the keys of the dictionary.  Note that the fields contain the actual current dictionary key object, not a field name string.

Instance Variables:
	ok	<Boolean>	true if the user has provided a legal new key to be added to the dictionary
	
Class Variables:
	DictListMenu	<ActionMenu> of operations on the keys of the dictionary being inspected'!


!DictionaryInspector methodsFor: 'field list'!

acceptText: aText from: aController
	"Text has been changed.  Store or compile the text, depending on 
	the current mode of the receiver."

	| val |
	field == nil ifTrue: [^ false].
	val _ self evaluateText: aText string from: aController ifFail: [^ false].
	object at: field put: val.
	self changed: #text.
	^ true!

fieldList
	"Answer a collection of the keys of the inspected dictionary."

	| keys | 
	keys _ object keys.
	keys
		detect: [:key | key isSymbol not]
		ifNone: [^keys asSortedCollection]. "sort dictionaries with Symbol keys"
	^keys asOrderedCollection!

fieldMenu
	"Menu for inspector on dictionary."

	field == nil ifTrue:
		[^PopUpMenu fromArray: #(
			('add field'	addField				'ST: Prompt for a key.  Add it to the dictionary.') )].
			
	^PopUpMenu fromArray: #(
		('inspect'		inspectField			'ST: Bring up an inspector on the value of the selected key/value pair.')
		('references'	browseReferences	'Xu: Bring up a browser on all methods that point to the selected key/value association.  (Such pointing is a smalltalk internal idiom for encoding class, global variable, and class variable references.)')
		-
		('add field'		addField			'ST: Prompt for a key.  Add it to the dictionary.')
		('remove'		removeField			'ST: Remove selected key/value pair from the dictionary.') ).!

fieldValue

	^object at: field!

printItems
	"Answer whether the elements of the fieldList need to be converted to strings"

	^true! !

!DictionaryInspector methodsFor: 'compiler interface'!

insertAndSelect: aString at: ignoredIndex
	ok _ false! !

!DictionaryInspector methodsFor: 'private: private-menu messages'!

browseReferences
	Smalltalk browseAllCallsOn: (object associationAt: field)!

removeField

	(self confirm: 'Confirm removal of ', field printString) ifFalse: [^self].
	object removeKey: field.
	field _ nil.
	self changed: #field! !

!DictionaryInspector methodsFor: 'menu commands'!

addField
	| aString key |
	aString _ FillInTheBlank request: 'Enter key as a Smalltalk constant'.
	aString isEmpty ifTrue: [^self].
	ok _ true.
	key _ Object evaluatorClass evaluate: aString.
	ok ifFalse: [^nil].
	key == nil ifTrue: [^nil].
	object add: (Association key: key value: nil).
	field _ key.
	self changed: #field! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DictionaryInspector class
	instanceVariableNames: ''!


!DictionaryInspector class methodsFor: 'class initialization'! !

!DictionaryInspector class methodsFor: 'examples'!

inspectExample
	"Create and schedule an Inspector in which the user can examine the
	receiver's variables."

	"DictionaryInspector inspectExample."

	| dictionary |
	dictionary _ Dictionary new.
	dictionary at: 'A' put: $A.
	dictionary at: 'Two' put: 2.
	dictionary at: 'Three' put: 3.
	InspectorView open: (DictionaryInspector inspect: dictionary)! !
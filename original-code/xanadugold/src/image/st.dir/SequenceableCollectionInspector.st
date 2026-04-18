'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:12 pm'!

Inspector subclass: #SequenceableCollectionInspector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
SequenceableCollectionInspector comment:
'Class SequenceableCollectionInspector represents a query path into the contents of a SequenceableCollection, such as a String of IntegerArray.  It presents the same list of fields seen by the at:, at:put:, and size messages.  In fact, it uses the messages at: and at:put:, rather than instVarAt:/put: or basicAt:/put:, to fetch and (in the case of accept) store into the object being inspected.  It also allows access to all indices of the receiver, and do not elide the middle ones as the basic Inspector does.
'!


!SequenceableCollectionInspector methodsFor: 'field list'!

acceptText: aText from: aController
	"Text has been changed.  Store or compile the text, depending on 
	the current mode of the receiver."

	| val |
	self fieldIndex isNil ifTrue: [^false].
	val _ self evaluateText: aText string from: aController ifFail: [^false].
	object at: self fieldIndex put: val.
	self changed: #text.
	^true!

fieldIndex
	"Answer the index of the currently selected field, or nil if no index is selected."

	field isNil ifTrue: [^nil].
	field = 'self' ifTrue: [^nil].
	^Integer readFromString: field!

fieldList
	^(Array with: 'self') , ((1 to: object size) collect: [:i | i printString])!

fieldValue
	field = 'self' ifTrue: [^object].
	^object at: self fieldIndex! !
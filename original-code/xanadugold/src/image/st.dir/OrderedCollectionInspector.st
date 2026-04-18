'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:11 pm'!

SequenceableCollectionInspector subclass: #OrderedCollectionInspector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
OrderedCollectionInspector comment:
'An OrderedCollectionInspector represents a query path into the contents of an OrderedCollection.  It presents the same list of fields seen by the at:, at:put:, and size messages.  That is, they maintain the fiction that the OrderedCollection only contains those elements between firstIndex and lastIndex.

Class Variables:
	OrderedCollectionMenu  <ActionMenu> of operations on the selected element of the collection'!


!OrderedCollectionInspector methodsFor: 'field list'!

fieldMenu
	"Menu for inspector on an ordered collection."
	
	self fieldIndex isNil ifTrue:
		[^PopUpMenu fromArray: #(
			('add'				addField		'') )].
		
	^PopUpMenu fromArray:  #(
		('inspect'			inspectField		'')	"Rest are standard smalltalk."
		-
		('backreference'	ownersOfField	'Xu: Ravi: Bring up an inspector on a set containing those objects that point at the value of the selected key/value pair.  (To debug why an object has not been garbage collected.)')
		('insert'				addField		'')
		('remove'			removeField		'') ).! !

!OrderedCollectionInspector methodsFor: 'private: private-menu messages'!

addField

	field == nil
		ifTrue: [object addLast: nil]	"nothing selected"
		ifFalse: [self fieldIndex isNil
				ifTrue: [object addFirst: nil]	"self selected"
				ifFalse: [object add: nil beforeIndex: self fieldIndex]].
	self changed: #field!

removeField
	self fieldIndex isNil ifTrue: [^self].
	object removeAtIndex: self fieldIndex.
	self changed: #field! !
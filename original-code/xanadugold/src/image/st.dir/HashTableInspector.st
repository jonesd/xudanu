'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:36 pm'!

Inspector subclass: #HashTableInspector
	instanceVariableNames: ''
	classVariableNames: 'HashTableMenu IntegerTableMenu '
	poolDictionaries: ''
	category: 'Xanadu-Testing'!


!HashTableInspector methodsFor: 'field'!

fieldIndex
	"Answer the index of the currently selected field, or nil if no index is selected."

	field isNil ifTrue: [^nil].
	field = 'self' ifTrue: [^nil].
	^field!

fieldList
	"Answer a collection of strings with 'self' and the keys of 
	the inspected IntegerTable."

	| res i |
	res _ Array new: object count + 1.
	res at: 1 put: #self.
	i _ 2.
	object stepper forKeyValues:
		[:key :value | res at: i put: key.
		i _ i + 1].
	^res!

fieldMenu
	"Menu for inspector on a hash table.  (Xanadu)"
	
	self fieldIndex isNil ifTrue:
		[^PopUpMenu fromArray: #(
			('discard'			removeField		'Xu: Remove the selected key/value association.  Bug????')
			('inspect frame'		inspectFrame	'Xu: Bring up the default inspector on this HashTable (to view the underlying implementation).') )].
			
	^PopUpMenu fromArray: #(
		('inspect'		inspectField			'Xu: Bring up an inspector on the value of the selected key/value pair.')
		-
		('discard'		removeField			'Xu: Remove the selected key/value association.') ).!

fieldValue

	field = #self ifTrue: [^object].
	^ object fetch: (self fieldIndex)!

printItems
	"Answer whether the elements of the fieldList need to be converted to strings"

	^true! !

!HashTableInspector methodsFor: 'menu commands'!

inspectFrame
	object basicInspect! !
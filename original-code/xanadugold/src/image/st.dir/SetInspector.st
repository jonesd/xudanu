'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:40 pm'!

Inspector subclass: #SetInspector
	instanceVariableNames: ''
	classVariableNames: 'SetMenu '
	poolDictionaries: ''
	category: 'Xanadu-Testing'!


!SetInspector methodsFor: 'field'!

fieldIndex
	"Answer the index of the currently selected field, or nil if no index is selected."

	field isNil ifTrue: [^nil].
	'self' = field ifTrue: [^nil].
	^field!

fieldList
	"Answer a collection of strings with 'self' and the keys of 
	the inspected Set."

	| res stp |
	res _ Array with: #self.
	stp _ object stepper. 
	stp forEach: [:val | res _ res , (Array with: val)].
	^res!

fieldMenu
	"Menu for inspector on a set.  (Xanadu)"
	
	self fieldIndex isNil ifTrue:
		[^PopUpMenu fromArray:  #(
			('discard'			removeField		'Xu: Remove the selected value.  Bug????')
			('inspect frame'		inspectFrame	'Xu: Bring up a default inspector (to view the underlying implementation of the set).') )].
			
	^PopUpMenu fromArray:  #(
		('inspect'		inspectField			'Xu: Bring up an inspector on the selected value.')
		-
		('basic Inspect'	basicInspectField	'Xu: Bring up a default inspector on the selected value (to view the underlying implementation).') ).!

fieldValue

	field == #self ifTrue: [^object].
	^self fieldIndex!

printItems
	"Answer whether the elements of the fieldList need to be converted to strings"

	^true! !

!SetInspector methodsFor: 'menu commands'!

basicInspectField
	self fieldValue basicInspect!

inspectFrame
	object basicInspect! !
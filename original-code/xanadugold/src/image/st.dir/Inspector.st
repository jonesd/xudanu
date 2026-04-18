'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:10 pm'!

Model subclass: #Inspector
	instanceVariableNames: 'object field '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
Inspector comment:
'Class Inspector represents a query path into the internal representation of an object.  The value of its fields can be inspected by selecting the field name, and can be changed using ''accept''.

Instance Variables:
	object		<Object> to be queried
	field		<String> name of field (variable of object) currently selected

Class Variables:
	ListMenu 	<ActionMenu> of operations on the selected field
	TextMenu	<ActionMenu> of operations on the value of the field'!


!Inspector methodsFor: 'initialize-release'!

inspect: anObject 
	"Set anObject to be the object inspected by the receiver."

	anObject == object ifTrue: [^ self update].
	object _ anObject.
	self changed: #field!

object
	"Answer the object being inspected by the receiver."

	^object! !

!Inspector methodsFor: 'updating'!

update
	"Reshow contents, assuming selected value may have changed."

	field ~~ nil ifTrue: [self changed: #text]! !

!Inspector methodsFor: 'field list'!

field
	"Answer the currently selected variable."

	^ field!

field: selection
	"Set selection to be the currently selected variable."

	field _ selection.
	self changed: #text!

fieldIndex
	"Answer the offset corresponding to the currently selected field."

	field first isDigit
		ifTrue: [^ Integer readFromString: field]
		ifFalse: [^ object class allInstVarNames indexOf: field]!

fieldList
	"Answer an Array consisting of 'self' and the instance variable 
	names of the inspected object. Up to 100 indices are given for 
	variable length objects."

	| max |
	max _ object basicSize.
	^(Array with: 'self')
		, object class allInstVarNames , ((max <= 100
			ifTrue: [1 to: max]
			ifFalse: [(1 to: 90)
					, (max - 10 to: max)])
			collect: [:i | i printString])!

fieldMenu
	"Generic menu for inspectors - overridden for specialized inspectors."

	field == nil ifTrue: [^PopUpMenu fromArray: #(
		('backreference'	ownersOfSelf	'Xu: Ravi: Bring up an inspector on a set containing those objects that point at this object.  (To debug why an object has not been garbage collected.)') )].
		
	^PopUpMenu fromPrefixedArray: #(
		(all				'inspect'			inspectField		'ST: Bring up an inspector on the value of the selected instance variable.')
		(all				'browse'			browseField		'Xu: Bring up a hierarchy(?) browser on the class of the value of this instance variable.')
		(screenplay	'audition'			auditionField	'Xu: Markm will document it when he decides it works.')
		(all				'backreference'	ownersOfField	'Xu: Ravi: Bring up an inspector on a set containing those objects that point at the value of the selected instance variable.  (To debug why an object has not been garbage collected.)') ).!

fieldValue
	"Answer the value of the currently selected variable."

	field = 'self' ifTrue: [^object].
	field first isDigit
		ifTrue: [^object basicAt: self fieldIndex]
		ifFalse: [^object instVarAt: self fieldIndex]!

printItems
	"Answer whether the elements of the list of fields needs to be converted to strings"

	^false! !

!Inspector methodsFor: 'text'!

text
	| ts |
	field == nil ifTrue: [^ Text new].
	ts _ TextStream on: String new.
	^ts print: self fieldValue; contents!

textMenu
	^PopUpMenu standardTextMenu! !

!Inspector methodsFor: 'doIt/accept/explain'!

acceptText: aText from: aController
	"Text has been changed.  Store or compile the text, depending on 
	the current mode of the receiver."

	| val |
	object class == CompiledMethod
		ifTrue: [^false].
	field == nil ifTrue: [^false].
	val _ self evaluateText: aText string from: aController ifFail: [^ false].
	field first isLetter
		ifTrue: [object instVarAt: self fieldIndex put: val]
		ifFalse: [object basicAt: self fieldIndex put: val].
	self changed: #text.
	^ true!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^ nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^object!

doItValue: ignored
	"Set the value to be returned when the interrupted process proceeds."!

evaluateText: aText from: aController ifFail: failBlock
	"The user wishes to evaluate expressions in the value part of an inspector.
	Do so in the context of the inspector's variables.  Evaluate failBlock
	if the evaluation does not work."
	
	^ object class evaluatorClass new evaluate: aText
		in: self doItContext to: self doItReceiver
		notifying: aController ifFail: failBlock! !

!Inspector methodsFor: 'private: private-menu messages'!

{NO_RETURN} auditionField
	self fieldValue audition!

{void} browseField
	self fieldValue browseHierarchy!

inspectField
	Sensor leftShiftDown ifTrue: [self fieldValue basicInspect] ifFalse: [self fieldValue inspect]!

ownersOfField

	| ownr |
	ownr _ self fieldValue allOwners.
	ownr remove: self ifAbsent: [].
	ownr inspect!

ownersOfSelf

	| ownr |
	ownr _ object allOwners.
	ownr inspect! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Inspector class
	instanceVariableNames: ''!


!Inspector class methodsFor: 'class initialization'! !

!Inspector class methodsFor: 'instance creation'!

inspect: anObject 
	"Answer an instance of me to provide an inspector for anObject."
	^self new inspect: anObject! !
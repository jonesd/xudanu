'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:10 pm'!

Inspector subclass: #ContextInspector
	instanceVariableNames: 'tempNames '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
ContextInspector comment:
'Class ContextInspector represents a query path into the internal representation of a ContextPart.  Typically this is a context at a point in the query path of a Debugger.  As a StringHolder, the string the ContextInspector represents is the value of the currently selected variable of the observed temporary variable of the context.

Instance Variables:
	tempNames	<Array of: Strings>  each the name of a temporary variable.
'!


!ContextInspector methodsFor: 'initialize-release'!

inspect: anObject 
	"Initialize the receiver so that anObject is the object to be inspected."

	object _ anObject.
	self changed: #field! !

!ContextInspector methodsFor: 'field list'!

fieldIndex
	"Answer the offset corresponding to the currently selected field."

	^ tempNames indexOf: field!

fieldList
	object == nil ifTrue: [^nil].
	^(tempNames _ object tempNames)!

fieldMenu
	"Menu for inspector panes in the debugger."

	field == nil ifTrue: [^ nil].
	
	^PopUpMenu fromArray: #(
		('inspect'	inspectField		'ST: ') ).!

fieldValue
	"field = 'self' ifTrue: [^ object receiver]."
	^ object tempAt: self fieldIndex! !

!ContextInspector methodsFor: 'doIt/accept'!

acceptText: aText from: aController
	"Text has been changed.  Store or compile the text, depending on 
	the current mode of the receiver."

	| val |
	(field == nil) | (field = 'self') ifTrue: [^ false].
	val _ self evaluateText: aText string from: aController ifFail: [^ false].
	object tempAt: self fieldIndex put: val.
	self changed: #text.
	^ true!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^object!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^object homeReceiver! !
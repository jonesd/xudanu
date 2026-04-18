'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:43 pm'!

TextView subclass: #CodeView
	instanceVariableNames: 'initialSelection '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
CodeView comment:
'A CodeView is a TextView that assumes the text is code.  It includes support for initial selection of a part of the text.

Instance Variables:
	initialSelection <nil | String | Text> nil or a message selector that is used to determine the initial text to highlight/select'!


!CodeView methodsFor: 'initialize-release'!

initialSelection: sel
	"Set the initial code selection to be sel."

	initialSelection _ sel!

newText: aText
	super newText: aText.
	(initialSelection == nil or: [initialSelection == NULL]) 
		ifFalse: [(initialSelection isKindOf: MethodAction)
			ifTrue: [ | sel {Interval | nil} |
				initialSelection emphasizeText: self controller text.
				sel _ initialSelection fetchSelection: self controller text startingAt: 1.
				sel ~~ nil 
					ifTrue: [self controller findInterval: sel]]
			ifFalse: [self controller find: initialSelection]]! !

!CodeView methodsFor: 'controller access'!

defaultControllerClass
	^ CodeController! !

!CodeView methodsFor: 'updating'!

update: aSymbol
	| range |
	aSymbol == #pc ifTrue:
		[range _ model pcRange.
		self controller selectAndScrollFrom: range first to: range last].
	aSymbol == #breakPC ifTrue: [^model breakPCFrom: controller].
	super update: aSymbol! !

!CodeView methodsFor: 'control'!

isSelected
	"Answer true for use with OnlyWhenSelectedCodeController"

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CodeView class
	instanceVariableNames: ''!


!CodeView class methodsFor: 'instance creation'!

on: anObject aspect: m1 change: m3 menu: m4 initialSelection: sel
	"Create an instance viewing anObject.  See super method in TextView for full
	explanation.  initialSelection (if not nil) is a string which will be searched for,
	and then highlighted if found, whenever the viewed text changes."

	^ (super on: anObject aspect: m1 change: m3 menu: m4) initialSelection: sel! !
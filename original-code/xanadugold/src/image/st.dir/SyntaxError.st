'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:09 pm'!

Model subclass: #SyntaxError
	instanceVariableNames: 'class badText processHandle '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Programming'!
SyntaxError comment:
'SyntaxError represents a report of a syntax error when reading class descriptions from a noninteractive source such as an external file.  As a StringHolder, the string to be viewed is the code or expression containing the error.

Instance Variables:
	class <Class>
	badText <Text>
	processHandle <ProcessHandle>

Class Variables:
	TextMenu 	<nil | ActionMenu>'!


!SyntaxError methodsFor: 'text'!

proceed
	"Continue the file in, ignoring this section of code, regardless of whether or not the
	syntax error was corrected."

	self changeRequest ifTrue: [processHandle proceed]!

text
	"Answer the text displayed by the receiver."

	^ badText!

textMenu
	"Menu for reporting syntax errors, typically when filing in code."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept syntax)! !

!SyntaxError methodsFor: 'doIt/accept/explain'!

acceptText: aString from: aController 
	"Compile the code in aString and notify aController of any errors.
	Proceed if successful."

	(class
		compile: aString
		classified: ClassOrganizer defaultProtocol
		notifying: aController)
		== nil
			ifTrue: [^false]
			ifFalse: [^true]!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^ nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^ nil!

doItValue: ignored
	"Set the value to be returned when the interrupted process proceeds."! !

!SyntaxError methodsFor: 'dependents access'!

removeDependent: aDependent 
	super removeDependent: aDependent.
	self dependents isEmpty "detect when closing"
		ifTrue: [processHandle terminate]! !

!SyntaxError methodsFor: 'private: private'!

setClass: aClass code: aString processHandle: aProcessHandle
	class _ aClass.
	processHandle _ aProcessHandle.
	badText _ aString asText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SyntaxError class
	instanceVariableNames: ''!


!SyntaxError class methodsFor: 'class initialization'! !

!SyntaxError class methodsFor: 'instance creation'!

errorInClass: aClass withCode: aString errorString: errorString
	"Create and scehduled a StandardSystemView whose model is an instance of the receiver.
	The syntax error occurred in trying to add code, aString, to class, aClass."

	| aSyntaxError topView |
	Cursor normal show.
	aSyntaxError _ self new
			setClass: aClass
			code: aString
			processHandle: (ProcessHandle on: Processor activeProcess at: thisContext interrupted: false).
	topView _ StandardSystemView model: aSyntaxError label: 'Syntax Error' minimumSize: 300 @ 180.
	topView addSubView:
			(CodeView on: aSyntaxError aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: errorString)
		in: (0@0 extent: 1@1) borderWidth: 1.
	topView controller openNoTerminateDisplayAt: Display extent // 2.
	Processor activeProcess suspend! !
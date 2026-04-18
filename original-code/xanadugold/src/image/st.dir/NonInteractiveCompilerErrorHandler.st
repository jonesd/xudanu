'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:34 pm'!

CompilerErrorHandler subclass: #NonInteractiveCompilerErrorHandler
	instanceVariableNames: 'source '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
NonInteractiveCompilerErrorHandler comment:
'I receive error notifications during code generation, and deal with them as well as possible without user interaction.'!


!NonInteractiveCompilerErrorHandler methodsFor: 'initialize-release'!

source: aStream
	source _ aStream! !

!NonInteractiveCompilerErrorHandler methodsFor: 'error handling'!

error: type with: message at: sourcePosition
	"Possible values of type:
		#syntax, message = error message
		#newSelector, message = selector"
	type == #newSelector ifTrue: [^self].  "allow new selectors if non-interactive"
	^self interactiveError: message at: sourcePosition!

error: type with: message in: node from: codeStream
	"Possible values of type:
		#error, message = error message
		#warning, message = error message
		#readBeforeWritten, message = var name
		#neverRead, message = var name, node = assignment
		#neverUsed, message = var name
		#redeclared, message = var name
		#redeclaredBlockArg, message = var name
		#undeclared, message = var Association
		#undeclaredStore, message = var Association, node = assignment
		#noEffect, message = nil, node = statement"
	| name |
	type == #error
		ifTrue: [^self interactiveError: message at: node sourcePosition first].
	(type == #undeclared or: [type == #undeclaredStore])
		ifTrue:
			[name _ message key asSymbol.
			(Undeclared includesKey: name) ifFalse:
				[self nonInteractiveError: name , ' is Undeclared'.
				message key: name.
				Undeclared add: message].
			^self  "go on"].
	self nonInteractiveError: (message isNil ifTrue: [''] ifFalse: [message, ' - ']), type.
	Transcript endEntry! !

!NonInteractiveCompilerErrorHandler methodsFor: 'private: private'!

interactiveError: aString at: position
	Cursor normal show.
	SyntaxError
		errorInClass: class
		withCode:
			(source contents
				copyReplaceFrom: position
				to: position - 1
				with: aString)
		errorString: aString.
	^self abort!

nonInteractiveError: message
	| s |
	s _ class printString.
	selector notNil ifTrue: [s _ s , ' ' , selector printString].
	Transcript show: ' (' , s , ' - ' , message , ') '! !
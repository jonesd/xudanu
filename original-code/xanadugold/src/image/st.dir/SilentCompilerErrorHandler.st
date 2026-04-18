'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:35 pm'!

CompilerErrorHandler subclass: #SilentCompilerErrorHandler
	instanceVariableNames: 'editor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
SilentCompilerErrorHandler comment:
'I handle errors for program-initiated compilation: I ignore warnings, and evaluate a failBlock on errors.  If used with an editor, I ignore warnings, but notify the editor of non-proceedable errors.'!


!SilentCompilerErrorHandler methodsFor: 'initialize-release'!

editor: ed
	editor _ ed!

source: aStream
	"This is only needed to make the protocol
	compatible with the NonInteractive handler."! !

!SilentCompilerErrorHandler methodsFor: 'error handling'!

error: type with: message at: sourcePosition
	"Possible values of type:
		#syntax, message = error message
		#newSelector, message = selector"
	type == #newSelector ifTrue: [^self].  "allow new selectors if non-interactive"
	^self error: message at: sourcePosition!

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
	type ~= #error ifTrue: [^self].
	^self error: (message isNil ifTrue: [type asString] ifFalse: [message]) at: node sourcePosition first! !

!SilentCompilerErrorHandler methodsFor: 'private: private'!

error: aString at: position
	editor isNil ifTrue: [^self abort].  "not interactive"
	Cursor normal show.
	aString isEmpty
		ifTrue:
			["insertAndSelect: adds a space on the front!!
			This is a kludge."
			editor selectAt: (position max: 1);
				deselect;
				selectAndScroll]
		ifFalse:
			[editor insertAndSelect: aString at: (position max: 1)].
	^self abort! !
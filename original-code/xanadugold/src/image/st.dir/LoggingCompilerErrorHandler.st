'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:34 pm'!

CompilerErrorHandler subclass: #LoggingCompilerErrorHandler
	instanceVariableNames: 'logFile '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
LoggingCompilerErrorHandler comment:
'I handle compiler errors for batch compilation: I simply log all errors to a file.

For this class, the ''selector'' instance variable is always set in advance, because we are always compiling code that is already in a method dictionary.
'!


!LoggingCompilerErrorHandler methodsFor: 'initialize-release'!

logFile: log
	logFile _ log isNil ifTrue: [Transcript] ifFalse: [log]! !

!LoggingCompilerErrorHandler methodsFor: 'error handling'!

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
	| msg |
	msg _ message isNil
		ifTrue: ['']
		ifFalse: [((message isMemberOf: Association) ifTrue: [message key] ifFalse: [message]) , ' : '].
	logFile nextPutAll: class name , ' ' , "selector ," ' - ' , msg , type; cr.
	logFile == Transcript ifTrue: [logFile endEntry].
	type == #error ifTrue: [^self abort]! !
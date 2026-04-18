'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:32 pm'!

Object subclass: #CompilerErrorHandler
	instanceVariableNames: 'failBlock retryBlock class selector '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
CompilerErrorHandler comment:
'I am a generic abstract superclass that just defines the protocol for the ''requestor'' that gets passed to the SmalltalkParser and the CodeStream.  Use one of my concrete subclasses for actual error handling.  See my methods error:with:at: and error:with:in:from: for the various error messages I know how to handle.

Instance variables:
	failBlock	<Block>  "execute this for an unrecoverable error"
	retryBlock	<Block with: Integer>  "execute this to retry after a correction,"
			"the argument is the change in the size of the text"
	class	<Behavior>  "class in which compilation is occurring"
	selector	<nil | Symbol>  "selector of method (may be nil if syntax error)"
'!


!CompilerErrorHandler methodsFor: 'initialize-release'!

class: aClass
	class _ aClass!

failBlock: aBlock
	failBlock _ aBlock!

retryBlock: aBlock
	retryBlock _ aBlock!

selector: aSymbol
	selector _ aSymbol! !

!CompilerErrorHandler methodsFor: 'error handling'!

error: type with: message at: sourcePosition
	"This message is sent for errors during parsing.
	Possible values of type:
		#syntax, message = error message
		#newSelector, message = selector, sourcePosition is array of (source range,
			keyword positions or nil).
	Note: this comment is duplicated in all subclasses."

	self subclassResponsibility!

error: type with: message in: node from: codeStream
	"This message is sent for errors during
	code generation.  Possible values of type:
		#error, message = error message
		#warning, message = error message
		#readBeforeWritten, message = var name
		#neverRead, message = var name, node = assignment
		#neverUsed, message = var name
		#redeclared, message = var name
		#redeclaredBlockArg, message = var name
		#undeclared, message = var Association
		#undeclaredStore, message = var Association, node = assignment
		#noEffect, message = nil, node = statement.
	Note: this comment is duplicated in all subclasses."

	self subclassResponsibility! !

!CompilerErrorHandler methodsFor: 'private: private'!

abort
	"Fail after error interaction"
	^failBlock value!

retryWith: lengthChange
	"Retry after error recovery, if possible"
	^retryBlock == nil
		ifTrue: [failBlock value]
		ifFalse: [retryBlock value: lengthChange]! !
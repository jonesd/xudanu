'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:05 pm'!

Compiler subclass: #EnvironmentCompiler
	instanceVariableNames: 'environment '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
EnvironmentCompiler comment:
'An EnvironmentCompiler is a Smalltalk-80 compiler that is capable of evaluating code in the context of an environment with local scope.  Instances need to know about the legal local variables that may be referenced (i.e., environments must implement the message locals). Instances also specify which InteractiveCompilerErrorHandler to use when compilation errors occur.
Instance Variables
	environment	<Environment> that is used as the context for the compilation
'!


!EnvironmentCompiler methodsFor: 'public access'!

evaluate: textOrStream in: aContext receiver: anEnvironment notifying: aRequestor ifFail: failBlock 
	"This is the preferred method for having a compiler 
	compile/install/execute code. For the receiver, this method compiles 
	and executes the code in textOrStream. If the parameter 
	anEnvironment is not nil, then the text can refer to local variables of
	Environment. If aRequestor is not nil, then it will receive a notify:at: 
	message before the attempt to evaluate is aborted.  Failure results
	in the evaluation of the block failBlock."

	environment := anEnvironment.
	^super
		evaluate: textOrStream
		in: aContext
		receiver: anEnvironment
		notifying: aRequestor
		ifFail: failBlock! !

!EnvironmentCompiler methodsFor: 'private: private'!

getInteractiveCompilerErrorHandler
	"Answer an initialized instance of the error handler used by the 
	receiver."

	^(InteractiveEnvironmentCompilerErrorHandler new) 
		class: class; 
		editor: requestor; 
		environment: environment!

scopeForClass
	"Answer the sequence of scopes of variables available for reference 
	by the receiver's environment."

	| envScopes headScope tailScope scope |
	envScopes := environment localScopes.
	envScopes size = 0 ifTrue: [^super scopeForClass].
	headScope := tailScope := StaticScope variables: (envScopes at: 1).
	2 to: envScopes size do: 
		[:i | 
		scope := StaticScope variables: (envScopes at: i).
		tailScope outerScope: scope.
		tailScope := scope].
	tailScope outerScope: super scopeForClass.
	^headScope!

translate: aStream noPattern: noPattern ifFail: failBlock 
	"Translate the stream aStream into a compiled method. Chooses 
	which CompilerErrorHandler to use in the event of an exceptional 
	condition--interactive if the receiver's requestor is not nil, 
	otherwise non-interactive handler. Execute failBlock if the 
	translation fails."

	^self
		translate: aStream
		noPattern: noPattern
		ifFail: failBlock
		needSourceMap: false
		handlerClass: (requestor isNil
				ifTrue: [NonInteractiveCompilerErrorHandler]
				ifFalse: [InteractiveEnvironmentCompilerErrorHandler])! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:38 pm'!

Object subclass: #SmalltalkCompiler
	instanceVariableNames: 'sourceStream requestor class targetClass context '
	classVariableNames: 'CachedScope '
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
SmalltalkCompiler comment:
'The compiler accepts Smalltalk source code from sourceStream, and compiles it in the context of a given class.  The debugger supplies a context as well, so that temporary variables are accessible.  If there is an error, the requestor (usually a CodeController) is sent the message notify:at:in:.  If not, then the result of compilation is a parse tree (made up of subinstances of ParseNode) whose root is a MethodNode.  The parse tree can then generate code in a CompiledMethod (for compile or evaluate), or prettyPrint the code (for format), or produce a map from object code back to source code (used by debugger pc selection).  See also Parser, CodeStream, ProgramNode.

****** Note: there is currently no provision for clearing the scope cache when a class is redefined.  This must be fixed, probably by making Class or Behavior notify dependents. ******

Instance Variables:
	sourceStream	<Stream> the source code to be compiled
	requestor		<Object | nil> the object that initiated the compilation and should be notified of errors
	class			<Behavior> the class which describes the environment in which the compiled code will be executed
	targetClass		<Behavior> the class in which the method will be installed--this will usually be identical to ''class''
	context			<Context | nil> the (optional) context which allows a method to reference temporary variables in another context--this is used by the debugger

Class Variables:
	CachedScope	<Association> of strings with InstanceVariables'!


!SmalltalkCompiler methodsFor: 'public access'!

compile: textOrStream in: aClass notifying: aRequestor ifFail: failBlock 
	"Answer with a parse tree whose root is a MethodNode.
	This can then be told to generate code as is done in the calls from Behavior"
	self from: textOrStream
		class: aClass
		context: nil
		notifying: aRequestor.
	^self
		translate: sourceStream
		noPattern: false
		ifFail: failBlock!

compileTree: parseTree in: aClass
	"Answer with a parse tree whose root is a MethodNode.
	This can then be told to generate code as is done in the calls from Behavior"

	| holder codeStream method mapFlag |
	class _ aClass.
	targetClass == nil ifTrue: [targetClass _ class].
	context _ nil.
	requestor _ (SilentCompilerErrorHandler new class: class) failBlock: [^nil].
	mapFlag _ false.
	codeStream _ self newCodeStream.
	codeStream class: targetClass outerScope: self scopeForClass;
		requestor: requestor.
	mapFlag ifTrue: [codeStream saveSourceMap].
	parseTree emitEffect: codeStream.
	method _ codeStream makeMethod: parseTree.
	holder _ self newMethodHolder.
	holder node: parseTree.
	holder method: method.
	mapFlag ifTrue: [holder sourceInfo: codeStream sourceInfo].
	^holder!

evaluate: textOrStream in: aContext receiver: receiver notifying: aRequestor ifFail: failBlock 
	"Compiles the sourceStream into a parse tree, then generates code 
	into a method. This method is then installed in the receiver's class 
	so that it can be invoked. In other words, if receiver is not nil, then 
	the text can refer to instance variables of that receiver (the 
	Inspector uses this). If aContext is not nil, the text can refer to 
	temporaries in that context (the Debugger uses this). If aRequestor 
	is not nil, then it will receive a notify:at: message before the 
	attempt to evaluate is aborted. 
	
	Finally, the compiled method is invoked from here as DoIt or (in the 
	case of evaluation in aContext) DoItIn:. 
	
	The method is subsequently removed from the class, but this will not 
	get done if the invocation causes an error which is terminated. Such 
	garbage can be removed by executing: 
		Smalltalk allBehaviorsDo: 
			[:cl | cl removeSelector: #DoIt; removeSelector: #DoItIn:]."

	| methodNode method value |
	class _ (aContext == nil
				ifTrue: [receiver]
				ifFalse: [aContext homeReceiver]) class.
	self from: textOrStream
		class: class
		context: aContext
		notifying: aRequestor.
	methodNode _ self translate: sourceStream noPattern: true ifFail: [^failBlock value].
	method _ methodNode generate.
	context == nil
		ifTrue:	[class addSelector: #DoIt withMethod: method.
				[value _ receiver DoIt]
					valueNowOrOnUnwindDo: [class removeSelectorSimply: #DoIt].
				^value]
		ifFalse: [class addSelector: #DoItIn: withMethod: method.
				[value _ receiver DoItIn: context.]
					valueNowOrOnUnwindDo: [class removeSelectorSimply: #DoItIn:.].
				^value]!

evaluate: textOrStream in: aContext to: receiver notifying: aRequestor ifFail: failBlock
	"This is an old message that mixes user interaction with
	functional behavior.  New applications should consider using
	evaluate:in:receiver:notifying:ifFail:."

	| value |
	Cursor execute show.
	[value _ self
				evaluate: textOrStream
				in: aContext
				receiver: receiver
				notifying: aRequestor
				ifFail:
					[Cursor normal show.
					^failBlock value]]
		valueNowOrOnUnwindDo: [Cursor normal show].
	^value!

format: textOrStream in: aClass notifying: aRequestor
	"Compile a parse tree from the incoming text, and then print the
	parse tree to yield the answer, a string containing the original code
	in standard format."

	| holder |
	self
		from: textOrStream
		class: aClass
		context: nil
		notifying: aRequestor.
	holder _ self
				translate: sourceStream
				noPattern: false
				ifFail: [^nil]
				needSourceMap: true
				handlerClass: SilentCompilerErrorHandler.
	^holder decompileString!

parse: textOrStream in: aClass notifying: req
	"Compile the incoming text and answer with the resulting parse tree.
	This is the only public message that saves the source map
	and the comments.  If the requestor is nil,
	warning messages (as opposed to outright errors)
	are silently discarded."

	self
		from: textOrStream
		class: aClass
		context: nil
		notifying: req.
	^self
		translate: sourceStream
		noPattern: false
		ifFail: [^nil]
		needSourceMap: true
		handlerClass: SilentCompilerErrorHandler! !

!SmalltalkCompiler methodsFor: 'private: private'!

from: textOrStream class: aClass context: aContext notifying: req 
	(textOrStream isKindOf: PositionableStream)
		ifTrue: [sourceStream _ textOrStream]
		ifFalse: [sourceStream _ ReadStream on: textOrStream asString].
	class _ aClass.
	targetClass == nil
		ifTrue:	[targetClass _ class].
	context _ aContext.
	requestor _ req!

getInteractiveCompilerErrorHandler
	^InteractiveCompilerErrorHandler new
		class: class;
		editor: requestor!

scopeForClass
	| cache |
	cache _ CachedScope.
	cache key == class ifTrue: [^cache value].
	^(CachedScope _ Association key: class value: (NameScope forClass: class)) value!

translate: aStream noPattern: noPattern ifFail: failBlock
	^self
		translate: aStream
		noPattern: noPattern
		ifFail: failBlock
		needSourceMap: false
		handlerClass:
			(requestor isNil
				ifTrue: [NonInteractiveCompilerErrorHandler]
				ifFalse: [InteractiveCompilerErrorHandler])!

translate: aStream noPattern: noPattern ifFail: failBlock needSourceMap: mapFlag handler: handler
	"noPattern is true for evaluation,
	false for compilation"
	| methodNode holder codeStream method |
	"Make special provisions for compiling methods
	in classes that still use the old parser."
	methodNode _
		class parserClass new
			parse: aStream
			class: class
			noPattern: noPattern
			context: context
			notifying: handler
			builder: ProgramNodeBuilder new
			saveComments: mapFlag
			ifFail: [^failBlock value].
	handler selector: methodNode selector.  "save selector in case of error"
	codeStream _ self newCodeStream.
	codeStream class: targetClass outerScope: self scopeForClass;
			requestor: handler.
	mapFlag ifTrue: [codeStream saveSourceMap].
	noPattern
		ifTrue: [methodNode emitValue: codeStream inContext: context]
		ifFalse: [methodNode emitEffect: codeStream].
	method _ codeStream makeMethod: methodNode.
	holder _ self newMethodHolder.
	holder node: methodNode.
	holder method: method.
	mapFlag ifTrue: [holder sourceInfo: codeStream sourceInfo].
	^holder!

translate: aStream noPattern: noPattern ifFail: failBlock needSourceMap: mapFlag handlerClass: handlerClass
	"The handler class is used only for non-interactive mode."
	"Do things this way to avoid creating a circularity."
	| startPos endPos |
	startPos := aStream position.
	^requestor == nil
		ifTrue:
			["Non-interactive mode"
			self
				translate: aStream
				noPattern: noPattern
				ifFail: failBlock
				needSourceMap: mapFlag
				handler: 
					((handlerClass new
						class: class;
						source: aStream)
					  failBlock: [^failBlock value])]
		ifFalse:
			["Interactive mode"
			aStream setToEnd.
			endPos := aStream position.
			aStream position: startPos.
			self
				translate: aStream
				noPattern: noPattern
				ifFail: failBlock
				needSourceMap: mapFlag
				handler: 
					((self getInteractiveCompilerErrorHandler)
					  failBlock: [^failBlock value];
					  retryBlock:
						[:lengthChange |
						^self
							translate: (ReadStream on: requestor text asString from: startPos + 1 to: endPos + lengthChange)
							noPattern: noPattern
							ifFail: failBlock
							needSourceMap: mapFlag
							handlerClass: handlerClass])]! !

!SmalltalkCompiler methodsFor: 'private: private-subclass'!

newCodeStream
	"Return an appropriate code stream"
	^self subclassResponsibility!

newMethodHolder
	"Return an appropriate method holder"
	^self subclassResponsibility! !

!SmalltalkCompiler methodsFor: 'accessing'!

targetClass: aClass

	targetClass _ aClass.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SmalltalkCompiler class
	instanceVariableNames: ''!


!SmalltalkCompiler class methodsFor: 'class initialization'!

initialize
	"Compiler initialize"
	CachedScope _ Association new! !

!SmalltalkCompiler class methodsFor: 'evaluating'!

evaluate: textOrString 
	^self evaluate: textOrString for: nil logged: false!

evaluate: textOrString for: anObject logged: logFlag 
	^ self evaluate: textOrString for: anObject notifying: nil logged: logFlag!

evaluate: textOrString for: anObject notifying: aController logged: logFlag
	"Compile and execute the supplied text (see message to instance for details).
	If both were successful then, if logFlag is true, log (write) the text onto
	the changes file so that it can be replayed if necessary."
	| val |
	val _ self new
				evaluate: textOrString
				in: nil
				to: anObject
				notifying: aController
				ifFail: [^nil].
	self thingToDo. "fix this for fileIns"
	logFlag ifTrue: [ChangeLog logDoItChanges: textOrString asString].
	^val!

evaluate: textOrString logged: logFlag
	^self evaluate: textOrString for: nil logged: logFlag!

evaluate: textOrString notifying: aController logged: logFlag 
	^self evaluate: textOrString for: nil notifying: aController logged: logFlag! !

!SmalltalkCompiler class methodsFor: 'accessing'!

preferredParserClass
	^ Parser! !

!SmalltalkCompiler class methodsFor: 'public access'!

compileClass: c selector: s
	^self compileClass: c selector: s source: (c sourceCodeAt: s)!

compileClass: c selector: s source: source
	^self subclassResponsibility!

parse: source class: c
	"SmalltalkCompiler 
		parse: (SmalltalkCompiler class sourceCodeStringAt: #parse:class:)
		class: SmalltalkCompiler class"
	
	^self preferredParserClass new
			parse: source readStream
			class: c
			noPattern: false
			context: nil
			notifying: (SilentCompilerErrorHandler new failBlock: [^nil])
			builder: ProgramNodeBuilder new
			saveComments: false
			ifFail: [^nil]! !

!SmalltalkCompiler class methodsFor: 'private: private'!

generate1: methodNode scope: scope class: c selector: s log: logFile ifError: failBlock codeStreamClass: csc
	| codeStream |
	codeStream _ csc new.
	codeStream class: c outerScope: scope;
		requestor: (LoggingCompilerErrorHandler new
			class: c;
			selector: s;
			logFile: logFile;
			failBlock: failBlock).
	methodNode emitEffect: codeStream.
	^codeStream makeMethod: methodNode! !

SmalltalkCompiler initialize!

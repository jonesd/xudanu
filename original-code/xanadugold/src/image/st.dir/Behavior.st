'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:10 pm'!

Object subclass: #Behavior
	instanceVariableNames: 'superclass methodDict format subclasses '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Classes'!
Behavior comment:
'Instances of class Behavior provides the minimum state necessary for compiling methods, and creating and running instances.  Most objects are created as instances of the more fully supported subclass, Class, but Behavior is a good starting point for providing instance-specific behavior (as in Metaclass).

Instance Variables:
	superclass	<Behavior> links the chain of inheritance
	methodDict	<IdentityDictionary> associates message names with methods
	format		<Integer> encodes storage layout of instances
	subclasses	<Set> back-pointers to the class'' subclasses
'!


!Behavior methodsFor: 'initialize-release'!

localObsolete
	"Remove the receiver from its superclass' subclass list."

	self removeFromSuper!

obsolete
	"Invalidate and recycle local messages.  Remove the receiver from its superclass' 
	subclass list."

	self localObsolete! !

!Behavior methodsFor: 'accessing'!

format
	"Answer an Integer that encodes the kinds and numbers of variables of instances
	of the receiver."

	^format! !

!Behavior methodsFor: 'testing'!

instSize
	"Answer the number of named instance variables (as opposed to indexed
	variables) of the receiver."

	^format bitAnd: 255!

isBehavior
	"Answer whether the object can be the 'class' of another object"

	^true!

isBits
	"Answer whether the receiver contains just bits (not pointers)."

	^format noMask: -16384!

isFixed
	"Answer whether the receiver does not have a variable (indexable) part."

	^self isVariable not!

isGenerated
	"Automatically generated classes should implement this as true."
	
	^false!

isPointers
	"Answer whether the receiver contains just pointers (not bits)."

	^self isBits not!

isVariable
	"Answer whether the receiver has a variable (indexable) part."

	^(format bitAnd: 4096) ~= 0!

shouldBeRegistered
	"Answer whether the receiver is named and should be 'stored' in its environment"

	^false! !

!Behavior methodsFor: 'copying'!

copy
	"Make a copy of the receiver without a list of subclasses."

	| myCopy savedSubclasses |
	savedSubclasses _ subclasses.
	subclasses _ nil. 		
	myCopy _ self shallowCopy.
	subclasses _ savedSubclasses.
	^myCopy methodDictionary: methodDict copy!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for Behaviors."

	^self deepCopyError! !

!Behavior methodsFor: 'printing'!

printHierarchy
	"Answer a description containing the names and instance variable
	names of all of the subclasses and superclasses of the receiver."

	| aStream index |
	index _ 0.
	aStream _ WriteStream on: (String new: 16).
	self allSuperclasses reverseDo: 
		[:aClass |
		| fileDescr |
		aStream crtab: index.
		index _ index + 1.
		aStream nextPutAll: aClass name.
		aStream space.
		aStream print: aClass instVarNames.
		(aClass fetchCxxClassDescription ~~ nil and: [(fileDescr _ aClass fetchCxxClassDescription fetchCxxModule) ~~ nil]) ifTrue: 
			[aStream tab.
			fileDescr path do: [:file |
				aStream print: file; space].
			aStream print: aClass fetchCxxClassDescription visibility]].
	aStream cr.
	self printSubclassesOn: aStream level: index.
	^aStream contents!

printOn: aStream 
	"Append to the argument aStream a statement of which
	superclass the receiver descends from."

	aStream nextPutAll: 'a descendent of '.
	superclass printOn: aStream! !

!Behavior methodsFor: 'creating class hierarchy'!

addSubclass: aSubclass 
	"Make the argument, aSubclass, be one of the subclasses of the receiver."
	
	aSubclass superclass = self
		ifTrue: [subclasses == nil
					ifTrue:	[subclasses _ Set with: aSubclass]
					ifFalse:	[subclasses add: aSubclass]]
		ifFalse: [self error: aSubclass name , ' is not my subclass']!

addToSuper
	"Add the receiver to the superclass's subclass list."

	(superclass == nil or: [superclass isMeta])
		ifFalse:	[superclass addSubclass: self]!

assignSuperclass: aClass
	"Change the superclass, updating the superclass's subclass list."

	self removeFromSuper.
	superclass _ aClass.
	self addToSuper!

classBuilder
	"Answer an appropriate class mutation object."

	^ClassBuilder new!

clearInstanceVariables
	"After creating the copy, clear in the copy those instance variables that would be confusing"

	superclass _ nil.
	methodDict _ methodDict copy.
	subclasses _ nil!

removeFromSuper
	"Remove the receiver from the superclass's subclass list"

	(superclass == nil or: [superclass isMeta])
		ifFalse:	[superclass removeSubclass: self]!

removeSubclass: aSubclass 
	"If the argument, aSubclass, is one of the receiver's subclasses, remove it."
	subclasses == nil ifFalse:
		[subclasses remove: aSubclass ifAbsent: [].
		subclasses isEmpty ifTrue: [subclasses _ nil]]!

superclass: aClass 
	"Change the receiver's superclass to be aClass."

	aClass isBehavior
		ifTrue: [superclass _ aClass]
		ifFalse: [self error: 'superclass must be a class-describing object']! !

!Behavior methodsFor: 'creating method dictionary'!

addSelector: selector withMethod: compiledMethod 
	"Add the message selector with the corresponding compiled method to the receiver's
	method dictionary."

	methodDict at: selector put: compiledMethod.
	self flushVMmethodCacheEntriesFor: selector.
	self changed: #selectors!

methodDictionary: aDictionary 
	"Store the argument, aDictionary, as the method dictionary of the receiver."

	methodDict _ aDictionary.
	self changed: #selectors!

removeSelector: selector 
	"Assuming that the message selector is in the receiver's method dictionary,
	remove it.  If the selector is not in the method dictionary, create an error
	notification."

	methodDict removeKey: selector.
	self flushVMmethodCacheEntriesFor: selector.
	self changed: #selectors! !

!Behavior methodsFor: 'instance creation'!

basicNew
	"Answer a new instance of the receiver (which is a class) with no indexable 
	variables.  Fail if the class is indexable.  Essential.  See Object documentation
	whatIsAPrimitive."

	<primitive: 70>
	self isVariable ifTrue: [^self basicNew: 0].
	self primitiveFailed!

basicNew: anInteger 
	"Answer a new instance of the receiver (which is a class) with the number of 
	indexable variables specified by the argument, anInteger.  Fail if the class is not
	indexable or if the argument is not a positive Integer.  Essential.  See Object
	documentation whatIsAPrimitive."

	<primitive: 71>
	self primitiveFailed!

new
	"Answer with a new instance of the receiver, which is a class with no indexable 
	variables.  Fail if the class is indexable.  Essential.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 70>
	self isVariable ifTrue: [^self new: 0].
	self primitiveFailed!

new: anInteger 
	"Answer with a new instance of the receiver, a class with the number of 
	indexable variables specified by the argument, anInteger.  Fail if the class is not
	indexable or if the argument is not a positive Integer.  Essential.  See Object
	documentation whatIsAPrimitive."

	<primitive: 71>
	self primitiveFailed! !

!Behavior methodsFor: 'accessing class hierarchy'!

allSubclasses
	"Answer an OrderedCollection of the receiver's subclasses and the receiver's ancestor's
	subclasses in breadth-first order, with the immediate subclasses first."
	| coll |
	coll _ OrderedCollection new.
	coll addAll: self subclasses.
	self subclasses do: [:eachSubclass | coll addAll: eachSubclass allSubclasses].
	^coll!

allSuperclasses
	"Answer an OrderedCollection of the receiver's superclass and the receiver's ancestor's
	superclasses, with the immediate superclasses first."

	superclass == nil
		ifTrue:	[^OrderedCollection new]
		ifFalse:	[| coll |
				coll _ superclass allSuperclasses.
				coll addFirst: superclass.
				^coll].!

{Behavior} fetchDefinerOf: sel {Symbol}

	| result {Behavior} |
	result _ self.
	[result ~~ nil] whileTrue:
		[(result includesSelector: sel)
			ifTrue: [^result].
		result _ result superclass].
	^nil!

subclasses
	"Answer the receiver's subclasses.  Return a copy so that callers who 
	add or delete subclasses won't get confused."

	subclasses == nil
		ifTrue: [^Set new]
		ifFalse: [^subclasses copy]!

{Behavior} subWhichIsSuperTo: descendent {Behavior}
	"Heaper subWhichIsSuperTo: ActualHashSet"

	^self subclasses detect: [:cls {Behavior} |
		cls = descendent or: [descendent inheritsFrom: cls]]!

superclass
	"Answer the receiver's superclass.  Only returns the first one
		- use 'superclasses' to find them all."
	^superclass!

withAllSubclasses
	"Answer an OrderedCollection of subclasses including this class in breadth first order."
	| subs |
	subs _ self allSubclasses.
	subs addFirst: self.
	^subs!

withAllSuperclasses
	"Answer an OrderedCollection of superclasses including this class in breadth first order."
	| subs |
	subs _ self allSuperclasses.
	subs addFirst: self.
	^subs! !

!Behavior methodsFor: 'accessing method dictionary'!

allSelectors
	"Answer a set of all the message selectors that instances of the receiver can
	understand."
	| aSet |
	aSet _ Set new.
	self withAllSuperclasses do: [:each | aSet addAll: each selectors].
	^aSet

	"Point allSelectors."!

compiledMethodAt: selector 
	"Answer the compiled method associated with the message selector in the
	receiver's method dictionary.  If the selector is not in the dictionary,
	create an error notification."

	^methodDict at: selector ifAbsent: [nil]!

{CommentHolder | nil} fetchClientComment: selector {Symbol}
	"Answer the paragraph corresponding to the source code for the argument."
	"The above comment is the client comment.  The rest are not"
	"Behavior sourceCodeWithoutClientCommentAt: #sourceCodeWithoutClientCommentAt:"

	| src {String} mn {MethodNode | nil} |
	(self includesSelector: selector)
		ifFalse: [^nil].
	src _ self sourceCodeStringAt: selector.
	src == nil
		ifTrue: [^nil].
	mn _ self parserClass new parse: src class: self notifying: nil.
	mn == nil
		ifTrue: [^nil]
		ifFalse: [^mn fetchClientComment: src]!

{Boolean} isSelectorOverridden: sel {Symbol}

	self allSubclassesDo: [:cls {Behavior} |
		(cls isGenerated not and: [cls includesSelector: sel]) ifTrue:
			[^true]].
	^false!

{void} methodsDo: aBlock {BlockClosure of: Symbol with: CompiledMethod}

	methodDict keyValuesDo: aBlock!

selectorAtMethod: method ifAbsent: aBlock
	"Answer the message selector associated with the compiled method,
	or the result of evaluating aBlock if the compiled method does not
	appear in this class."

	^methodDict keyAtValue: method ifAbsent: aBlock!

selectorAtMethod: method setClass: classResultBlock 
	"Answer both the message selector associated with the compiled method 
	and the class in which that selector is defined."

	| sel |
	sel _ methodDict keyAtValue: method
				ifAbsent: 
					[superclass == nil
						ifTrue: 
							[classResultBlock value: self.
							^self defaultSelectorForMethod: method].
					sel _ superclass selectorAtMethod: method setClass: classResultBlock.
					"Set class to be self, rather than that returned from 
					superclass. "
					sel == (self defaultSelectorForMethod: method) ifTrue: [classResultBlock value: self].
					^sel].
	classResultBlock value: self.
	^sel!

selectors
	"Answer a Set of all the message selectors specified in the receiver's
	method dictionary."

	^methodDict keys  

	"Point selectors."!

{void} selectorsDo: aBlock {BlockClosure of: Symbol}

	methodDict keysDo: aBlock!

sourceCodeAt: messageSelector 
	"Answer the string corresponding to the source code for the argument.
	Will decompile if necessary or asked (by holding down the left shift key).
	See sourceCodeStringAt:
	Try a 'print it' on the comment below with and without holding down the shift key."
	"Behavior sourceCodeAt: #sourceCodeAt:"

	^self sourceCodeForMethod: (methodDict at: messageSelector) at: messageSelector!

sourceCodeForMethod: method at: messageSelector 
	"Answer the string corresponding to the source code for the argument."

	^method getSourceForUserIfNone:
		[(self decompilerClass new
				decompile: messageSelector
				in: self
				method: method) decompileString]!

sourceCodeStringAt: messageSelector 
	"Answer the string corresponding to the actual source code for the argument.
	Does not decompile, will error instead.
	See sourceCodeAt:"
	"Behavior sourceCodeStringAt: #sourceCodeStringAt:"
	
	^(methodDict at: messageSelector) getSourceStringForUserIfNone:
		[self class blast.SourceCodeStringNotFound raise]!

{String} sourceCodeWithoutClientCommentAt: selector {Symbol}
	"Answer the paragraph corresponding to the source code for the argument."
	"The above comment is the client comment.  The rest are not"
	"Behavior sourceCodeWithoutClientCommentAt: #sourceCodeWithoutClientCommentAt:"

	| result {String} mn {MethodNode | nil} cc {CommentHolder | nil} interval {Interval} |
	result _ self sourceCodeStringAt: selector.
	cc := "self fetchClientComment: selector" nil.
	cc == nil
		ifTrue: [^result].

	mn _ self parserClass new parse: result class: self notifying: nil.
	interval _ cc position.
	mn comment size = 1
		ifTrue: [interval _ interval first -1 to: interval last + 1].
	^(result copyFrom: 1 to: interval first),
	 (result copyFrom: interval last to: result size)!

sourceMethodAt: selector 
	"Answer the paragraph corresponding to the source code for the argument."

	^(self sourceCodeAt: selector) asText makeSelectorBoldIn: self! !

!Behavior methodsFor: 'accessing instances and variables'!

allClassVarNames
	"Answer a Set of the names of the receiver's and the receiver's
	ancestor's class variables."

	^superclass allClassVarNames!

allInstances 
	"Answer a collection of all instances of this class."

	| aCollection |
	aCollection _ OrderedCollection new: self fastInstanceCount.
	self allInstancesDo:
		[:x | x == aCollection ifFalse: [aCollection add: x]].
	^aCollection!

allInstVarNames
	"Answer an Array of the names of the receiver's instance variables."
	| names |
	names _ OrderedCollection new.
	self accumulateInstVarNames: names.
	^names!

allSharedPools
	"Answer a Set of the pools, dictionaries, that the receiver and the
	receiver's ancestors share.  Subclasses, such as class Class, override this message."

	^superclass allSharedPools!

allVarNamesSelect: selectBlock 
	"Answer a collection of all the static variable names defined for the 
	receiver which satisfy the condition in selectBlock. Test class and 
	pool variables, including superclass variables. Also include global 
	variables."

	| set |
	set _ self classPool keys select: selectBlock.
	self sharedPools do: [:pool | set addAll: (pool keys select: selectBlock)].
	superclass == nil
		ifTrue: [set addAll: (Smalltalk keys select: selectBlock)]
		ifFalse: [set addAll: (superclass allVarNamesSelect: selectBlock)].
	^set!

atomicAllInstances 
	"Answer a WeakArray of all instances of this class that existed prior to the 
invocation of this primitive. Fails if we cannot allocate a WeakArray large 
enough to contain all such instances or if the WeakArray class does not exist."

	<primitive: 536>
	self primitiveFailed!

classVarNames
	"Answer a Set of the receiver's class variable names.  Since the receiver does
	not retain knowledge of class variables, the method fakes it by creating an empty set."

	^Set new!

fastAllInstVarNamesDo: aBlock
	"Evaluate aBlock with the names of the receiver's instance variables.
	This is a fast version that bypasses (non-existent) multiple inheritance."
	superclass == nil ifFalse: [superclass fastAllInstVarNamesDo: aBlock].
	self instVarNames do: aBlock!

fastInstanceCount
	"Answer the number of instances of the receiver that are currently in use."

	| current count |
	current _ self someInstance.
	count _ 0.
	[current ~~ nil] whileTrue: [
		count _ count + 1.
		current _ current nextInstance].
	^ count!

instanceCount
	"Answer the number of instances of the receiver that are currently in use."

	| count |
	count _ 0.
	self allInstancesDo: [:x | count _ count + 1].
	^count!

instVarNames
	"Answer an Array of the instance variable names.  Behaviors must make up fake
	local instance variable names because Behaviors have instance variables for the
	purpose of compiling methods, but these are not named instance variables.  "

	| mySize superSize |
	mySize _ self instSize.
	superSize _ 
		superclass == nil
			ifTrue: [0]
			ifFalse: [superclass instSize].
	mySize = superSize ifTrue: [^#()].	
	^(superSize + 1 to: mySize) collect: [:i | 'inst' , i printString]!

{Set of: String} instVarNamesTouchedBy: sel {Symbol}
	"Behavior instVarNamesTouchedBy: #selectorAtMethod:setClass:"
	^(self compiledMethodAt: sel) fieldsTouched collect: [:instVarIndex |
		self allInstVarNames at: instVarIndex]!

sharedPools
	"Answer a Set of the pools, dictionaries, that the receiver shares.  Since the receiver
	does not retain knowledge of pool dictionaries, the method fakes it by creating an
	empty array.  Subclasses, such as class Class, override this message."

	^Set new!

someInstance
	"Answer with the first instance of this receiver.  See Object  
	nextInstance.  Fails if there are none.  Essential.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 77>
	^nil!

subclassInstVarNames
	"Answer with a Set of the names of the receiver's subclasses' 
	instance variables."

	| vars |
	vars _ Set new.
	self allSubclasses do: [:aSubclass | vars addAll: aSubclass instVarNames].
	^vars! !

!Behavior methodsFor: 'testing class hierarchy'!

inheritsFrom: aClass 
	"Answer whether the argument, aClass, is on the receiver's superclass chain."

	superclass == nil
		ifTrue:	[^superclass == aClass]
		ifFalse:	[^superclass==aClass or: [superclass inheritsFrom: aClass]]!

{BooleanVar} isSuperTo: cat {Class}
	"Answer whether the receiver is on the arguments superclass chain."

	^cat inheritsFrom: self!

{TypePair} | type {Category | CategoryPair}
	^CategoryPair create: self with: type! !

!Behavior methodsFor: 'testing method dictionary'!

canUnderstand: selector 
	"Answer true if the receiver can respond to the message whose selector
	is the argument, false otherwise.  The selector can be in the method dictionary
	of the receiver's class or any of its superclasses."

	(self includesSelector: selector) ifTrue: [^true].
	superclass == nil ifTrue: [^false].
	^superclass canUnderstand: selector!

hasMethods
	"Answer whether the receiver has any methods in its method dictionary."

	^methodDict size > 0!

includesSelector: aSymbol 
	"Answer whether the message whose selector is the argument is in the 
	method dictionary of the receiver's class."

	^methodDict includesKey: aSymbol!

scopeHas: varName ifTrue: assocBlock 
	"Look up varName in this class, its superclasses, and Smalltalk.  If it is there,
	pass the association to assocBlock, and answer true; else answer false."
	| assoc |
	self withAllSuperclasses do:
		[:sup |
		(sup poolHas: varName ifTrue: assocBlock) ifTrue: [^true]].
	assoc _ Smalltalk associationAt: varName ifAbsent: [].
	assoc == nil
		ifFalse: 
			[assocBlock value: assoc.
			^true].
	^false!

selector: sel refersTo: literal
	"Answer whether the method at sel refers to the given literal."

	| special method |
	special _ Smalltalk specialSelectorIndexOf: literal.
	^(method _ methodDict at: sel ifAbsent: []) ~~ nil and: 
			[(method refersToLiteral: literal) or:
				[special > 0 and: [method sendsSpecialSelector: special]]]!

selector: sel refersTowards: literal
	"Answer whether the method at sel refers to the given literal."

	| special method |
	special _ Smalltalk specialSelectorIndexOf: literal.
	^(method _ methodDict at: sel ifAbsent: []) ~~ nil and: 
			[(method refersTowardsLiteral: literal) or:
				[special > 0 and: [method sendsSpecialSelector: special]]]!

whichClassIncludesSelector: aSymbol 
	"Answer the class on the receiver's superclass chain where the argument, aSymbol
	(a message selector), will be found."

	(methodDict includesKey: aSymbol) ifTrue: [^self].
	superclass == nil ifTrue: [^nil].
	^superclass whichClassIncludesSelector: aSymbol

	"Rectangle whichClassIncludesSelector: #inspect."!

whichSelectorsAccess: instVarName 
	"Answer a set of selectors whose methods access the argument, instVarName,
	as a named instance variable."

	| instVarIndex |
	instVarIndex _ self allInstVarNames indexOf: instVarName ifAbsent: [^Set new].
	^methodDict keys select: 
		[:sel | 
		((methodDict at: sel)
			readsField: instVarIndex)
			or: [(methodDict at: sel) writesField: instVarIndex]]

	"Point whichSelectorsAccess: 'x'."!

whichSelectorsAssign: instVarName 
	"Answer a set of selectors whose methods assign the argument, instVarName,
	as a named instance variable."

	| instVarIndex |
	instVarIndex _ self allInstVarNames indexOf: instVarName ifAbsent: [^Set new].
	^methodDict keys select: 
		[:sel | (methodDict at: sel) writesField: instVarIndex]

	"Point whichSelectorsAssign: 'x'."!

whichSelectorsReferTo: literal
	"Answer a collection of selectors whose methods
	access the argument as a literal."

	^methodDict whichSelectorsReferTo: literal

	"Rectangle whichSelectorsReferTo: #+."!

whichSelectorsReferTowards: literal
	"Answer a collection of selectors whose methods
	access the argument as a literal."

	^methodDict whichSelectorsReferTowards: literal

	"Rectangle whichSelectorsReferTowards: #+."! !

!Behavior methodsFor: 'compiling'!

compile: code notifying: requestor
	"Compile  the argument, code, as source code in the context of the 
	receiver.  Use the default fail code [^nil].  Does not save source code. 
	The second argument, requestor, is to be notified if an error occurs. The
	argument code is either a string or an object that converts to a string or a
	PositionableStream on an object that converts to a string."

	^self compile: code notifying: requestor ifFail: [^nil]!

compile: code notifying: requestor ifFail: failBlock 
	"Compile the argument, code, as source code in the context of the receiver and
	install the result in the receiver's method dictionary.  The argument requestor is to  
	be notified if an error occurs. The argument code is either a string or an 
	object that converts to a string or a PositionableStream on an object that   
	converts to a string.  This method does not save the source code. 
	Evaluate the failBlock if the compilation does not succeed."

	| methodNode selector |
	methodNode _ self compilerClass new
				compile: code
				in: self
				notifying: requestor
				ifFail: failBlock.
	selector _ methodNode selector.
	self addSelector: selector withMethod: methodNode generate.
	^selector!

compileAll
	"Compile all the methods in the receiver's method dictionary."

	^ self compileAllFrom: self!

compileAllFrom: oldClass
	"Compile all the methods in oldClass's method dictionary.
	See recompile:from: regarding oldClass, which is normally just self."

	self selectorsDo: [:sel | self recompile: sel from: oldClass]!

compileAllFrom: oldClass into: third
	"Compile all the methods in oldClass's method dictionary.
	See recompile:from: regarding oldClass, which is normally just self."

	self selectorsDo: [:sel | self recompile: sel from: oldClass into: third]!

compileAllSubclasses
	"Compile all the methods in the receiver's subclasses.  This does not modify
	code (re-install the compiled versions), just compiles the methods as a kind of static
	check."

	self allSubclasses do: [:aSubclass | aSubclass compileAll]!

compilerClass
	"Answer a compiler class appropriate for source methods of this class."

	^Compiler!

decompile: selector 
	"Find the compiled code associated with the argument, selector, as a message selector
	in the receiver's method dictionary and decompile it.  Answer the resulting source
	code as a string.  Create an error if the selector is not in the receiver's method
	dictionary."

	^self decompilerClass new decompile: selector in: self!

decompilerClass
	"Answer a decompiler class appropriate for compiled methods of this class."

	^Decompiler!

evaluatorClass
	"Answer an evaluator class appropriate for evaluating expressions in the 
	context of instances of this class."

	^Compiler!

parserClass
	"Answer a parser class to use for parsing methods in this class."

	^self compilerClass preferredParserClass!

poolHas: varName ifTrue: assocBlock 
	"Behaviors have no pools."

	^false!

recompile: selector 
	"Recompile the method associated with selector in the receiver's method dictionary.
	Take care not to write out any new source code - just generate new bytes."

	^ self recompile: selector from: self!

recompile: selector from: oldClass
	"Recompile the method associated with selector in the receiver's method dictionary.
	Take care not to write out any new source code - just generate new bytes.
	oldClass may differ from self in order to decompile right (if sourceFiles == nil)
	when adding or removing fields of a class."

	| method sourceFile sourcePosition methodNode |
	method _ oldClass compiledMethodAt: selector.
	method hasSource ifTrue:
		[sourceFile _ method fileIndex.
		sourcePosition _ method filePosition].
	methodNode _ self compilerClass new
				compile: (oldClass sourceCodeAt: selector)
				in: self
				notifying: nil
				ifFail: [].
	methodNode == nil  "Try again after proceed from SyntaxError"
		ifTrue: [^self recompile: selector].
	selector == methodNode selector ifFalse: [self error: 'selector changed!!'].
	method _ methodNode generate.
	sourceFile notNil ifTrue:
		[method setSourcePosition: sourcePosition inFile: sourceFile].
	self addSelector: selector withMethod: method!

recompile: selector from: oldClass into: third
	"Recompile the method associated with selector in the receiver's method dictionary.
	Take care not to write out any new source code - just generate new bytes.
	oldClass may differ from self in order to decompile right (if sourceFiles == nil)
	when adding or removing fields of a class."

	| method sourceFile sourcePosition methodNode |
	method _ oldClass compiledMethodAt: selector.
	method hasSource ifTrue:
		[sourceFile _ method fileIndex.
		sourcePosition _ method filePosition].
	methodNode _ self compilerClass new
				targetClass: third;
				compile: (oldClass sourceCodeAt: selector)
				in: self
				notifying: nil
				ifFail: [].
	methodNode == nil  "Try again after proceed from SyntaxError"
		ifTrue: [^self recompile: selector].
	selector == methodNode selector ifFalse: [self error: 'selector changed!!'].
	method _ methodNode generate.
	sourceFile notNil ifTrue:
		[method setSourcePosition: sourcePosition inFile: sourceFile].
	self addSelector: selector withMethod: method!

sourceCodeTemplate
	"Answer an expression to be edited and evaluated in order to
	define methods in this class."

	^'message selector and argument names
	"comment stating purpose of message"

	| temporary variable names |
	statements'!

subclassDefinerClass
	"Answer an evaluator class appropriate for evaluating definitions of new 
	subclasses of this class."

	^Compiler! !

!Behavior methodsFor: 'enumerating'!

allCallsOn: aLiteral
	"Answer a SortedCollection of all the methods
	in this class or any subclass that call on aLiteral."

	| set |
	self == Object ifTrue: [^Smalltalk allCallsOn: aLiteral].
	set _ Set new.
	self withAllSuperclasses reverse , self allSubclasses do:
		[:class | 
		(class whichSelectorsReferTowards: aLiteral)
			do: [:sel | sel ~~ #DoIt ifTrue: [set add: class name , ' ' , sel]].
		(class class whichSelectorsReferTowards: aLiteral)
			do: [:sel | sel ~~ #DoIt ifTrue: [set add: class class name , ' ' , sel]]].
	^set asSortedCollection!

allInstancesDo: aBlock 
	"Evaluate the argument, aBlock, for each of the current instances of the receiver."

	| inst next all |
	inst _ self someInstance.
	all _ IdentityGreatSet newForSize: self fastInstanceCount.
	inst == nil
		ifFalse: 
			[[next _ inst nextInstance.
			all add: inst.
			next == nil]
				whileFalse: [inst _ next]].
	nil class == self ifTrue: [aBlock value: nil].
	all do:
		[ :i |	aBlock value: i.	].!

allSubclassesDo: aBlock 
	"Evaluate the argument, aBlock, for each of the receiver's subclasses."

	self subclasses do: 
		[:cl | 
		aBlock value: cl.
		cl allSubclassesDo: aBlock]!

allSubInstancesDo: aBlock 
	"Evaluate the argument, aBlock, for each of the current instances of the receiver's
	subclasses."

	self allSubclassesDo: [:sub | sub allInstancesDo: aBlock]!

{NOWAIT} browseAllCallsOn: aSymbol 
	"Create and schedule a message browser on each method that calls on aSymbol."

	"For example,
		Number browseAllCallsOn: #/.	"

	| filter {MethodFilter} |
	(aSymbol isKindOf: Association)
		ifTrue: [filter _ AssociationRefsFilter make: aSymbol]
		ifFalse: [filter _ SendersFilter make: aSymbol asSymbol].
	((FromFamily make: self) filteredBy: filter) browse.!

crossReference
	"Answer an array of arrays of size 2 whose first element is a message selector
	in the receiver's method dictionary and whose second element is a set of all message
	selectors in the method dictionary whose methods send a message with that selector.
	Subclasses are not included."

	^self selectors asSortedCollection asArray collect:
		[:x | 
		Array 
			with: (String with: Character cr), x 
			with: (self whichSelectorsReferTowards: x)]

	"Point crossReference."!

showVariableMenu: generatorBlock collect: valueBlock
	"Construct a menu of variable names supplied by the generatorBlock,
	with lines between classes in the superclass chain.  Show the menu,
	returning the variable chosen by the user, or nil if no
	variable was chosen."

	^self showVariableMenu: generatorBlock 
		collectWithClass: [:eachClass {Behavior} :var |
			(valueBlock value: var) contractTo: 40].!

showVariableMenu: generatorBlock collectWithClass: valueBlock
	"Construct a menu of variable names supplied by the generatorBlock,
	with lines between classes in the superclass chain.  Show the menu,
	returning the variable chosen by the user, or nil if no
	variable was chosen."

	| menuDesc {OrderedCollection of: (Array | Symbol)}
	  needsSep {BooleanVar}
	  result |
	menuDesc _ OrderedCollection new.
	needsSep _ false.
	self withAllSuperclasses reverseDo: [:eachClass {Behavior} |
		| vars {OrderedCollection} |
		vars _ generatorBlock value: eachClass.
		vars isEmpty not 
			ifTrue: [
				needsSep
					ifTrue: [menuDesc add: #-].
				needsSep _ true.
				vars do: [:var |
					menuDesc add: (Array 
						with: (valueBlock value: eachClass value: var)
						with: var
						with: 'ST: Create a browser on all methods which do the appropriate thing to the variable')]]].
	menuDesc isEmpty ifTrue: [^nil].  "Nothing to choose from"
	result _ (PopUpMenu fromArray: menuDesc) startUp.
	result = 0
		ifTrue: [^nil]
		ifFalse: [^result].!

subclassesDo: aBlock 
	"Evaluate the argument, aBlock, for each of the receiver's immediate subclasses."

	self subclasses do: [:cl | aBlock value: cl]!

{void} withAllSubsAndMetasDo: aBlock {BlockClosure of: Behavior}
	"Note: Metaclass overrides to avoid duplication"

	aBlock value: self.
	aBlock value: self class.
	self subclasses do: [:cl {Behavior} | 
		cl withAllSubsAndMetasDo: aBlock]! !

!Behavior methodsFor: 'fileIn/Out'!

printMethod: selector on: aStream
	"Print the source code for the method associated with the argument selector onto
	the stream."

	| source emphasis parser length |
	aStream cr; cr.
	aStream label: (Association key: self name asString value: selector asString).
	source _ (self sourceMethodAt: selector) asString.
	emphasis _ aStream emphasis.
	aStream emphasis: 2.
	(parser _ self parserClass new) parseSelector: source.
	length _ parser endOfLastToken min: source size.
	aStream nextPutAll: (source copyFrom: 1 to: length).
	aStream emphasis: emphasis.
	aStream nextPutAll: (source copyFrom: length + 1  to: source size)!

printMethodChunk: selector on: aFileStream moveSource: moveSource toFile: fileIndex
	"Print the source code for the method associated with the argument selector onto
	the fileStream. aFileStream, and, for backup, if the argument moveSource (a Boolean)
	is true, also set the file index within the method to be the argument fileIndex."

	| position |
	aFileStream cr; cr.
	moveSource ifTrue: [position _ aFileStream position].
	aFileStream nextChunkPut: (self sourceMethodAt: selector) asString.
	moveSource 
		ifTrue: [(self compiledMethodAt: selector)
					setSourcePosition: position inFile: fileIndex]!

printMethodInterface: selector on: aStream
	"Print the source code for the method associated with the argument selector onto
	the stream."

	| source emphasis parser length comment |
	aStream cr; cr.
	source _ (self sourceMethodAt: selector) asString.
	emphasis _ aStream emphasis.
	aStream emphasis: 2.
	aStream label: (Association key: self name asString value: selector asString).
	(parser _ self parserClass new) parseSelector: source.
	length _ parser endOfLastToken min: source size.
	aStream nextPutAll: (source copyFrom: 1 to: length).
	aStream emphasis: emphasis.
	
	Ravi hack.
	comment := source indexOfSubCollection: '"'
		startingAt: length + 1
		ifAbsent: [^self].
	(source copyFrom: length + 1 to: comment - 1)
		do: [ :char | char isSeparator ifFalse: [^self]].
	comment := source indexOfSubCollection: '"'
		startingAt: comment + 1
		ifAbsent: [^self].
	aStream nextPutAll: (source copyFrom: length + 1 to: comment).
	
	MarkM thingToDo. "Make fetchClientComment work"
	"comment := self fetchClientComment: selector.
	comment ~~ nil ifTrue:
		[aStream nextPutAll: comment]"! !

!Behavior methodsFor: 'private: private'!

accumulateInstVarNames: names
	"accumulate instance variable names in 'names'.  Do this in depth-first,
	  left-to-right order.  This will give the ordering of instance variable names
	  expected by the compiler and other parts of the system."

	superclass == nil
		ifFalse:	[superclass accumulateInstVarNames: names].
	names addAll: self instVarNames.!

copyMethodDictionary

	methodDict _ methodDict copy!

defaultSelectorForMethod: aMethod 
	"Given a method, invent an appropriate selector, that is, one that will parse with
	the correct number of arguments."

	| aStream |
	aStream _ WriteStream on: (String new: 16).
	aStream nextPutAll: 'unboundMethod'.
	1 to: aMethod numArgs do: [:i | aStream nextPutAll: 'with:'].
	^aStream contents asSymbol!

flushVMmethodCache
	"Tell the interpreter to remove the contents of its method lookup cache, if it has 
	one.  Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 89>
	self primitiveFailed!

flushVMmethodCacheEntriesFor: selector 
	"Tell the interpreter to remove from its method lookup cache (if any) 
	all entries affected by adding, changing, or removing a definition 
	for this selector in the receiver. Optional. 
	See Object documentation whatIsAPrimitive."

	<primitive: 522>
	"If we can't do a selective flush, flush the entire cache."
	self flushVMmethodCache!

printSubclassesOn: aStream level: level 
	"As part of the algorithm for printing a description of the receiver, print the
	subclass on the file stream, aStream, indenting level times."
	| subs |
	aStream crtab: level.
	aStream nextPutAll: self name.
	aStream space; print: self instVarNames.
	(self fetchCxxClassDescription ~~ nil and: [self fetchCxxClassDescription fetchCxxModule ~~ nil]) ifTrue: [
		aStream tab.
		self fetchCxxClassDescription fetchCxxModule path do: [:file |
			aStream print: file; space].
		aStream print: self fetchCxxClassDescription visibility].
	"aStream cr."
	subs _ self subclasses.
	self == Class ifTrue:
		[aStream crtab: level+1; nextPutAll: '... all the Metaclasses ...'.
		subs _ subs reject: [:sub | sub isMeta]].
	"Print subclasses in alphabetical order"
	(subs asSortedCollection: [:x :y | x name < y name]) do:
		[:sub |
		(Sensor ctrlDown not 
			or: [sub fetchCxxClassDescription == nil 
			or: [sub fetchCxxClassDescription visibility == #public]])
			ifTrue: [sub printSubclassesOn: aStream level: level + 1]]!

removeSelectorSimply: selector 
	"Remove the message selector from the receiver's method dictionary.
	Internal access from compiler."

	methodDict removeKey: selector ifAbsent: [^self].
	self flushVMmethodCacheEntriesFor: selector!

setInstanceFormat: sizeAndFlags 
	"Set the format for the receiver (a Class)."

	format _ sizeAndFlags!

sourceTextAt: selector 
	"Answer with the string of the source code for the message selector."

	| newSource method |
	method _ methodDict at: selector.
	Sensor leftShiftDown
		ifTrue: [newSource _ 
					self decompilerClass new
						decompile: selector
						in: self
						method: method]
		ifFalse: 
			[newSource _ method getSource.
			newSource == nil 
				ifTrue: [newSource _ 
							self decompilerClass new
								decompile: selector
								in: self
								method: method]].
	^newSource asText! !

!Behavior methodsFor: 'interface'!

browseClass
	Browser newOnClass: self!

inspectMenuArray
	^#(
		('browse'	browseClass	'')
		('tree view'	treeView		''))!

treeView
	EntView
		make: self
		gettingChildren: [:class | (class isKindOf: Behavior)
				ifTrue: [class subclasses]
				ifFalse: [#()]]
		gettingImage: [:class | class displayString asDisplayText]
		at: 0 @ 0
		vertical: false
		separation: 10 @ 10! !

!Behavior methodsFor: 'cxx extensions'!

declarationCandidates
	"AbstractListComp declarationCandidates"

	| inSub candidates |
	inSub _ Set new: 40.
	candidates _ Set new: 40.
	self subclasses do: [:sub | 
		sub selectorsDo: [:sel | 
			(inSub includes: sel) 
				ifTrue: [candidates add: sel] 
				ifFalse: [inSub add: sel]]].
	self selectorsDo: [:sel | candidates remove: sel ifAbsent: []].
	^candidates asSortedCollection!

deepDeclarationCandidates
	"Viewer deepDeclarationCandidates"

	| inSub candidates |
	inSub _ Set new: 40.
	candidates _ Set new: 40.
	self allSubclasses do: [:sub | 
		sub selectorsDo: [:sel | 
			(inSub includes: sel) 
				ifTrue: [candidates add: sel] 
				ifFalse: [inSub add: sel]]].
	self selectorsDo: [:sel | candidates remove: sel ifAbsent: []].
	^candidates asSortedCollection!

hashForEqual
	^self asOop!

isEqual: other
	^self == other!

{BooleanVar} isEqualOrSubclassOf: aCategory {Behavior}
	^ (self isEqual: aCategory) or: [self inheritsFrom: aCategory]!

{BooleanVar} isSubclassOf: aCategory {Behavior}
	^ self inheritsFrom: aCategory!

superCategory
	"Answer the receiver's superclass.  Only returns the first one
		- use 'superclasses' to find them all."
	^superclass! !
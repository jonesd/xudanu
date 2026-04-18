'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:51 pm'!

Scanner subclass: #ChangeScanner
	instanceVariableNames: 'file chunkString '
	classVariableNames: 'ChangeTypeTable '
	poolDictionaries: ''
	category: 'System-Changes'!
ChangeScanner comment:
'Class ChangeScanner knows how to parse a file into a collection of changes.

Instance Variables:
	file			<File> of change information
	chunkString	<String> read from the file

Class Variables:
	ChangeTypeTable	<ScannerTable>'!


!ChangeScanner methodsFor: 'initialize-release'!

initChangeScanner
	typeTable _ ChangeTypeTable.
	chunkString _ String new: 200! !

!ChangeScanner methodsFor: 'change set scanning'!

scanChangedMessages: changedMessages do: aBlock
	| selector change className class category |
	changedMessages do:
		[:aString |
	super scan: (ReadStream on: aString).
		(className _ self nextClass) notNil ifTrue:
			[(selector _ self nextSelector) notNil ifTrue:
				[change _ MethodDefinitionChange new className: className; selector: selector.
				(className includes: Character space)
					ifTrue: [class _ (Smalltalk at: (className copyUpTo: Character space) asSymbol) class]
					ifFalse: [class _ Smalltalk at: className asSymbol].
				category _ class whichCategoryIncludesSelector: selector asString asSymbol.
				category == nil ifTrue: [category _ 'As yet unclassified'].
				change category: category.
				change getSource.
				aBlock value: change]]]! !

!ChangeScanner methodsFor: 'file scanning'!

scanFile: aFile do: aBlock
	"Evaluate aBlock with each item on the file"
	| position |
	file _ aFile.
	[file skipSeparators.
	file atEnd]
		whileFalse:
			[file peek = $!!
				ifTrue:
					[file next.
					super scan: self nextChunkStream.
					self scanSpecialDo: aBlock]
				ifFalse:
					[position _ file position.
					self scanExpression: self nextChunkStream do:
						[:item | aBlock value: (item file: file position: position)]]]!

scanMethodsClass: class category: category do: aBlock
	| classObject position method selector | 
	classObject _ Smalltalk at: class asSymbol ifAbsent: [Object].
	classObject isBehavior ifFalse: [classObject _ Object].
	[file skipSeparators.
	position _ file position.
	(method _ self nextChunkStream) atEnd]
		whileFalse:
			[method _ method contents.
			selector _ classObject parserClass new parseSelector: method.
			selector notNil ifTrue:
				[aBlock value: ((MethodDefinitionChange file: file position: position) className: class; selector: selector; category: category)]]!

scanSpecialDo: aBlock
	"Scan a chunk of file beginning with a !!.  For now, the only thing I understand is method definitions."
	| class category | 
	(class _ self nextClass) notNil ifTrue:
		[(tokenType == #keyword and: [token = 'methodsFor:']) ifTrue:
			[self scanToken.
			(tokenType == #string or: [tokenType == #literal]) ifTrue:
				[category _ token.
				self scanToken.
				tokenType == #doIt ifTrue:
					[^self scanMethodsClass: class category: category asSymbol do: aBlock]]]].
	"I don't understand what's on the file.  Scan for a blank chunk and hope for the best."
	[self nextChunkStream atEnd] whileFalse: []! !

!ChangeScanner methodsFor: 'expression scanning'!

scanClassDefinition: classType className: superName do: aBlock
	"Scan a presumed class definition.  The classType is the first keyword of the class defining message (subclass:, variableSubclass:, etc.)"
	| newName parameters |
	(tokenType == #literal and: [token isSymbol]) ifFalse: [^nil].
	newName _ token.
	parameters _ #('instanceVariableNames:' 'classVariableNames:' 'poolDictionaries:' 'category:') collect:
		[:keyword |
		self scanToken.
		(tokenType == #keyword and: [token = keyword]) ifFalse: [^nil].
		self scanToken.
		tokenType == #string ifFalse: [^nil].
		token].
	self scanToken.
	^aBlock value: (ClassDefinitionChange new className: newName; superclassName: superName classType: classType otherParameters: parameters)!

scanClassExpression: class do: aBlock
	"Scan an expression beginning with a class name.  This might be a class   
	definition, a class removal, a class comment change, a class initialization,
	a method removal, or a doIt."

	| firstToken selector newName |
	firstToken _ token.
	self scanToken.
	firstToken = 'removeSelector:'
		ifTrue: 
			[(tokenType == #literal and: [token isSymbol]) ifTrue:
				[selector _ token.
				self scanToken.
				^aBlock value: (MethodOtherChange new className: class; selector: selector; type: #remove)]].
	firstToken = 'rename:'
		ifTrue: 
			[(tokenType == #literal and: [token isSymbol]) ifTrue:
				[newName _ token.
				self scanToken.
				aBlock value: (ClassOtherChange new className: class; type: #rename).
				^aBlock value: (ClassOtherChange new className: newName; type: 'rename to' asSymbol)]].
	firstToken = 'comment:'
		ifTrue:
			[tokenType == #string
				ifTrue:
					[self scanToken.
					^aBlock value: (ClassCommentChange new className: class)]].
	(#('subclass:' 'variableSubclass:' 'variableByteSubclass:' 'variableWordSubclass:') includes: firstToken)
		ifTrue:
			[^self scanClassDefinition: firstToken className: class do: aBlock].
	firstToken = 'initialize'
		ifTrue:
			[^aBlock value: (ClassOtherChange new className: class; type: #initialize)].
	firstToken = 'removeFromSystem'
		ifTrue:
			[^aBlock value: (ClassOtherChange new className: class; type: #remove)].
	firstToken = 'instanceVariableNames:'
		ifTrue:
			[tokenType == #string
				ifTrue:
					[self scanToken.
					^aBlock value: (ClassOtherChange new className: class; type: 'inst vars for' asSymbol)]].
	^nil!

scanExpression: aStream do: aBlock
	"Scan a chunk of file consisting of an expression.  This might be a class   
	definition, a class removal, a class comment change, a method removal,   
	a doIt."

	| class item |
	super scan: aStream.
	((class _ self nextClass) notNil and: [tokenType == #keyword or: [tokenType == #word]])
		ifTrue:
			[self scanClassExpression: class do:
				[:it | item _ it.
				(tokenType == #doIt or: [tokenType == #period])
					ifTrue: [aBlock value: item]]].
	item == nil ifTrue: [aBlock value: OtherChange new]! !

!ChangeScanner methodsFor: 'private: private'!

nextChunkStream
	"Answer a read stream on the next chunk of the file."

	| chunkStream aChar terminator |
	terminator _ $!!.
	file skipSeparators.
	chunkStream _ ReadWriteStream on: chunkString.
	[file atEnd]
		whileFalse: 
			[aChar _ file next.
			aChar == terminator
				ifTrue: [(file peekFor: terminator)
						ifTrue: ["doubled terminator"
							chunkStream nextPut: aChar]
						ifFalse: [chunkStream position: 0.  ^chunkStream]]
				ifFalse: [chunkStream nextPut: aChar]].
	chunkStream position: 0.  "Sets read limit to current
position"
	^chunkStream!

nextClass
	| class |
	tokenType == #word ifTrue:
		[class _ token.
		self scanToken.
		(tokenType == #word and: [token = 'class'])
			ifTrue:
				[class _ (class, ' ', token) asSymbol.
				self scanToken]
			ifFalse:
				[class _ class asSymbol].
		^class].
	^nil!

nextSelector
	| selector |
	tokenType == #keyword
		ifTrue:
			[self scanLitWord].
	(tokenType == #word or: [tokenType == #keyword or: [tokenType == #binary]])
		ifTrue:
			[selector _ token.
			self scanToken].
	^selector! !

!ChangeScanner methodsFor: 'multi-character scans'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeScanner class
	instanceVariableNames: ''!


!ChangeScanner class methodsFor: 'class initialization'!

initialize
	"ChangeScanner initialize"

	"change the type table to treat #-quoted symbols as a single unit
	rather than a # followed by a symbol"
	ChangeTypeTable _ TypeTable copy.
	ChangeTypeTable at: $# asciiValue put: #xLitQuote.
	ChangeTypeTable at: ${ asciiValue put: #xLetter.
	ChangeTypeTable at: $} asciiValue put: #xLetter! !

!ChangeScanner class methodsFor: 'instance creation'!

new
	^super new initChangeScanner! !

ChangeScanner initialize!

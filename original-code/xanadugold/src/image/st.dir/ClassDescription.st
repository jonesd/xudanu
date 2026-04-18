'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:14 pm'!

Behavior subclass: #ClassDescription
	instanceVariableNames: 'instanceVariables organization '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Classes'!
ClassDescription comment:
'ClassDescription adds a number of facilities to basic Behavior:
		- named instance variables
		- category organization for methods
		- the notion of a name of this class (implemented as subclass responsibility)
		- the maintenance of the Changes set, and logging changes on a file
		- most of the mechanism for fileOut
ClassDescription is an abstract class: its facilities are intended for inheritance by the two subclasses, Class and Metaclass.

Subclasses must implement
	instance variables
		addInstVarName:
		removeInstVarName:

Instance Variables:
		instanceVariables	<Array of: Strings> names of instance fields
		organization		<ClassOrganizer> provides organization of message protocol

'!


!ClassDescription methodsFor: 'initialize-release'!

localObsolete
	"Make the receiver obsolete."

	organization _ nil.
	super localObsolete! !

!ClassDescription methodsFor: 'accessing'!

comment
	"Answer the receiver's comment."

	| aString |
	aString _ self organization classComment.
	aString size = 0 ifTrue: [^''].
	"get string only of classComment, undoubling quotes"
	^ String readFromString: aString!

comment: aString 
	"Set the receiver's comment to be the argument, aString."
	"heh 7 October 1990 commented out comment change logging because
	they are now logged with the class change.  This will also help prevent
	file-in problems due to class changes and renames where the comment:
	change is left in the log even though the class change is removed because
	of superscession.
	ravi 12 April 90 - put the change logging back in because comments were getting lost."
	
	| aStream |
	aString size = 0
		ifTrue: 
			[self organization classComment: aString.
			ChangeLog log: #comment class: self changes: self name , ' comment: ''''']
		ifFalse: 
			["double internal quotes of the comment string"
			aStream _ WriteStream on: (String new: aString size).
			aStream nextPutAll: self name , ' comment:'; cr.
			aString storeOn: aStream.
			ChangeLog log: #comment class: self changes: nil. "it is put in a RemoteString"
			self organization classComment: aStream contents.
			"Smalltalk changes commentClass: self"]!

commentTemplate
	"Answer an expression to edit and evaluate in order to produce the receiver's comment."

	| aString |
	aString _ self organization classComment.
	aString size = 0
		ifTrue: [^self name , ' comment:
''This class has not yet been commented.  A proper comment should include the purpose of the class and the type and purpose of each instance variable.
''']
		ifFalse: [^aString]!

environment
	"Answer the class's compilation scope."

	^Smalltalk!

name
	"Answer a String that is the name of the receiver."

	^'an anonymous Behavior'! !

!ClassDescription methodsFor: 'copying'!

copy: sel from: class 
	"Install the method associated with the first argument, sel, a message selector,
	found in the method dictionary of the second argument, class, as one of the
	receiver's methods.  Classify the message under -as yet not classified-."

	self copy: sel
		from: class
		classified: nil!

copy: sel from: class classified: cat 
	"Install the method associated with the first argument, sel, a message selector,
	found in the method dictionary of the second argument, class, as one of the
	receiver's methods.  Classify the message under the third argument, cat."

	| code category |
	"Useful when modifying an existing class"
	code _ class sourceMethodAt: sel.
	code == nil
		ifFalse: 
			[cat == nil
				ifTrue: [category _ class organization categoryOfElement: sel]
				ifFalse: [category _ cat].
			(methodDict includesKey: sel)
				ifTrue: [code asString = (self sourceMethodAt: sel) asString 
							ifFalse: [self notify: self name 
										, ' ' 
										, sel 
										, ' will be redefined if you proceed.']].
			self compile: code classified: category]!

copy: sel fromParent: class classified: cat 
	"Install the method associated with the first argument, sel, a message selector,
	found in the method dictionary of the second argument, class, as one of the
	receiver's methods.  Classify the message under the third argument, cat.
	
	If 'class' really is one of my superclasses, then I remove the client-comment from my copy of the method."

	| code category |
	"Useful when modifying an existing class"
	(self inheritsFrom: class)
		ifTrue: [code _ class sourceCodeWithoutClientCommentAt: sel]
		ifFalse: [code _ class sourceCodeStringAt: sel].
	code == nil
		ifFalse: 
			[cat == nil
				ifTrue: [category _ class organization categoryOfElement: sel]
				ifFalse: [category _ cat].
			(methodDict includesKey: sel)
				ifTrue: [code asString = (self sourceMethodAt: sel) asString 
							ifFalse: [self notify: self name 
										, ' ' 
										, sel 
										, ' will be redefined if you proceed.']].
			self compile: code classified: category]!

copyAll: selArray from: class 
	"Install all the methods found in the method dictionary of the second argument, class,
	as the receiver's methods.  Classify the messages under -as yet not classified-."

	self copyAll: selArray
		from: class
		classified: nil!

copyAll: selArray from: class classified: cat 
	"Install all the methods found in the method dictionary of the second argument, class,
	as the receiver's methods.  Classify the messages under the third argument, cat."

	selArray do: 
		[:s | self copy: s
				from: class
				classified: cat]!

copyAll: selArray fromParent: class 
	"Install all the methods found in the method dictionary of the second argument, class,
	as the receiver's methods."

	self copyAll: selArray
		fromParent: class
		classified: nil!

copyAll: selArray fromParent: class classified: cat 
	"Install all the methods found in the method dictionary of the second argument, class,
	as the receiver's methods.  Classify the messages under the third argument, cat."

	selArray do: 
		[:s | self copy: s
				fromParent: class
				classified: cat]!

copyAllCategoriesFrom: aClass 
	"Specify that the categories of messages for the receiver include all of those found
	in the class, aClass.  Install each of the messages found in these categories into the
	method dictionary of the receiver, classified under the appropriate categories."

	aClass organization categories do: [:cat | self copyCategory: cat from: aClass]!

copyCategory: cat from: class 
	"Specify that one of the categories of messages for the receiver is cat, as found
	in the class, aClass.  Copy each message found in this category."

	self copyCategory: cat
		from: class
		classified: cat!

copyCategory: cat from: aClass classified: newCat 
	"Specify that one of the categories of messages for the receiver is the third argument,
	newCat.  Copy each message found in the category cat in class aClass into this
	new category."

	self copyAll: (aClass organization listAtCategoryNamed: cat)
		from: aClass
		classified: newCat!

copyDeferred
	"copy all methods that send subclassResponsibility"
	
	self copyAll: (self superclass selectors select:
		[ :sel |
		(self superclass includesSelector: sel)
			and: [(self includesSelector: sel) not
			and: [ | special method |
				special _ Smalltalk specialSelectorIndexOf: #subclassResponsibility.
				method _ self superclass compiledMethodAt: sel.
				(method refersToLiteral: #subclassResponsibility)
					or: [special > 0 and: [method sendsSpecialSelector: special]]]]])
	fromParent: self superclass!

copyMethodsFrom: aClass 
	" opy all the categories from the specified class and its metaclass."

	self copyAllCategoriesFrom: aClass.
	(self isKindOf: Metaclass) ifFalse: [self class copyAllCategoriesFrom: aClass class]! !

!ClassDescription methodsFor: 'testing'!

isMeta
	"Answer whether the receiver is a meta class."

	^ false! !

!ClassDescription methodsFor: 'printing'!

classVariablesString
	"Answer a string of my class variable names separated by spaces, in alphabetical order."
	| aStream |
	aStream _ WriteStream on: (String new: 100).
	self classPool keys asSortedCollection do: [:key | aStream nextPutAll: key; space].
	^ aStream contents!

classVariablesStringWithTypes
	"Answer a string of my class variable names separated by spaces, in alphabetical order."
	self fetchCxxClassDescription == nil ifTrue:
		[^String streamContents: [ :stream |
			self classPool keys asSortedCollection do: [:key |
				stream nextPutAll: key; space]]]
	ifFalse:
		[^self getCxxClassDescription classVarTypeString]!

definition
	"Answer a string that defines the receiver."
	| aStream cxxPart |
	aStream _ WriteStream on: (String new: 300).
	aStream nextPutAll: (superclass == nil ifTrue: ['nil'] ifFalse: [superclass name]).
	aStream nextPutAll: self kindOfSubclass.
	self name storeOn: aStream.
	aStream cr; tab; nextPutAll: 'instanceVariableNames: '.
	aStream store: self instanceVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'classVariableNames: '.
	aStream store: self classVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'poolDictionaries: '.
	aStream store: self sharedPoolsString.
	aStream cr; tab; nextPutAll: 'category: '.
	(SystemOrganization categoryOfElement: self name) asString storeOn: aStream.
	"cxxPart _ self fetchCxxClassDescription.
	cxxPart ~~ nil ifTrue:
		[aStream cr; tab; nextPutAll: 'attributes: #', cxxPart attributes printString]."
	^aStream contents!

definitionWithComment
	"Answer a string that defines the receiver."
	| aStream |
	aStream _ WriteStream on: (String new: 300).
	aStream nextPutAll: (superclass == nil ifTrue: ['nil'] ifFalse: [superclass name]).
	aStream nextPutAll: self kindOfSubclass.
	self name storeOn: aStream.
	aStream cr; tab; nextPutAll: 'instanceVariableNames: '.
	aStream store: self instanceVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'classVariableNames: '.
	aStream store: self classVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'poolDictionaries: '.
	aStream store: self sharedPoolsString.
	aStream cr; tab; nextPutAll: 'category: '.
	(SystemOrganization categoryOfElement: self name) asString storeOn: aStream.
	aStream cr; tab; nextPutAll: 'comment: '; cr.
	self comment storeOn: aStream.
	^aStream contents!

definitionWithCommentAndAttributes
	"Answer a string that defines the receiver."
	| aStream |
	aStream _ WriteStream on: (String new: 300).
	aStream nextPutAll: (superclass == nil ifTrue: ['nil'] ifFalse: [superclass name]).
	aStream nextPutAll: self kindOfSubclass.
	self name storeOn: aStream.
	aStream cr; tab; nextPutAll: 'instanceVariableNames: '.
	aStream store: self instanceVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'classVariableNames: '.
	aStream store: self classVariablesStringWithTypes.
	aStream cr; tab; nextPutAll: 'poolDictionaries: '.
	aStream store: self sharedPoolsString.
	aStream cr; tab; nextPutAll: 'category: '.
	(SystemOrganization categoryOfElement: self name) asString storeOn: aStream.
	self fetchCxxClassDescription ~~ nil ifTrue:
		[aStream cr; tab; nextPutAll: 'attributes: '.
		self getCxxClassDescription attributes isEmpty
		ifTrue:
			[aStream nextPutAll: '#()'; cr; tab; tab;
				nextPutAll: CxxClassDescription attributeComment]
		ifFalse:
			[aStream nextPutAll: '#('.
			self getCxxClassDescription attributes do: [ :attr |
				(attr isKindOf: Symbol) ifTrue:
					[aStream nextPutAll: attr; space]
				ifFalse:
					[aStream nextPut: $(; nextPutAll: (attr at: 1); space;
						nextPutAll: (attr at: 2); nextPut: $); space]].
			aStream nextPut: $)]].
	aStream cr; tab; nextPutAll: 'comment: '; cr.
	self comment storeOn: aStream.
	^aStream contents!

instanceVariablesString
	"Answer a string of my instance variable names separated by spaces."
	| aStream names |
	aStream _ WriteStream on: (String new: 100).
	names _ self instVarNames.
	1 to: names size do: [:i | aStream nextPutAll: (names at: i); space].
	^ aStream contents!

instanceVariablesStringWithTypes
	"Answer a string of my instance variable names separated by spaces, in alphabetical order."
	self fetchCxxClassDescription == nil ifTrue:
		[^String streamContents: [ :stream |
			self instVarNames do: [:key |
				stream nextPutAll: key; space]]]
	ifFalse:
		[self isMeta
			ifTrue: [^self getCxxClassDescription classInstVarTypeString]
			ifFalse: [^self getCxxClassDescription instVarTypeString]]!

printOn: aStream  
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	aStream nextPutAll: self name!

sharedPoolsString
	"Answer a string of my class variable names separated by spaces."
	| aStream |
	aStream _ WriteStream on: (String new: 100).
	self sharedPools do: [:x | aStream nextPutAll: (Smalltalk keyAtValue: x); space].
	^ aStream contents!

storeOn: aStream
	"Append to the argument aStream the global names of.
	Classes and Metaclasses."

	aStream nextPutAll: self name! !

!ClassDescription methodsFor: 'instance variables'!

addInstVarName: aString 
	"Add the argument, aString, as one of the receiver's instance variables."

	self subclassResponsibility!

instanceVariables: aCollection
	"Set the class's instance variable list"

	(aCollection == nil or: [aCollection isEmpty])
		ifTrue:	[instanceVariables _ nil]
		ifFalse:	[instanceVariables _ aCollection]!

instVarNames
	"Answer an Array of the names of instance variables defined in the receiver."

	instanceVariables == nil
		ifTrue: [^#()]
		ifFalse: [^instanceVariables]!

removeInstVarName: aString 
	"Remove the argument, aString, as one of the receiver's instance variables."

	self subclassResponsibility! !

!ClassDescription methodsFor: 'method dictionary'!

addSelector: s withMethod: m category: c
	"Add the message selector s associated with the method m under category c."

	self addSelector: s withMethod: m.
	self organization classify: s under: c!

removeCategory: aString 
	"Remove each of the messages categorized under aString in the method dictionary
	of the receiver.  Then remove the category aString."

	(self organization listAtCategoryNamed: aString asSymbol) do:
		[:sel | self removeSelector: sel].
	self organization removeEmptyCategories!

removeSelector: aSymbol 
	"Remove the message whose selector is aSymbol from the method 
	dictionary of the receiver, if it is there. Answer nil otherwise."

	self organization removeElement: aSymbol.
	(methodDict includesKey: aSymbol)
		ifFalse: [^nil].
	super removeSelector: aSymbol.
	ChangeLog logging ifTrue: [
		"This test is to reduce log cruft when removing generated code
		- it's not logged anyway"
		ChangeLog
			log: #remove
			selector: aSymbol
			in: self
			changes: self name , ' removeSelector: ' , aSymbol storeString]

	"Smalltalk changes removeSelector: aSymbol class: self."! !

!ClassDescription methodsFor: 'organization'!

category
	"Answer the system organization category for the receiver."

	^SystemOrganization categoryOfElement: self name!

category: cat 
	"Categorize the receiver under the system category, cat, removing it from any
	previous categorization."

	cat isString
		ifTrue: [SystemOrganization classify: self name under: cat asSymbol]
		ifFalse: [self errorCategoryName]!

{void} cleanupOrganization
	"Put any methods that I have in common with my superclass into the same protocol as they are in the superclass, and then remove any protocols that become empty. Reorder the protocols in the same way, putting any remaining non-inherited protocols at the end."
	
	| first |
	self organization elements do: [ :selector |
		(self superclass organization includesElement: selector) ifTrue:
			[self organization classify: selector
				under: (self superclass organization
					categoryOfElement: selector)
				logged: false]].
	
	first := nil.
	self organization categories do: [ :protocol |
		(self organization listAtCategoryNamed: protocol) isEmpty ifTrue:
			[self organization removeCategory: protocol logged: false]
		ifFalse:
			[(first == nil and: [(self superclass organization
						listAtCategoryNamed: protocol) isEmpty]) ifTrue:
					[first := protocol]]].
	
	self superclass organization categories do: [ :protocol |
		(self organization listAtCategoryNamed: protocol) isEmpty ifFalse:
			[self organization addCategory: protocol before: first logged: false]].
	
	self reorganize!

organization
	"Answer the instance of ClassOrganizer that represents the organization
	of the messages of the receiver."
	nil == organization ifTrue:
		[organization _ ClassOrganizer new].
	self ~~ organization organizedClass ifTrue:
		[organization organizedClass: self].
	^organization!

reorganize
	"Record that the receiver is being reorganized and answer the receiver's organization."
	
	"Smalltalk changes reorganizeClass: self."
	^self organization!

whichCategoryIncludesSelector: aSelector 
	"Answer the category of the argument, aSelector, in the organization of the
	receiver, or answer nil if the receiver does not inlcude this selector."

	(self includesSelector: aSelector)
		ifTrue: [^organization categoryOfElement: aSelector]
		ifFalse: [^nil]! !

!ClassDescription methodsFor: 'compiling'!

compile: code classified: heading 
	"Compile the argument, code, as source code in the context of the receiver and
	install the result in the receiver's method dictionary under the classification 
	indicated by the second argument, heading. nil is to be notified if an error occurs.
	The argument code is either a string or an object that converts to a string or a
	PositionableStream on an object that converts to a string."

	^self
		compile: code
		classified: heading
		notifying: nil!

compile: aString classified: protocol notifying: aController 
	| selector |
	selector _ self
				compile: aString
				notifying: aController
				ifFail: [^nil].
	(methodDict at: selector)
		putSource: aString asString
		class: self
		category: protocol
		inFile: 2.
	self organization classify: selector under: protocol logged: false.
	^selector!

compile: code notifying: requestor ifFail: failBlock 
	"Intercept this message in order to remember system changes."

	| methodNode selector action |
	Cursor execute showWhile:
		[methodNode _
			 	self compilerClass new
					compile: code
					in: self
					notifying: requestor
					ifFail: failBlock.
	selector _ methodNode selector.
	action _ (methodDict includesKey: selector)
		ifTrue: [#accept] ifFalse: [#add].
	ChangeLog log: action selector: selector in: self changes: nil.
	self addSelector: selector withMethod: methodNode generate].
	^selector!

recompile: method {Symbol} afterSearch: searchString {String} andReplace: replaceString {String} notifying: notifier

	| codeString fixedString whichProt |
	(self includesSelector: method) ifFalse: [^ nil].
	whichProt _ organization categoryOfElement: method.
	codeString _ self sourceCodeAt: method.
	fixedString _ codeString replaceAll: searchString with: replaceString.
	codeString ~= fixedString
		ifTrue: [^ self compile: fixedString classified: whichProt notifying: notifier]
		ifFalse: [^ method]!

recompileAllAfterSearch: searchString {String} 
	andReplace: replaceString {String} 
	notifying: notifier 
	
	self selectorsDo: [:method | (self
			recompile: method
			afterSearch: searchString
			andReplace: replaceString
			notifying: notifier)
		== nil ifTrue: [^nil]]! !

!ClassDescription methodsFor: 'fileIn/Out'!

fileOutCategory: aString 
	"Create a file whose name is the name of the receiver with -.st- as the
	extension, and file a description of the receiver's category aString onto it."

	| fileName fileStream |
	fileName _ self name , '-' , aString , '.st'.
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self fileOutCategory: aString
		on: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

fileOutCategory: aString on: aFileStream moveSource: moveSource toFile: fileIndex 
	"File a description of the receiver's category, aString, onto aFileStream.  If
	the boolean argument, moveSource, is true, then set the trailing bytes to the position 
	of aFileStream and to fileIndex in order to indicate where to find the source code."

	self printCategoryChunk: aString on: aFileStream.
	(self organization listAtCategoryNamed: aString)
		do: [:sel | self
				printMethodChunk: sel
				on: aFileStream
				moveSource: moveSource
				toFile: fileIndex].
	aFileStream nextChunkPut: ' '!

fileOutChangedMessages: aSet on: aFileStream 
	"File a description of the messages of the receiver that have been changed
	(i.e., are entered into the system ChangeSet) onto aFileStream."

	self fileOutChangedMessages: aSet
		on: aFileStream
		moveSource: false
		toFile: 0!

fileOutChangedMessages: aSet on: aFileStream moveSource: moveSource toFile: fileIndex 
	"File a description of the messages of the receiver that have been changed
	(i.e., are entered into the system ChangeSet) onto aFileStream.  If
	the boolean argument, moveSource, is true, then set the trailing bytes to the position 
	of aFileStream and to fileIndex in order to indicate where to find the source code."

	| org sels |
	(org _ self organization) categories do: 
		[:cat | 
		sels _ (org listAtCategoryNamed: cat) select: [:sel | aSet includes: sel].
		sels size > 0
			ifTrue: 
				[Transcript cr; show: self name , '>' , cat.
				self printCategoryChunk: cat on: aFileStream.
				sels do: [:sel | 
						self
							printMethodChunk: sel
							on: aFileStream
							moveSource: moveSource
							toFile: fileIndex].
				aFileStream nextChunkPut: ' ']]!

fileOutMessage: aString 
	"Create a fileName which is the name of the receiver with -.st as the
	extension, and file a description of the receiver's message aString onto it"

	self fileOutMessage: aString
		fileName: (self name , '-' , aString , '.st')!

fileOutMessage: aString fileName: fileName
	"Create a local file named fileName
	and file a description of the receiver's message aString onto it"

	| fileStream |
	fileStream _ (Filename named: fileName) writeStream.
	[fileStream timeStamp.
	self fileOutOn: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

fileOutMessage: aString on: aFileStream moveSource: moveSource toFile: fileIndex 
	"File a description of the receiver's message, aString, onto aFileStream.  If
	the boolean argument, moveSource, is true, then set the trailing bytes to the position 
	of aFileStream and to fileIndex in order to indicate where to find the source code."

	| cat |
	cat _ self organization categoryOfElement: aString.
	cat == nil ifTrue: [^self error: 'no such message'].
	self printCategoryChunk: cat on: aFileStream.
	self
		printMethodChunk: aString
		on: aFileStream
		moveSource: moveSource
		toFile: fileIndex.
	aFileStream nextChunkPut: ' '!

fileOutOn: aFileStream 
	"File a description of the receiver on aFileStream."

	self fileOutOn: aFileStream
		moveSource: false
		toFile: 0!

fileOutOn: aFileStream moveSource: moveSource toFile: fileIndex
	"file me out on aFileStream"
	aFileStream emphasis: 5.		"Meant to be 12 point bold font."
	aFileStream nextChunkPut: self definition.
	self organization
		putCommentOnFile: aFileStream
		numbered: fileIndex
		moveSource: moveSource.
	aFileStream cr.
	self fetchCxxClassDescription ~= nil ifTrue: [
		self fetchCxxClassDescription fileoutOrgOn: aFileStream].
	self organization categories do: 
		[:heading |
		self
			fileOutCategory: heading
			on: aFileStream
			moveSource: moveSource
			toFile: fileIndex]!

fileOutOrganizationOn: aFileStream 
	"File a description of the receiver's organization onto aFileStream."

	aFileStream emphasis: 3.
	aFileStream cr.
	aFileStream nextChunkPut: self name , ' organization changeFromString: ' , self organization storeString storeString.
	aFileStream cr.
	aFileStream emphasis: 1!

kindOfSubclass
	"Answer a string that describes what kind of subclass the receiver is, i.e.,
	variable, variable byte, variable word, or not variable."

	self isVariable
		ifTrue: [self isBits
					ifTrue: [^' variableByteSubclass: ']
					ifFalse: [^' variableSubclass: ']]
		ifFalse: [^' subclass: ']!

methodsFor: aString 
	"Answer a ClassCategoryReader for accessing the messages in the method
	dictionary category, aString, of the receiver."

	^ClassCategoryReader class: self category: aString asSymbol
	"(False methodsFor: 'logical operations') inspect"!

moveChangesTo: newFile 
	"Used in the process of condensing changes, this message requests that the source
	code of all methods of the receiver that have been changed should be moved to
	newFile."

	| changes |
	self organization moveChangedCommentToFile: newFile numbered: 2.
	changes _ methodDict keys select: [:sel | (methodDict at: sel) fileIndex > 1].
	self fileOutChangedMessages: changes
		on: newFile
		moveSource: true
		toFile: 2!

printCategoryChunk: aString on: aFileStream 
	"Print category definition on aFileStream."

	aFileStream cr; cr; nextPut: $!!.
	aFileStream nextChunkPut:
				self name , ' methodsFor: ' , '''' , aString , ''''!

printMethodChunk: aSelector on: aFileStream moveSource: moveSource toFile: fileIndex 
	"Print the source code for the method associated with the argument 
	selector onto 
	the fileStream. aFileStream, and, for backup, if the argument 
	moveSource (a Boolean) 
	is true, also set the file index within the method to be the argument 
	fileIndex. "

	| position |
	aFileStream cr.
	Cursor write showWhile:
		[moveSource
			ifTrue: 
				[position _ aFileStream writePosition.
				aFileStream nextChunkPut: (self sourceCodeAt: aSelector).
				(self compiledMethodAt: aSelector)
					setSourcePosition: position inFile: fileIndex]
			ifFalse: [aFileStream cr; nextChunkPut: (self sourceCodeAt: aSelector)]]!

printOutCategory: aString 
	"Create a readable version of the message category aString, and send to a printer.
	Defaults to fileOut."
	self fileOutCategory: aString!

printOutCategory: aSymbol on: aStream 
	"File a description of the receiver's category, aSymbol, onto aStream."
	|saved|
	saved _ aStream emphasis.
	aStream emphasis: 2.
	aStream cr.
	aStream nextPutAll: self name , ' methodsFor: ' , aSymbol.
	aStream emphasis: saved.
	(self organization listAtCategoryNamed: aSymbol)
		do: [:sel | self printMethod: sel on: aStream].
	aStream cr!

printOutCategoryInterface: aSymbol on: aStream 
	"File a description of the receiver's category, aSymbol, onto aStream."
	|saved|
	saved _ aStream emphasis.
	aStream emphasis: 2.
	aStream cr.
	aStream nextPutAll: self name , ' methodsFor: ' , aSymbol.
	aStream emphasis: saved.
	(self organization listAtCategoryNamed: aSymbol)
		do: [:sel | "(self selector: sel hasAttribute: #CLIENT)
			ifTrue: ["self printMethodInterface: sel on: aStream"]"].
	aStream cr!

printOutInterfaceOn: aStream
	"Print me out on a textStream"
	|saved |
	saved _ aStream emphasis.
	aStream emphasis: 11.		"Meant to be 12 point bold font."
	aStream nextPutAll: self definition.
	aStream emphasis: 3.		"meant to be 10 point italic font"
	aStream cr.
	aStream nextPutAll: self comment.
	aStream emphasis: saved.
	aStream cr.
	self organization categories do: 
		[:heading |
			(self interfaceProtocol: heading)
				ifTrue: [self printOutCategoryInterface: heading on: aStream]].
	aStream cr.
	aStream cr!

printOutMessage: aString 
	"Create a readable version of the message with selector aString, and send to a printer.
	Defaults to fileOut."
	self fileOutMessage: aString!

printOutOn: aStream
	"Print me out on a textStream"
	|saved |
	saved _ aStream emphasis.
	aStream emphasis: 11.		"Meant to be 12 point bold font."
	aStream label: (Association key: self name asString value: nil).
	aStream nextPutAll: self definition.
	aStream emphasis: 3.		"meant to be 10 point italic font"
	aStream cr.
	aStream nextPutAll: self comment.
	aStream emphasis: saved.
	aStream cr.
	self organization categories do: 
		[:heading | self printOutCategory: heading on: aStream].
	aStream cr.
	aStream cr! !

!ClassDescription methodsFor: 'private: private'!

errorCategoryName
	self error: 'Category name must be a String'! !

!ClassDescription methodsFor: 'doc generation'!

documentCxxCategory: cat on: docStream inline: aBool
	| vis |
	(self protocol: cat hasAttribute: #smalltalk) ifTrue: [^self].
	vis _ self cxxVisibility: cat.
	(vis = #public or: [vis = #PROXY]) ifTrue: [
		"don't convert categories that are only appropriate to smalltalk. 
	 	This is used for constructors in the class as well."
		docStream nextPutAll: '  ', (self cxxVisibility: cat), ': '; printComment: cat.
		docStream indent.
		(self organization listAtCategoryNamed: cat)
			do: [ :sel | 
				self documentCxxMethod: sel on: docStream notifying: nil].
		docStream unindent; cr]!

documentCxxMethod: sel on: docStream notifying: controller
	| tree |
	tree _ Parser new
				parse: (self sourceCodeStringAt: sel)
				class: self
				notifying: controller.
	tree == nil ifTrue: [self error: 'couldn''t parse method.' . ^false].
	sel = #restart ifFalse:
		[docStream cr.
		docStream printMethod: tree.
		docStream checkStatement].
	docStream cr.
	^true! !

!ClassDescription methodsFor: 'cxx fileOut'!

{String} cxxVisibility: cat {String}
	"Return one of public private or protected."

	(self protocol: cat hasAttribute: #private)
		ifTrue: [^#private].
	(self protocol: cat hasAttribute: #protected)
		ifTrue: [^#protected].
	^#public!

star!

vector! !

!ClassDescription methodsFor: 'cxx fileIn/fileOut'!

at: key storeInfo: info
	
	(info == nil or: [info isEmpty]) ifTrue: [^self class removeSelector: key].
	self class compile: 'info.', key, '
"',	(info copyReplaceAll: '"' with: '""'), '"'
		classified: #'smalltalk: system'!

attributes
	| cxc |
	cxc _ self fetchCxxClassDescription.
	cxc == nil ifTrue: [^Set new]
		ifFalse: [^cxc attributes]!

cxxName
	"I make sure the class name is not a dotted type, and if it is, I remove the dot 
	and extension"
	^HxxPrintStream mapVarName: (self isMeta ifTrue: [self soleInstance name] ifFalse: [self name])!

fetchCxxClassDescription
	self isMeta
		ifTrue: [^self soleInstance fetchCxxClassDescription]
		ifFalse: [^self organization fetchCxxClassDescription].!

getCxxClassDescription
	self isMeta
		ifTrue: [^self soleInstance getCxxClassDescription]
		ifFalse: [^self organization getCxxClassDescription]!

getInfo: key
	"Heaper getInfo: #promiseClasses"
	
	| string ii oo sel |
	sel _ ('info.', key) asSymbol.
	(self class includesSelector: sel) ifFalse: [^''].
	string _ self class sourceCodeStringAt: sel.
	ii _ string readStream.
	ii skipThrough: $".
	oo _ (String new: string size) writeStream.
	[ii atEnd] whileFalse:
		[| c |
		c _ ii next.
		(c == $" and: [ii atEnd or: [ii next ~~ $"]]) 
			ifTrue: [^oo contents].
		oo nextPut: c].                                   
	^oo contents!

getOrMakeCxxClassDescription
	self isMeta
		ifTrue: [^self soleInstance getOrMakeCxxClassDescription]
		ifFalse: [^self organization getOrMakeCxxClassDescription: self]!

{BooleanVar} globalProtocol: protocolName 
	(HxxPrintStream globalProtocolAttributes)
		notNil: [:attrs | 
			attrs do: [:attr {Symbol} |
				(self protocol: protocolName hasAttribute: attr) ifTrue: [^ true]]].
	^ false!

hasAttribute: attr
	| cxc |
	cxc _ self fetchCxxClassDescription.
	^cxc ~~ nil and: [cxc includesAttribute: attr]!

{BooleanVar} interfaceProtocol: protocolName 

	(HxxPrintStream nonInterfaceProtocolAttributes)
		notNil: [:attrs | 
			attrs do: [:attr {Symbol} |
				(self protocol: protocolName hasAttribute: attr) ifTrue: [^false]]].
	^true!

{BooleanVar} protocol: prot {String} hasAttribute: attr {Symbol}
	"currently matches if the string consisting of 'attr' followed by ';' appears in the protocol.  Eventually will be only match if (attr,':') appears in protocol as a keyword token by the normal lexing rules."
	
	prot isNil ifTrue: [^false].
	self knownBug. "have it only match according to lexing rules as stated above."
	^(prot indexOfSubCollection: (attr, ':')) > 0!

{BooleanVar} selector: sel {Symbol} hasAttribute: attr {Symbol}

	| source {String}  returnType ii |
	source _ (methodDict at: sel) getSource.
	source == nil ifTrue: [^false].
	ii _ source readStream.
	ii skipSeparators.
	ii next == ${ ifFalse: [^false].
	returnType _ ii upTo: $}.
	^(returnType indexOfSubCollection: attr) > 0! !

!ClassDescription methodsFor: 'change log'!

{Symbol} getClassName
	"get the class name"
	
	self isMeta
		ifTrue: [^ self soleInstance name asSymbol]
		ifFalse: [^ self name asSymbol]!

{OrderedCollection of: Symbol} getPath
	"get a list of symbols defining the path down to this class"
	| loc |  
	(self fetchCxxClassDescription ~~ nil
			and: [CxxSystemOrganization ~~ nil
			and: [(CxxSystemOrganization fetchFileForClass: self nonMeta name) ~~ nil
			and: [(loc _ CxxSystemOrganization fetchLocationOfClass: self) ~~ nil]]])
		ifTrue: [^loc turns]
		ifFalse: [^Array with: (SystemOrganization getCategoryOfElement: self getClassName)]!

{Symbol} getVisibility
	"get the class visibility"
	
	self fetchCxxClassDescription == nil
		ifTrue: [^ ChangeRecord visibility]
		ifFalse: [^ self getCxxClassDescription visibility]! !

!ClassDescription methodsFor: 'metrics'!

classDepth
	"depth from Object"
	self == Object
		ifTrue: [^0]
		ifFalse: [^superclass classDepth+1]!

depthHistogram
	"Object depthHistogram"
	^(self withAllSubclasses collect: [ :class | class classDepth])
		asBag sortedElements! !

!ClassDescription methodsFor: 'stubble'!

{Object} makeProxy: comm {CommHandler}
	^self! !

!ClassDescription methodsFor: 'smalltalk: passe'!

cxxHeader: ignored
	
	self passe!

hxxHeader: ignored
	self passe! !

!ClassDescription methodsFor: 'obsolete:'! !

!ClassDescription methodsFor: 'smalltalk: smalltalk/v'!

fileOutSmalltalkVOn: stv
	"File out a version of the class that can be filed in to Smalltalk/V"
	| cxx t |
	"| f | f := (Filename named: 'xupoint.stv') newReadAppendStream.
		XuPoint fileOutSmalltalkVOn: f.
		f close"
		
	stv cr; cr; nextChunkPut: self stvDefinition.
	"Class methods that store the information stored in the organization and cxxDescription"
	stv cr; cr; nextChunkPut: ''; nextChunkPut: self name , ' class methods'.
	(t := SystemOrganization categoryOfElement: self name) ~~ nil ifTrue:
		[stv cr; cr; nextPut: $!!; nextChunkPut: 'browserCategory
    ^' , t storeString].
	((t := self comment) ~~ nil and: [t isEmpty not]) ifTrue:
		[stv cr; cr; nextPut: $!!; nextChunkPut: 'comment
    ^' , t storeString].
	cxx := self fetchCxxClassDescription.
	cxx ~~ nil ifTrue:
		[((t := cxx fetchInstVarTypeArray) ~~ nil and: [t isEmpty not]) ifTrue:
			[stv cr; cr; nextPut: $!!; nextChunkPut: 'instVarTypes
    ^' , t storeString].
		((t := cxx fetchClassVarTypeArray) ~~ nil and: [t isEmpty not]) ifTrue:
			[stv cr; cr; nextPut: $!!; nextChunkPut: 'classVarTypes
    ^' , t storeString].
		(t := cxx attributes asOrderedCollection asArray) isEmpty not ifTrue:
			[stv cr; cr; nextPut: $!!; nextChunkPut: 'attributes
    ^' , t storeString].
		(t := cxx friends) ~~ nil ifTrue:
			[stv cr; cr; nextPut: $!!; nextChunkPut: 'friends
    ^' , t storeString].
		(t := cxx fetchGroup) ~~ nil ifTrue:
			[stv cr; cr; nextPut: $!!; nextChunkPut: 'group
    ^' , t fileBaseName storeString]].
	
	self class selectors do: [ :classMethod |
		self class fileOutSTVMethod: classMethod on: stv].
	
	self selectors do: [ :method |
		self fileOutSTVMethod: method on: stv].!

fileOutSTVMethod: sel {Symbol} on: stv {WriteStream}
	"File out a method translated into Smalltalk/V form"
	(SmalltalkVTranscriber make: self with: sel) fileOutOn: stv!

stvDefinition
	"Answer a string that defines the receiver in Smalltalk/V format."
	| aStream |
	aStream _ WriteStream on: (String new: 300).
	aStream nextPutAll: (superclass == nil ifTrue: ['nil'] ifFalse: [superclass name]).
	aStream nextPutAll: self kindOfSubclass.
	self name storeOn: aStream.
	aStream cr; nextPutAll: ' instanceVariableNames: '.
	aStream store: self instanceVariablesString.
	aStream cr; nextPutAll: ' classVariableNames: '.
	aStream store: self classVariablesString.
	aStream cr; nextPutAll: ' poolDictionaries: '.
	aStream store: self sharedPoolsString.
	^aStream contents! !
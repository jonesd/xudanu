'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:29 pm'!

Object subclass: #Checker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Releasing'!
Checker comment:
'I contain a collection of checks to run for system consistency.'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Checker class
	instanceVariableNames: ''!
Checker class comment:
'I am a class used for running static checks over the system.'!



!Checker class methodsFor: 'static checks'!

allUnimplementedCalls 
	"Answer an Array of each message that is sent by an expression in a method
	but is not implemented by any object in the system."

	| aStream secondStream mu  |
	mu _ MessageUsage stale.
	aStream _ WriteStream on: (Array new: 50).
	Cursor execute showWhile:
		[Smalltalk allBehaviorsDo: [:cl |
			cl methodsDo: [:sel {Symbol} :code {CompiledMethod} | 
				secondStream _ WriteStream on: (String new: 5).
				code messages do: [:m | 
					(mu isImplemented: m) 
						ifFalse: [secondStream nextPutAll: m; space]].
				secondStream position = 0 
					ifFalse: [aStream nextPut: cl name , ' ' , sel , ' calls: ', secondStream contents]]]].
	^aStream contents!

{OrderedCollection of: String} allUnSentMessages
	"Answer an OrderedCollection of each message that is implemented by some object in the
	system but is not sent by any."

	| result |
	result _ OrderedCollection new.
	Cursor execute
		showWhile: 
			[MessageUsage stale allUnusedDo: [:sel | 
				result addAll: (Smalltalk allImplementorsOf: sel)]].
	^result!

findAllNonAsciiSources
	"Collect chunks from the source files containing bad
characters."

	"Checker findAllNonAsciiSources inspect."

	| aChar cr ff tab aStream badCharacter aFileStream aChunk
badStream|
	cr _ Character cr asciiValue.
	ff _ Character newPage asciiValue.
	tab _ Character tab asciiValue.
	badStream _ WriteStream on: (Array new: 10).
	Cursor execute show.
	1 to: 2 do:
		[:i |
		aFileStream _ (SourceFiles at: i) name asFilename
readStream.
		aFileStream reset.
		[aFileStream atEnd]
			whileFalse:
				[aChunk _ aFileStream nextChunk.
				aStream _ ReadStream on: aChunk.
				badCharacter _ false.
				[aStream atEnd or: [badCharacter]]
				whileFalse: 
					[aChar _ aStream next asciiValue.
					(aChar > 127 
						or: [aChar < 32
							and: [aChar ~= cr & (aChar ~= ff) & (aChar ~=
tab)]])
						ifTrue: 
						[Transcript show: '*'.
						badCharacter _ true]].
				badCharacter ifTrue: [badStream nextPut: aChunk]].
		aFileStream close].
	Cursor normal show.
	^badStream contents!

findSharedPoolVariables
	"Answer an ordered collection of pool variable names and classes in which
	the variable declaration is duplicated."

	"Checker findSharedPoolVariables inspect."

	| aSet duplicates |
	duplicates _ OrderedCollection new.
	Smalltalk allClassesDo:
	[:class |
	class subclasses isEmpty
		ifTrue:
			[aSet _ Set new.
			class allSharedPools do:
				[:pool |
				pool keys do:
					[:key |
					(aSet includes: key)
						ifTrue: [duplicates add: (Association key: key value: class)].
					aSet add: key]]]].
	^duplicates!

instanceVariablesNotReferenced
	"Answer a list of classes and instance variables defined in, but not used in that class."

	"Checker instanceVariablesNotReferenced"

	| aStream classes |
	aStream _ WriteStream on: (Array new: 50).
	Smalltalk allBehaviorsDo:
		[:class |
		classes _ (Array with: class) , class allSubclasses.
		class instVarNames do:
			[:instVarName |
			classes detect: [:c | (c whichSelectorsAccess: instVarName) size > 0]
				ifNone: [aStream nextPut: class name, ' ', instVarName]]].
	^aStream contents!

multipleCategoryMessageNames
	"Answer the names of all the messages defined in more then one category, 
	along with the category names."

	| aDictionary |
	aDictionary _ IdentityDictionary new: 1024.
	Smalltalk allBehaviorsDo:
		[:class |
		class organization categories do:
			[:catName |
			(class organization listAtCategoryNamed: catName) do:
				[:selector |
				(aDictionary includesKey: selector)
					ifTrue:
						[(aDictionary at: selector) add: catName]
					ifFalse: [aDictionary
								at: selector
								put: (Set with: catName)]]]].
	^aDictionary keys select: [:selector | (aDictionary at: selector) size > 1]!

obsoleteClasses
	"Answer a collection of all obsolete classes."

	"Checker obsoleteClasses inspect "

	^(Metaclass allInstances select: [:metaclass | metaclass isObsolete])
		collect: [:metaclass | metaclass someInstance]!

obsoleteClassReferences
	"Answer a collection of all the methods that reference obsolete classes."

	"Checker obsoleteClassReferences inspect "

	| methods |
	methods _ SortedCollection new.
	self obsoleteAssociations do: [:assoc | methods addAll: (Smalltalk allCallsOn: assoc)].
	^methods!

obsoleteInstanceCounts
	"Answer a Dictionary of the number of instances of each obsolete class."

	"Checker obsoleteInstanceCounts inspect"

	| obsolete count |
	obsolete _ Dictionary new.
	self obsoleteClasses do:
		[:class |
		count _ class instanceCount.
		count > 0 ifTrue: [obsolete at: class put: count]].
	^obsolete!

onlyReturnSelves
	"Answer an Array of the message names for messages that 
	are ^self only (i.e. no implementation)."

	"Checker onlyReturnSelves inspect"

	| aStream |
	aStream _ WriteStream on: (Array new: 50).
	Smalltalk allBehaviorsDo:
		[:class |
		class methodsDo:
				[:sel {Symbol} :code {CompiledMethod} |
			(code byteAt: 1) = (OpcodePool at: #OpReturnReceiver)
				ifTrue: [aStream nextPut: class name, ' ', sel]]].
	^aStream contents!

rehashBadSets
	"Answer a Set of all the Sets in the system that had to be rehashed."

	"Checker rehashBadSets inspect"

	| badSets checkSet |
	badSets _ Set new.
	checkSet _ [:set |
		(set isKindOf: Dictionary)
			ifTrue: [set keysDo:
				[:x | (set includesKey: x) ifFalse: [badSets add: set]]]
			ifFalse: [set do:
				[:x | (set includes: x) ifFalse: [badSets add: set]]]].

	Set allInstances do: checkSet.
	Set allSubInstancesDo: checkSet.
	badSets do: [:bad | bad rehash].
	Transcript cr; print: badSets size; show: ' bad sets/dictionaries rehashed'.
	^badSets!

unResponsives
	"Answer an Array of all methods in the system that were implemented
	in a superclass as subclassResponsibility and should have been reimplemented
	in at least one subclass."

	"Checker unResponsives inspect"

	| aStream aCollection satisfiedSet workingSet aSubclass |
	aStream _ WriteStream on: (Array new: 50).
	Smalltalk allBehaviorsDo:
		[:class |
		aCollection _ class whichSelectorsReferTo: #subclassResponsibility.
		aCollection size > 0
			ifTrue:
				[aCollection do:
					[:selector |
					workingSet _ class subclasses asOrderedCollection.
					satisfiedSet _ Set new.
					[workingSet isEmpty] whileFalse:
						[aSubclass _ workingSet removeFirst.
						(aSubclass includesSelector: selector)
							ifFalse: 
								[satisfiedSet add: aSubclass.
								workingSet addAll: aSubclass subclasses]].
					 satisfiedSet do:
						[:subclass | 
						aStream nextPut: class name, ' ', selector, '
	', subclass name]]]].
	^aStream contents! !

!Checker class methodsFor: 'catagory checks'!

allCategoryNames
	"Answer a SortedCollection of the names of all the categories (sorted 
	alphabetically). "

	| aSet |
	aSet _ Set new: 1000.
	Smalltalk allBehaviorsDo: [:class | class organization categories do: [:catName | aSet add: catName]].
	^aSet asSortedCollection!

categoriesSelect: aBlock 
	"Answer an Array of categories that fill the criteria  
	tested with the argument aBlock."

	"Checker categoriesSelect: [:catName | catName first = $A]"

	| aStream |
	aStream _ WriteStream on: (Array new: 500).
	Smalltalk allBehaviorsDo: 
		[:class | class organization categories 
					do: [:catName | (aBlock value: catName)
							ifTrue: [aStream nextPut: class name , ' >> ' , catName]]].
	^aStream contents asSortedCollection!

checkOrganizations
	"Check for organization/messagedict inconsistencies.  Print the result in the
	System Transcript."

	"Checker checkOrganizations.
	Smalltalk allClassesDo: 
			[:cl | cl removeSelector: #DoIt; removeSelector: #DoItIn:]. "

	| set |
	Smalltalk classNames do: 
		[:className | 
		(Array with: (Smalltalk at: className) with: (Smalltalk at: className) class) do: 
			[:class | 
			set _ Set new.
			class organization categories do: 
				[:cat | (class organization listAtCategoryNamed: cat) do: 
						[:sel | 
						(set includes: sel)
							ifTrue: [Transcript show: class name , ' multiple: ' , sel; cr].
						set add: sel]].
			class selectorsDo: 
				[:sel | (set includes: sel)
					ifTrue: [set remove: sel]
					ifFalse: [Transcript show: class name , ' missing: ' , sel; cr]].
				set do: [:sel | Transcript nextPutAll: (class name , '
spurious: ' , sel); cr; endEntry.
					class organization removeElement: sel.]]].
	Transcript show: 'Done checking.'; cr!

singleClassCategoryNames
	"Answer the names of all the categories defined in only one class, alphabetic."

	"Checker singleClassCategoryNames."

	| aDictionary aStream |
	aDictionary _ IdentityDictionary new: 512.
	Smalltalk allBehaviorsDo: 
		[:class | class organization categories do: 
			[:catName |
			(aDictionary includesKey: catName)
				ifTrue: [(aDictionary at: catName) = nil
							ifFalse: [aDictionary at: catName put: nil]]
				ifFalse: [aDictionary at: catName put: class name]]].
	aStream _ WriteStream on: (Array new: 500).
	aDictionary associationsDo:
		[:assn |
		assn value == nil
			ifFalse: [aStream nextPut: assn value, ' >> ',assn key]].
	^aStream contents asSortedCollection!

unaryCategoryNames
	"Answer the names of all the categories with only one message in them."

	| aSet |
	aSet _ Set new: 1000.
	Smalltalk allBehaviorsDo: 
		[:class | class organization categories do: 
			[:catName | 
			(class organization listAtCategoryNamed: catName) size = 1
				ifTrue: [aSet add: class name, ' >> ',  catName]]].
	^aSet asSortedCollection!

whichClassesHaveCategory: categoryName
	"Answer the names of all the classes with the category."

	"Checker whichClassesHaveCategory: 'accessing'."

	| aStream |
	aStream _ WriteStream on: (Array new: 500).
	Smalltalk allBehaviorsDo: 
		[:class | 
		(class organization categories includes: categoryName asSymbol)
			ifTrue: [aStream nextPut: class name]].
	^aStream contents asSortedCollection!

whichClassesIncludeCategory: categoryName
	"Answer an Array of each class that includes the name, categoryName, as
	one of its message categories."

	"Checker whichClassesIncludeCategory: #comparison."

	| aStream cat |
	aStream _ WriteStream on: (Array new: 10).
	cat _ categoryName asSymbol.
	Smalltalk allClassesDo:
		[:class |
		(class organization categories includes: cat)
			ifTrue: [aStream nextPut: class].
		(class class organization categories includes: cat)
			ifTrue: [aStream nextPut: class class]].
	^aStream contents! !

!Checker class methodsFor: 'browsing'!

browseAllNonAsciiMessages
	"Bring up a Message Set Window with methods containing
bad characters."

	"Checker browseAllNonAsciiMessages."

	| aChar cr ff tab aStream badCharacter |
	cr _ Character cr asciiValue.
	ff _ Character newPage asciiValue.
	tab _ Character tab asciiValue.
	Smalltalk 
		browseAllSelect: 
			[:method | 
			badCharacter _ false.
			aStream _ ReadStream on: method getSource.
			[aStream atEnd or: [badCharacter]]
				whileFalse: 
					[aChar _ aStream next asciiValue.
					(aChar > 127 
						or: [aChar < 32
								and: [aChar ~= cr & (aChar ~= ff) & (aChar ~=
tab)]])
						ifTrue: 
							[Transcript show: '*'.
							badCharacter _ true]].
			badCharacter]!

browseAllUnimplementedCalls
	"Create and schedule a message browser on each method that includes a message
	that is not implemented in any object in the system."

	"Checker browseAllUnimplementedCalls "

	BrowserView
		openListBrowserOn: self allUnimplementedCalls
		label: 'Unimplemented calls'!

browseAllUnSentMessages
	"Create and schedule a message browser on each method that is not sent."
	
	"Checker browseAllUnSentMessages "

	BrowserView
		openListBrowserOn: self allUnSentMessages

		label: 'Unsent Messages'!

browseObsoleteClassReferences
	"Bring up a Message Set Window with methods that reference obsolete classes
	if there are any, otherwise simply print 'nobody' in the System Transcript."

	"Checker browseObsoleteClassReferences."

	BrowserView
		openListBrowserOn: Checker obsoleteClassReferences 
		label: 'References to Obsolete Classes'! !

!Checker class methodsFor: 'printing'!

printAllMessagesOn: aFileStream 
	"Print a list of all the messages implemented in the system on the file, aFileStream."

	"Checker printAllMessagesOn: 'Smalltalk.allMessages' asFilename writeStream."

	| class selectorStream |
	selectorStream _ WriteStream on: (String new: 100).
	SystemOrganization categories do: 
		[:sysCat | 
		Transcript show: sysCat; cr.
		"form feed between categories of classes"
		aFileStream nextPut: Character newPage; cr; nextPutAll: sysCat.
		(SystemOrganization listAtCategoryNamed: sysCat) do: 
			[:className | 
			class _ Smalltalk at: className.
			aFileStream crtab: 1; nextPutAll: className.
			class organization categories do: 
				[:classCat | 
				aFileStream crtab: 2; nextPutAll: classCat; crtab: 3.
				selectorStream reset.
				(class organization listAtCategoryNamed: classCat) do: 
					[:selector | 
					(selectorStream position + selector size) > 70
						ifTrue: 
							[aFileStream nextPutAll: selectorStream contents.
							aFileStream crtab: 4.
							selectorStream reset].
					selectorStream space; nextPutAll: selector.
					aFileStream nextPutAll: selectorStream contents.]].
			aFileStream crtab: 1; nextPutAll: class class name.
			class class organization categories
			  do: 
				[:classCat | 
				aFileStream crtab: 2; nextPutAll: classCat; crtab: 3.
				selectorStream reset.
				(class class organization listAtCategoryNamed: classCat) do: 
					[:selector | 
					(selectorStream position + selector size) > 70
						ifTrue: 
							[aFileStream nextPutAll: selectorStream contents.
							aFileStream crtab: 4.
							selectorStream reset].
					selectorStream space; nextPutAll: selector.
					aFileStream nextPutAll: selectorStream contents.]].
			]
		].
	aFileStream close.!

printCategoryNamesOn: aFileStream 
	"Print the names of all the categories, alphabetically, in the file aFileStream."

	"Checker printCategoryNamesOn: 'Smalltalk.catNames' asFilename writeStream."

	aFileStream cr; nextPutAll: 'Method Categories'; cr.
	self allCategoryNames do: [:catName | aFileStream nextPutAll: catName; cr].
	aFileStream close!

printHeaperCounts: aFileStream
	"Print the names of each class and the number of instances of the class 
	currently created in the system."

	"Checker printHeaperCounts: 'Heaper.counts' asFilename writeStream.
	'Heaper.counts' asFilename edit"

	Smalltalk timeStamp: aFileStream.
	aFileStream cr; nextPutAll: 'Instances of Classes'; cr.
	Checker
		heaperInstanceCountsAndSpaceDo: 
			[:class :count :nbytes | 
			aFileStream cr; nextPutAll: class name.
			(60 - class name size) timesRepeat: [aFileStream space].
			aFileStream tab; print: count; tab; print: nbytes].
	aFileStream close!

printInstanceCounts: aFileStream
	"Print the names of each class and the number of instances of the class 
	currently created in the system."

	"Checker printInstanceCounts: 'Instance.counts' asFilename writeStream.
	'Instance.counts' asFilename edit"

	Smalltalk timeStamp: aFileStream.
	aFileStream cr; nextPutAll: 'Instances of Classes'; cr.
	Checker
		instanceCountsAndSpaceDo: 
			[:class :count :nbytes | 
			aFileStream cr; nextPutAll: class name.
			(60 - class name size) timesRepeat: [aFileStream space].
			aFileStream tab; print: count; tab; print: nbytes].
	aFileStream close!

printInstanceVariablesNotReferencedOn: aFileStream 
	"Print a list of classes and instance variables defined in, but not used in that 
	class."

	"Checker printInstanceVariablesNotReferencedOn: 
		'Smalltalk.unrefedIvars' asFilename writeStream "

	aFileStream cr; nextPutAll: 'Instance Variables Defined but not Referenced'; cr.
	self instanceVariablesNotReferenced do: [:ivar | aFileStream nextPutAll: ivar; cr].
	aFileStream close!

printMessageUsage: aFileStream
	"Print a list of each message and the number of times it is used in the system."

	"Checker printMessageUsage: 'Smalltalk.messageCount' asFilename writeStream."

	| dict set |
	dict _ IdentityDictionary new: 1024.
	Cursor execute showWhile:
	[CompiledMethod allInstancesDo:
		[:meth |
		set _ meth messages.
		set do:
			[:sel | dict at: sel put: (dict at: sel ifAbsent: [0]) + 1]
		]
	].
	Cursor write showWhile:
	[aFileStream cr; nextPutAll: 'Usage of Each Message in the System'; cr.
	dict associationsDo:
		[:assn | 
		assn value > 10
			ifTrue: [aFileStream cr; nextPutAll: assn key; tab; nextPutAll: assn value printString]].
	aFileStream close]!

printMultipleCategoryMessageNamesOn: aFileStream 
	"Print the names of all the messages defined in more than one category."

	"Checker printMultipleCategoryMessageNamesOn: 
		'Smalltalk.mulCatNames' asFilename writeStream."

	| aCollection |
	aFileStream cr; nextPutAll: 'Messages Defined in More Than One Category'; cr.
	aCollection _ self multipleCategoryMessageNames asSortedCollection.
	aCollection do: 
		[:selector | 
		aFileStream cr; nextPutAll: selector.
		Smalltalk allBehaviorsDo:
			[:class | 
			(class includesSelector: selector)
				ifTrue:
					[ aFileStream crtab: 1; nextPutAll: class name.
					aFileStream nextPutAll: '>'.
					aFileStream
						nextPutAll: (class whichCategoryIncludesSelector: selector)]]].
	aFileStream close!

printNonHeaperCounts: aFileStream
	"Print the names of each class and the number of instances of the class 
	currently created in the system."

	"Checker printNonHeaperCounts: 'NonHeaper.counts' asFilename writeStream.
	'NonHeaper.counts' asFilename edit"

	Smalltalk timeStamp: aFileStream.
	aFileStream cr; nextPutAll: 'Instances of Classes'; cr.
	Checker
		nonHeaperInstanceCountsAndSpaceDo: 
			[:class :count :nbytes | 
			aFileStream cr; nextPutAll: class name.
			(60 - class name size) timesRepeat: [aFileStream space].
			aFileStream tab; print: count; tab; print: nbytes].
	aFileStream close!

printOnlyReturnSelvesOn: aFileStream 
	"Print a list of messages that are only ^self (unimplemented)."
	
	"Checker printOnlyReturnSelvesOn:
		'Smalltalk.unimplementeds' asFilename writeStream "

	aFileStream cr; nextPutAll: 'Messages Implemented as ^self'; cr.
	self onlyReturnSelves do: [:aString | aFileStream nextPutAll: aString; cr].
	aFileStream close!

printReceivedButNotSentOn: aFileStream
	"Print a list of messages implemented but not sent anywhere (could be sent
	by performs)."

	"Checker printReceivedButNotSentOn:
		'Smalltalk.receivedButNotSent' asFilename writeStream"

	
	aFileStream cr; nextPutAll: 'Messages Implemented But Not Sent'; cr.
	self allUnSentMessages do:
		[:aString | aFileStream nextPutAll: aString; cr].
	aFileStream close!

printSentButNotReceivedOn: aFileStream 
	"Print a list of messages sent but not implemented anywhere."
	
	"Checker printSentButNotReceivedOn: 	
		'Smalltalk.sentButNotReceived' asFilename writeStream "

	aFileStream cr;  nextPutAll: 'Messages Sent But Not Implemented'; cr.
	self allUnimplementedCalls do: [:aString | aFileStream nextPutAll: aString; cr].
	aFileStream close!

printSingleClassCategoryNamesOn: aFileStream 
	"Print the names of all the categories defined in only one class."

	"Checker printSingleClassCategoryNamesOn: 
		'Smalltalk.singles' asFilename writeStream. "

	aFileStream cr;  nextPutAll: 'Categories Defined in Only One Class'; cr.
	self singleClassCategoryNames do: [:catName | aFileStream nextPutAll: catName; cr].
	aFileStream close!

printUnaryCategoryNamesOn: aFileStream
	"Print the names of all the categories with only one message."

	"Checker printUnaryCategoryNamesOn: 
		'Smalltalk.unaries' asFilename writeStream."

	aFileStream cr;  nextPutAll: 'Categories with only one Message'; cr.
	self unaryCategoryNames do:
		[:catName | aFileStream nextPutAll: catName; cr].
	aFileStream close!

printUnresponsivesOn: aFileStream
	"Print a list of unimplemented subclassResponsibilities."

	"Checker printUnresponsivesOn: 'Smalltalk.subclassUnimps' asFilename writeStream"

	aFileStream cr; nextPutAll: 'subclassResponsibility messages that are supposed to be implemented but are not'; cr.
	self unResponsives do:
		[:aString | aFileStream nextPutAll: aString; cr].
	aFileStream close! !

!Checker class methodsFor: 'running basic test suite'!

runPrintTests
	"Run the basic test suite consisting of 8 tests itemized here.
	The results are printed files named with unique extentions but whose
	initial name starts with a user provided string.  The system prompts
	for the string.

	The test suite consists of
		1.  Instance Counts
			a count of instances for each class already in the system	
			look for surprises in case there are objects hanging around that need
			deletion
		2.  Unreferenced Instance Variables
			a list of classes and instance variables that are not referenced
			these are extraneous and should be deleted
		3.  Unimplemented Methods
			a list of methods that simply return self
			sometimes programmers do this as a place holder and intend to
			provide an implementation later 
		4.  Received But Not Sent
			a list of messages that are implemented in some class but not sent
			this is frequently acceptable when the messages are part of completing
			the class protocol or, unfortunately, when the messages are sent from
			a perform:
		5.  Sent But Not Received
			a list of messages that are sent from a method but are not implemented
			in any class;  these represent serious bugs and must be fixed
		6.  Single Class Categories
			these are the names of categories and the  class in which they
			are declared that contain only one method.  typically this is okay--
			indicating that a subclass has overridden a message--make sure that
			the category is correct
		7.  Unary Class Categories
			these are the names of categories and the unique class in which they
			are declared.  In the interest of not proliferating categories, it 
			might be useful to reconsider the use of a unique name.
		8.  Unimplemented subclassResponsibility
			a list of the classes that contain methods implemented with a 
			subclassResponsibility message that is supposed to be implemented 
			but is not
"

	"Checker runPrintTests"

	 | dir |

	FillInTheBlank
		request: 'Type the initial part of the name of the 
file for saving checker information'
		displayAt: (100@ Display boundingBox height//2)
		centered: false
		action: [:res | dir _ res]
		initialAnswer: ''.
	dir isEmpty ifTrue: [^self].
	Transcript cr; show: 'instance counts'; cr.
	self printInstanceCounts: (dir, 'InstanceCounts') asFilename writeStream .
	Transcript show: 'unrefed InstVars'; cr.
	self printInstanceVariablesNotReferencedOn: (dir, 'unrefedInstVars') asFilename writeStream.
	Transcript show: 'unimplementeds'; cr.
	self printOnlyReturnSelvesOn: (dir, 'unimplementeds') asFilename writeStream.
	Transcript show: 'received But Not Sent'; cr.
	self printReceivedButNotSentOn: (dir, 'receivedButNotSent') asFilename writeStream.
	Transcript show: 'sent But Not Received'; cr.
	self printSentButNotReceivedOn: (dir, 'sentButNotReceived') asFilename writeStream.
	Transcript show: 'single class cats'; cr.
	self printSingleClassCategoryNamesOn: (dir, 'singlesClassCats') asFilename writeStream.
	Transcript show: 'unary categories'; cr.
	self printUnaryCategoryNamesOn: (dir, 'unaryCategories') asFilename writeStream.
	Transcript show: 'unresponsives'; cr.
	self printUnresponsivesOn: (dir, 'subclassUnimps') asFilename writeStream.
	Transcript show: 'done'; cr; cr.! !

!Checker class methodsFor: 'private: private'!

heaperInstanceCountsAndSpaceDo: aBlock 
	"Evaluate aBlock value: class value: instanceCount value: totalSpace 
	for every class in the system."

	| nbytes isBits isPointers n |
	Heaper withAllSubclasses do: [:class |
		class fastInstanceCount == 0 ifFalse: [
		nbytes _ 0.
		class isVariable
			ifTrue: [n _ 0.
				isBits _ class isBits.
				isPointers _ class isPointers.
				class allInstancesDo: [:inst | 
					n _ n + 1.
					nbytes _ nbytes + (isPointers
											ifTrue: [inst basicSize*4]
											ifFalse: [isBits
														ifTrue: [inst basicSize + 1 // 2 * 2]
														ifFalse: [inst basicSize*2]])]]
			ifFalse: [n _ class fastInstanceCount].
		n = 0 ifFalse: [nbytes _ nbytes + (class instSize * n*4) +6].  "+6 for header"
		aBlock value: class value: n value: nbytes]]!

instanceCountsAndSpaceDo: aBlock 
	"Evaluate aBlock value: class value: instanceCount value: totalSpace 
	for every class in the system."

	| nbytes isBits isPointers n |
	Smalltalk allClassesDo: [:class |
		class fastInstanceCount == 0 ifFalse: [
		nbytes _ 0.
		class isVariable
			ifTrue: [n _ 0.
				isBits _ class isBits.
				isPointers _ class isPointers.
				class allInstancesDo: [:inst | 
					n _ n + 1.
					nbytes _ nbytes + (isPointers
											ifTrue: [inst basicSize*4]
											ifFalse: [isBits
														ifTrue: [inst basicSize + 1 // 2 * 2]
														ifFalse: [inst basicSize*2]])]]
			ifFalse: [n _ class fastInstanceCount].
		n = 0 ifFalse: [nbytes _ nbytes + (class instSize * n*4) +6].  "+6 for header"
		aBlock value: class value: n value: nbytes]]!

nonHeaperInstanceCountsAndSpaceDo: aBlock 
	"Evaluate aBlock value: class value: instanceCount value: totalSpace 
	for every class in the system."

	| nbytes isBits isPointers n classes |
	classes _ Object withAllSubclasses.
	classes removeAll: Heaper withAllSubclasses.
	classes do: [:cls |
		cls fastInstanceCount == 0 ifFalse: [
		nbytes _ 0.
		cls isVariable
			ifTrue: [n _ 0.
				isBits _ cls isBits.
				isPointers _ cls isPointers.
				cls allInstancesDo: [:inst | 
					n _ n + 1.
					nbytes _ nbytes + (isPointers
											ifTrue: [inst basicSize*4]
											ifFalse: [isBits
														ifTrue: [inst basicSize + 1 // 2 * 2]
														ifFalse: [inst basicSize*2]])]]
			ifFalse: [n _ cls fastInstanceCount].
		n = 0 ifFalse: [nbytes _ nbytes + (cls instSize * n*4) +6].  "+6 for header"
		aBlock value: cls value: n value: nbytes]]!

obsoleteAssociations
	"Answer a collection of all associations containing obsolete classes."

	"Checker obsoleteAssociations inspect"

	| class |
	^Association allInstances select:
		[:assoc |
		class _ assoc value class.
		class isMeta and: [class isObsolete]]!

removeEmptyCategories
	"Remove all empty class and method categories."

	"Checker removeEmptyCategories "

	SystemOrganization removeEmptyCategories.
	ClassOrganizer allInstancesDo: [:organizer | organizer removeEmptyCategories].! !
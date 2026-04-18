'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:33 pm'!

Object subclass: #CxxFileOrganizer
	instanceVariableNames: '
		myFiles {IdentityDictionary of: Symbol with: CxxModule}
		myTree {CxxTreeAssociation}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-File Organization'!
CxxFileOrganizer comment:
'The CxxFileOrganizer holds on to all of the
individual CxxFileDescriptions.
This is the collected set of all (known) cxx files to
browse.
The general organization of the CxxBrowser is:
CxxFileOrganizer ->
	table of: CxxFileDescription.
	
	CxxFileDescription
		public -> CxxClassGroup  (the public classes)
		private -> CxxClassGroup (the private classes)
		test -> CxxClassGroup (the test classes)
		name -> the descriptive name for the file.
		fileName -> the horribly hacked awful name for MS-DOS
compatible files
		comment -> a useful, edifying note attached by the
programmer for these classes
		cxxHeader -> programmer provided header stuff for the
x.cxx file
		cxxComment -> another useful, edifying note for the
x.cxx file (impl notes)
		cxxIncludes -> set of CxxFileDescriptions to include in
x.cxx file
		opaques -> a set of CxxClassDescriptions for classes
opaque in the x.hxx and included in x.cxx

	CxxClassGroup
		classes -> table of: CxxClassDescription
		hxxHeader -> WordArray containing the (user written)
header to be stuffed into the ?.hxx file
		comment -> WordArray containing a comment for the group
inserted in the ?.hxx file
		hxxIncludes -> set of CxxFileDescriptions to include in
?.hxx

	CxxClassDescription
		classDescription -> a standard Smalltalk class
description object (the *real* description...)
		functions -> CxxFunctionOrganizer (.cxx global functions)
		methods -> CxxMethodOrganizer (.cxx methods)
		inlines -> CxxMethodsOrganizer (.ixi methods)
		friends -> friend class and function description

	CxxMethodOrganizer
		name -> name of the protocol
		methodList -> table of method names
		friendList -> table of method->friend pairs

	CxxFunctionOrganizer
		name -> name of the protocol
		functionList -> table of function names (class methods)'!



!CxxFileOrganizer methodsFor: 'accessing'!

{CxxModule | nil} fetchFileForClass: clsname {Symbol} 
	
	| cxc |
	cxc _ (Smalltalk at: clsname asSymbol) fetchCxxClassDescription.
	cxc == nil  
		ifTrue: [^nil]
		ifFalse: [^cxc fetchCxxModule]!

{CxxTreeLocation} fetchLocationOfClass: class {ClassDescription}
	| dFile dTree |
	class fetchCxxClassDescription == nil ifTrue: [^ nil].
	dFile _ self fetchFileForClass: class nonMeta name.
	dFile == nil ifTrue: [^nil]. 
	dTree _ self fetchTreeLocForFile: dFile moduleName.
	dTree == nil ifTrue: [^nil].
	^ self treePositionOf: dTree.!

{CxxModule} fetchModuleNamed: someName {String} 

	someName == nil ifTrue: [^nil].
	^myFiles at: someName asSymbol ifAbsent: [nil]!

{CxxTreeAssociation} fetchTreeLocForFile: fileName {String}

	fileName == nil
		ifTrue: [^nil].
	self tree withChildrenDo: [:c | 
		(c value = #file and: [c key asSymbol == fileName asSymbol])
			ifTrue: [^c]].
	^nil!

{CxxTreeAssociation} fetchTreeLocOf: moduleName {String | nil}

	moduleName == nil
		ifTrue: [^nil].
	self tree withChildrenDo: [:kid | 
		kid key asSymbol == moduleName asSymbol
			ifTrue: [^kid]].
	^nil!

{OrderedCollection} fileList
	^myFiles asOrderedCollection!

{CxxClassDescription} findClass: aClassName {String}
	
	| cls {Behavior} |
	cls _ Smalltalk at: aClassName ifAbsent: [^nil].
	(cls == nil or: [cls isBehavior not])
		ifTrue: [^nil]
		ifFalse: [^cls fetchCxxClassDescription]!

{CxxModule} getModuleNamed: someName {String} 
	| result {CxxModule} |
	
	result _ self fetchModuleNamed: someName.
	result = nil ifTrue: [self notify: ('file ', someName, 'does not exist, proceed to create.').
		result _ CxxModule create: someName.
		self introduceFile: result].
	^result!

getOrMakeFileNamed: someName {String} 
	| result {CxxModule} |
	
	result _ self fetchModuleNamed: someName.
	result = nil ifTrue: [result _ CxxModule create: someName.
		self introduceFile: result].
	^result!

{CxxTreeAssociation} getTreeLocForFile: fileName {String}

	| result {CxxTreeAssociation} |
	result _ self fetchTreeLocForFile: fileName.
	result == nil
		ifTrue: [self class blast.NotFound raise].
	^result!

{CxxTreeAssociation} getTreeLocOf: moduleName {String}

	| result {CxxTreeAssociation} |
	result _ self fetchTreeLocOf: moduleName.
	result == nil
		ifTrue: [self class blast.NotFound raise].
	^result!

{Collection of: Symbol} nameList
	
	^myFiles keys!

{AssociationTreeWithParent} tree
	^myTree!

{void} tree: newTree {AssociationTreeWithParent}
	myTree _ newTree!

{CxxTreeLocation} treePositionOf: treeLocation {AssociationTreeWithParent}

	| res treeP |
	res _ CxxTreeLocation create.
	treeP _ treeLocation.
	[treeP ~~ nil] whileTrue: [res addFirst: treeP key.
		treeP _ treeP parent].
	^ res! !

!CxxFileOrganizer methodsFor: 'adding-removing'!

{void} addFileNamed: aName {String} 
	| newFile {CxxModule} |
	newFile _ CxxModule create: aName.
	self introduceFile: newFile!

{void} introduceFile: aFile {CxxModule} 
	| oldFile |
	oldFile _ self fetchModuleNamed: aFile moduleName.
	oldFile = nil
		ifTrue: [self storeFile: aFile.
			(self fetchTreeLocForFile: aFile moduleName) == nil ifTrue: 
				[self tree addChild: 
					(CxxTreeAssociation key: aFile moduleName value: #file)]]
		ifFalse: [self error: 'file ' , aFile moduleName , ' already in organization']!

{void} removeClassNamed: aClassName {String} 

	| cxc {CxxClassDescription} |
	cxc _ (Smalltalk at: (aClassName asSymbol)) fetchCxxClassDescription.
	(cxc == nil or: [cxc fetchGroup == nil])
		ifTrue: [^ VOID].
	cxc fetchGroup removeClass: cxc.
	cxc destroy!

{void} removeFile: aFile {CxxModule} 
	| treeItem |
	treeItem _ self fetchTreeLocForFile: aFile moduleName.
	treeItem ~~ nil 
		ifTrue: [treeItem parent removeChild: treeItem].
	myFiles removeKey: aFile moduleName asSymbol
			ifAbsent: [self error: (aFile moduleName , 'not found')]!

{void} removeFileNamed: filename {string} 
	| aFile |
	aFile _ self fetchModuleNamed: filename.
	aFile == nil
		ifTrue: [self notify: 'File named ' , filename , ' not
in organization.']
		ifFalse: [self removeFile: aFile]!

{void} replaceFile: aFile {CxxModule}
	(myFiles includesKey: (aFile moduleName asSymbol)) not 
		ifTrue: [self error: ('file ', aFile moduleName, ' not found')].
	self storeFile: aFile!

{void} storeFile: aFile {CxxModule} 
	myFiles at: aFile moduleName asSymbol put: aFile! !

!CxxFileOrganizer methodsFor: 'creation'!

create
	super create.
	myFiles _ IdentityDictionary new.
	myTree _ CxxTreeAssociation key: 'xanadu' value: nil! !

!CxxFileOrganizer methodsFor: 'printing'!

hardcopyModuleListUnder: where {String} 
	"This was useful once as a DoIt.  Makes a hardcopy of the module list."
	| result tree doc |
	tree _ CxxSystemOrganization tree childNamed: where.
	result _ TextStream on: (String new: 5000).
	tree children do: [:c |
		c value ~~ #file
			ifTrue: [result emphasis: 2]
			ifFalse: [result emphasis: 1].
		result nextPutAll: c key , '
'.
		c children do: 
			[:d | 
			d value ~~ #file
				ifTrue: [result emphasis: 2]
				ifFalse: [result emphasis: 1].
			result nextPutAll: '	' , d key , '
'.
			d children do: [:e | e value ~~ #file
					ifTrue: [result emphasis: 2]
					ifFalse: [result emphasis: 1].
				result nextPutAll: '		' , e key , '
']]].
	doc _ Document new.
	doc
		doFooter: true
		footerString: 'Xanadu Module List'
		doPageNumbers: true.
	doc startParagraph.
	doc addText: result contents asText.
	doc close.
	doc toPrinter!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << ' on ' << self nameList.! !

!CxxFileOrganizer methodsFor: 'fileout'!

{void} fileOutSmalltalk
	"This will write out all of the classes in smalltalk to
group streams"
	self fileList do: [:aFile |
		aFile fileOutSmalltalk]! !

!CxxFileOrganizer methodsFor: 'fileout organization'!

{void} fileoutOrgOn: oo {ostream reference} 
	| dateTime |
	dateTime _ Time dateAndTimeNow.
	dateTime _ (dateTime at: 1) printString, ' ', (dateTime
at: 2) printString.
	Transcript show: 'filing out all organization (',
dateTime, ')...'; cr; endEntry.
	oo << '
"Organization fileout at ' <<  dateTime << '"
	
(Smalltalk at: #CxxSystemOrganization) == nil ifTrue: [
	CxxSystemOrganization _ CxxFileOrganizer create]!!
'.
	self fileList do: [:aFile |
		aFile fileoutOrgOn: oo].
	Transcript show: 'filing out organization tree'; cr;
endEntry.
	oo << '
CxxSystemOrganization tree addChild:
'.
	self fileoutTree: self tree on: oo.
	oo << '!!'!

fileoutTree: aChild on: aStream
	aStream << '((CxxTreeAssociation key: ' << aChild key storeString.
	aStream << ' value: ' << aChild value storeString << ')'.
	aChild isLeaf ifFalse: [
		aChild children do: [ :child | aStream << '
 addChild: '.
			self fileoutTree: child on: aStream.
			aStream << ';']].
	aStream << ' yourself)'! !

!CxxFileOrganizer methodsFor: 'smalltalk: private: smalltalk private'!

check
	"CxxSystemOrganization check"
	"nothin to do now.."! !

!CxxFileOrganizer methodsFor: 'changes'!

wrapCxxOrgChange: aString 
	"Wrap the string with a test for the existence of the Cxx organization"
	^ '((Smalltalk includesKey: #CxxSystemOrganization) ifTrue: [' ,
		 aString ,
		  '])'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxFileOrganizer class
	instanceVariableNames: ''!



!CxxFileOrganizer class methodsFor: 'pseudo constructors'!

make
	^ self create! !

!CxxFileOrganizer class methodsFor: 'accessing'!

{void} setPrefix: path {String}

	CxxFilePrefix == nil ifTrue:
		[CxxOutlineBrowser initialize].
	CxxFilePrefix fluidSet: path! !
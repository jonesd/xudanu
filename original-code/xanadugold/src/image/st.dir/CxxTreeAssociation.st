'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:42 pm'!

AssociationTreeWithParent subclass: #CxxTreeAssociation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!


!CxxTreeAssociation methodsFor: 'accessing'!

{void} classesDo: aBlock {BlockClosure of: CxxClassDescription}

	self value == #file ifTrue:
		[ | mod {CxxModule} |
		mod := CxxSystemOrganization getModuleNamed: self key.
		mod allClasses do: aBlock]
	ifFalse:
		[self children do: [:kid {CxxTreeAssociation} |
			kid classesDo: aBlock]]!

key: anObject 
	"Store the argument, anObject, as the lookup key of the receiver."

	key _ anObject asSymbol!

key: aKey value: anObject 
	"Store the arguments as the variables of the receiver."

	key _ aKey asSymbol.
	value _ anObject!

{OrderedCollection of: CxxModule} modulesInActualDirectories
	"Note: The fetchFilePrefix below will check and prompt to create directories.
	Any modules which are not in actual file system directories are not accumulated."
	
	| result {OrderedCollection of: CxxModule} |
	result _ OrderedCollection new.
	self fetchFilePrefix == NULL
		ifTrue: [^result].
	self value == #file
		ifTrue: [result add: (CxxSystemOrganization getModuleNamed: self key)].
	children ~~ nil
		ifTrue: [children do: [:kid {CxxTreeAssociation} |
					result addAll: kid modulesInActualDirectories]].
	^result!

{void} modulesInActualDirectoriesDo: aBlock {BlockClosure of: CxxModule}
	"We do modulesInActualDirectories first to get all the prompting done quickly"
	
	self modulesInActualDirectories doAll: (OrderedCollection with: aBlock)! !

!CxxTreeAssociation methodsFor: 'fileout'!

{String} fetchFilePrefix
	
	| result {String} filename {Filename} |
	parent == nil
		ifTrue: [result _ CxxFilePrefix fluidGet]
		ifFalse: [result _ parent fetchFilePrefix].
	result == NULL
		ifTrue: [^NULL].
	value == #dir
		ifTrue: [result _ result , self key , Filename separator asString].
	filename _ result asFilename.
	filename exists
		ifTrue: [filename isDirectory
					ifTrue: [^result]
					ifFalse: [Transcript show: (result, ' is not a directory'); cr; endEntry.
							^NULL]]
		ifFalse: [(self confirm: result, ' doesn''t exist, create?')
					ifTrue: [filename makeDirectory.
							^result]
					ifFalse: [^NULL]]!

{String} getFilePrefix
	
	| result {String} |
	result _ self fetchFilePrefix.
	(result == NULL or: [result == nil])
		ifTrue: [self class blast.NotFound raise].
	^result!

{void} newReference: editor

	self modulesInActualDirectoriesDo: [:mod {CxxModule} |
		editor newFileList: mod.
		editor makeOutputIntoReference].!

{Dictionary of: Symbol with: BooleanVar} runTests
	"This methods executes the test classes in the module"
	
	| results {Dictionary} |
	results _ Dictionary new.
	Initializer doMain:
		[self modulesInActualDirectoriesDo: [:mod {CxxModule} |
			results at: mod moduleName asSymbol put: mod runTest]].
	^ results!

{void} writeMacSegmentNamesOn: oo {ostream reference}

	self value = #file ifTrue: [
		Transcript show: 'writing segment names for ', self key; cr; endEntry.
		(CxxSystemOrganization fetchModuleNamed: self key)
			writeMacSegmentNamesOn: oo].
	children ~~ nil ifTrue: [
	children do: [:kid |
		kid writeMacSegmentNamesOn: oo]].! !

!CxxTreeAssociation methodsFor: 'manip'!

{Boolean} destroyEmptyModules
	"Note that if I am a module, the CxxSystemOrganization removeFileNamed: will remove me from the tree. This is so that file-in changes will work correctly"
	
	| oldValue |
	oldValue _ value.
	self children copy do: [:kids | 
		kids destroyEmptyModules].
	oldValue == #file ifTrue: 
		[ | mod |
		mod := CxxSystemOrganization getModuleNamed: self key.
		mod allClasses isEmpty ifFalse: 
			[^false].
		CxxSystemOrganization removeFile: mod]
	ifFalse: 
		[self isLeaf ifFalse: 
			[^false].
		self parent removeChild: self].
	value _ nil.
	^true! !

!CxxTreeAssociation methodsFor: 'smalltalk: passe'!

destroyFiles
	"Note that if I am a file, the CxxSystemOrganization removeFile... 
	will remove me from the tree. This is so that file-in changes will 
	work correctly"
	
	self passe!

{void} modulesInActualDirectoriesDoAll: blocks {Collection of: (BlockClosure of: CxxModule)}

	self passe! !
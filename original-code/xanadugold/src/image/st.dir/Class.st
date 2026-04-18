'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:12 pm'!

ClassDescription subclass: #Class
	instanceVariableNames: 'name classPool sharedPools '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Classes'!
Class comment:
'Instances of class Class describe the representation and behavior of objects.  Class adds more comprehensive programming support facilities to the basic attributes of Behavior and the descriptive facilities of ClassDescription.  An example is accessing shared (pool) variables.

Instance Variables:
		name		<Symbol> name of class for printing and global reference
		classPool	<Dictionary> of variables common to all instances
		sharedPools	<Array of: Dictionaries> access to other shared variables
'!


!Class methodsFor: 'initialize-release'!

declare: varString 
	"Declare class variables common to all instances.  Answer whether
	recompilation is advisable."

	| newVars conflicts |
	newVars _ 
		(Scanner new scanFieldNames: varString)
			collect: [:x | x asSymbol].
	newVars do:
		[:var | var first isLowercase
			ifTrue: [self error: var, ' class variable name should be capitalized; proceed to include anyway.']].
	conflicts _ false.
	classPool == nil 
		ifFalse: [(classPool keys reject: [:x | newVars includes: x]) do: 
					[:var | self removeClassVarName: var]].
	(newVars reject: [:var | self classPool includesKey: var])
		do: [:var | "adding"
			"check if new vars defined elsewhere"
			(self scopeHas: var ifTrue: [:ignored])
				ifTrue: 
					[self error: var , ' is defined elsewhere'.
					conflicts _ true]].
	newVars size > 0
		ifTrue: 
			[classPool _ self classPool.
			"in case it was nil"
			newVars do: [:var | classPool declare: var from: Undeclared]].
	^conflicts!

localObsolete
	"Change the receiver to an obsolete class by changing its name to have the prefix -AnObsolete-, and nilling the fields of any instances."

	self isPointers ifTrue:
		[self allInstancesDo: [:instance | instance nilFields]]. 	"nil fields of instances"
	('AnObsolete*' match: name) ifFalse:
		[name _ 'AnObsolete' , name].
	classPool _ Dictionary new.
	super localObsolete!

obsolete
	"Change the receiver to an obsolete class by changing its name to have the prefix -AnObsolete-, and nilling the fields of any instances."

	self class obsolete.
	super obsolete!

removeFromSystem
	"Forget the receiver, and all of its subclasses, from the Smalltalk 
	global dictionary. Any existing instances will refer to an obsolete 
	version of the receiver."

	Smalltalk removeClassNamed: self name
	"remove from system dictionary"!

sharing: poolString 
	"Set up sharedPools.  Answer whether recompilation is advisable."

	| oldPools |
	oldPools _ self sharedPools.
	sharedPools _ Set new.
	(Scanner new scanFieldNames: poolString) do: 
		[:poolName | 
		sharedPools add: (Smalltalk at: poolName asSymbol)].
	sharedPools isEmpty ifTrue: [sharedPools _ nil].
	oldPools 
		detect: [:pool | (self sharedPools includes: pool) not]
		ifNone: [^false].
	^true	"A pool got deleted - who knows if there are still references?"! !

!Class methodsFor: 'accessing'!

classPool
	"Answer the dictionary of class variables."

	classPool == nil
		ifTrue: [^Dictionary new]
		ifFalse: [^classPool]!

name
	"Answer the name of the receiver."

	name == nil
		ifTrue: [^'a Class']
		ifFalse: [^name]!

nonMeta
	^self!

setName: aSymbol
	"Set the name of the receiver to be aSymbol."

	name _ aSymbol! !

!Class methodsFor: 'accessing class hierarchy'!

isObsolete
	"Answer whether the receiver is an obsolete class."

	^self class isObsolete 		"ask the metaclass"! !

!Class methodsFor: 'testing method dictionary'!

hasMethods
	"Answer a Boolean as to whether any methods are defined for the receiver
	(includes whether there are methods defined in the receiver's metaclass)."

	^super hasMethods or: [self class hasMethods]! !

!Class methodsFor: 'class name'!

rename: aString 
	"The new name of the receiver is the argument, aString."

	| newName |
	newName _ aString asSymbol.
	(Smalltalk includesKey: newName)
		ifTrue: [^self error: newName , ' already exists'].
	ChangeLog logRenameClass: self to: newName
		changes: self name,' rename: ', newName storeString. 
	Smalltalk renameClass: self as: newName.
	name _ newName.
	self fetchCxxClassDescription ~~ nil ifTrue: [
		self getCxxClassDescription renameClassTo: newName].
	self comment: self comment.
	self class comment: self class comment.!

renameAndFixSourceTo: newName 
	"The new name of the receiver is the argument, aString.
	Rename the receiver, and then change all references in
	the system from the old name to the new name."

	| oldName |
	oldName  _ self name.
	self rename: newName.
	self renameReferencesFrom: oldName!

renameReferencesFrom: oldNameString
	"The old name of the receiver is the argument, oldNameString.
	Change all references in the system from the old name
	to the new (current) one."

	| oldName ref meths s cat pos |
	oldName _ oldNameString asSymbol.
	ref _ Smalltalk associationAt: oldName ifAbsent: [^self].
	Smalltalk allBehaviorsDo:
		[:b |
		meths _ b whichSelectorsReferTo: ref.
		meths size > 0
			ifTrue: [meths do:
						[:sel | 
						sel == #DoIt
							ifFalse: [s _  b sourceCodeAt: sel.
									cat _ b whichCategoryIncludesSelector: sel.
									Transcript cr; show: b name , ' (' , cat , ') ' , '>> ' , sel.
									pos _ Scanner new
										scanPositionsFor: oldName
										inString: s.
									pos reverseDo:
										[:p |
										s _ s copyReplaceFrom: p
											to: p + oldName size - 1
											with: name].
									b compile: s classified: cat]]]].!

renameToReplace: aClass
	"Obsolete aClass, and then rename the receiver to
	have the name that aClass currently has."

	| oldName newName |
	oldName _ self name.
	newName _ aClass name.
	aClass obsolete.
	SystemOrganization removeElement: oldName.
	"Smalltalk changes renameClass: self from: self name to: newName."
	Smalltalk at: newName put: self.
	name _ newName.
	Smalltalk flushClassNameCache.
	ChangeLog logRenameClass: self from: oldName asSymbol
		changes: oldName , ' renameToReplace: ' , oldName.
	self renameReferencesFrom: oldName.
	Smalltalk removeKey: oldName! !

!Class methodsFor: 'instance variables'!

addInstVarName: aString
	"Add the argument, aString, as one of the receiver's instance variables."

	self classBuilder
		currentClass: self;
		superclass: superclass;
		environment: self environment;
		instanceVariables: (self instVarNames copyWith: aString);
		format: self format;
		reviseSystem!

removeInstVarName: aString 
	"Remove the argument, aString, as one of the receiver's instance variables."

	(self instVarNames includes: aString)
		ifFalse: [self error: aString , ' is not one of my instance variables'].
	self classBuilder
		currentClass: self;
		superclass: superclass;
		environment: self environment;
		instanceVariables: (self instVarNames copyWithout: aString);
		format: self format;
		reviseSystem! !

!Class methodsFor: 'class variables'!

addClassVarName: aString 
	"Add the argument, aString, as a class variable of the receiver."

	aString first isLowercase
		ifTrue: [self error: aString, ' class variable name should be capitalized; proceed to include anyway.'].
	self withAllSubclasses do: 
		[:subclass | 
		subclass 
			poolHas: aString asSymbol 
			ifTrue:
				[:ignored |
				^self error: aString , ' is already used as a variable name in ' , subclass name]].
	classPool _ self classPool.  "might be nil"
	classPool add: (Association key: aString asSymbol value: nil)!

allClassVarNames
	"Answer a Set of the names of the receiver's class variables, including those
	defined in the superclasses of the receiver."
	| aSet |
	superclass == nil
		ifTrue: 
			[^self classVarNames]  "This is the keys so it is a new Set."
		ifFalse: 
			[aSet _ superclass allClassVarNames.
			aSet addAll: self classVarNames.
			^aSet]!

classVarNames
	"Answer a Set of the names of the class variables defined in the receiver."

	^self classPool keys!

initialize
	"Typically used for the initialization of class variables and metaclass instance
	variables.  Does nothing, but may be overridden in Metaclasses."
	^self!

removeClassVarName: aString 
	"Remove the class variable whose name is the argument, aString, from the names
	defined in the receiver, a class."

	| aSymbol |
	aSymbol _ aString asSymbol.
	(classPool includesKey: aSymbol)
		ifFalse: [^self error: aString, ' is not a class variable'].
	(self superclass allClassVarNames includes: aSymbol)
		ifFalse: [self withAllSubclasses do: [:subclass |
			(Array with: subclass with: subclass class) do:
				[:classOrMeta |
				(classOrMeta whichSelectorsReferTo: (classPool associationAt: aSymbol))
					isEmpty
						ifFalse: [self warn: aString
									, ' is still used in code of class '
									, classOrMeta name.
								^self]]]].
	classPool removeKey: aSymbol! !

!Class methodsFor: 'pool variables'!

addSharedPool: aDictionary 
	"Add the argument, aDictionary, as one of the receiver's pool dictionaries.  Create
	an error if the dictionary is already one of the pools."

	(self sharedPools includes: aDictionary)
		ifTrue: [^self error: 'The dictionary is already in my pool'].
	sharedPools == nil
		ifTrue: [sharedPools _ Set with: aDictionary]
		ifFalse: [sharedPools add: aDictionary]!

allSharedPools
	"Answer a Set of the pools the receiver shares, including those defined 
	in the superclasses of the receiver."

	| aSet |
	superclass == nil
		ifTrue:
			[^self sharedPools copy]
		ifFalse: 
			[aSet _ superclass allSharedPools.
			aSet addAll: self sharedPools.
			^aSet]!

removeSharedPool: aDictionary 
	"Remove the pool dictionary, aDictionary, as one of the receiver's pool dictionaries.
	Create an error if the dictionary is not one of the pools."

	| satisfiedSet workingSet aSubclass |
	(self sharedPools includes: aDictionary)
		ifFalse: [^self error: 'the dictionary is not in my pool'].

	"first see if it is declared in a superclass in which case we can remove it."
	(self allSuperclasses select: [:class | class sharedPools includes: aDictionary]) isEmpty
		ifFalse: [sharedPools remove: aDictionary.
				sharedPools isEmpty ifTrue: [sharedPools _ nil].
				^self]. 

	"second get all the subclasses that reference aDictionary through me rather than a 
	superclass that is one of my subclasses."

	workingSet _ self subclasses asOrderedCollection.
	satisfiedSet _ Set new.
	[workingSet isEmpty] whileFalse:
		[aSubclass _ workingSet removeFirst.
		(aSubclass sharedPools includes: aDictionary)
			ifFalse: 
				[satisfiedSet add: aSubclass.
				workingSet addAll: aSubclass subclasses]].

	"for each of these, see if they refer to any of the variables in aDictionary because 
	if they do, we can not remove the dictionary."
	satisfiedSet add: self.
	satisfiedSet do: 
		[:sub | 
		aDictionary associationsDo: 
			[:aGlobal | 
			(sub whichSelectorsReferTo: aGlobal) isEmpty 
				ifFalse: [^self error: aGlobal key 
								, ' is still used in code of class '
								, sub name]]].
	sharedPools remove: aDictionary.
	sharedPools isEmpty ifTrue: [sharedPools _ nil]!

sharedPools
	"Answer a Set of the pool dictionaries declared in the receiver."

	sharedPools == nil
		ifTrue: [^Set new]
		ifFalse: [^sharedPools]! !

!Class methodsFor: 'compiling'!

compileAllFrom: otherClass
	super compileAllFrom: otherClass.
	self class compileAllFrom: otherClass class!

poolHas: varName ifTrue: assocBlock 
	"Look up the first argument in the context of the receiver.  If it is there,
	pass the association to assocBlock, and answer true, else answer false."
	| assoc |
	assoc _ self classPool associationAt: varName ifAbsent: [].
	assoc == nil
		ifFalse: 
			[assocBlock value: assoc.
			^true].
	self sharedPools do: 
		[:pool | 
		assoc _ pool associationAt: varName ifAbsent: [].
		assoc == nil
			ifFalse: 
				[assocBlock value: assoc.
				^true]].
	^ false!

possibleVariablesFor: misspelled continuedFrom: oldResults
	| results |
	results _ misspelled correctAgainstDictionary: self classPool continuedFrom: oldResults.
	self sharedPools do: [:pool | 
		results _ misspelled correctAgainstDictionary: pool continuedFrom: results ].
	superclass == nil
		ifTrue: 
			[ ^ misspelled correctAgainstDictionary: Smalltalk continuedFrom: results ]
		ifFalse:
			[ ^ superclass possibleVariablesFor: misspelled continuedFrom: results ].! !

!Class methodsFor: 'subclass creation'!

subclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat 
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver)."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		beFixed;
		reviseSystem!

subclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat attributes: attr comment: com
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver)."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		attributes: attr;
		comment: com;
		beFixed;
		reviseSystem!

subclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat comment: com
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver)."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		comment: com;
		beFixed;
		reviseSystem!

variableByteSubclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat 
	"This is the standard initialization message for creating a new class 
	as a subclass of an existing class (the receiver) in which the 
	subclass is to have indexable byte-sized nonpointer variables."

	^(self classBuilder) 
		superclass: self; 
		environment: self environment; 
		className: t; 
		instVarString: f; 
		classVarString: d; 
		poolString: s; 
		category: cat; 
		beBytes; 
		reviseSystem!

variableByteSubclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat attributes: attr comment: com 
	"This is the standard initialization message for creating a new class 
	as a subclass of an existing class (the receiver) in which the 
	subclass is to have indexable byte-sized nonpointer variables."

	^(self classBuilder) 
		superclass: self; 
		environment: self environment; 
		className: t; 
		instVarString: f; 
		classVarString: d; 
		poolString: s; 
		category: cat;
		attributes: attr;
		comment: com;
		beBytes; 
		reviseSystem!

variableByteSubclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat comment: com 
	"This is the standard initialization message for creating a new class 
	as a subclass of an existing class (the receiver) in which the 
	subclass is to have indexable byte-sized nonpointer variables."

	^(self classBuilder) 
		superclass: self; 
		environment: self environment; 
		className: t; 
		instVarString: f; 
		classVarString: d; 
		poolString: s; 
		category: cat;
		comment: com;
		beBytes; 
		reviseSystem!

variableSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver) in which the subclass is to have indexable
	pointer variables."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		beVariable;
		reviseSystem!

variableSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat attributes: attr comment: com
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver) in which the subclass is to have indexable
	pointer variables."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		attributes: attr;
		comment: com;
		beVariable;
		reviseSystem!

variableSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat comment: com
	"This is the standard initialization message for creating a new class as a subclass
	of an existing class (the receiver) in which the subclass is to have indexable
	pointer variables."

	^self classBuilder
		superclass: self;
		environment: self environment;
		className: t;
		instVarString: f;
		classVarString: d;
		poolString: s;
		category: cat;
		comment: com;
		beVariable;
		reviseSystem! !

!Class methodsFor: 'fileIn/Out'!

fileOut
	"Create a file whose name is the name of the receiver with -.st- as the
	extension, and file a description of the receiver onto it"

	| fileStream |
	Transcript refresh; cr; cr; show: 'Filing out class:'.
	fileStream _ (Filename named: self name , '.st') writeStream.
	[fileStream timeStamp.
	self fileOutOn: fileStream
		moveSource: false
		toFile: 0]
		valueNowOrOnUnwindDo: [fileStream close]!

fileOutAll
	"file out all the code implemented in the system "

	
	| class |
	SystemOrganization categories do: 
		[:sysCat | 
		Transcript show: sysCat; cr.
		"form feed between categories of classes"
		"sysCat fileOutCategory ."
		(SystemOrganization listAtCategoryNamed: sysCat) do: 
		
			[:className | 
			class _ Smalltalk at: className.
		class fileOut.
			].
			]!

fileOutOn: aFileStream moveSource: moveSource toFile: fileIndex 
	"File a description of the receiver on aFileStream.  If the boolean argument,
	moveSource, is true, then set the trailing bytes to the position of aFileStream and
	to fileIndex in order to indicate where to find the source code."

	Transcript cr; show: name.
	super
		fileOutOn: aFileStream
		moveSource: moveSource
		toFile: fileIndex.
	self class nonTrivial
		ifTrue:
			[aFileStream cr; nextPutAll: '"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!!'; cr; cr.
			self class
				fileOutOn: aFileStream
				moveSource: moveSource
				toFile: fileIndex].!

printOut
	"Create a readable version of my definition, and send to a printer.
	Defaults to fileOut."
	self fileOut!

printOutInterfaceOn: aStream
	"Print me out on aStream"

	super printOutInterfaceOn: aStream.
	self class nonTrivial
		ifTrue:[self class printOutInterfaceOn: aStream]!

printOutOn: aStream
	"Print me out on aStream"

	super printOutOn: aStream.
	self class nonTrivial
		ifTrue:[self class printOutOn: aStream]!

readBinaryContentsFrom: stream
	"Read instance from stream."

	methodDict _ stream inClass: self do: [stream next].
	organization _ stream next!

removeFromChanges
	"References to the receiver, a class, and its metaclass should no longer be included
	in the system ChangeSet."
	"Smalltalk changes removeClassChanges: self"!

storeBinaryContentsOn: aStream
	"Store binary representation of the contents of the receiver onto aStream."

	aStream inClass: self do: [aStream nextPut: methodDict].
	aStream nextPut: organization! !

!Class methodsFor: 'testing'!

shouldBeRegistered
	"Answer whether the receiver is named and should be 'stored' in its environment"

	^name ~~ nil! !

!Class methodsFor: 'creating class hierarchy'!

addToSuper
	"Add the receiver to the superclass's subclass list"

	super addToSuper.
	self class addToSuper!

removeFromSuper
	"Remove the receiver from the superclass's subclass list"

	super removeFromSuper.
	self class removeFromSuper! !

!Class methodsFor: 'cxx accessing'!

cast: type 
	"This only works for simple types (else the Smalltalk syntax breaks 
	down)."

	Category == type ifFalse: 
		[(self class inheritsFrom: type)
			ifFalse: [self error: 'Cast violation: ' , type printString]]!

const
	"Implemented so that type expressiobn can be executed."!

CONST
	"Implemented so that type expressiobn can be executed."!

defineClientFluid: varName with: emulsion with: initialValueBlock
	"Create a new fluid named varName.  This must be in a staticTimeNonInherited method."
	
	FluidVar make: varName with: initialValueBlock with: emulsion with: self!

defineFluid: varName with: emulsion
	"Create a new fluid named varName.  This must be in a staticTimeNonInherited method."
	
	FluidVar make: varName with: nil with: emulsion with: self!

defineFluid: varName with: emulsion with: initialValueBlock
	"Create a new fluid named varName.  This must be in a staticTimeNonInherited method."
	
	FluidVar make: varName with: initialValueBlock with: emulsion with: self!

defineGlobal: varName
	"Put varName in the the global dictionary if there isn't already a Behavior there.  This is called from linkTimeInheriteds."
	
	Smalltalk safeAt: varName put: nil!

defineGlobal: varName with: initialValue
	"Put varName in the the global dictionary with an initial value if there isn't already a Behavior there.  This is called from linkTimeInheriteds."
	
	Smalltalk safeAt: varName put: initialValue!

definePromiseFluid: varName with: emulsion with: initialValueBlock with: actual {FluidVar} with: actualType {Class}
	"Create a new promise fluid named varName of type this class.  The promise fluid corresponds to the non-promise
	fluid actual of type actualType.  actualType is needed for the X++ implementation in order to do a type safe
	fluidSet: on the actual fluid."
	
	FluidPromiseVar make: varName with: initialValueBlock with: emulsion with: self with: actual!

{Category} getCategory
	^Category create: Category!

reference
	"Implemented so that type expressiobn can be executed."!

sendSelfTo: xmtr
	xmtr sendCategory: self!

star
	"Implemented so that type expressiobn can be executed."!

wimpy
	"Implemented so that type expressiobn can be executed."! !

!Class methodsFor: 'smalltalk: passe'!

subclass: t 
	instanceVariableNames: f 
	classVariableNames: d 
	poolDictionaries: s 
	category: cat 
	attributes: attr
	"default which is called by some file-outs for some reason"
	
	self passe. "oops.  Only due to fileout bug"
	^self
		subclass: t 
		instanceVariableNames: f 
		classVariableNames: d 
		poolDictionaries: s 
		category: cat 
		attributes: attr 
		comment: ''! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Class class
	instanceVariableNames: ''!


!Class class methodsFor: 'instance creation'!

cxxTemplate: category 
	"Answer an expression that can be edited and evaluated in order to define
	 a new class."

	^'NameOfSuperclass subclass: #NameOfClass
	instanceVariableNames: ''''
	classVariableNames: ''''
	poolDictionaries: ''''
	category: ''' , category , '''
	attributes: #()
		' , CxxClassDescription attributeComment , '
	comment: '''''!

template: category 
	"Answer an expression that can be edited and evaluated in order to define
	 a new class."

	^'NameOfSuperclass subclass: #NameOfClass
	instanceVariableNames: ''''
	classVariableNames: ''''
	poolDictionaries: ''''
	category: ''' , category , '''
	comment: '''''! !
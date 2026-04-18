'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:13 pm'!

Object subclass: #ClassBuilder
	instanceVariableNames: '
		recompile {UNKNOWN}
		format {UNKNOWN}
		environment {UNKNOWN}
		pools {UNKNOWN}
		instanceVariables {UNKNOWN}
		instanceVariableTypes {UNKNOWN}
		classVariables {UNKNOWN}
		superclass {UNKNOWN}
		className {UNKNOWN}
		classVariableTypes {UNKNOWN}
		class {UNKNOWN}
		classAttributes {OrderedCollection of: Symbol | Array}
		category {UNKNOWN}
		organizer {UNKNOWN}
		classComment {UNKNOWN}'
	classVariableNames: '
		BuildErrorSignal {UNKNOWN} 
		BuildFailureSignal {UNKNOWN} 
		NilSuperclassSignal {UNKNOWN} '
	poolDictionaries: ''
	category: 'Kernel-Classes'!
ClassBuilder comment:
'ClassBuilders are initialized with a set of changes to be made to a particular class, such as changing the superclass, or the number of instance variables, then released to make the change in as nearly atomic a fashion as possible.  Initialization code makes no changes to the system, only to the state of the ClassBuilder.

Instance Variables:
	class				<Behavior> the class to be modified
	className			<Symbol> the name of the class, if modifications are done by name, when defining a new class
	superclass			<Behavior or nil> the new superclass
	instanceVariables	<Array or nil> the new instance variable names
	format				<SmallInteger> bit representation of the class instSize/type
	classVariables		<Set> class variable names
	pools				<Set> names of shared environments
	category			<String> class''s category name
	environment		<Environment/SystemDictionary> class''s name space
	organizer			<SystemOrganizer> object which maps classes to categories
	recompile			<Boolean> whether a change may have occurred that would cause the class to be recompiled

Class Variables:
	BuildErrorSignal		<Signal> Class definition error
	BuildFailureSignal	<Signal> Invalid class definition
	NilSuperclassSignal	<Signal> Warning -- class being defined with nil superclass'!



!ClassBuilder methodsFor: 'initialize-release'!

initialize
	"Set the default parameters.
	We know nothing yet about what format might be
	reasonable--assume fixed"

	environment _ Smalltalk.
	organizer _ SystemOrganization.
	format _ 0.
	self beFixed.
	recompile _ false! !

!ClassBuilder methodsFor: 'accessing'!

{OrderedCollection of: (Symbol | Array)} attributes
	^classAttributes!

{void} attributes: attributes {OrderedCollection of: (Symbol | Array)}
	classAttributes _ attributes!

category
	"Answer the category."

	^category!

category: aCategory
	"Record the category."

	category _ aCategory!

className
	"Answer the current class name.  This may be nil if the class was
	specified explicitly via #currentClass:."

	^className!

className: aName 
	"Record the name of the class--this will be resolved into a class later.
	No restriction is currently placed on what a name is."

	(aName isString and: [aName first isUppercase not])
		ifTrue:	[self notify: 'Classes should be capitalized'].
	className _ aName!

classVariables
	"Answer the names of class variables for the class."

	classVariables == nil
		ifTrue:	[^Set new]
		ifFalse:	[^classVariables]!

classVariables: aVariableList 
	"Specify the names of class variables. This should be a set of Symbols."

	classVariables _ aVariableList asSet collect: [:i | i asSymbol]!

classVariableTypes: types {OrderedCollection of: (Association of: String and: nil | ParseNode)}
	"Specify the types of class variables"
	classVariableTypes _ Dictionary new.
	types do: [ :var {Association} |
		var value ~~ nil ifTrue:
			[classVariableTypes at: var key put: var value printString]].
	classVariableTypes isEmpty ifTrue: [classVariableTypes _ nil].!

classVarString: aVariableList 
	"Specify the names of class variables. This should be a set of Symbols."
	| vars {Dictionary} |
	vars _ self scan: aVariableList.
	self classVariables: (vars collect: [ :var | var key]).
	self classVariableTypes: vars.!

{String} comment
	classComment == nil
		ifTrue: [self class commentTemplate]
		ifFalse: [^ classComment]!

{void} comment: newComment {String} 
	
	classComment _ newComment!

currentClass
	"Answer the class being changed."

	^class!

currentClass: aClass 
	"Record the class to be modified."

	aClass isBehavior
		ifFalse:	[^self failureSignal raiseErrorString: 'Invalid class'].
	class _ aClass!

environment
	"Answer the name space that will contain the class.
	This is generally Smalltalk in the generic image."

	^environment!

environment: aDictionary
	"Specify the name space that will contain the class.
	This is generally Smalltalk in the generic image--it may
	be set to nil if the class is supposed to be anonymous."

	environment _ aDictionary!

instanceVariables
	"Answer the collection of instance variable names."

	instanceVariables == nil
		ifTrue:	[^#()]
		ifFalse:	[^instanceVariables]!

instanceVariables: aNameList 
	"Specify the names of instance variables.  This should be an array of strings."

	instanceVariables _ aNameList asArray collect: [:i | i asString].!

instanceVariableTypes: types {OrderedCollection of: (Association of: String and: nil | ParseNode)}
	"Specify the types of instance variables"
	instanceVariableTypes _ Dictionary new.
	types do: [ :var {Association} |
		var value ~~ nil ifTrue:
			[instanceVariableTypes at: var key put: var value printString]].
	instanceVariableTypes isEmpty ifTrue: [instanceVariableTypes _ nil].!

instVarString: anInstVarString
	"Specify the names of instance variables."
	| vars {Dictionary} |
	vars _ self scan: anInstVarString.
	self instanceVariables: (vars collect: [ :var | var key]).
	self instanceVariableTypes: vars.!

organization
	"Answer the organizer which records the class's category,
	such as SystemOrganization."

	^organizer!

organization: anOrganizer
	"Specify the organizer which records the class's category,
	such as SystemOrganization."

	organizer _ anOrganizer!

pools
	"Specify which pools are to be used. This should be a set of Symbols."

	pools == nil
		ifTrue:	[^Set new]
		ifFalse:	[^pools]!

pools: aNameList 
	"Specify which pools are to be used. This should be a set of Symbols."

	pools _ aNameList asSet collect: [:i | i asSymbol]!

poolString: aNameList 
	"Specify which pools are to be used. This should be a set of Symbols."

	self pools: (Scanner new scanFieldNames: aNameList)!

superclass
	"Answer under which superclass the class will be created/moved."

	^superclass!

superclass: aClass 
	"Specify under which superclass the class will be created/moved."

	superclass _ aClass! !

!ClassBuilder methodsFor: 'class type'!

beBytes
	"State that the class will have variable-length byte instances."

	format _ self formatWithBytesSet: format!

beFixed
	"State that the class will have pointer instances with only named
	instance variables."

	format _ self formatWithFixedSet: format!

beImmediate
	"State that the class will have instances that have no instance
	variables, and are stored efficiently by the Smalltalk-80
	implementations.  An example of this is SmallIntegers."

	format _ self formatWithImmediateSet: format!

beVariable
	"State that the class will have pointer instances with named
	and/or indexed instance variables."

	format _ self formatWithVariableSet: format!

format: fmt
	"Specify that the class's new format should be fmt, subject to
	consistency checks against other information supplied."

	format _ fmt! !

!ClassBuilder methodsFor: 'evaluate'!

createNewSubclass
	"The class does not exist--create a new class-metaclass pair"

	| newMeta nuClass |
	self runValidationChecksForNewClass.
	newMeta _ self metaclassClass new.
	newMeta assignSuperclass: (self classOf: superclass).
	newMeta methodDictionary: MethodDictionary new.
	newMeta setInstanceFormat: (self classOf: superclass) format.
	class _ newMeta new.
	class assignSuperclass: superclass.
	class methodDictionary: MethodDictionary new.
	class setInstanceFormat: self computeFormat.
	self setStructureOf: class.
	class setName: className.
	self register: class inPlaceOf: nil.
	self changeMicroState.
	nuClass _ self logNew: class.
	self changeLoggedMicroState.
	^nuClass!

modifyExistingClass
	"Enumerate the legal types of changes and perform them.  If a new
	class was created, the final check for which kind of mutation is
	skipped, since a new class needs no mutation"

	| nuClass |
	self runValidationChecks.
	self needsMutation
		ifTrue:	[self doMutationInPlace
			ifTrue:	[self mutateCurrentClass]
			ifFalse:	[self mutateToNewClass]].
	self changeMicroState.
	nuClass _ self logChanged: self currentClass.
	self changeLoggedMicroState.
	^nuClass!

mutateCurrentClass
	"The only thing that needs to be done (if the superclass and
	instanceVariables haven't changed) is to recompile code if the
	name scope has changed"

	self setStructureOf: class.
	superclass == class superclass
		ifFalse:
			[class class
				assignSuperclass: (self classOf: superclass);
				flushVMmethodCache.
			class
				assignSuperclass: superclass;
				flushVMmethodCache.
			"How can we tell whether recompilation is needed?"
			recompile _ true]!

reviseSystem 
	"Mutate the system, differently based on whether the class already exists or not"

	^self needsNewClass
		ifTrue:	[self createNewSubclass]
		ifFalse:	[self modifyExistingClass]! !

!ClassBuilder methodsFor: 'evaluate-testing'!

doMutationInPlace
	"Answer whether it is safe to modify the class in place. This can 
	be done if the number and order of instance variables has not 
	changed, and the kind of object has not changed"

	self computeFormat = class format
		ifFalse: [^false].
	superclass == class superclass
		ifTrue: [^instanceVariables == nil or: [instanceVariables = class instVarNames]].
	((self allSortedInstVarNames: superclass), instanceVariables) = class allInstVarNames
		ifFalse: [^false].
	(class isMeta not and: [(self classOf: superclass) allInstVarNames = class class superclass allInstVarNames])
		ifFalse: [^false].
	^true!

needsMutation
	"Answer whether the class requires reconstruction"

	^superclass ~~ class superclass
		or: [self computeFormat ~= class format
		or: [instanceVariables ~~ nil
		and: [instanceVariables ~= class instVarNames]]]!

needsNewClass
	"If the class was specified by name, look it up. If it doesn't exist, 
	return true, else return false"

	class == nil
		ifTrue: [(className ~~ nil and:
					[environment ~~ nil and:
					[environment includesKey: className]])
				ifTrue: 
					[class _ environment at: className.
					[class isBehavior] whileFalse:
						[class _ self failureSignal raiseRequestErrorString: 'Class must be a Behavior']]
				ifFalse: [^true]].
	^false! !

!ClassBuilder methodsFor: 'evaluate-mutate instances'!

createCopy: inst under: new using: newIV 
	"Create an instance of 'new' that is like 'inst', using 'newIV'
	to specify how named instance variables should be mapped.
	If 'newIV' has zero at index 'i', the new instance will have nil
	in the named instance variable 'i'.  Otherwise, the value will
	specify which instance variable of 'inst' should be stored into
	the new instance"

	| newInst |
	new isVariable
		ifTrue: 
			[newInst _ new basicNew: inst basicSize.
			1 to: inst basicSize do: [:i | newInst basicAt: i put: (inst basicAt: i)]]
		ifFalse: [newInst _ new basicNew].
	1 to: new instSize do: 
		[:i | 
		| j |
		j _ newIV at: i.
		j = 0 ifFalse: [newInst instVarAt: i put: (inst instVarAt: j)]].
	^newInst!

genNewClass: aClass under: newSuper 
	"Generate a subclass of newSuper that is 'like' aClass.  This also
	creates a new metaclass for the new class"

	| f new newMeta |
	f _ aClass == class
		ifTrue:	[self genFormat: (instanceVariables ~~ nil
								ifTrue: [instanceVariables]
								ifFalse: [aClass instVarNames]) size
					under: newSuper
					format: format]
		ifFalse:	[self genFormat: aClass instVarNames size
					under: newSuper
					format: aClass format].
	newMeta _ self genNewMetaclass: aClass class under: (self classOf: newSuper).
	new _ self createCopy: aClass
				under: newMeta
				using: (self map: newMeta from: aClass class).
	new clearInstanceVariables.
	newMeta adopt: new.
	new superclass: newSuper.
	new setInstanceFormat: f.
	aClass == class
		ifTrue: [self setStructureOf: new].
	^new!

genNewMetaclass: aMetaclass under: newMetaSuperclass 
	"Generate a subclass of newMetaSuperclass that is 'like' aMetaclass"

	| f new |
	f _ aMetaclass == class
		ifTrue:	[self genFormat: (instanceVariables ~~ nil
								ifTrue: [instanceVariables]
								ifFalse: [aMetaclass instVarNames]) size
					under: newMetaSuperclass
					format: format]
		ifFalse:	[self genFormat: aMetaclass instVarNames size
					under: newMetaSuperclass
					format: aMetaclass format].
	new _ aMetaclass shallowCopy clearInstanceVariables.
	new superclass: newMetaSuperclass.
	new setInstanceFormat: f.
	aMetaclass == class
		ifTrue: [self setStructureOf: new].
	^new!

give: new identityOf: aClass 
	"Having changed the structure of a class, we now want to force 
	that class to be essentially the identical object it was before any 
	changes took place"

	| proto cl |
	cl _ new shallowCopy.
	cl copyMethodDictionary.
	cl isMeta
		ifFalse:	[cl class adopt: cl].
	cl compileAllFrom: new into: aClass.
	aClass removeFromSuper.
	aClass flushVMmethodCache.
	aClass become: cl.
	aClass flushVMmethodCache.
	aClass isMeta
		ifFalse:	[aClass class adopt: aClass].
	proto _ aClass basicNew.
	new allInstances do: [:inst | inst changeClassToThatOf: proto].
	new subclasses do:
		[:sub |
		sub superclass == new
			ifTrue:	[sub assignSuperclass: aClass; flushVMmethodCache]].
	self register: aClass inPlaceOf: new.
	new localObsolete.
	^aClass!

map: newClass from: aClass
	"Determine how instance variables are to be mapped between
	the two classes.  This is based purely on the two instance variable
	names being the same"

	| newIV oldIV |
	newIV _ newClass allInstVarNames.
	oldIV _ aClass allInstVarNames.
	^newIV collect: [ :i | oldIV indexOf: i].!

mutateClass: aClass toSuper: newSuper
	"Change the class's superclass to be newSuper.  This involves making
	a new class, installing it in the environment, mutating all instances to
	the new class, and modifying the old class's subclasses to be subclasses
	of the new one"

	| new |
	new _ aClass isMeta
				ifTrue:	[self genNewMetaclass: aClass under: newSuper]
				ifFalse:	[self genNewClass: aClass under: newSuper].
	aClass hasMethods
		ifTrue:	[Transcript show: new name,' recompiling... '.
				new compileAllFrom: aClass.
				Transcript show: 'done'; cr].
	self register: new inPlaceOf: aClass.
	self mutateInstances: new from: aClass.
	aClass subclasses do:
		[ :cls |
		cls superclass == aClass
			ifTrue:	[self mutateClass: cls toSuper: new]].
	self give: new identityOf: aClass.
	^aClass!

mutateInstances: newClass from: aClass
	"Take all instances of aClass and make them instances of newClass"

	| newIV |
	newIV _ self map: newClass from: aClass.
	aClass allInstancesDo:
		[ :inst |
		inst become: (self createCopy: inst under: newClass using: newIV)]!

mutateToNewClass
	"Modify class to be a subclass of superclass"

	^self mutateClass: class toSuper: superclass!

register: new inPlaceOf: aClass
	"Do whatever is necessary to cause instance creation to use the new
	version of the class"

	new addToSuper.
	environment == nil
		ifTrue:	[^self].
	new shouldBeRegistered
		ifFalse:	[^self].
	environment at: new name put: new.!

setStructureOf: aClass
	"Set aClass's instance structure."

	instanceVariables == nil 
		ifFalse:	[aClass instanceVariables: instanceVariables]! !

!ClassBuilder methodsFor: 'evaluate-micro state'!

changeAttributes

	classAttributes == nil 
		ifFalse: [class getOrMakeCxxClassDescription
			attributes: classAttributes]!

changeCategory
	"During the update phase, change the class's category"

	(category == nil or: [organizer == nil])
		ifFalse:	[organizer classify: class name under: category]!

changeClassVariables 
	"If class variable names have been specified, modify the class's classPool"

	| oldClassVars removed added |
	classVariables == nil
		ifTrue:	[^self].
	classVariables _ classVariables asOrderedCollection asArray.
	recompile _ recompile | (class declare: classVariables)!

changeClassVarTypes
	"Update the class variable types"

	class getOrMakeCxxClassDescription classVarTypes: classVariableTypes!

changeComment

	(classComment ~~ nil
			and: [classComment ~= class comment])
		ifTrue: [class comment: classComment.]!

changeInstanceVarTypes
	"Update the instance variable types"
	instanceVariableTypes == nil ifTrue:
		[instanceVariableTypes _ Dictionary new].
	class isMeta
			ifTrue: [class getOrMakeCxxClassDescription classInstVarTypes: instanceVariableTypes]
			ifFalse: [class getOrMakeCxxClassDescription instVarTypes: instanceVariableTypes]!

changeLoggedMicroState
	"Change those aspects of the class that are relatively independent 
	of any other changes to the class, but must be logged after the class definition"
	self changeAttributes.
	self changeComment.!

changeMicroState
	"Change those aspects of the class that are relatively independent 
	of any other changes to the class"

	self changeInstanceVarTypes.
	self changeClassVarTypes.
	self changeCategory.
	self changeClassVariables.
	self changePools.
	self sanityCheck: class.
	recompile ifTrue: [class withAllSubclasses do: [:cls | cls compileAll]]!

changePools
	"Revise the sharedPools of the class. The names of the pools are 
	translated now rather than earlier because the environment may 
	have been reset"

	| oldPools removed added failString |
	failString _ 'Can''t find the pool dictionary'.
	pools == nil ifTrue: [^self].
	pools _ pools collect:
		[:i | i isString
				ifTrue: [environment == nil
						ifTrue: [self failureSignal raiseRequestErrorString: failString]
						ifFalse: [environment at: i
									ifAbsent: [self failureSignal raiseRequestErrorString: failString]]]
				ifFalse: [i]].
	oldPools _ class sharedPools.
	removed _ oldPools - pools.
	added _ pools - oldPools.
	removed do: 
		[:pool | 
		class removeSharedPool: pool.
		recompile _ true].
	added do: 
		[:pool | 
		class addSharedPool: pool]! !

!ClassBuilder methodsFor: 'validation'!

runValidationChecks
	"Make an effort not to start operations if they have to be abandoned later"

	self computeFormat.
	self validateInstanceVariables.
	self validateSuperclassAssignment.
	self validateSubclassFormats.
	class isMeta
		ifFalse:	[self validateClassInstanceVariables].!

runValidationChecksForNewClass
	"'Prove' that
		1) the superclass is not a metaclass or other bogus object
		2) the class will not have a reserved word as an instance
			variable name
		3) the class will not have an instance variable name in common
			with one of its superclasses"

	self computeFormat.
	(superclass == nil or: [superclass isBehavior and: [superclass isMeta not]])
		ifFalse:	[self failureSignal raiseErrorString: 'Cannot create a subclass of this object'].
	self validateInstanceVariablesForNewClass!

validateClassInstanceVariables
	"'Prove' that
		2) the class's class will not have an instance variable name in common
			with one of its super-metaclasses
		3) the class's sub-metaclasses have no instance variable names
			in common with the new super-metaclasses"

	| all vars |
	all _ self allInstVarNames: (self classOf: superclass).
	vars _ class class instVarNames.
	1 to: vars size do: 
		[:i | | n |
		n _ vars at: i.
		(all includes: n)
			ifTrue: [self failureSignal raiseErrorString: 'Variable naming conflict in meta-hierarchy change']
			ifFalse: [all add: n]].
	class class allSubclassesDo: 
		[:cls | | v |
		v _ cls instVarNames.
		1 to: v size do: 
			[:i | | n |
			n _ v at: i.
			(all includes: n)
				ifTrue: [self failureSignal raiseErrorString: 'Variable naming conflict in meta-hierarchy change']]]!

validateInstanceVariables
	"'Prove' that
		1) the class will not have a reserved word as an instance
			variable name
		2) the class will not have an instance variable name in common
			with one of its superclasses
		3) the subclasses have no instance variable names in common
			with the new instance variable names of the class, or with
			the new superclasses"

	| all vars |
	all _ self allInstVarNames: superclass.
	all addAll: #('self' 'true' 'false' 'nil' 'thisContext' 'super' ).
	vars _ instanceVariables == nil
				ifTrue: [class instVarNames]
				ifFalse: [instanceVariables].
	1 to: vars size do: 
		[:i | | n |
		n _ vars at: i.
		(all includes: n)
			ifTrue: [self failureSignal raiseErrorString: 'Variable naming conflict in hierarchy change']
			ifFalse: [all add: n]].
	class allSubclassesDo: 
		[:cls | | v |
		v _ cls instVarNames.
		1 to: v size do: 
			[:i | | n |
			n _ v at: i.
			(all includes: n)
				ifTrue: [self failureSignal raiseErrorString: 'Variable naming conflict in hierarchy change']]]!

validateInstanceVariablesForNewClass
	"'Prove' that
		1) the class will not have a reserved word as an instance
			variable name
		2) the class will not have an instance variable name in common
			with one of its superclasses"

	| all |
	all _ self allInstVarNames: superclass.
	all addAll: #('self' 'true' 'false' 'nil' 'thisContext' 'super' ).
	1 to: instanceVariables size do: 
		[:i | | n |
		n _ instanceVariables at: i.
		(all includes: n)
			ifTrue: [self failureSignal raiseErrorString: 'Variable naming conflict in hierarchy change']
			ifFalse: [all add: n]]!

validateSubclassFormats
	"Determine whether any changes to the class will cause subclasses to have really
	bogus formats--such as an object with named instance variables that has a byte
	oriented superclass"

	self validateSubclassFormats: class format: format.!

validateSubclassFormats: aClass format: fmt
	"Determine whether any changes to the class will cause subclasses to have really
	bogus formats--such as an object with named instance variables that has a byte
	oriented superclass"

	| list mock |
	list _ aClass subclasses.
	list isEmpty
		ifTrue:	[^self].
	"We can use a mocked class as long as the format generator only asks questions that
	are confined to the format of the 'superclass'"
	mock _ Behavior new.
	mock setInstanceFormat: fmt.
	list do:
		[ :aSubclass |
		| f |
		f _ self genFormat: aSubclass instVarNames size under: mock format: aSubclass format.
		"If the format of the subclass would change, validate subclasses of the subclass"
		(self typeOf: f) = (self typeOf: aSubclass format)
			ifFalse:	[self validateSubclassFormats: aSubclass format: f]].!

validateSuperclassAssignment
	"Do checking against legal reassignment of the superclass.  Specifically,
	the redefinition of superclass-ness can not be done on a metaclass
	and the new superclass cannot inherit from the new subclass."

	(superclass ~~ nil and: [superclass == class or: [superclass inheritsFrom: class]])
		ifTrue: [self failureSignal raiseErrorString: 'Invalid superclass--superclass inherits from class'].
	(superclass == class superclass or: [class isMeta not])
		ifFalse:	[self failureSignal raiseErrorString: 'Invalid superclass--redefinition of a metaclass''s superclass']! !

!ClassBuilder methodsFor: 'format validation'!

computeFormat
	"Make sure the format value is correct"

	| list |
	(class ~~ nil and:
			[class format ~~ nil and:
			[class isBits and:
			[class isFixed]]])
		ifTrue:	[self beImmediate].
	list _ instanceVariables == nil
		ifTrue:	[class instVarNames]
		ifFalse:	[instanceVariables].
	format _ self genFormat: list size under: superclass format: format.
	^format!

genFormat: listSize under: newSuper format: aFormat
	"Make sure the format value is correct"

	| f size fmt |
	fmt _ aFormat.
	f _ fmt bitAnd: -4096.
	f = 0
		ifTrue:	[fmt _ self validateFormatImmediate: newSuper format: fmt size: listSize].
	f = 4096
		ifTrue:	[fmt _ self validateFormatBytes: newSuper format: fmt size: listSize].
	f = -8192
		ifTrue:	[fmt _ self validateFormatFixed: newSuper format: fmt size: listSize].
	f = -4096
		ifTrue:	[fmt _ self validateFormatVariable: newSuper format: fmt size: listSize].
	size _ listSize + (self instSize: newSuper).
	size > 255
		ifTrue:	[^self failureSignal raiseErrorString: 'Object too large'].
	^size bitOr: (fmt bitAnd: -256)!

validateFormatBytes: newSuper format: f size: size
	"Do validations based on the assumption that the subclass will be 
	variable bytes"

	(newSuper ~~ nil and: [newSuper instSize > 0])
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make a byte subclass of a class with named fields'].
	(newSuper ~~ nil and: [newSuper isVariable and: [newSuper isPointers]])
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make a byte subclass of a class with pointer fields'].
	size > 0
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make a byte subclass with pointer fields'].
	^f!

validateFormatFixed: newSuper format: f size: size
	"Do validations based on the assumption that the subclass will be 
	fixed-size pointers"

	(newSuper ~~ nil and: [newSuper isBits])
		ifTrue: [^self validateFormatBytes: newSuper format: (self formatWithBytesSet: f) size: size].
	(newSuper ~~ nil and: [newSuper isVariable])
		ifTrue: [^self validateFormatVariable: newSuper format: (self formatWithVariableSet: f) size: size].
	^f!

validateFormatImmediate: newSuper format: f size: size
	"Do validations based on the assumption that the subclass will be 
	an immediate class, similar to SmallInteger"

	(newSuper ~~ nil and: [newSuper isVariable])
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make an immediate subclass of a variable class'].
	(newSuper ~~ nil and: [newSuper instSize > 0])
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make an immediate subclass of a class with pointer fields'].
	size > 0
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make an immediate subclass with pointer fields'].
	^f!

validateFormatVariable: newSuper format: f size: size
	"Do validations based on the assumption that the subclass will be 
	variable pointers"

	(newSuper ~~ nil and: [newSuper isBits])
		ifTrue: [^self failureSignal raiseErrorString: 'cannot make a pointer subclass of a class with non-pointer fields'].
	^f! !

!ClassBuilder methodsFor: 'defaults'!

metaclassClass
	"The class used to create new metaclasses when they are needed"

	^Metaclass! !

!ClassBuilder methodsFor: 'logging'!

logChanged: aClass
	"Record that a class has been modified"

	"environment == nil
		ifFalse:	[environment changes changeClass: aClass]."
	ChangeLog log: #accept class: aClass changes: aClass definition.
	^aClass!

logNew: aClass
	"Record that a class has been created"

	"environment == nil
		ifFalse:	[environment changes addClass: aClass]."
	ChangeLog log: #add class: aClass changes: aClass definition.
	^aClass! !

!ClassBuilder methodsFor: 'prototypes'!

class
	"Answer the object which is the receiver's class. Essential.  See 
	documentation in Object metaclass."

	<primitive: 111>
	self primitiveFailed!

doesNotUnderstand: aMessage 
	"The default behavior is to create a Notifier containing the 
	appropriate message and to allow the user to open a Debugger. 
	Subclasses can override this message in order to modify this behavior."

	(Object canUnderstand: aMessage selector)
		ifTrue:	[self class copy: aMessage selector from: Object.
				^self perform: aMessage selector withArguments: aMessage arguments].

	Object messageNotUnderstoodSignal
		raiseRequestWith: aMessage
		errorString: 'Message not understood: ' , aMessage selector.
	^self perform: aMessage selector withArguments: aMessage arguments! !

!ClassBuilder methodsFor: 'private: private'!

allInstVarNames: aClass

	| cls names |
	cls _ aClass.
	names _ Set new.
	[cls == nil]
		whileFalse:
			[names addAll: cls instVarNames.
			cls _ cls superclass].
	^names!

allSortedInstVarNames: aClass

	| cls names |
	cls _ aClass.
	names _ OrderedCollection new.
	[cls == nil]
		whileFalse:
			[names addAllFirst: cls instVarNames.
			cls _ cls superclass].
	^names!

classOf: aClass

	^aClass == nil
		ifTrue:	[Class]
		ifFalse:	[aClass class]!

failureSignal

	^self class buildFailureSignal!

formatWithBytesSet: fmt
	"Answer a format similar to the one specified, but which represents
	variable-length byte instances--these can have no named instance
	variables"

	^4096!

formatWithFixedSet: fmt
	"Answer a format similar to the one specified, but which represents
	pointer instances with only named instance variables"

	^(fmt bitAnd: 255) bitOr: -8192!

formatWithImmediateSet: fmt
	"Answer a format similar to the one specified, but which represents
	instances that have no instance variables, and are stored efficiently
	by the Smalltalk-80 implementations.  An example of this is SmallIntegers"

	^0!

formatWithVariableSet: fmt
	"Answer a format similar to the one specified, but which represents
	pointer instances with named and/or indexed instance variables"

	^(fmt bitAnd: 255) bitOr: -4096!

instSize: aClass

	^aClass == nil
		ifTrue:	[0]
		ifFalse:	[aClass instSize]!

sanityCheck: aClass

	(aClass canUnderstand: #doesNotUnderstand:)
		ifFalse:	[aClass copyCategory: #prototypes from: ClassBuilder].!

{OrderedCollection of: (Association of: String and: ParseNode)} scan: aString
	"Answer the variable list encoded in aString"
	^(Parser new parseTypedVars: aString notifying: nil) collect:
		[ :node {ParameterNode} |
		node name -> node type]!

typeOf: fmt
	"Answer the format as a specification of only kind of object, not size"

	^fmt bitAnd: -256! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassBuilder class
	instanceVariableNames: ''!



!ClassBuilder class methodsFor: 'class initialization'!

initialize
	"Initialize the failure signals."

	"ClassBuilder initialize"

	BuildErrorSignal _ (Object errorSignal newSignalMayProceed: true)
				notifierString: 'Class definition error';
				nameClass: self message: #errorSignal.
	BuildFailureSignal _ BuildErrorSignal newSignal
				notifierString: 'Invalid class definition';
				nameClass: self message: #buildFailureSignal.
	NilSuperclassSignal _ BuildErrorSignal newSignal
				notifierString: 'Warning -- class being defined with nil superclass';
				nameClass: self message: #nilSuperclassSignal! !

!ClassBuilder class methodsFor: 'instance creation'!

new
	"Answer a new instance, suitably initialized"

	^super new initialize! !

!ClassBuilder class methodsFor: 'Signal constants'!

buildFailureSignal

	^BuildFailureSignal!

errorSignal

	^BuildErrorSignal!

nilSuperclassSignal

	^NilSuperclassSignal! !

ClassBuilder initialize!

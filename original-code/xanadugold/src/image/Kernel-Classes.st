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

ClassDescription subclass: #Metaclass
	instanceVariableNames: 'thisClass '
	classVariableNames: 'ObsoleteSignal '
	poolDictionaries: ''
	category: 'Kernel-Classes'!
Metaclass comment:
'Metaclasses add instance-specific behavior to various classes in the system.  This typically includes messages for initializing class variables and instance creation messages particular to that class.  There is only one instance of a metaclass, namely the class (thisClass) which is being described.  A metaclass shares the class variables of its instance.

[Subtle] In general, the superclass hierarchy for metaclasses parallels that for classes.  Thus,
	Integer superclass == Number, and
	Integer class superclass == Number class.
However there is a singularity at Object.  Here the class hierarchy terminates, but the metaclass hierarchy must wrap around to Class, since ALL metaclasses are subclasses of Class.  Thus,
	Object superclass == nil, and
	Object class superclass == Class.

Instance Variables:
	thisClass	<Class> the chief instance of the receiver, which the receiver describes

Class Variables:
	ObsoleteSignal 	<Signal> Obsolete metaclass
		
'!


!Metaclass methodsFor: 'initialize-release'!

instanceVariableNames: instVarString 
	"Declare additional variables for my instances."

	^self classBuilder
		currentClass: self;
		superclass: superclass;
		instVarString: instVarString;
		reviseSystem! !

!Metaclass methodsFor: 'accessing'!

name
	"Answer a String that is the name of the receiver, either Metaclass or the
	name of the receiver's class followed by the ' class'."

	thisClass == nil
		ifTrue: [^'a Metaclass']
		ifFalse: [^thisClass name , ' class']!

nonMeta
	"the non-meta class"
	^self soleInstance!

soleInstance
	"The receiver has only one instance.  Answer it.
	If the receiver is an obsolete metaclass, raise a signal."

	thisClass == nil ifTrue: [^Metaclass obsoleteSignal raise].
	^thisClass! !

!Metaclass methodsFor: 'testing'!

isMeta
	^ true!

isObsolete
	"Answer whether the receiver is an obsolete metaclass."

	^thisClass == nil or: [thisClass ~~ (Smalltalk at: thisClass name ifAbsent: [nil])]
	"should only be true for obsolete metaclass"! !

!Metaclass methodsFor: 'copying'!

copy
	"Make a copy of the receiver without a list of subclasses.  Share the 
	reference to the sole instance."

	| copy t |
	t _ thisClass.
	thisClass _ nil.
	copy _ super copy.
	thisClass _ t.
	^copy! !

!Metaclass methodsFor: 'instance creation'!

adopt: aClass
	"Define the current class for this metaclass."

	aClass class == self
		ifFalse:	[^self error: 'Invalid assignment'].
	thisClass _ aClass!

new
	"The receiver can only have one instance.  Create it or complain that
	one already exists."

	thisClass == nil
		ifTrue: [^thisClass _ super new]
		ifFalse: [self error: 'A Metaclass should only have one instance!!']! !

!Metaclass methodsFor: 'instance variables'!

addInstVarName: aString 
	"Add the argument, aString, as one of the receiver's instance variables."

	| fullString |
	fullString _ aString.
	self instVarNames do: [:aString2 | fullString _ aString2 , ' ' , fullString].
	self instanceVariableNames: fullString!

removeInstVarName: aString 
	"Remove the argument, aString, as one of the receiver's instance variables."


	| newArray newString |
	(self instVarNames includes: aString)
		ifFalse: [self error: aString , ' is not one of my instance variables'].
	newArray _ self instVarNames copyWithout: aString.
	newString _ ''.
	newArray do: [:aString2 | newString _ aString2 , ' ' , newString].
	self instanceVariableNames: newString! !

!Metaclass methodsFor: 'class variables'!

addClassVarName: aString
	"Add the new class variable named aString to the receiver."

	^thisClass addClassVarName: aString!

classPool
	"Answer the dictionary of class variables."

	^thisClass classPool! !

!Metaclass methodsFor: 'class hierarchy'!

{Collection of: Behavior} subclasses
	"Answer the receiver's subclasses."

	| result {Collection of: Behavior} subs {Collection of: Behavior} |
	subs _ thisClass subclasses.
	result _ Set new: subs size.
	subs do: [:cls {Behavior} |
		cls isMeta not
			ifTrue: [result add: cls class]].
	^result!

{void} withAllSubsAndMetasDo: aBlock {BlockClosure of: Behavior}

	^VOID! !

!Metaclass methodsFor: 'compiling'!

possibleVariablesFor: misspelled continuedFrom: oldResults
	^ thisClass possibleVariablesFor: misspelled continuedFrom: oldResults.!

scopeHas: name ifTrue: assocBlock 
	^thisClass scopeHas: name ifTrue: assocBlock! !

!Metaclass methodsFor: 'printing'!

definition
	"Answer with a string that defines me"
	^self name , '
	' , 'instanceVariableNames: ' , self instanceVariablesStringWithTypes storeString!

definitionWithComment
	^self definition!

definitionWithCommentAndAttributes
	^self definition! !

!Metaclass methodsFor: 'fileIn/Out'!

fileOutOn: aFileStream moveSource: moveSource toFile: fileIndex 
	"File me out on aFileStream."

	super
		fileOutOn: aFileStream
		moveSource: moveSource
		toFile: fileIndex.
	(methodDict includesKey: #initialize)
		ifTrue: 
			[aFileStream cr.
			aFileStream cr.
			aFileStream nextChunkPut: thisClass name , ' initialize'.
			aFileStream cr]!

nonTrivial
	"Answer whether the receiver has some state or methods or class comment."

	^self instVarNames size > 0 or: [methodDict size > 0 or: [self comment size > 0]]!

readBinaryContentsFrom: stream
	"Read instance from stream."

	methodDict _ stream inClass: self do: [stream next].
	organization _ stream next!

storeBinaryContentsOn: stream
	"Store binary representation of the contents of the receiver onto aStream."

	stream inClass: self do: [stream nextPut: methodDict].
	stream nextPut: organization! !

!Metaclass methodsFor: 'cxx fileOut'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Metaclass class
	instanceVariableNames: ''!


!Metaclass class methodsFor: 'class initialization'!

initialize
	"Initialize signals."

	| es |
	es _ Object errorSignal.
	ObsoleteSignal _ es newSignal 
		notifierString: 'Obsolete metaclass';
		nameClass: self message: #obsoleteSignal.! !

!Metaclass class methodsFor: 'Signal constants'!

obsoleteSignal

	^ObsoleteSignal! !

Metaclass initialize!


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

Object subclass: #CategoryPair
	instanceVariableNames: '
		myLeft {Category}
		myRight {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Classes'!



!CategoryPair methodsFor: 'operations'!

{TypePair} | type {Category | CategoryPair}
	^CategoryPair create: self with: type! !

!CategoryPair methodsFor: 'testing'!

{BooleanVar} isSuperTo: cat {Class}

	^cat == myLeft 
		or: [cat == myRight 
		or: [(myLeft isSuperTo: cat) 
		or: [myRight isSuperTo: cat]]]! !

!CategoryPair methodsFor: 'creation'!

create: cat1 {Category} with: cat2 {Category}
	super create.
	myLeft _ cat1.
	myRight _ cat2! !
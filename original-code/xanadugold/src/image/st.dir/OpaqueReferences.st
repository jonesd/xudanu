'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:48 pm'!

GenerateMethods subclass: #OpaqueReferences
	instanceVariableNames: 'myClass {Class}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!OpaqueReferences methodsFor: 'creation'!

create: cls {Behavior}

	super create.
	myClass _ cls nonMeta! !

!OpaqueReferences methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	| name {Symbol} |
	name _ myClass name.
	^MethodAction 
		combine: (BlockParsingAction create: [:each {ProgramNode} | 
			(each isKindOf: VariableNode) and: [each name asSymbol == name]]) 
		with: (ClassAction create: [:each {ProgramNode} | 
			(each isKindOf: VariableNode) and: [each name asSymbol == name]])!

{String} label
	
	^'Opaque Refs to ', myClass name!

{BooleanVar} passes: cls {Behavior} 

	| cxc {CxxClassDescription}
	  group {CxxClassGroup} |
	cxc _ cls fetchCxxClassDescription.
	(cxc == nil or: [(group _ cxc fetchGroup) == nil])
		ifTrue: [^false].
	^group referencesType: myClass!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((cls sourceCodeStringAt: sel) findToken: myClass name startingAt: 1) ~= 0! !

!OpaqueReferences methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	CxxSystemOrganization fileList do: [:mod {CxxModule} |
		mod allGroups do: [:group {CxxClassGroup} |
			(group referencesType: myClass)
				ifTrue: [group classes do: [:cxc {CxxClassDescription} |
							| c {Class} |
							c _ cxc classDescription.
							aBlock value: c.
							aBlock value: c class]]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OpaqueReferences class
	instanceVariableNames: ''!



!OpaqueReferences class methodsFor: 'creation'!

make: cls {Behavior}

	^self create: cls! !
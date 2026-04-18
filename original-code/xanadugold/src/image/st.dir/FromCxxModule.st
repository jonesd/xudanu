'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:39 pm'!

GenerateMethods subclass: #FromCxxModule
	instanceVariableNames: '
		myOrg {CxxFileOrganizer}
		myTree {CxxTreeAssociation}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromCxxModule methodsFor: 'private:'!

{CxxFileOrganizer} org

	myOrg == nil 
		ifTrue: [^CxxSystemOrganization]
		ifFalse: [^myOrg]!

{CxxTreeAssociation} tree

	myTree == nil
		ifTrue: [^self org tree]
		ifFalse: [^myTree]! !

!FromCxxModule methodsFor: 'creation'!

create: org {CxxFileOrganizer default: nil}
	with: tree {CxxTreeAssociation default: nil}

	super create.
	myOrg _ org.
	myTree _ tree! !

!FromCxxModule methodsFor: 'accessing'!

{String} label
	
	(self org == CxxSystemOrganization and: [self tree == self org tree])
		ifTrue: [^'Cxx System']
		ifFalse: [^'Module ', self tree key]!

{BooleanVar} passes: cls {Behavior} 
	
	| cxc {CxxClassDescription | nil} name {Symbol} mod {CxxModule | nil} |
	cxc _ cls fetchCxxClassDescription.
	(cxc == nil or: [(mod _ cxc fetchCxxModule) == nil]) ifTrue:
		[^false].
	name _ mod moduleName asSymbol.
	self tree withChildrenDo: [:kid {CxxTreeAssociation} |
		(kid value == #file and: [kid key asSymbol == name]) ifTrue:
			[^true]].
	^false!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !

!FromCxxModule methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self tree withChildrenDo: [:kid {CxxTreeAssociation} |
		kid value == #file
			ifTrue: [(self org getModuleNamed: kid key) allClasses 
					 do: [:cxc {CxxClassDescription} |
						| c {Class} |
						c _ cxc classDescription.
						aBlock value: c.
						aBlock value: c class]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromCxxModule class
	instanceVariableNames: ''!



!FromCxxModule class methodsFor: 'smalltalk: defaults'!

make

	^self make: nil with: nil!

make: org

	^self create: org with: nil!

{OrderedCollection of: Array} 
	menuArrayFrom: modules {OrderedCollection of: CxxTreeAssociation}
	passing: aPredicate {BlockClosure of: CxxModule with: Boolean}
	
	^self menuArrayFrom: modules passing: aPredicate parent: nil! !

!FromCxxModule class methodsFor: 'creation'!

make: org {CxxFileOrganizer default: nil}
	with: tree {CxxTreeAssociation default: nil}

	^self create: org with: tree! !

!FromCxxModule class methodsFor: 'prompting'!

{OrderedCollection of: Array} 
	menuArrayFrom: modules {OrderedCollection of: CxxTreeAssociation}
	passing: aPredicate {BlockClosure of: CxxModule with: Boolean}
	parent: parent {String default: nil}
	
	| result {OrderedCollection of: Array} |
	result _ OrderedCollection new.
	modules do: [:kid {CxxTreeAssociation} |
		kid value == #file
			ifTrue: [
				| mod {CxxModule} |
				mod _ CxxSystemOrganization getModuleNamed: kid key.
				(aPredicate value: mod)
					ifTrue: [result addLast: (Array with: kid key with: kid key)]].
		kid children isEmpty not
			ifTrue: [
				| subMenu {OrderedCollection of: Array} |
				subMenu _ self menuArrayFrom: kid children passing: aPredicate parent: kid key.
				subMenu isEmpty not
					ifTrue: [result addLast: (Array with: kid key with: subMenu)]]].
	(result isEmpty not and: [parent ~~ nil]) ifTrue:
		[result addFirst: #-.
		result addFirst: (Array with: parent with: parent)].
	^result!

{String} pickAModule

	^self pickAModuleFrom: CxxSystemOrganization tree!

{String} pickAModuleFrom: tree {CxxTreeAssociation}

	| result {String} menu {PopUpMenu} |
	menu := PopUpMenu fromArray: (self menuArrayFrom: tree children passing: [:mod {CxxModule} |
		true]).
	result _ menu startUp.
	result = 0
		ifTrue: [^nil]
		ifFalse: [^result].! !
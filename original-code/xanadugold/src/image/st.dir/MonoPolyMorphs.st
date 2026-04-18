'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:46 pm'!

MethodFilter subclass: #MonoPolyMorphs
	instanceVariableNames: 'myMonoRoots {IdentityDictionary of: Symbol with: Behavior | nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!MonoPolyMorphs methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		each isKindOf: MethodNode]!

{String} label
	
	^'Mono-Polymorphs'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| topClass {Behavior | nil} |
	topClass _ myMonoRoots at: sel ifAbsent: [^false].
	topClass = nil
		ifTrue: [^false].
	^cls = topClass or: [cls inheritsFrom: topClass]! !

!MonoPolyMorphs methodsFor: 'creation'!

create: meths {Collection of: MethodRep}

	super create.
	myMonoRoots _ IdentityDictionary new.
	meths do: [:meth |
		| topClass |
		topClass _ meth methodClass withAllSuperclasses reverse detect: [:c1 {Behavior} |
			c1 includesSelector: meth selector].
		(myMonoRoots includesKey: meth selector)
			ifTrue: [(myMonoRoots at: meth selector) ~= topClass
						ifTrue: [myMonoRoots at: meth selector put: nil]]
			ifFalse: [myMonoRoots at: meth selector put: topClass]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MonoPolyMorphs class
	instanceVariableNames: ''!



!MonoPolyMorphs class methodsFor: 'creation'!

make: meths {Collection of: MethodRep}

	^self create: meths! !
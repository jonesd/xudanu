'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:37 pm'!

Heaper subclass: #Initializer
	instanceVariableNames: ''
	classVariableNames: '
		GarbageClasses {ImmuSet of: Category} 
		InitTimeClasses {ImmuSet of: Category} '
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(Initializer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Initializer class
	instanceVariableNames: ''!

(Initializer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Initializer class methodsFor: 'smalltalk: link/init/exit times'!

{void} exitTimeInherited
	"stuff to do at program exit time, like:"
		"classInstanceVariable delete"
	"done for all classes that respondTo: #exitTimeInherited"
	"Exit time corresponds to C++ static destruction.  Does not translate"!

{void} exitTimeNonInherited
	"stuff to do at program exit time, like:"
		"ClassVariable delete"
	"done for all classes whose class includesSelector: #exitTimeNonInherited"
	"Exit time corresponds to C++ static destruction.  Does not translate"
	
	Transcript show: 'Exit Time'; cr; endEntry!

{void} initTimeInherited

	"stuff to do at program initialization time, like:"
		"classInstanceVariable _ Foo make: self"
	"done for all classes that respondTo: #initTimeInherited"
	"Init time corresponds to C++ static construction"!

{void} initTimeNonInherited
	"stuff to do at program initialization time, like:"
		"ClassVariable _ Foo make: ThisClass"
	"done for all classes whose class includesSelector: #initTimeNonInherited"
	"Init time corresponds to C++ static construction"!

{void} linkTimeInherited

	"stuff to do at program link time (sort of), like:"
		"classInstanceVariable _ NULL"
	"done for all classes that respondTo: #linkTimeInherited"
	"Link time corresponds to C static data initialization"
	
	"Transcript show: 'Link Time for', self name; cr; endEntry"!

{void} linkTimeNonInherited
	"stuff to do at program link time (sort of), like:"
		"ClassVariable _ NULL"
	"done for all classes whose class includesSelector: #linkTimeNonInherited"
	"Link time corresponds to C static data initialization"
	
	Transcript show: 'Link Time'; cr; endEntry!

{void} staticTimeInherited

	"stuff to do at program static initialization time (sort of), like:"
		"classInstanceVariable _ NULL"
	"done for all classes that respondTo: #staticTimeInherited"
	"Static time corresponds to C++ static construction"
	
	"Transcript show: 'Static Time for', self name; cr; endEntry"!

{void} staticTimeNonInherited
	"stuff to do at program static initialization time (sort of), like:"
		"ClassVariable _ NULL"
	"done for all classes whose class includesSelector: #staticTimeNonInherited"
	"Stastic time corresponds to C++ static construction."
	
	Transcript show: 'Static Time'; cr; endEntry! !

!Initializer class methodsFor: 'smalltalk: initialization'!

{void} checkCleanup: class {Category} with: set {MuSet}
	"Initializer initialize"

	class isMeta ifTrue: [^self].
	(class class includesSelector: #cleanupGarbage)
		ifTrue: [set add: class].
	class subclassesDo: [:cl | self checkCleanup: cl with:
set]!

{void} initialize
	"Initializer initialize"

"	InitTimeClasses _ MuSet make: 50.
	GarbageClasses _ MuSet make: 29.
"	InitTimeClasses _ IdentitySet new.
	GarbageClasses _ IdentitySet new.
	self initialize: Object with: InitTimeClasses.
	self checkCleanup: Object with: GarbageClasses.
	Emulsion cleanupGarbage.  "We must reset the emulsions."!

{void} initialize: class {Category} with: set {MuSet}
	"Initializer initialize"

	class isMeta ifTrue: [^self].
	((class class includesSelector: #linkTimeInherited)
		or: [(class class includesSelector: #staticTimeInherited)
		or: [(class class includesSelector: #initTimeInherited)
		or: [class class includesSelector: #exitTimeInherited]]])
		ifTrue:
			[set add: class.
			class allSubclassesDo: [:cl | set add: cl].
			^self].
	((class class includesSelector: #linkTimeNonInherited)
		or: [(class class includesSelector: #staticTimeNonInherited)
		or: [(class class includesSelector: #initTimeNonInherited)
		or: [class class includesSelector: #exitTimeNonInherited]]])
		ifTrue: [set add: class].
	class subclassesDo: [:cl | self initialize: cl with: set].! !

!Initializer class methodsFor: 'smalltalk: init... times'!

{void} doExitTime
	"Initializer doExitTime"
	
	InitTimeClasses stepper forEach: [:class {Behavior} |
		(class class includesSelector: #exitTimeNonInherited)
			ifTrue: [class exitTimeNonInherited].
		(class respondsTo: #exitTimeInherited)
			ifTrue: [class exitTimeInherited]]!

{void} doInitTime
	"Initializer doInitTime"

	Transcript show: 'Init Time'; cr; endEntry.
	InitTimeClasses stepper forEach: [:class {Behavior} | 
		(class inheritsFrom: Converter)
			ifTrue:
				[Heaper initializingClasses add: class.
				class initTimeInherited.
				InitializedClasses add: class.
				Heaper initializingClasses remove: class]].
	InitTimeClasses stepper forEach: [:class {Behavior} | 
		(InitializedClasses includes: class) ifFalse: 
			[(class class includesSelector: #initTimeNonInherited) ifTrue: [class initTimeNonInherited].
			((class respondsTo: #initTimeInherited) 
				and: [(class class includesSelector: #suppressInitTimeInherited) not])
				ifTrue:
					[Heaper initializingClasses add: class.
					class initTimeInherited.
					Heaper initializingClasses remove: class].
			InitializedClasses add: class]].
	Transcript show: 'Init Finished'; cr; endEntry!

{void} doLinkTime
	"Initializer doLinkTime"
	
	InitializedClasses _ IdentitySet new: InitTimeClasses count * 2.
	InitializingClasses _ IdentitySet new: InitTimeClasses count.
	InitTimeClasses stepper forEach: [:class {Behavior} |
		(class class includesSelector: #linkTimeNonInherited) ifTrue: [class linkTimeNonInherited].
		((class respondsTo: #linkTimeInherited) and: [(class class includesSelector: #suppressLinkTimeInherited) not])
			ifTrue: [class linkTimeInherited]].
	Smalltalk garbageCollect.!

{void} doStaticTime
	"Initializer doStaticTime"
	Emulsion cleanupGarbage.
	InitializedClasses _ IdentitySet new: InitTimeClasses count * 2.
	InitializingClasses _ IdentitySet new: InitTimeClasses count.
	InitTimeClasses stepper forEach: [:class {Behavior} |
		(class class includesSelector: #staticTimeNonInherited)
			ifTrue: [class staticTimeNonInherited].
		((class respondsTo: #staticTimeInherited)
				and: [(class class includesSelector: #suppressLinkTimeInherited) not])
			ifTrue: [class staticTimeInherited]].
	Heaper allSubclassesDo: [:cls {Behavior} |
		| cxc {CxxClassDescription} |
		cxc _ cls fetchCxxClassDescription.
		(cxc ~~ nil) ifTrue:
			[cxc attributes do: [:attr {Symbol | (Array of: Symbol)} |
				(attr isKindOf: Array) ifTrue:
					[(attr at: 1) == #MAY.BECOME
						ifTrue: [cls mayBecome: (Smalltalk at: (attr at: 2))]
						ifFalse: [(attr at: 1) == #MAY.BECOME.ANY.SUBCLASS.OF
								ifTrue: [cls mayBecomeAnySubclassOf: (Smalltalk at: (attr at: 2))]]]]]].
	Package allSubclassesDo: [ :c | c registerWithContents]! !

!Initializer class methodsFor: 'global: smalltalk: pseudo-main'!

{int} mainAC
	^2!

{char star vector} mainAV
	| av {PtrArray} |
	av _ PtrArray nulls: 2.
	av at: UInt32Zero store: 'Smalltalk'.
	av at: 1 store: 'ent.ent'.
	^av! !

!Initializer class methodsFor: 'smalltalk: pseudo-main'!

doMain: block
	"Do the link time and static initialization time, run the block, then do exit-time."
	
	self doLinkTime; doStaticTime; doInitTime.
	block valueNowOrOnUnwindDo: [self doExitTime; cleanupGarbage]!

with: argc with: argv doMain: block
	"Do the link time and static initialization time, run the block, then do exit-time."
	
	self doMain: block! !

!Initializer class methodsFor: 'smalltalk: cleanup'!

cleanup

	GarbageClasses stepper forEach: [:gc {Category} |
		gc cleanupGarbage].
	Smalltalk garbageCollect! !

Initializer initialize!

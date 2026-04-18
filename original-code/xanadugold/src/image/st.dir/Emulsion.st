'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:18 pm'!

Object subclass: #Emulsion
	instanceVariableNames: '
		myFluids {UNKNOWN}
		myFluidsUsed {UNKNOWN}'
	classVariableNames: 'TheImageEmulsion {UNKNOWN} '
	poolDictionaries: ''
	category: 'Xanadu-Xpp-fluid'!

(Emulsion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Emulsion methodsFor: 'accessing'!

{void star} fetchNewRawSpace: size {#size.U.t var}

	self subclassResponsibility!

{void star} fetchOldRawSpace

	self subclassResponsibility!

{Array} fluidsSpace
	| result {Array} |
	result _ self fetchOldRawSpace.
	result ~~ NULL ifTrue:
		[ ^ result ].
	result _ self fetchNewRawSpace: myFluids size.
	myFluidsUsed _ true.
	myFluids do: [ :fluid | fluid init ].
	^ result.! !

!Emulsion methodsFor: 'create'!

create
	super create.
	myFluids _ OrderedCollection new.
	myFluidsUsed _ false.! !

!Emulsion methodsFor: 'finalization'!

destructAll
	myFluids do: [ :f | f fluidSet: nil ]! !

!Emulsion methodsFor: 'printing'!

printOn: aStream
	aStream << self class name << '(' << myFluids << ')'! !

!Emulsion methodsFor: 'special'!

{Integer} addFluid: fluid {FluidVar}
	"add a new fluid to the emulsion, and return its index"
	myFluidsUsed not assert: 'Fluids may not be added to emulsion after init.'.
	myFluids add: fluid.
	^ myFluids size!

reset
	myFluids ~~ nil ifTrue: [myFluids do: [ :f | f goAway ]].
	myFluids _ OrderedCollection new.
	myFluidsUsed _ false.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Emulsion class
	instanceVariableNames: ''!

(Emulsion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Emulsion class methodsFor: 'accessing'!

imageEmulsion

	^ TheImageEmulsion! !

!Emulsion class methodsFor: 'global: metamorphic creation'!

{Emulsion} globalEmulsion

	^ GlobalEmulsion make! !

!Emulsion class methodsFor: 'cleanup'!

cleanupGarbage
	Emulsion subclassesDo: [:c | c allInstances do: [:e | e ~~ TheImageEmulsion ifTrue: [e reset]]]! !

!Emulsion class methodsFor: 'initialize'!

initialize
	"Emulsion initialize"

	self cleanupGarbage.
	TheImageEmulsion ~~ nil ifTrue:
		[TheImageEmulsion reset.
		TheImageEmulsion _ nil].
	Smalltalk garbageCollect.
	TheImageEmulsion _ GlobalEmulsion new create.
	self initImageEmulsions: Object!

initImageEmulsions: class

	class isMeta ifTrue: [^self].
	(class class includesSelector: #initImageEmulsion)
		ifTrue: [class initImageEmulsion].
	class subclassesDo: [:cl | self initImageEmulsions: cl]! !

Emulsion initialize!

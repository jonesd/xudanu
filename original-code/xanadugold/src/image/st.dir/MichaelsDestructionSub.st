'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:39 pm'!

MichaelsDestructionSuper subclass: #MichaelsDestructionSub
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsDestructionSub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsDestructionSub methodsFor: 'creation'!

create
	super create.!

{void} delete
	"This should generage a translator warning and translate to something broken."!

{void} destroy
	1 == 1 ifTrue:
		[super destroy]!

{void} destruct

	cerr << 'MichaelsDestructionSub::destruct() called.
'.
	super destruct!

{void} destructor

	cerr << 'MichaelsDestructionSub::~MichaelsDestructionSub() called.
'.
	super destructor! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MichaelsDestructionSub class
	instanceVariableNames: ''!

(MichaelsDestructionSub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsDestructionSub class methodsFor: 'pseudo constructors'!

{MichaelsDestructionSub} make
	^self create! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:39 pm'!

Heaper subclass: #MichaelsDestructionSuper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsDestructionSuper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsDestructionSuper methodsFor: 'creation'!

create
	super create.!

{void} destroy
	1 == 1 ifTrue:
		[super destroy]!

{void} destruct

	cerr << 'MichaelsDestructionSuper::destruct() called.
'.
	super destruct!

{void} destructor

	cerr << 'MichaelsDestructionSuper::~MichaelsDestructionSuper() called.
'.
	super destructor! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MichaelsDestructionSuper class
	instanceVariableNames: ''!

(MichaelsDestructionSuper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsDestructionSuper class methodsFor: 'pseudo constructors'!

{MichaelsDestructionSuper} make
	^self create! !
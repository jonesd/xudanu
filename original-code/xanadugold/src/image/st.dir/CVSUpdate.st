'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:15 pm'!

CVSOperator subclass: #CVSUpdate
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!

(CVSUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSUpdate methodsFor: 'accessing'!

{NOWAIT} cvsClass: cls {Class}

	self subclassResponsibility!

{NOWAIT} cvsMethod: sel {Symbol} in: cls {Behavior}

	self subclassResponsibility!

{NOWAIT} cvsModule: cta {CxxTreeAssociation}

	self subclassResponsibility!

{NOWAIT} cvsProtocol: prot {Symbol} in: cls {Behavior}

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSUpdate class
	instanceVariableNames: ''!

(CVSUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSUpdate class methodsFor: 'creation'!

{CVSOperator | nil} fetchNew

	^self create! !
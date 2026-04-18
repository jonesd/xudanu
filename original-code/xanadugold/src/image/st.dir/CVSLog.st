'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:14 pm'!

CVSOperator subclass: #CVSLog
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!

(CVSLog getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSLog methodsFor: 'accessing'!

{NOWAIT} cvsClass: cls {Class}

	self subclassResponsibility!

{NOWAIT} cvsMethod: sel {Symbol} in: cls {Behavior}

	self subclassResponsibility!

{NOWAIT} cvsModule: cta {CxxTreeAssociation}

	self subclassResponsibility!

{NOWAIT} cvsProtocol: prot {Symbol} in: cls {Behavior}

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSLog class
	instanceVariableNames: ''!

(CVSLog getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSLog class methodsFor: 'creation'!

{CVSOperator | nil} fetchNew

	^self create! !
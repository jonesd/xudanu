'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:13 pm'!

CVSOperator subclass: #CVSSave
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-CVS Support'!

(CVSSave getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSSave methodsFor: 'accessing'!

{NOWAIT} cvsClass: cls {Class}

	self subclassResponsibility!

{NOWAIT} cvsMethod: sel {Symbol} in: cls {Behavior}

	self subclassResponsibility!

{NOWAIT} cvsModule: cta {CxxTreeAssociation}

	cta value == #file ifTrue:
		[ | mod {CxxModule} |
		mod := CxxSystemOrganization getModuleNamed: cta key.
		mod allClasses do: [:cls {CxxClassDescription} |
			self cvsClass: cls classDescription]].
	cta children do: [:kid {CxxTreeAssociation} |
		self cvsModule: kid]!

{NOWAIT} cvsProtocol: prot {Symbol} in: cls {Behavior}

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSSave class
	instanceVariableNames: ''!

(CVSSave getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSSave class methodsFor: 'creation'!

{CVSOperator | nil} fetchNew

	^self create! !
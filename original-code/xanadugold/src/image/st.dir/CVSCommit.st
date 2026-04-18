'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:11 pm'!

CVSOperator subclass: #CVSCommit
	instanceVariableNames: 'myText {Text}'
	classVariableNames: 'LastText {Text | nil} '
	poolDictionaries: ''
	category: 'Cxx-CVS Support'!

(CVSCommit getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSCommit methodsFor: 'accessing'!

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

!CVSCommit methodsFor: 'creation'!

create: text {Text}

	super create.
	myText _ text! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSCommit class
	instanceVariableNames: ''!

(CVSCommit getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CVSCommit class methodsFor: 'creation'!

{CVSOperator | nil} fetchNew

	| text {String | Text} |
	LastText == nil ifTrue:
		[LastText _ ''].
	text _ FillInTheBlank 
		request: 'Describe the nature of your commitment to our respository ;-)
then accept or CR' initialAnswer: LastText.
	(text == nil or: [text = '']) ifTrue:
		[^nil].
	LastText _ text asText.
	^self create: LastText! !
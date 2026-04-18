'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:59 pm'!

DocumentWindowModel subclass: #PassageWindowModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
PassageWindowModel comment:
'A window for showing passages (TextDocs) '!

(PassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageWindowModel methodsFor: 'create'!

create: document {DocumentModel}
	super create: document.
	self setDocumentSelection: SelectionRange make.
	[mySTWindowModel _ self createSmalltalkWindow] smalltalkOnly.
	XVIEW ifdef: [ self setMyXViewWindowModel:  self createXViewWindow].! !

!PassageWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow
	"create a corresponding smalltalk window object"
	^XViewPassageWindowModel create: self!

{XViewWindowModel} createXViewWindow: tBuild {FMBuilding} with: lBuild{FMBuilding}
	"create a corresponding smalltalk window object"
	^XViewPassageWindowModel create: self! !

!PassageWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"create a corresponding smalltalk window object"
	^STPassageWindowModel create: self! !

!PassageWindowModel methodsFor: 'accessing'!

{FMScaffold} documentScaffold
	"scaffold to use for building document pane"
 
	^FMScaffold
		make: PassageModel
		with: (PassageBuilder make: (self documentSelection cast: SelectionRange))
		with: Scaffold fluidVar! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageWindowModel class
	instanceVariableNames: ''!

(PassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageWindowModel class methodsFor: 'pseudoConstructors'!

make: passage {PassageModel}
	^self create: passage! !
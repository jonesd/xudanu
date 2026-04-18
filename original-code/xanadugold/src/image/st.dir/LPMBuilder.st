'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:02 pm'!

FMBuilder subclass: #LPMBuilder
	instanceVariableNames: 'myHighLightModel {VariableModel of: Highlight}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(LPMBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LPMBuilder methodsFor: 'creation'!

create: aHighlight {VariableModel of: Highlight}
	super create.
	myHighLightModel _ aHighlight! !

!LPMBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 
	| lpm {ListPaneModel} build {FMBuilding} sel {SelectionObject}
	 msv {Viewer} msc {FMController} sg {SelectionGate} both {FMController} |
	lpm _ obj basicCast: ListPaneModel.
	sel _ lpm selection. 
	build _ Scaffold fluidGet build: lpm list.
	msv _ MultiSelectionViewer
				make: build view
				with: sel
				with: myHighLightModel.
	msc _ MultiSelectionController make: build view with: sel.
	sg _ SelectionGate make: msv with: msc.
	(build controller == NULL)
		ifTrue: [both _ sg]
		ifFalse: [both _ MultiController make: 
			(MuArray array: build controller with: sg)].
	List2SelectionSchnert make: lpm list with: sel.
	^FMBuilding make: msv with: both! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LPMBuilder class
	instanceVariableNames: ''!

(LPMBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LPMBuilder class methodsFor: 'make'!

make: aHighlight {VariableModel default: NULL}
	aHighlight == NULL
		ifTrue: [^ self create: (VariableModel make: HighlightAll make)]
		ifFalse: [^ self create: aHighlight]! !

!LPMBuilder class methodsFor: 'smalltalk: defaults'!

make
	^ self make: NULL! !
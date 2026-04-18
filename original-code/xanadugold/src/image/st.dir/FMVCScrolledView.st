'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:53 pm'!

FMVCView subclass: #FMVCScrolledView
	instanceVariableNames: '
		myOffset {VariableModel of: PointPos}
		myScrolled {Viewer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMVCScrolledView comment:
'FMVCScrolledView is a Smalltalk view that scrolls a FM view that it contains.
	Instance Variables:
	
		myOffset - variable model holding the offset by which the view should be scrolled
		myScrolled - the viewer which is being scrolled'!



!FMVCScrolledView methodsFor: 'scrolling'!

offset
	"Smalltalk, being only interested in the y scroll, gets only that."
	^ myOffset getValue y!

offset: n {IntegerVar} 
	| new {IntegerVar} |
	new _ (n max: myScrolled enclosure height - model enclosure height) min: IntegerVar0.
	new ~= self offset ifTrue: [myOffset setValue: (PointPos make: IntegerVar0 with: new)]!

{IntegerVar} scrolledHeight

	^ myScrolled enclosure height! !

!FMVCScrolledView methodsFor: 'creation/deletion'!

create: fmPair {FMBuilding} with: scrolledView {Viewer} with: offset {VariableModel}
	"This create routine MUST be used only from the pseudo constructor because of the requirement to build other structure before calling the super create."
	
	super create: fmPair.
	myOffset _ offset.
	myScrolled _ scrolledView! !

!FMVCScrolledView methodsFor: 'accessing'!

{Category} defaultControllerClass
	^FMMVCScrollController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMVCScrolledView class
	instanceVariableNames: ''!



!FMVCScrolledView class methodsFor: 'pseudo constructor'!

make: onBuilding {FMBuilding} 
	"Note, the pseudoconstructor MUST be used to build instances of 
	this class correctly..."

	| newModel {VariableModel} newScroller {TranslateViewer} |
	newModel _ VariableModel make: PointPos make.
	newScroller _ TranslateViewer make: onBuilding view with: newModel.
	^ self create: (FMBuilding make: newScroller with: onBuilding controller)
		with: onBuilding view
		with: newModel! !
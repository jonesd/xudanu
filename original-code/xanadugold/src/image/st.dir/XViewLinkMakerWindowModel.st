'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:31 pm'!

XViewWindowModel subclass: #XViewLinkMakerWindowModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!
XViewLinkMakerWindowModel comment:
'This is the xview version of the LinkMaker window model.wasShifted {BooleanVar}
		myCurrentEndView {FMVCScrolledView}
		currentReader {DisplayObject}
		currentEditor {DisplayObject}
		currentFromType {DisplayObject}
		currentTooType {DisplayObject}
		myFromView {FMVCView}
		myTooView {FMVCView}'!

(XViewLinkMakerWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewLinkMakerWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create: window.
	"
	wasShifted _ false.
	myController _ NULL.
	myTop _ NULL.
	myCurrentEndView _ NULL.
	currentEditor _ 'Hugh' asString asParagraph.
	currentReader _ 'Hugh' asString asParagraph.
	currentFromType _ 'From Type' asString asParagraph.
	currentTooType _ 'To Type' asString asParagraph."! !

!XViewLinkMakerWindowModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel} 
"
	(model == self window and: [change isKindOf: AspectUpdate])
		ifTrue: [| asp {AspectUpdate wimpy} |
			asp _ change basicCast: AspectUpdate.
			(asp aspect isEqual: (PackOBits make: 'CurrentEnd'))
				ifTrue: [myCurrentEndView newBuilding: self window currentEndBuilding]
			ifFalse: [(asp aspect isEqual: (PackOBits make: 'FromEnds'))
				ifTrue: [myFromView source: (self getIconForCount: (self window fromEnds count))]
			ifFalse: [(asp aspect isEqual: (PackOBits make: 'TooEnds'))
				ifTrue: [myTooView source: (self getIconForCount: (self window tooEnds count))]]]]"! !

!XViewLinkMakerWindowModel methodsFor: 'windowing'!

{void} open
	"myTop  _ StandardSystemView model: self
		label: 'Link Creator'
		minimumSize: 300@300.
	self attachButtonsTo: myTop.
	self attachMenusTo: myTop.
	self attachIconsTo: myTop.
	self attachPanesTo: myTop.
	myController _ myTop controller.
	myController initialize; open"! !

!XViewLinkMakerWindowModel methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name  << '()'! !
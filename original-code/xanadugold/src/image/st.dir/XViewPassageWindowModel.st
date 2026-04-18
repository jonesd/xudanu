'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:09 pm'!

XViewDocumentWindowModel subclass: #XViewPassageWindowModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-XView'!

(XViewPassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewPassageWindowModel methodsFor: 'create'!

create: gwindow {WindowModel}
 super create: gwindow.
 XView USES.
 
	"| wname {Waldo} name {String} top {StandardSystemView} |"
	" super create: window."
	"wname _ self window document name.
	(wname isKindOf: XuText)
		ifTrue: [name _ (wname asWordArray: -1) asString]
		ifFalse: [name _ '<' , wname getCategory name , '>'].
	top  _ StandardSystemView model: self
		label: name
		minimumSize: 500@400.
	self attachIconsTo: top above: 0.075.
	self attachPanesTo: top below: 0.075.
	myController _ top controller.
	myController initialize; open"! !

!XViewPassageWindowModel methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name  << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewPassageWindowModel class
	instanceVariableNames: 'hackPassageObjectInternal {hackpassage.U.passagewindow.U.objects star} '!

(XViewPassageWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
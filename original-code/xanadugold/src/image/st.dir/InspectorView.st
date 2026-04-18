'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:11 pm'!

StandardSystemView subclass: #InspectorView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Inspector'!
InspectorView comment:
'An InspectorView is a StandardSystemView that provides initialization methods (messages to itself) to create and schedule the interface to an object Inspector.  It has two subViews, an InspectListView and an InspectCodeView.'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InspectorView class
	instanceVariableNames: ''!


!InspectorView class methodsFor: 'instance creation'!

inspector: anInspector 
	"Answer an instance of me on the model, anInspector.
	Label and minimum size are not set."

	| anInspectorView |
	anInspectorView _ InspectorView new.
	anInspectorView model: anInspector.
	self view: anInspector in: (0@0 extent: 1@1) of: anInspectorView.
	^anInspectorView!

open: anInspector
	"Create and schedule an instance of me on the model, anInspector."
	(self buildScheduledView: anInspector) controller open!

view: anInspector in: area of: superView
	"Create proportioned List and Code views on anInspector in area of superView"

	| mid |
	mid _ area left + (area width * 0.3).
	superView addSubView:
		(SelectionInListView
			on: anInspector printItems: anInspector printItems
			oneItem: false aspect: #field change: #field: list: #fieldList
			menu: #fieldMenu initialSelection: #field)
		in: (area copy right: mid) borderWidth: 1.
	superView addSubView: (CodeView on: anInspector aspect: #text
			change: #acceptText:from:
			menu: #textMenu initialSelection: nil)
		in: (area copy left: mid) borderWidth: 1! !

!InspectorView class methodsFor: 'private: private'!

buildScheduledView: anInspector 
	| topView |
	topView _ self model: anInspector label: anInspector object class name minimumSize: 180 @ 180.
	self view: anInspector in: (0@0 extent: 1@1) of: topView.
	^ topView! !
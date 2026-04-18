'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:04 pm'!

WindowModel subclass: #UserListWindowModel
	instanceVariableNames: '
		myULPM {ListPaneModel}
		mySelection {SelectionObject}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-udirmod'!

(UserListWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UserListWindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} createXViewWindow

	"LinkMakerWindowModel create open"
	"create a corresponding smalltalk window object"
	^XViewUserListWindowModel create: self!

{void} openXViewWindow
self myXViewWindowModel open! !
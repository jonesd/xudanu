'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:33 pm'!

XViewWindowModel subclass: #XViewPermissionWindowModel
	instanceVariableNames: 'hackPassageObjectInternal {hackpassage.U.passagewindow.U.objects star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewPermissionWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewPermissionWindowModel methodsFor: 'creation'!

create: winModel{PermissionWindowModel }
super create: winModel.! !

!XViewPermissionWindowModel methodsFor: 'windowing'!

{void} open! !
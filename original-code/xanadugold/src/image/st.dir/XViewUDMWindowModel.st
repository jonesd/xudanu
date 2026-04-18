'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:39 pm'!

XViewWindowModel subclass: #XViewUDMWindowModel
	instanceVariableNames: 'hackPassageObjectInternal {hackpassage.U.passagewindow.U.objects star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewUDMWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewUDMWindowModel methodsFor: 'windowing'!

{void} open
 
 	'fprintf(stderr,"leaving open:XViewUDMWindowModel\n");' translateOnly! !

!XViewUDMWindowModel methodsFor: 'creation'!

create: winModel{UDMWindowModel }
super create: winModel.! !
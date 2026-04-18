'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:36 pm'!

FMBuilder subclass: #BitEditorBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!


!BitEditorBuilder methodsFor: 'build'!

{FMBuilding} build: form {Heaper as: Image} 
	| v {Viewer} |
	^FMBuilding make: (v _ FormViewer create: form) 
		with: (FMBitEditor create: v with: form)! !
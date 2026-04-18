'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:42 pm'!

FMBuilder subclass: #ScrollBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(ScrollBuilder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScrollBuilder methodsFor: 'build'!

{FMBuilding} build: obj {Heaper} 
	| building {FMBuilding} var {VariableModel} view {Viewer} |
 
	building _ Scaffold fluidGet build: obj.
	var _ VariableModel make: (PointPos make).
	view _ TranslateViewer make: building view with: var.
	^FMBuilding make: (view basicCast: Viewer) 
				with: ((SimpleScrollController make: view with: var)
basicCast: FMController)! !

!ScrollBuilder methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
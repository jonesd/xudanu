'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:03 pm'!

XnDependent subclass: #RebuilderDirector
	instanceVariableNames: '
		myModel {XnModel}
		myView {FMVCView}
		myScaffold {FMScaffold}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!

(RebuilderDirector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RebuilderDirector methodsFor: 'create'!

create: model {XnModel} with: view {FMVCView} with: scaffold {FMScaffold}
	super create.
	myModel _ model.
	myView _ view.
	myScaffold _ scaffold.
	myModel addDependent: self! !

!RebuilderDirector methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
        model == (myModel basicCast: XnModel) ifTrue:
                [Scaffold fluidBind: myScaffold during:
                        [myView newBuilding: (Scaffold fluidGet build: myModel).]]! !

!RebuilderDirector methodsFor: 'protected: creation'!

{void} destruct
	myModel removeDependent: self.
	super destruct! !
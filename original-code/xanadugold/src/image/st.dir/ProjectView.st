'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:22 pm'!

StringHolderView subclass: #ProjectView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Projects'!
ProjectView comment:
'Class ProjectView is a StringHolderView of the description of a Project.  ProjectController is the default controller.'!


!ProjectView methodsFor: 'initialize-release'!

release
	model release.
	super release! !

!ProjectView methodsFor: 'controller access'!

defaultControllerClass
	^ProjectController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProjectView class
	instanceVariableNames: ''!


!ProjectView class methodsFor: 'instance creation'!

open
	"Answer an instance of me for a new Project.  It is created on the display screen."

	^self open: Project new
	"ProjectView open"!

open: aProject 
	"Answer an instance of me for the argument, aProject.  It is created on the
	display screen."
	| aProjectView topView |
	aProjectView _ super new.
	aProjectView model: aProject.
	aProjectView borderWidth: 1.
	topView _ StandardSystemView new.
	topView model: aProject.
	topView borderWidth: 1.
	topView addSubView: aProjectView.
	topView label: 'Project'.
	topView minimumSize: 100 @ 50.
	topView icon: (Icon constantNamed: #default).
	topView iconView controller: ProjectIconController new.
	topView iconText: 'project'.
	topView controller open! !
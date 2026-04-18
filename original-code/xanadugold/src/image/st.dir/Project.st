'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:21 pm'!

StringHolder subclass: #Project
	instanceVariableNames: 'projectWindows projectChangeSet projectTranscript projectHolder '
	classVariableNames: 'CurrentProject '
	poolDictionaries: ''
	category: 'Tools-Projects'!
Project comment:
'Each screen is a manifestation of a project.  Each project manages the windows (views) in it.  While the user is working in the project, the changes made to classes are collected.  Thus a system-wide set of changes is the collection of all project changes.

Instance Variables:
	projectWindows	 <ControlManager> access to the set of windows/views open in this project
	projectChangeSet	<ChangeSet> set of changes made within this project
	projectTranscript	<TextCollector> system transcript
	projectHolder	<Project> reference to the receiver

Class Variables:
	CurrentProject	<Project> the one in which the user is currently working'!


!Project methodsFor: 'initialize-release'!

release
	projectWindows isNil ifFalse: [projectWindows release].
	^super release! !

!Project methodsFor: 'accessing'!

changes
	"Answer the system changes made while using the receiver as the 
	active project."

	^projectChangeSet! !

!Project methodsFor: 'controlling'!

enter
	"The user has chosen to change the context of the workspace to be that of
	the receiver.  Change the ChangeSet, Transcript, and collection of scheduled
	views accordingly."

	Smalltalk newChanges: projectChangeSet.
	CurrentProject _ self.
	TextCollector newTranscript: projectTranscript.
	ControlManager newScheduler: projectWindows!

exit
	"Leave the current project and enter the project in which the receiver's view
	is scheduled."
	projectHolder enter! !

!Project methodsFor: 'dependents access'!

removeDependent: aDependent 
	super removeDependent: aDependent.
	self dependents isEmpty ifTrue: [self release]! !

!Project methodsFor: 'change management'!

noChanges
	"Reset the receiver's ChangeSet so that it is empty."
	projectChangeSet _ ChangeSet new.
	Smalltalk newChanges: projectChangeSet! !

!Project methodsFor: 'lock access'!

isLocked
	^super isLocked
	| projectChangeSet isEmpty not 
	| (projectWindows scheduledControllers size > 1)!

isUnlocked 
	^ self isLocked not! !

!Project methodsFor: 'private: private'!

initialProject
	"Initialize the root project"

	projectWindows _ ScheduledControllers.
	projectChangeSet _ Smalltalk changes.
	projectHolder _ self.
	projectTranscript _ Transcript.!

putStatsOn: aStream 
	"Write a description of the receiver onto aStream."

	aStream nextPutAll: 'PROJECT '; nextPutAll: self contents; cr; cr.
	projectChangeSet putStatsOn: aStream.
	aStream cr!

setProjectHolder: aProject 
	projectWindows _ ControlManager new.
	projectChangeSet _ ChangeSet new.
	projectTranscript _ TextCollector new.
	projectHolder _ aProject! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Project class
	instanceVariableNames: ''!


!Project class methodsFor: 'class initialization'!

initialize
	"This is the Top Project."   

	CurrentProject _ super new initialProject
	"Project initialize."! !

!Project class methodsFor: 'instance creation'!

new
	^super new setProjectHolder: CurrentProject! !

!Project class methodsFor: 'constants'!

current
	"Answer the project that is currently being used."
	^CurrentProject! !

!Project class methodsFor: 'change set stats'!

putStatsOn: aStream 
	"Write a description of the receiver onto aStream."

	self allInstances do: [:aProject | aProject putStatsOn: aStream]! !

Project initialize!

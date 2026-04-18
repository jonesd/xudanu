'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:03 pm'!

ChangeRecord subclass: #SetUserCR
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!SetUserCR methodsFor: 'creation'!

create: recorder {ChangeRecorder}
	super create: recorder.
	self link: #USER! !
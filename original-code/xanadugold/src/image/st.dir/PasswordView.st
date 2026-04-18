'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:45 pm'!

TextView subclass: #PasswordView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!



!PasswordView methodsFor: 'updating'!

update: aspect 
	aspect == #login
		ifTrue: [self controller accept]
		ifFalse: [super update: aspect]! !
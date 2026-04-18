'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:36 pm'!

StandardSystemView subclass: #LabelSystemView
	instanceVariableNames: '
		aspect {UNKNOWN}
		aspectMessage {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!



!LabelSystemView methodsFor: 'updating'!

update: aSymbol 
	aSymbol == aspect
		ifTrue: [self newLabel: (model perform: aspectMessage).
		self displaySafe: [self displayView]]! !
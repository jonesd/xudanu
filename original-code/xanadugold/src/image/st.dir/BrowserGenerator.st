'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:25 pm'!

Object subclass: #BrowserGenerator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!BrowserGenerator methodsFor: 'accessing'!

{BooleanVar} hasNextBrowser

	self subclassResponsibility!

{NOWAIT} nextBrowserFrom: aBrowser {MethodSetBrowser}

	self subclassResponsibility! !
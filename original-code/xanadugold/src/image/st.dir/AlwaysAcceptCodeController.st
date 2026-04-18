'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:42 pm'!

CodeController subclass: #AlwaysAcceptCodeController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
AlwaysAcceptCodeController comment:
'An alwaysAcceptCodeController is a code controller that will do an accept even if the text is the same.'!


!AlwaysAcceptCodeController methodsFor: 'menu messages'!

accept
	(model changeRequestFrom: view)
		ifFalse: [^view flash].
	self controlTerminate.
	(view accept: self text from: self)
		ifTrue: [initialText _ paragraph text copy]
		ifFalse: [view flash].
	self controlInitialize! !
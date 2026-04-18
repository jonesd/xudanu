'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:20 pm'!

StringHolderView subclass: #TextCollectorView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Transcript'!
TextCollectorView comment:
'A TextCollectorView is a StringHolderView of the description of the contents of a TextCollector or Transcript.  TextCollectorController is the default controller.'!


!TextCollectorView methodsFor: 'updating'!

update: aParameter 
	self topView isCollapsed ifTrue: [model appendEntry].
	(self controller isKindOf: TextCollectorController)
		ifTrue: 
			[aParameter == #appendEntry 
				ifTrue: [^controller appendEntry].
			aParameter == #update 
				ifTrue: [^controller changeText: model contents asText].
			aParameter == #refresh
				ifTrue:	[^controller viewToTop]]! !

!TextCollectorView methodsFor: 'controller access'!

defaultControllerClass
	^TextCollectorController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextCollectorView class
	instanceVariableNames: ''!


!TextCollectorView class methodsFor: 'instance creation'!

open
	"Answer an instance of me on a new TextCollector.  Schedule it."
	^self open: TextCollector new label: 'TextCollector'!

open: aTextCollector label: aString 
	"Answer an instance of me on the argument, aTextCollector.  The
	label of the StandardSystemView should be aString."

	| topView aView |
	topView _ StandardSystemView new.
	topView model: aTextCollector.
	topView label: aString.
	topView minimumSize: 160 @ 120.
	aView _ self new model: aTextCollector.
	aView insideColor: Form white.
	aView borderWidth: 1.
	topView borderWidth: 1.
	topView addSubView: aView.
	topView icon: (Icon constantNamed: #default).
	topView controller open! !
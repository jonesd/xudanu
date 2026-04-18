'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:54 pm'!

Change subclass: #ClassRelatedChange
	instanceVariableNames: 'className '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
ClassRelatedChange comment:
'Class ClassRelatedChange represents a change related in some way to a particular class.

Instance Variables:
	className	<Symbol>'!


!ClassRelatedChange methodsFor: 'accessing'!

className
	^className!

className: aSymbol
	className _ aSymbol asSymbol!

classObject
	| class |
	^Smalltalk at: className ifAbsent:
		[(className size > 6 and: [(className copyFrom: className size - 5 to: className size) = ' class'])
			ifTrue:
				[class _ Smalltalk at: (className copyFrom: 1 to: className size - 6) asSymbol ifAbsent: [^nil].
				class isBehavior ifTrue: [class class] ifFalse: [nil]]
			ifFalse:
				[nil]]!

getSource
	"Set me up to point to the version of this change which is currently installed in the system."
	self subclassResponsibility!

parameters
	^className! !
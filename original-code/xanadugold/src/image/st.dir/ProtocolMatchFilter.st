'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:50 pm'!

MethodFilter subclass: #ProtocolMatchFilter
	instanceVariableNames: 'myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ProtocolMatchFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Of Protocols matching ''', myPattern, ''''!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^myPattern match: (cls organization getCategoryOfElement: sel)! !

!ProtocolMatchFilter methodsFor: 'creation'!

create: pattern {String}
	
	super create.
	myPattern _ pattern! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProtocolMatchFilter class
	instanceVariableNames: ''!



!ProtocolMatchFilter class methodsFor: 'creation'!

make: pattern {String}

	^self create: pattern! !
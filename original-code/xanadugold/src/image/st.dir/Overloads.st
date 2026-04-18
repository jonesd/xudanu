'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:49 pm'!

MethodFilter subclass: #Overloads
	instanceVariableNames: 'myOverloads {Set of: MethodRep}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!Overloads methodsFor: 'creation'!

create: meths {Collection of: MethodRep}

	| trunks {Set of: MethodRep} |
	trunks _ Set new. 
	myOverloads _ Set new.
	meths do: [:rep {MethodRep} |
		| trunk {MethodRep} |
		trunk _ MethodRep asTranslated: rep.
		(trunks includes: trunk)
			ifTrue: [myOverloads add: trunk]
			ifFalse: [trunks add: trunk]]! !

!Overloads methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		each isKindOf: MethodNode]!

{String} label
	
	^'Overloads'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^myOverloads includes: (MethodRep asTranslated: cls with: sel)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Overloads class
	instanceVariableNames: ''!



!Overloads class methodsFor: 'creation'!

make: meths {Collection of: MethodRep}

	^self create: meths! !
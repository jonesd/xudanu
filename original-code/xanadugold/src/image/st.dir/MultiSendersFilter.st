'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:46 pm'!

MethodFilter subclass: #MultiSendersFilter
	instanceVariableNames: '
		myGen {GenerateMethods}
		myChangeTable {IdentityDictionary of: Symbol with: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!MultiSendersFilter methodsFor: 'creation'!

create: changes {IdentityDictionary of: Symbol with: Symbol}
	with: gen {GenerateMethods default: nil} 

	super create.
	myChangeTable _ changes.
	myGen _ gen! !

!MultiSendersFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
		
	^MethodAction 
		combine: (SendersAction make: myChangeTable)
		with: (LiteralsAction make: myChangeTable)!

{MethodFilter | nil} fetchWithReplacer

	self unimplemented!

{String} label
	
	myGen == nil
		ifTrue: [^'Senders of any in set']
		ifFalse: [^'Senders of any in ', myGen label]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	code messages do: [:sel2 {Symbol} |
		(myChangeTable includesKey: sel2)
			ifTrue: [^true]].
	code literalSymbols do: [:sel2 {Symbol} |
		(myChangeTable includesKey: sel2)
			ifTrue: [^true]].
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiSendersFilter class
	instanceVariableNames: ''!



!MultiSendersFilter class methodsFor: 'creation'!

make.Collection: messages {(Collection of: Symbol) | nil}
	with: gen {GenerateMethods default: nil} 

	| changes {IdentityDictionary of: Symbol with: Symbol} |
	(gen ~~ nil or: [messages ~~ nil]) assert.
	changes _ IdentityDictionary new.
	(messages == nil
			ifTrue: [gen methodReps collect: [:mr {MethodRep} | mr selector]]
			ifFalse: [messages]) 
		do: [:sel {Symbol} |
			changes at: sel put: sel].
	^self make: changes with: gen!

make.IdentityDictionary: changes {IdentityDictionary of: Symbol with: Symbol}
	with: gen {GenerateMethods default: nil} 

	^self create: changes with: gen! !

!MultiSendersFilter class methodsFor: 'smalltalk: defaults'!

make: t1 

	^self make: t1 with: nil!

make: t1 with: t2

	(t1 isKindOf: IdentityDictionary)
		ifTrue: [^self make.IdentityDictionary: t1 with: t2]
		ifFalse: [^self make.Collection: t1 with: t2]! !
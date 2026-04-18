'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:29 pm'!

Heaper subclass: #ProtocolItem
	instanceVariableNames: '
		myName {char star}
		myNext {ProtocolItem}
		myItem {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-negoti8'!

(ProtocolItem getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ProtocolItem methodsFor: 'accessing'!

{Heaper} get: name {char star}
	(String strcmp: name with: myName) == Int32Zero ifTrue:
		[ ^ myItem ].
	myNext ~~ NULL
		ifTrue: [ ^ myNext get: name ]
		ifFalse: [ Heaper BLAST: #NotInList ].
	^NULL "fodder"! !

!ProtocolItem methodsFor: 'create'!

create: name {char star} with: item {Heaper} with: next {ProtocolItem} 
	super create.
	myName _ name.
	myItem _ item.
	myNext _ next! !
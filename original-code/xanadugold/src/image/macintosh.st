'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:40:57 pm'!

((CxxSystemOrganization tree childNamed: 'macintosh') ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: 'macintosh') destroyFiles]!

Heaper subclass: #CStruct
	instanceVariableNames: 'fieldDict {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MacApp emulation'!

(CStruct getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CStruct methodsFor: 'smalltalk: smalltalk accessing'!

{Heaper} ARROW: fieldName {Symbol}

	^ fieldDict at: fieldName ifAbsent: [self error: ('Field ', fieldName, ' not found in ', self class name)]!

{Heaper} ARROW: fieldName {Symbol} put: value {Heaper} 
	(self class fieldNames includes: fieldName)
		assert: 'fieldName ' , fieldName , ' not in struct ' , self class name.
	^fieldDict at: fieldName put: value!

{Heaper} DOT: fieldName {Symbol}

	^ fieldDict at: fieldName ifAbsent: [self error: ('Field ', fieldName, ' not found in ', self class name)]!

{Heaper} DOT: fieldName {Symbol} put: value {Heaper} 
	(self class fieldNames includes: fieldName)
		assert: 'fieldName ' , fieldName , ' not in struct ' , self class name.
	^fieldDict at: fieldName put: value! !

!CStruct methodsFor: 'test'!

{void} test
	| nigit {cooper struct var} |
	self ARROW: #testing.
	#blah DOT: #anyThing.
	nigit _ CStruct create.
	nigit DOT: #blarg put: (self ARROW: #nothing).
	(nigit DOT: #pBlarney) ARROW: #blarney put: (self ARROW: #fulsome)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!


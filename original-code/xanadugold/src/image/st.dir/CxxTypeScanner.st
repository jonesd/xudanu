'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:26 pm'!

CxxTranslator subclass: #CxxTypeScanner
	instanceVariableNames: '
		myTypeRefs {Set of: CxxClassDescription}
		myCxxCd {CxxClassDescription}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxTypeScanner methodsFor: 'protected:'!

{void} addTypeRef: type {Symbol} 

	""

	| cls {Class} cxc {CxxClassDescription} |
	(#(UInt4 UInt1 Int4 Int1 UInt32 UInt8 Int32 Int8 void Category UNKNOWN IntegerVar BooleanVar IEEEDoubleVar Integer) includes: type)
			ifTrue: [^VOID].
	((Smalltalk includesKey: type) not
	  or: [(cls _ Smalltalk at: type) isBehavior not
	  or: [(cxc _ cls fetchCxxClassDescription) == nil
	  or: [cxc fetchModuleName = 'tofu'
	  or: [(myCxxCd fetchGroup hasSubclassOf: cxc)
	  or: [myCxxCd fetchGroup = cxc fetchGroup
	  or: [(cxc fetchCxxModule = myCxxCd fetchCxxModule and: [cxc visibility == #public])]]]]]])
			ifTrue: [^VOID].
	(myCxxCd fetchGroup mustBeAllowedToSee: cls)
		ifTrue: [myTypeRefs add: cxc]!

{void} computeReferences: string {String} 
	string tokensDo: 
		[:intok | 
		intok isEmpty not
			ifTrue: 
				[| tok |
				tok _ intok.
				tok = 'integer' ifTrue: [tok _ #XnInteger].
				tok = 'defineFluid' ifTrue: [tok _ #Emulsion]. "so that fluidx.oxx is included."
				(tok last == $0 and: [tok size > 1]) 
					ifTrue: [tok _ tok copyFrom: 1 to: tok size - 1].
				tok first isUppercase 
					ifTrue: [self addTypeRef: tok asSymbol]]]! !

!CxxTypeScanner methodsFor: 'translating'!

{void} beginClass: cxc {CxxClassDescription}

	super beginClass: cxc.
	myCxxCd _ cxc.!

{void} beginGroup: group {CxxClassGroup}

	super beginGroup: group.
	myTypeRefs _ IdentitySet new!

{void} endClass: cxc {CxxClassDescription}

	myCxxCd _ nil.
	super endClass: cxc!

{BooleanVar} startInitializerTree: cxc {CxxClassDescription} 
	with: cls {Behavior}
	sel: sel {Symbol}

	^false!

{BooleanVar} startSelectorTree: cxc {CxxClassDescription}
	with: cls {Behavior}
	sel: sel {Symbol}

	^false! !

!CxxTypeScanner methodsFor: 'creation'!

create
	
	super create.
	myTypeRefs _ nil.
	myCxxCd _ nil! !
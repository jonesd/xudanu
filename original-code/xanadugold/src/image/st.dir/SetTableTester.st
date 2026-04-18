'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:07 pm'!

Tester subclass: #SetTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(SetTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SetTableTester methodsFor: 'tests'!

{void} allTestsOn: oo {ostream reference}
	self simpleAccess: oo.
	self test1on: oo.
	self growTestOn: oo.
	self growTest2On: oo.
	self stepTestOn: oo.!

{void} growTest2On: oo {ostream reference}

	| tab {SetTable} keyPile {ScruSet} valuePile {ScruSet} oc {IntegerVar} |
	
	keyPile _ self testKeys.
	valuePile _ self testValues.
	oo << 'start of grow test 2, add key->value associations in a different order
'.
	
	tab _ SetTable make: self testCS.
	oc _ IntegerVar0.
	valuePile stepper forEach: [:val {Heaper} |
		keyPile stepper forEach: [:key {Position} |
			tab count = oc ifFalse: [oo << 'table count wrong before store!! ' << tab << '
'].
			tab at: key introduce: val.
			oc _ oc + 1.
			tab count = oc ifFalse: [oo << 'table count wrong after store!!  ' << tab << '
'].
			(tab count = (self manualCount: tab)) 
				ifFalse: [oo << 'manual count doesn''t match count!!  ' << tab << '
']]].
	oo << 'end of grow test 2, table now:
' << tab << '

now - remove all those entries, use a different order than the introduce order
'.

	keyPile stepper forEach: [:key2 {Position} |
		valuePile stepper forEach: [:val2 {Heaper} |
			tab count = oc ifFalse: [oo << 'table count wrong before remove!! ' << tab << '
'].
			tab remove: key2 with: val2.
			oc _ oc - 1.
			tab count = oc ifFalse: [oo << 'table count wrong after remove!!  ' << tab << '
'].
			(tab count = (self manualCount: tab)) 
				ifFalse: [oo << 'manual count doesn''t match count!!  ' << tab << '
']]].

	oo << '
end of remove test. ta ta!!
'!

{void} growTestOn: oo {ostream reference}

	| tab {SetTable} keyPile {ScruSet} valuePile {ScruSet} oc {IntegerVar} |
	
	keyPile _ self testKeys.
	valuePile _ self testValues.
	oo << 'start of grow test, keys =
' << keyPile << '
and values = ' << valuePile << '
'.
	
	tab _ SetTable make: self testCS.
	oc _ IntegerVar0.
	keyPile stepper forEach: [:key {Position} |
		valuePile stepper forEach: [:val {Heaper} |
			tab count = oc ifFalse: [oo << 'table count wrong before store!! ' << tab << '
'].
			tab at: key introduce: val.
			oc _ oc + 1.
			tab count = oc ifFalse: [oo << 'table count wrong after store!!  ' << tab << '
'].
			(tab count = (self manualCount: tab)) 
				ifFalse: [oo << 'manual count doesn''t match count!!  ' << tab << '
']]].
	oo << 'end of grow test, table now:
' << tab << '

and the domain is: ' << tab domain << '

now - remove all those entries!!
'.

	keyPile stepper forEach: [:key2 {Position} |
		valuePile stepper forEach: [:val2 {Heaper} |
			tab count = oc ifFalse: [oo << 'table count wrong before remove!! ' << tab << '
'].
			tab remove: key2 with: val2.
			oc _ oc - 1.
			tab count = oc ifFalse: [oo << 'table count wrong after remove!!  ' << tab << '
'].
			(tab count = (self manualCount: tab)) 
				ifFalse: [oo << 'manual count doesn''t match count!!  ' << tab << '
']]].

	oo << '
end of remove test. ta ta!!
'!

{void} simpleAccess: oo {ostream reference}
	| tab {SetTable} |
	tab _ SetTable make: IntegerSpace make.
	oo << 'Introduce I(2) at I(1).
'.
	tab at: 1 integer introduce: 2 integer.
	oo << 'Retrieve all from 1: 
'.
	(tab stepperAtInt: 1) forEach:
		[:elem {Heaper} | oo << '	' << elem << '
'].
	oo << '
'.
	oo << 'Introduce I(2) at I(1) again and catch the blast.
'.
	(MuTable problems.AlreadyInTable)
		handle: [:ex | oo << 'Blasted while introducing.

'.				ex return]
		do: [tab at: 1 integer introduce: 2 integer.
			oo << 'Should have blasted on second introduce.
'].

	oo << 'Store I(3) at 1.
'.
	tab atInt: 1 store: 3 integer.
	oo << 'Retrieve all from I(1): 
'.
	(tab stepperAt: 1 integer) forEach:
		[:elem2 {Heaper} | oo << '	' << elem2 << '
'].
	oo << '
'.
	oo << 'Store I(4) at 1.
'.
	tab atInt: 1 store: 4 integer.
	oo << 'Retrieve all from 1: 
'.
	(tab stepperAtInt: 1) forEach:
		[:elem3 {Heaper} | oo << '	' << elem3 << '
'].
	oo << '
'.
	oo << 'Table is now: ' << tab << '
Remove I(3) at I(1).
'.
	tab remove: 1 integer with: 3 integer.
	oo << 'Table is now: ' << tab << '

'.!

{void} stepTestOn: oo {ostream reference}
	| stepr {Stepper} keyPile {ScruSet of: Position} valuePile {ScruSet of: Heaper} 
	 tab {SetTable} |
	oo << 'Test fetching of steppers (stepper at a key).
'.
	keyPile _ self testKeys.
	valuePile _ self testValues.
	tab _ SetTable make: self testCS.
	keyPile stepper forEach: [:key {Position} |
		valuePile stepper forEach: [:val {Heaper} |
			tab at: key introduce: val]].
	keyPile stepper forEach: [:key2 {Position} | | valSet {MuSet} |
		valSet _ self testValues asMuSet.
		stepr _ tab stepperAt: key2.
		oo << 'stepper for key ' << key2 << ' is ' << stepr << '
'.
		stepr forEach: [:val3 {Heaper} |
			valSet remove: val3].
		valSet isEmpty not ifTrue: [oo << 'valSet contains ' << valSet << '
']].

	oo << 'end of stepperAt: test

'.!

{void} test1on: oo {ostream reference}

	| tab1 {SetTable} stp {TableStepper} |
	
	tab1 _ SetTable make: IntegerSpace make.
	oo << 'table is now ' << tab1 << '
'.
	tab1 at: 1 integer store: (Sequence string: 'abcd').
	tab1 at: 1 integer store: (Sequence string: 'abce').
	tab1 at: 1 integer store: (Sequence string: 'abcf').
	tab1 at: 1 integer store: (Sequence string: 'abcg').
	tab1 at: 1 integer store: (Sequence string: 'abch').
	tab1 at: 1 integer store: (Sequence string: 'abci').
	oo << 'tab1 is now ' << tab1 << '
'.
	tab1 at: 2 integer store: (Sequence string: 'abcd').
	tab1 at: 2 integer store: (Sequence string: 'abce').
	tab1 at: 2 integer store: (Sequence string: 'abcf').
	tab1 at: 2 integer store: (Sequence string: 'abcg').
	tab1 at: 2 integer store: (Sequence string: 'abch').
	tab1 at: 2 integer store: (Sequence string: 'abci').
	oo << 'tab1 is now ' << tab1 << '
'.
	tab1 at: 3 integer store: (Sequence string: 'abcd').
	tab1 at: 3 integer store: (Sequence string: 'abce').
	tab1 at: 3 integer store: (Sequence string: 'abcf').
	tab1 at: 3 integer store: (Sequence string: 'abcg').
	tab1 at: 3 integer store: (Sequence string: 'abch').
	tab1 at: 3 integer store: (Sequence string: 'abci').
	oo << 'tab1 is now ' << tab1 << '
'.
	oo << '
contents of table are:
'.
	(stp _ tab1 stepper) forEach: [:elem {Heaper} | 
		oo << 'tab1 fetch: ' << stp position << ' == ' << elem << '
']! !

!SetTableTester methodsFor: 'private: testing'!

{IntegerVar} lastTestValue

	^ 9!

{IntegerVar} manualCount: table {SetTable}

	| cnt {IntegerVar} |
	cnt _ IntegerVar0.
	
	table stepper forEach: [:elem {Heaper} |
		elem ~~ NULL ifTrue: [cnt _ cnt + 1]]. "kill st80 'elem not used' msg"
	^ cnt!

{CoordinateSpace} testCS
	^ SequenceSpace make!

{ScruSet of: Position} testKeys

	| keys {MuSet of: Position} |
	
	keys _ MuSet make.
	keys introduce: (Sequence string: 'fghijklmna').
	keys introduce: (Sequence string: 'fghijklmnb').
	keys introduce: (Sequence string: 'fghijklmnc').
	keys introduce: (Sequence string: 'fghijklmnd').
	keys introduce: (Sequence string: 'fghijklmne').

	keys introduce: (Sequence string: 'fghijklmao').
	keys introduce: (Sequence string: 'fghijklmbo').
	keys introduce: (Sequence string: 'fghijklmco').
	keys introduce: (Sequence string: 'fghijklmdo').
	keys introduce: (Sequence string: 'fghijklmeo').

	keys introduce: (Sequence string: 'fghijklano').
	keys introduce: (Sequence string: 'fghijklbno').
	keys introduce: (Sequence string: 'fghijklcno').
	keys introduce: (Sequence string: 'fghijkldno').
	keys introduce: (Sequence string: 'fghijkleno').

	keys introduce: (Sequence string: 'fghijkamno').
	keys introduce: (Sequence string: 'fghijkbmno').
	keys introduce: (Sequence string: 'fghijkcmno').
	keys introduce: (Sequence string: 'fghijkdmno').
	keys introduce: (Sequence string: 'fghijkemno').

	keys introduce: (Sequence string: 'fghijalmno').
	keys introduce: (Sequence string: 'fghijblmno').
	keys introduce: (Sequence string: 'fghijclmno').
	keys introduce: (Sequence string: 'fghijdlmno').
	keys introduce: (Sequence string: 'fghijelmno').

	keys introduce: (Sequence string: 'fghiaklmno').
	keys introduce: (Sequence string: 'fghibklmno').
	keys introduce: (Sequence string: 'fghicklmno').
	keys introduce: (Sequence string: 'fghidklmno').
	keys introduce: (Sequence string: 'fghieklmno').

	keys introduce: (Sequence string: 'fghajklmno').
	keys introduce: (Sequence string: 'fghbjklmno').
	keys introduce: (Sequence string: 'fghcjklmno').
	keys introduce: (Sequence string: 'fghdjklmno').
	keys introduce: (Sequence string: 'fghejklmno').

	keys introduce: (Sequence string: 'fgaijklmno').
	keys introduce: (Sequence string: 'fgbijklmno').
	keys introduce: (Sequence string: 'fgcijklmno').
	keys introduce: (Sequence string: 'fgdijklmno').
	keys introduce: (Sequence string: 'fgeijklmno').

	keys introduce: (Sequence string: 'fahijklmno').
	keys introduce: (Sequence string: 'fbhijklmno').
	keys introduce: (Sequence string: 'fchijklmno').
	keys introduce: (Sequence string: 'fdhijklmno').
	keys introduce: (Sequence string: 'fehijklmno').

	keys introduce: (Sequence string: 'aghijklmno').
	keys introduce: (Sequence string: 'bghijklmno').
	keys introduce: (Sequence string: 'cghijklmno').
	keys introduce: (Sequence string: 'dghijklmno').
	keys introduce: (Sequence string: 'eghijklmno').

	^ keys!

{ScruSet of: Heaper} testValues

	| vals {MuSet of: IntegerPos} |
	
	vals _ MuSet make.
	
	IntegerVar0 to: self lastTestValue do: [:ti {IntegerVar} |
		vals introduce: (ti integer)].
	^ vals! !

!SetTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
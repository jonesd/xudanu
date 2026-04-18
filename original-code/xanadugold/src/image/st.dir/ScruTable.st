'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:02 pm'!

Heaper subclass: #ScruTable
	instanceVariableNames: ''
	classVariableNames: '
		NotInTableSignal {Signal smalltalk} 
		WrongCoordSpaceSignal {Signal smalltalk} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
ScruTable comment:
'Please read class comment for ScruSet first.
	
	Like Sets, Tables represent collections of Heapers, and provide protocol for storing, retrieving, and iterating over the collection.  However, Tables in addition provide an organization for the Heapers collected together in the range of a Table:  A Table can also be seen as a collection of associations between keys and values.  A particular Table object has a particular domain coordinateSpace, and all keys in that Table are positions in that coordinate space.  For each position in a Table''s coordinate space there is at most one value which it maps to.  This value may be any arbitrary Heaper.  The same Heaper may appear as value for several keys. 
	
	When iterating over the contents of a Table with a Stepper, the normal elements enumerated by the Stepper are values (i.e., range elements) of the Table.  However, ScruTable::stepper returns a TableStepper (a subclass of Stepper) which provides aditional protocol of accessing the key corresponding to the current value.  (see ScruTable::stepper and TableStepper.)'!

(ScruTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ScruTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	"The kind of elements used to index into the table are Positions of this 
	coordinate space. Therefore, the domain of this table is an XuRegion in this 
	coordinate space."

	self subclassResponsibility!

{IntegerVar} count
	"Return the number of domain elements, which is to say, the number of associations.
	'table->count()' should be equivalent to 'table->domain()->count()'.
	
	Used to say: 'Return the number of range elements'.  This seems clearly wrong."
	
	self subclassResponsibility.!

{XnRegion} domain
	"Return an XuRegion representing a snapshot of the current domain.  
	'table->domain()->hasMember(p)' iff 'table->fetch(p) !!= NULL'."

	self subclassResponsibility.!

{Heaper} fetch: key {Position} 
	"Return the range element at the domain position key. The routine will return 
	NULL if the position is not in the table."

	self subclassResponsibility!

{Heaper} get: key {Position} 
	"Return the range element at the domain position key. BLAST if the position is 
	not in the table."

	| tmp {Heaper wimpy} |
	tmp _ self fetch: key.
	tmp == NULL ifTrue: [Heaper BLAST: #NotInTable.
		^NULL].
	^tmp!

{ImmuSet of: Heaper} range
	"A snapshot of the current range elements of the table collected together into 
	an ImmuSet."

	| acc {SetAccumulator} |
	acc _ SetAccumulator make.
	self stepper forEach: [:obj {Heaper} | acc step: obj].
	^acc value cast: ImmuSet!

{ScruTable} subTable: region {XnRegion} 
	"Return a table which contains only the intersection of this table's domain and 
	the domain specified by 'region'. 
	table->subTable(r)->domain()->isEqual( table->domain()->intersect(r) ). 
	
	It is unspecified whether the resulting table starts as a snapshot of a subset of 
	me, after which we go our own ways; or whether the resulting table is a view 
	onto a subset of me, such that changes to me are also visible to him. Of 
	course, subclasses may specify more. If you want to ensure snapshot behavior, 
	do 'table->subTable(r)->asImmuTable()'. 
	
	NOTE: In the future we may specify snapshot behavior or we may specify view 
	behavior. As a client this shouldn't effect you. However, if you implement a 
	new kind of ScruTable, please let us know. Also, if you have an opinion as to 
	which way you'd like the specification tightened up, please tell us."

	self subclassResponsibility!

{ScruTable} transformedBy: dsp {Dsp} 
	"Return a ScruTable with the domain of the receiver transformed by the Dsp. 
	'table->transformedBy(d)->fetch(p)' is equivalent to 
	'table->fetch(d->of(p))'. 
	
	See ScruTable::subTable for caveats regarding whether we return a snapshot 
	or a view. All the same caveats apply."

	^ OffsetScruTable create: self with: dsp! !

!ScruTable methodsFor: 'testing'!

{UInt32} actualHashForEqual
	"See ScruTable::isEqual"

	self subclassResponsibility!

{BooleanVar} contentsEqual: other {ScruTable}
	"Returns whether the two ScruTables have exactly the same mapping from 
	keys to values at the moment. 'a->contentsEqual(b)' is equivalent to 
	'a->asImmuTable()->isEqual(b->asImmuTable())'. See ScruTable::contentsEqual"

	| myStepper {TableStepper} otherValue {Heaper} |
	(other count ~= self count) ifTrue: [^false].
	(other coordinateSpace isEqual: self coordinateSpace) ifFalse: [^false].
	myStepper _ self stepper.
	[myStepper hasValue] whileTrue:
		[otherValue _ other fetch: myStepper position.
		otherValue == NULL ifTrue: [^false].
		(otherValue isEqual: myStepper fetch) ifFalse: [^false].
		myStepper step].
	^true!

{UInt32} contentsHash
	"Has the same relationship to contentsEqual that hashForEqual has to isEqual. 
	I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == b->contentsHash()'. 
	The same complex caveats apply as to the stability and portability of the 
	hash values as apply for hashForEqual.  See ScruSet contentsHash."

	| dom {XnRegion} |
	dom _ self domain.
	dom isEmpty
		ifTrue: [^self coordinateSpace hashForEqual*17]
		ifFalse: [dom
			cast: IntegerRegion into: [ :ints |
				^ints start DOTasLong
				+ ints stop DOTasLong
				+ self count DOTasLong
				+ self coordinateSpace hashForEqual]
			others:
				[^self count DOTasLong 
				+ self coordinateSpace hashForEqual]].
	^UInt32Zero "fodder"!

{BooleanVar} includesKey: key {Position}
	"includesKey is used to test for the presence of a key->value pair in the
	table.  This routine returns true if there is a value present at the specified
	key, and false otherwise.
	'table->includesKey(p)' iff 'table->domain()->hasMember(p)'."

	^ (self fetch: key) ~~ NULL!

{BooleanVar} isEmpty
	"Is there anything in the table? 
	'table->isEmpty()' iff 'table->domain()->isEmpty()'."

	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	"All MuTable subclasses have equality based on identity 
	(now and forever equal. Many ScruTable subclasses will 
	represent an aspect of another table. Therefore they have 
	hashForEqual and isEqual: based on both their contained 
	table, and the aspect that they represent. Thus, two similar 
	views onto the same MuTable are now (and forever) equal. 
	The hashForEqual: must use exactly the same aspects for 
	the hash as get used for isEqual:. ImmuTables all use 
	contentBased comparison operations."
	
	self subclassResponsibility! !

!ScruTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	"Return a TableStepper which will enumerate my key->value mappings. The 
	Stepper component of the TableStepper protocol will just enumerate my values 
	(as that is what I'm a container *of*--the keys are simply how I organize my 
	contents). TableStepper provides additional protocol to ascetain the current 
	key. See TableStepper and XuRegion::stepper. The TableStepper I produce given 
	an order must enumerate keys according to the same rules which specify how 
	XuRegion::stepper must enumerate positions. I am not asserting that the actual 
	orders are the same, only that the correctness criteria on the allowable orders 
	are the same. 
	
	Keeping in mind that we are talking about equivalence of specification 
	and not equivalence of particular behavior, the following two statements 
	are equivalent: 

	{
		SPTR(TableStepper) stomp = table->stepper(o);
		SPTR(Position) key;
		FOR_EACH(Heaper,val,stomp, {
			key = stomp->key();
			doSomethingWith(key, val);
		});
	}
	
	and
	
	{
		SPTR(Heaper) val;
		SPTR(ImmuTable) snapShot = table->asImmuTable();
		FOR_EACH(Position,key,(snapShot->domain()->stepper(o)), {
			val = snapShot->get (key);
			doSomethingWith(key, val);
		});
	}
			
	"

	self subclassResponsibility!

{Heaper} theOne
	"Iff I contain exactly one range element, return it.  Otherwise BLAST.
	The idea for this message is taken from the THE function of ONTIC
	(reference McAllester)"

	| stepper {TableStepper} result {Heaper} |
	self count ~~ 1 ifTrue:
		[ Heaper BLAST: #NotOneElement ].
	stepper _ self stepper.
	result _ stepper fetch.
	stepper destroy.
	^ result! !

!ScruTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable
	"Return a side-effect-free snapshot of my current contents.
	See ScruSet::asImmuSet."

	self subclassResponsibility!

{MuTable} asMuTable
	"Return a side-effectable version of the same table.
	See ScruSet::asMuSet."

	self subclassResponsibility! !

!ScruTable methodsFor: 'smalltalk: backfollow'!

{ScruTable} backfollowFrom: value {Heaper} 
	"Return the subTable with the domain of all positions whose values are equal to 
	value.  Defined by analogy with corresponding Waldo-level operation."
	self unimplemented.
	"value == NULL
		ifTrue: [^self]
		ifFalse: [^BackfollowTable create: self with: value]"! !

!ScruTable methodsFor: 'printing'!

{void} printOn: stream {ostream reference}
	stream << self getCategory name.
	self printOnWithSimpleSyntax: stream with: '(' with: ', ' with: ')'!

{void} printOnWithSimpleSyntax: oo {ostream reference} 
	with: open {char star} 
	with: sep {char star} 
	with: close {char star}
	"Print the contents of the table as
	<open> key1 ""->"" value1 <sep> key2 ""->"" value2 <sep> ... <sep> keyN ""->"" valueN <close>.
	For example, 'table->printOnWithSyntax(oo, ""{"", "", "", ""}"");' may result in
	'{3->Foo(), 5->Bar()}'.
	
	One wierd but convenient special case: if the domain space is an IntegerSpace, 
	we print the keys according to the way IntegerVars print, not the way 
	XuIntegers print.
	
	For yet more fine-grained control over printing, see the ScruTable::printOnWithSyntax 
	with 5 arguments."
	
	self printOnWithSyntax: oo
		with: open
		with: '->'
		with: sep
		with: close.!

{void} printOnWithSyntax: stream {ostream reference} 
	with: open {char star} 
	with: map {char star} 
	with: sep {char star} 
	with: close {char star} 
	"Print the contents of the table as 
	<open> key1 <map> value1 <sep> key2 <map> value2 
	<sep> ... <sep> keyN <map> valueN <close>. 
	For example, 'table->printOnWithSyntax(oo, ""{"", 
	""=>"", "", "", ""}"");' may result in 
	'{3=>Foo(), 5=>Bar()}'. 
	
	One wierd but convenient special case: if the 
	domain space is an IntegerSpace, 
	we print the keys according to the way IntegerVars 
	print, not the way 
	XuIntegers print."

	| stomp {TableStepper} |
	stream << open.
	self isEmpty ifFalse:
		[stomp _ self stepper.
		[stomp hasValue]
			whileTrue: 
				[stomp position 
					cast: IntegerPos into: [:xui |
						stream << xui asIntegerVar]
					others: [stream << stomp position].
				stream << map << stomp fetch.
				stomp step.
				stomp hasValue ifTrue: [stream << sep]].
		stomp destroy].
	stream << close! !

!ScruTable methodsFor: 'runs'!

{XnRegion} runAt: key {Position} 
	"Return the length of the run starting at position key. A run is defined as a 
	contiguous (charming) sequence of domain positions mapping to equal (isEqual) 
	objects. Charming is defined as: Given a charming region R, for all a,c which 
	are elements of R and a >= b >= c, b is an element of R. Where '>=' is 
	according to the 'isGE' message. 
	
	NOTE: We may retire the above definition of charming. The possible changes 
	will only effect spaces which aren't fully ordered. OrderedRegions, 
	TreeRegions, and IntegerRegions will be unaffected, as any future definition of 
	'runAt' will be equivalent for them."

	self subclassResponsibility! !

!ScruTable methodsFor: 'creation'!

{ScruTable} copy
	"A new one whose initial state is my current state, but that doesn't track 
	changes. Note that there is no implication that these can be 'destroy'ed 
	separately, because (for example) an ImmuTable just returns itself"

	self subclassResponsibility!

{ScruTable} emptySize: size {IntegerVar} 
	"Return an empty table just like the current one. The 'size' argument is a hint 
	about how big the count of the table will probably become (so that the new 
	table can be prepared to grow to that size efficiently)."

	self subclassResponsibility! !

!ScruTable methodsFor: 'protected: creation'!

create
	super create! !

!ScruTable methodsFor: 'overloads'!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"

	^self includesKey: aKey integer!

{Heaper} intFetch: key {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"

	^ self fetch: key integer!

{Heaper} intGet: key {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"
	| tmp {Heaper wimpy} |
	tmp _ self intFetch: key.
	tmp == NULL ifTrue: [Heaper BLAST: #NotInTable.
		^NULL].
	^tmp!

{XnRegion} runAtInt: key {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"

	^ self runAt: key integer! !

!ScruTable methodsFor: 'smalltalk: enumerating'!

stepper
	"implement default argument of NULL"
	^self stepper: NULL! !

!ScruTable methodsFor: 'smalltalk: special'!

asOrderedCollection
	"convert for use with Smalltalk MVC stuff"

	| stomp {TableStepper} res {OrderedCollection} |
	res _ OrderedCollection new: self count.
	stomp _ self stepper.
	[stomp hasValue]
		whileTrue: [res add: stomp get.
			stomp step].
	^res.!

{void} do: aBlock {BlockClosure of: Heaper}

	self stepper forEach: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScruTable class
	instanceVariableNames: ''!

(ScruTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ScruTable class methodsFor: 'exceptions: exceptions'!

problems.NotInTable
	^self signals: #(NotInTable)! !
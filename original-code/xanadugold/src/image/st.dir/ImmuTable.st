'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:55 pm'!

ScruTable subclass: #ImmuTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
ImmuTable comment:
'ImmuTable are to ScruTables much like ImmuSets are to ScruSets.  See ImmuSet.
	
	The ImmuTable subclass of tables represents all tables which CANNOT be side-effected during operations on them.  They are intended to represent mathematical abstractions (such as vectors) and are intended to be used in a functional-programming style.  Operations are provided for building new ImmuTables out of old ones.'!

(ImmuTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ImmuTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	self subclassResponsibility!

{IntegerVar} count

	self subclassResponsibility.!

{XnRegion} domain

	self subclassResponsibility.!

{Heaper} fetch: key {Position} 

	self subclassResponsibility!

{Heaper} intFetch: key {IntegerVar}
	^ super intFetch: key!

{XnRegion} runAt: key {Position} 

	self subclassResponsibility!

{XnRegion} runAtInt: key {IntegerVar}
	^ super runAtInt: key!

{ScruTable} subTable: reg {XnRegion} 

	self subclassResponsibility!

{ScruTable} transformedBy: dsp {Dsp} 
	"Return a ScruTable with the domain of the receiver transformed by the Dsp. 
	'table->transformedBy(d)->fetch(p)' is equivalent to 
	'table->fetch(d->of(p))'. 
	
	See ScruTable::subTable for caveats regarding whether we return a snapshot 
	or a view. All the same caveats apply.
	
	In this case of transforming an ImmuTable, it makes sense to return an ImmuTable."

	^ OffsetImmuTable create: self with: dsp! !

!ImmuTable methodsFor: 'creation'!

{ScruTable} copy
	"don't need to actually make a copy, as this is immutable"
	^self!

{ScruTable} emptySize: size {IntegerVar}
	"The idea of a 'size' argument would seem kind of ridiculous here as the resulting empty table can't be changed."
	
	self subclassResponsibility.! !

!ImmuTable methodsFor: 'SEF manipulation'!

{ImmuTable} combineWith: other {ImmuTable}
	"Similar to unionWith.  In particular, if 'a = b->combineWith(c);', then:
	'a->domain()->isEqual(b->domain()->unionWith(c->domain())' and
	'a->range()->isSubsetOf(b->range()->unionWith(c->range())'.
	(Note that the domain case uses XuRegion::unionWith, while the range case
	uses ImmuSet::unionWith.)
	
	Despite this correspondence, unionWith is symmetrical while combineWith is not.
	Given that the two input tables have different associations for a given key,
	one gets to dominate.  I need to specify which one here, but the code seems
	inconsistent on this question.  Until this is resolved, console youself with the
	thought that if the tables don't conflict we have a simple unionWith of the two
	sets of associations (and the 'isSubsetOf' above can be replaced with 'isEqual')."
	
	self subclassResponsibility!

{ImmuTable} without: index {Position} 
	"Return a new table just like the current one except with the association whose 
	key is 'index'."

	self subclassResponsibility! !

!ImmuTable methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.ImmuTable hashForEqual + self contentsHash!

{BooleanVar} includesIntKey: aKey {IntegerVar}
	^ super includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}
	self subclassResponsibility!

{BooleanVar} isEmpty
	self subclassResponsibility.!

{BooleanVar} isEqual: other {Heaper}

	other cast: ImmuTable into: [:o |
			^self contentsEqual: o]
		others: [^false].
	^ false "compiler fodder"! !

!ImmuTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	self subclassResponsibility! !

!ImmuTable methodsFor: 'conversion'!

{ImmuTable} asImmuTable

	^self!

{MuTable} asMuTable

	self subclassResponsibility! !

!ImmuTable methodsFor: 'smalltalk: passe'!

{ImmuTable} with: other {ImmuTable} 
	"Please use ImmuTable::combineWith instead. 'with' was an innapropriate name 
	because its use elsewhere (see ImmuSet::with and XuRegion::with) implies that 
	the argument is a single element to be added, not a collection of elements to 
	be added."
	self passe. 
	^self combineWith: other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImmuTable class
	instanceVariableNames: ''!

(ImmuTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ImmuTable class methodsFor: 'pseudo constructors'!

{ImmuTable} make.CoordinateSpace: cs {CoordinateSpace}
	"An empty ImmuTable whose domain space is 'cs'."
	
	^ImmuTableOnMu create: (MuTable make: cs)!

{ImmuTable} offsetImmuTable: aTable {ImmuTable} with: aDsp {Dsp}
	^ OffsetImmuTable create: aTable with: aDsp! !

!ImmuTable class methodsFor: 'smalltalk: smalltalk defaults'!

make: something
	"(something isKindOf: MuTable)
		ifTrue: [^self make.MuTable: something]."
	^self make.CoordinateSpace: (something cast: CoordinateSpace)! !
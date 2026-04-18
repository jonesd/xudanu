'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:49 pm'!

TableWaldo subclass: #IntegerTableWaldo
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!
IntegerTableWaldo comment:
'A TableWaldo which wraps an IntegerTable, in order to manipulate it and to report such manipulation to dependents (via the XuModel mechanism).  The kinds of manipulation operations defined here loosely corresponds to what one would expect in the heart of a text editor:  Insertion and deletion.  Curiously, this class doesn''t provide for rearrangement but swapping.'!

(IntegerTableWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTableWaldo methodsFor: 'deferred accessing'!

{XnRegion} domain
	"The domain of the wrapped table"
	
	self subclassResponsibility!

{ScruTable} table
	"The wrapped table. Note the warning in class comment of TableWaldo: Do not 
	modify this table directly while continuing to use this waldo."

	self subclassResponsibility! !

!IntegerTableWaldo methodsFor: 'deferred manipulating'!

{void} insert.IntegerVar: atKey {IntegerVar} with: element {Heaper} 
	"Store element at index 'atKey'. If there's already something there, move all 
	elements from there on up forward by one. 
	
	Sends an InsertionUR to my dependents. BUG BUG: Not all implementations of 
	this method notify dependents."

	self subclassResponsibility! !

!IntegerTableWaldo methodsFor: 'deferred operations'!

{void} deflate: reg {XnRegion} 
	"Wipe out all elements at position in 'reg'. For elements at positions past 'reg', 
	slide them down by the number of elements wiped out.
	
	Sends an DeletionUR to my dependents. BUG BUG: Not all implementations of 
	this method notify dependents."

	self subclassResponsibility!

{void} insertAll.IntegerVar: atKey {IntegerVar} with: table {IntegerTable} 
	"It is clear what this is intended to do to the receiver (me) given that the 
	argument table is an MuArray (i.e., its elements start at index 0 and there are 
	no gaps), and that I have no gaps: In this case, all my elements from atKey on 
	down are shifted forward to open up a gap starting at atKey for the elements 
	of the table, an the elements of the table are then stored in that gap. Issues 
	that need to be cleared up in the specification: 
	
	1) What if 'table' doesn't start at 0? 
	2) What if it has gaps? 
	3) Should the argument table be modified? (probably not, but currently it 
		sometimes is) 
	4) What if I have gaps, especially in the region into which the contents of 
		'table' is to be inserted?
	5) Should we define some of the hard cases above away by declaring
		a) 'table' as an MuArray?
		b) this message as applying only to kinds of ArrayWaldo?
	
	Until these issues are cleared up, this method should probably be avoided.
	
	Sends an InsertionUR to my dependents. BUG BUG: Not all implementations of 
	this method notify dependents."

	self subclassResponsibility!

{void} transform: dsp {Dsp} 
	"Move all elements of the from their current index to 'dsp->of(index)'. Since 
	IntegerSpace dsps are only displacements, this results in offsetting all indecies 
	by a constant amount. 
	
	BUG BUG BUG: This message is a publicly accessible way to change an XuModel. 
	Therefore, after doing its stuff, it must notify dependents. However, not only 
	do none of the implementations of this method do so, there isn't even a defined 
	UpdateRecord class for them to use to do so."

	self subclassResponsibility! !

!IntegerTableWaldo methodsFor: 'smalltalk: smalltalk obsolete:'!

{void} swap: index1 {IntegerVar} with: index2 {IntegerVar} 
	"Given that my underlying table has elements at both index1 and index2, swap 
	them. Afterwards, my table will have at index2 the element that used to be at 
	index1 and vice versa. It is an error for either index to not be in the domain of 
	the table being manipulated. 
	
	It is perfectly legal for index1 to equal index2. Even though no change results, 
	an update record may still be sent to dependents.
	
	Sends an SwapUR to my dependents. BUG BUG: Not all implementations of 
	this method notify dependents."

	self shouldNotImplement! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerTableWaldo class
	instanceVariableNames: ''!

(IntegerTableWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!IntegerTableWaldo class methodsFor: 'pseudo constructors'!

make: onTable {IntegerTable} 
	"Returns an IntegerTableWaldo which wraps 'onTable'. Unlike real Waldos, the 
	wrapping process does nothing to ensure exclusive access. Rather it is up to 
	the programmer not to modify the table while it is wrapped."

	onTable
		cast: MuWordArray into: [:tab |
			^WordArrayWaldo make: tab]
		others: [^AITWaldo create: onTable].
	^ NULL "compiler fodder"! !
'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:30 pm'!

FebeTester subclass: #ComparatorTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(ComparatorTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ComparatorTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	"ComparatorTester runTest"

	self crazyDogTestOn: oo.
	self arrangeMovesTestOn: oo.
	self sodaTestOn: oo.! !

!ComparatorTester methodsFor: 'smalltalk: tests'!

{void} interactiveTestOn: oo {ostream reference}
	"ComparatorTester runTest: #interactiveTestOn:"
	| text1 {XuText} text2 {XuText} text3 {XuText} |
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'Apple Banana Cherry Durian Elderberry Grape ').
	text1 vcopy: text1 count with: text1 with: (IntegerRegion make: 13 with: 20).
	text2 _ (text1 copy: true) cast: XuText.
	text2 insert: IntegerVar0 with: (MuWordArray make.charVector: 'Zero ').
	text2 vcopy: text2 count with: text1 with: (IntegerRegion make: 13 with: 20).
	text2 rearrange: 12 with: 18 with: 39.
	text2 move: text2 count with: text2 with: (IntegerRegion make: 26 with: 33).
	text2 deflate: (IntegerRegion integerExtent: 32 with: 5).
	text2 insert: text2 count with: (MuWordArray make.charVector: 'Melon ').
self halt.

text3 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')) cast: XuText.
text3 insert: IntegerVar0 with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text2 with: (IntegerRegion make: IntegerVar0 with: 5).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: IntegerVar0 with: 7).
text3 insert: text3 count with:  (MuWordArray make.charVector: '[(a)').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 7 with: 13).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 13 with: 27).
text3 insert: text3 count with:  (MuWordArray make.charVector: '[(b)').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 27 with: 34).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 insert: text3 count with:  (MuWordArray make.charVector: '[').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 34 with: 39).
text3 insert: text3 count with:  (MuWordArray make.charVector: ']').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<(a)>').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 39 with: 51).
text3 insert: text3 count with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text1 with: (IntegerRegion make: 44 with: 51).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<(b)>').
text3 insert: text3 count with:  (MuWordArray make.charVector: '<').
text3 vcopy: text3 count with: text2 with: (IntegerRegion make: 58 with: 64).
text3 insert: text3 count with:  (MuWordArray make.charVector: '>').
^text3 asDataTable asMuTable cast: MuWordArray! !

!ComparatorTester methodsFor: 'tests'!

{void} arrangeMovesTestOn: oo {ostream reference}
	"ComparatorTester runTest: #arrangeMovesTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (ID key: 'XuText') with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'Apple Banana Cherry Durian Elderberry Grape ').
	text1 vcopy: text1 count with: text1 with: (IntegerRegion integerExtent: 13 with: 20).
	text2 _ (text1 copy: true) cast: XuText.
	text2 insert: IntegerVar0 with: (MuWordArray make.charVector: 'Zero ').
	text2 vcopy: text2 count with: text1 with: (IntegerRegion integerExtent: 13 with: 20).
	text2 rearrange: 12 with: 18 with: 39.
	text2 move: text2 count with: text2 with: (IntegerRegion integerExtent: 26 with: 33).
	text2 deflate: (IntegerRegion integerExtent: 32 with: 5).
	text2 insert: text2 count with: (MuWordArray make.charVector: 'Melon ').

	[EditSequence] USES.
	oo << (MoveMaker make: ((TextComparator  make: text1 with: text2) findLCS allSequences)) sequences << '
'!

{void} crazyDogTestOn: oo {ostream reference}
	"ComparatorTester runTest: #crazyDogTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'The crazy brown fox jumped over the uqick dog').
	text2 _ (text1 copy: true) cast: XuText.
	text2 rearrange: 4 with: (IntegerRegion integerExtent: 36 with: 41).
	text2 rearrange: 10 with: (IntegerRegion integerExtent: 16 with: 41).
	text2 rearrange: 4 with: (IntegerRegion integerExtent: 5 with: 6).
	text2 deflate: (IntegerRegion integerExtent: 36 with: 2).
	text2 insert: 36 with: (MuWordArray make.charVector: 'l').
	[EditSequence] USES.
	oo << (TextComparator  make: text1 with: text2) findLCS allSequences!

{void} sodaTestOn: oo {ostream reference}
	"ComparatorTester runTest: #sodaTestOn:"
	| text1 {XuText} text2 {XuText} |
	[KeyMaster] USES.
	text1 _ (self keyMaster makeEmptyWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText.
	
	text1 insert: IntegerVar0 with: (MuWordArray make.charVector:
		'ABCDEFGHIJKL grape root beer doctor pepper sprite sevenup').
	text2 _ (text1 copy: true) cast: XuText.
	text2 rearrange: IntegerVar0 with: 3 with: 7.
	text2 rearrange: 2 with: 9 with: 12.
	text2 rearrange: IntegerVar0 with: 12 with: 57.
	
	oo << (TextComparator  make: text1 with: text2) findLCS << '
'.! !

!ComparatorTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
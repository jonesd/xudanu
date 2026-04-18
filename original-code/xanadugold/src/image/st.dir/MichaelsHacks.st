'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:40 pm'!

Heaper subclass: #MichaelsHacks
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-michael'!

(MichaelsHacks getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MichaelsHacks methodsFor: 'precedence tests'!

{UInt4} precedence: a {UInt4} with: b {UInt4} with: c {UInt4} with: d {UInt4} with: e {UInt4} with: f {UInt4} with: g {UInt4} with: h {UInt4} with: i {UInt4}
	| x {UInt4} y {UInt4} |
	
	a and: [b and: [c]].
	(a and: [b]) and: [c].
	a and: [b or: [c]].
	(a and: [b]) or: [c].
	a or: [b or: [c]].
	(a or: [b]) or: [c].
	
	true ifTrue: [
		x _ (((((((a * b) + c) << d) < e) == f) bitAnd: g) bitXor: h) bitOr: i.
	] ifFalse: [
		x _ (((((((a bitOr: b) bitXor: c) bitAnd: d) == e) < f) << g) + h) * i.
	].
	
	"
	equal precedence, left-to-right
	"
	
	x _ (((a * b) / c) // d).
	x _ (((a // b) / c) * d).
	x _ ((a + b) - c).
	x _ ((a - b) + c).
	x _ ((a << b) >> c).
	x _ ((a >> b) << c).
	x _ ((((a < b) <= c) >= d) > e).
	x _ ((((a > b) >= c) <= d) < e).
	x _ ((a == b) !!= c).
	x _ ((a !!= b) == c).
	
	"equal precedence, default order"
	
	x _ a * b / c // d.
	x _ a // b / c * d.
	x _ a + b - c.
	x _ a - b + c.
	x _ a << b >> c.
	x _ a >> b << c.
	x _ a < b <= c >= d > e.
	x _ a > b >= c <= d < e.
	x _ a == b !!= c.
	x _ a !!= b == c.
	
	"equal precedence, right-to-left"
	
	x _ (a * (b / (c // d))).
	x _ (a // (b / (c * d))).
	x _ (a + (b - c)).
	x _ (a - (b + c)).
	x _ (a << (b >> c)).
	x _ (a >> (b << c)).
	x _ (a < (b <= (c >= (d > e)))).
	x _ (a > (b >= (c <= (d < e)))).
	x _ (a == (b !!= c)).
	x _ (a !!= (b == c)).
	
	x _ a == b ifTrue: [ c ] ifFalse: [ d ].
	x _ a == b ifTrue: [ y _ c ] ifFalse: [ y _ d ].
	x _ (y _ b).
	^x + y.! !
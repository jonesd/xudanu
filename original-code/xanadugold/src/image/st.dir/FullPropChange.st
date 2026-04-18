'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:28 pm'!

PropChange subclass: #FullPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
FullPropChange comment:
'Use this to indicate that all aspects of the Prop may have changed.'!

(FullPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!FullPropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^a isEqual: b!

{Prop} changed: old {Prop unused} with: a {Prop}

	^a!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^true!

{Prop} with: old {Prop} with: a {Prop}

	^old with: a! !

!FullPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^a isEqual: b!

{PropJoint} changedJoint: old {PropJoint unused} with: a {PropJoint}
	
	^a!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	^a join: b!

{PropJoint} joinProp: old {PropJoint unused} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	^(a join: b) with: prop! !
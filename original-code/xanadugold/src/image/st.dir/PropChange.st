'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:29 pm'!

Heaper subclass: #PropChange
	instanceVariableNames: ''
	classVariableNames: '
		TheBertPropChange {PropChange} 
		TheCannotPartializeChange {PropChange} 
		TheDetectorWaitingChange {PropChange} 
		TheEndorsementsChange {PropChange} 
		ThePermissionsChange {PropChange} 
		TheSensorPropChange {PropChange} '
	poolDictionaries: ''
	category: 'Xanadu-props'!
PropChange comment:
'Each concrete class has just one canonical instance and no state.  A PropChange is used to represent which property aspect changed (such as permission vs endorsement vs both).'!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	self subclassResponsibility!

{Prop} changed: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change replaces, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also: with:with:, which unions rather than replacing."
	
	self subclassResponsibility!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	"return a finder looking for this change from before to after, in addition to whatever oldFinder is looking for (assumes this changes is a subset of oldFinder's change)"
	
	self subclassResponsibility!

{BooleanVar} isFull
	"whether this is a complete change of props"
	self subclassResponsibility!

{Prop} with: old {Prop} with: a {Prop}
	"Return a Prop which is the same as 'old' for aspects which I don't represent as changing, and the union of 'old' and 'a' for aspects that I do represent as changing.
	
	 This is used to accumulate changes to Props with minimum effort, given that the 'a' parameter has only new props which are of the aspect this change changes, while the 'old' parameter starts as the original set of Props, perhaps including other aspects.
	 
	 See also changed:with:, which replaces rather than unioning."
	
	self subclassResponsibility! !

!PropChange methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self takeOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!PropChange methodsFor: 'smalltalk: passe'!

{PropFinder} fetchFinder: before {Prop} with: after {Prop}

	self passe "extra args"!

{PropFinder} finderPartFrom: finder {PropFinder}

	self passe! !

!PropChange methodsFor: 'smalltalk: defaults'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	
	^self fetchFinder: before with: after with: element with: NULL! !

!PropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	
	self subclassResponsibility!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	"Return a PropJoint which is the same as 'old' for aspects which I don't represent as changing, and 'a' for aspects that I do represent as changing.
	
	 This is used to replace PropJoints with minimum effort, given that the 'a' parameter has only new PropJoints which are of the aspect this change replaces, while the 'old' parameter starts as the original set of PropJoints, perhaps including other aspects.
	 
	 See also: change:with:, which does this for Props rather than PropJoints."
	
	self subclassResponsibility!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	self subclassResponsibility!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	self subclassResponsibility!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropChange class
	instanceVariableNames: ''!

(PropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropChange class methodsFor: 'pseudo constructors'!

{PropChange} bertPropChange
	^TheBertPropChange!

{PropChange} cannotPartializeChange
	^TheCannotPartializeChange!

{PropChange} detectorWaitingChange
	^TheDetectorWaitingChange!

{PropChange} endorsementsChange
	^TheEndorsementsChange!

{PropChange} permissionsChange
	^ThePermissionsChange!

{PropChange} sensorPropChange
	"Returns the canonical PropChange object for propagating the properties that result from installing a recorder (permissions and endorsement filters).  A better name would be recorderPropChange"
	
	^TheSensorPropChange! !

!PropChange class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	TheCannotPartializeChange _ CannotPartializeChange create.
	TheDetectorWaitingChange _ DetectorWaitingChange create.
	TheEndorsementsChange _ EndorsementsChange create.
	TheBertPropChange _ BertPropChange create.
	TheSensorPropChange _ SensorPropChange create.
	ThePermissionsChange _ PermissionsChange create.!

linkTimeNonInherited
	TheCannotPartializeChange _ NULL.
	TheDetectorWaitingChange _ NULL.
	TheEndorsementsChange _ NULL.
	TheBertPropChange _ NULL.
	TheSensorPropChange _ NULL.
	ThePermissionsChange _ NULL! !
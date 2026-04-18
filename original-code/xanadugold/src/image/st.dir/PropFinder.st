'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:58 pm'!

Heaper subclass: #PropFinder
	instanceVariableNames: 'myFlags {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PropFinder comment:
'For filtering by canopies.  Matches against Props and CanopyCrum flags'!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create.
	myFlags := flags.! !

!PropFinder methodsFor: 'accessing'!

{BooleanVar} doesPass: parent {CanopyCrum}
	"return whether the propJoint passes the finder"

	^(myFlags bitOr: parent flags) ~= UInt32Zero!

{PropFinder} findPast: stamp {BeEdition}
	"During a southwards walk of a multi-Edition (aka multi-Stamp), normally we simplify the finder by using PropFinder>>pass:.  However, when we cross an internal Edition boundary and are about to walk into the O-plane of that contained edition we call this method (findPast:) to get the new PropFinder."
	
	self subclassResponsibility!

{UInt32} flags

	^myFlags!

{BooleanVar} isEmpty
	"Overridden only in ClosedPropFinder"
	^false!

{BooleanVar} isFull
	"Overridden only in OpenPropFinder"
	^false!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility!

{PropFinder} pass: parent {CanopyCrum}
	"return a simple enough finder for looking at the children"

	(self doesPass: parent)
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PropFinder class
	instanceVariableNames: ''!

(PropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropFinder class methodsFor: 'creation'!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)}
	permissionsFilter isEmpty
		ifTrue: [^PropFinder closedPropFinder]
		ifFalse: [^BackfollowPFinder 
			create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter]!

{PropFinder} backfollowFinder: permissionsFilter {Filter of: (XnRegion of: ID)} 
	with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	(permissionsFilter isEmpty or: [endorsementsFilter isEmpty]) ifTrue:
		[^PropFinder closedPropFinder].
	endorsementsFilter isFull ifTrue:
		[^BackfollowPFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: NULL
				with: false
				with: false)
			with: permissionsFilter].
	^BackfollowFinder create: (BertCrum
				flagsFor: (permissionsFilter relevantRegion cast: IDRegion)
				with: (endorsementsFilter relevantRegion cast: CrossRegion)
				with: false
				with: false)
			with: permissionsFilter
			with: endorsementsFilter!

{PropFinder} cannotPartializeFinder
	^CannotPartializeFinder create!

{PropFinder} closedPropFinder
	^ClosedPropFinder create!

{PropFinder} openPropFinder
	^OpenPropFinder create!

{PropFinder} sensorFinder
	^SensorFinder create! !

!PropFinder class methodsFor: 'smalltalk: passe'!

{PropFinder} partialityFinder

	self passe!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderFinder.RegionDelta: permissionsDelta {RegionDelta of: (XuRegion of: ID)} 
	with.XuRegion: endorsements {XuRegion of: ID} 

	self passe.!

{PropFinder} recorderFinder.XuRegion: permissions {XuRegion of: ID} 
	with.RegionDelta: endorsementsDelta {RegionDelta of: (XuRegion of: ID)} 

	self passe.!

{PropFinder} recorderPFinder: element {BeRangeElement}
	with: permissionsDelta {RegionDelta of: IDRegion}
	with: endorsements {CrossRegion of: IDRegion and: IDRegion}
	
	self passe! !
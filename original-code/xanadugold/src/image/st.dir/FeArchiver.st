'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:07 pm'!

Heaper subclass: #FeArchiver
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sysadm'!
FeArchiver comment:
'Used for transferring information to and from external storage medium. This protocol is still expected to evolve.'!

(FeArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeArchiver methodsFor: 'accessing'!

{FeEdition CLIENT} archive: works {FeEdition} with: medium {FeEdition}
	"Essential.  Copy the entire contents of a set of Works onto secondary storage. Requires read permission on all the Works (or the authority of the System Archive Club, which can read anything). The medium is an Edition describing the kind of device on which to write the backup. The result and the list of Works are wrapped as Sets, the medium as a StorageMedium.
	Returns the set of Works which were in fact successfully backed up."
	
	Dean shouldImplement.
	^NULL "fodder"!

{void CLIENT} markArchived: edition {FeEdition}
	"Essential. Mark the contents of a set of Works as archived so that they can be discarded from the online disk. Requires System Admin authority."
	
	Dean shouldImplement!

{FeEdition CLIENT} restore: works {FeEdition | NULL}
	with: medium {FeEdition}
	"Essential.  Restore information from a backup tape. If a set of Works is specified, then restores only them from the backup medium, otherwise just reads the entire contents. Must have edit authority on Works which are restored. (Is this the right authority? What to do about history?)
	Returns the Works which were restored from tape."
	
	Dean shouldImplement.
	^NULL "fodder"! !

!FeArchiver methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeArchiver class
	instanceVariableNames: ''!

(FeArchiver getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #EQ; yourself)!

!FeArchiver class methodsFor: 'create'!

{FeArchiver CLIENT} make

	^self create! !

!FeArchiver class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeEdition CLIENT} archive: works {FeEdition} with: medium {FeEdition}
{void CLIENT} markArchived: edition {FeEdition}
{FeEdition CLIENT} restore: works {FeEdition | NULL} with: medium {FeEdition}
"! !
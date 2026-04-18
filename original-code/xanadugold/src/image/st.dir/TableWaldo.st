'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:49 pm'!

XnModel subclass: #TableWaldo
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!
TableWaldo comment:
'Note that this isn''t actually a kind of Waldo.  Rather, we use the term here because these classes have a very similar relationship to table that Waldos have to Stamps and Berts.  (See Waldo)
	
	A TableWaldo is a wrapper around a table which provides some convenient higher level operations for manipulating the table.  It is also correctly an XuModel (as opposed to the tables themseves) in that it will inform its dependents about any changes made through it to the underlying table.  It is an error to be modifying the table between wrapping it with a TableWaldo and any use of the TableWaldo.  This is so the TableWaldo can assume it is the only one making changes to the table, and to ensure that no changes escape the notice of the dependents.'!

(TableWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!
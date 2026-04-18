#
#	Exported objects from translated xpp
#
#	This export file inherits comm's export file
#
#  $Id: export.mk,v 1.1 1992/12/19 00:52:13 ravi Exp $
#

# XLATELIBX_O is the full library with comm

# XCOMMLIBX_O is the minimal comm library

# XXPPLIBX_O is the basic spaceless translated xpp library

# SPACELIBX_O is the above with tables and spaces included

# SPACELIBT_O is the above with the class Tester included

# RCMAINX_O should be included in any executable

# SETT_O is for ScruSet subclass tests

# SPACET_O is for Region subclass tests

include $(XPPDIR)/comm/$(PLATFORM)/export.mk

XXPPLIBX_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/xxpplibx.lib
SPACELIBX_O = $(XXPPLIBX_O) $(XPPDIR)/xlatexpp/$(PLATFORM)/spclibx.lib
SPACELIBT_O = $(SPACELIBX_O) $(XPPDIR)/xlatexpp/$(PLATFORM)/testerx.obj
RCMAINX_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/rcmainx.obj

XCOMMLIBX_O = $(XXPPLIBX_O) $(COMMLIBX_O)

XLATELIBX_O = $(SPACELIBX_O) $(COMMLIBX_O)
XLATELIBT_O = $(SPACELIBT_O) $(COMMLIBX_O)
XLATELIBT_LINK = _xxlib.lnk
_xxlib.lnk : $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk
	echo $(SPACELIBX_O) > $@
	echo $(XPPDIR)/xlatexpp/$(PLATFORM)/testerx.obj >> $@
	echo $(COMMLIBX_O) >> $@

SETT_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/sett.obj
SPACET_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/spacet.obj

$(XPPDIR)/xlatexpp/$(PLATFORM)/xxpplibx.lib : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) xxpplibx.lib 

$(XPPDIR)/xlatexpp/$(PLATFORM)/spclibx.lib : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) spclibx.lib 

$(XPPDIR)/xlatexpp/$(PLATFORM)/testerx.obj : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) testerx.obj 

$(XPPDIR)/xlatexpp/$(PLATFORM)/rcmainx.obj : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) rcmainx.obj 

$(XPPDIR)/xlatexpp/$(PLATFORM)/sett.obj : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) sett.obj 

$(XPPDIR)/xlatexpp/$(PLATFORM)/spacet.obj : FORCE
	xumake -C $(XPPDIR)/xlatexpp/$(PLATFORM) spacet.obj 


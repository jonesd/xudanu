#
#	Exported objects from translated xpp
#
#	This export file inherits comm's export file
#
#  $Id: export.mk,v 1.7 1992/11/25 23:24:40 eric Exp $
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

XXPPLIBX_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/xxpplibx.o
SPACELIBX_O = $(XXPPLIBX_O) $(XPPDIR)/xlatexpp/$(PLATFORM)/spclibx.o
SPACELIBT_O = $(SPACELIBX_O) $(XPPDIR)/xlatexpp/$(PLATFORM)/testerx.o
RCMAINX_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/rcmainx.o

XCOMMLIBX_O = $(XXPPLIBX_O) $(COMMLIBX_O)

XLATELIBX_O = $(SPACELIBX_O) $(COMMLIBX_O)
XLATELIBT_O = $(SPACELIBT_O) $(COMMLIBX_O)

SETT_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/sett.o
SPACET_O = $(XPPDIR)/xlatexpp/$(PLATFORM)/spacet.o

$(XPPDIR)/xlatexpp/$(PLATFORM)/xxpplibx.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake xxpplibx.o || (rm -f $@ ; false)

$(XPPDIR)/xlatexpp/$(PLATFORM)/spclibx.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake spclibx.o || (rm -f $@ ; false)

$(XPPDIR)/xlatexpp/$(PLATFORM)/testerx.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake testerx.o || (rm -f $@ ; false)

$(XPPDIR)/xlatexpp/$(PLATFORM)/rcmainx.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake rcmainx.o || (rm -f $@ ; false)

$(XPPDIR)/xlatexpp/$(PLATFORM)/sett.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake sett.o || (rm -f $@ ; false)

$(XPPDIR)/xlatexpp/$(PLATFORM)/spacet.o : FORCE
	cd $(XPPDIR)/xlatexpp/$(PLATFORM) ; xumake spacet.o || (rm -f $@! ; false)


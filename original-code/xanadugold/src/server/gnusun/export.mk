#
#	Exported objects from server
#
#  $Id: export.mk,v 1.6 1992/10/21 17:47:16 ravi Exp $
#

include $(XPPDIR)/disk/$(PLATFORM)/export.mk

SERVLIBX_O = $(XPPDIR)/server/$(PLATFORM)/servlibx.o $(DISKLIBX_O)
FEBESRVX_O = $(XPPDIR)/server/$(PLATFORM)/worksrvx.o
SERVTESTS_O = $(XPPDIR)/server/$(PLATFORM)/grantabt.o

SERVERX_O = $(SERVLIBX_O) $(FEBESRVX_O) $(SPIRSRVX_O)

$(XPPDIR)/server/$(PLATFORM)/servlibx.o : FORCE
	cd $(XPPDIR)/server/$(PLATFORM) ; xumake servlibx.o || (rm -f $@ ; false)
 
$(XPPDIR)/server/$(PLATFORM)/worksrvx.o : FORCE
	cd $(XPPDIR)/server/$(PLATFORM) ; xumake worksrvx.o || (rm -f $@ ; false)

$(XPPDIR)/server/$(PLATFORM)/grantabt.o : FORCE
	cd $(XPPDIR)/server/$(PLATFORM) ; xumake grantabt.o || (rm -f $@ ; false)


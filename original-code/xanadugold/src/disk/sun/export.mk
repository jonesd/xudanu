#
#	Exported objects from disk
#
#	This library is incorporated into those provided by server/export.mk
#	Include that to get this.
#
#	$Id: export.mk,v 1.3 1992/10/21 17:45:48 ravi Exp $
#

include $(XPPDIR)/urdi/$(PLATFORM)/export.mk

DISKLIBX_O = $(XPPDIR)/disk/$(PLATFORM)/disklibx.o $(URDILIBX_O)

DISKTESTS_O = $(XPPDIR)/disk/$(PLATFORM)/diskmant.o $(XPPDIR)/disk/$(PLATFORM)/packert.o \
		$(XPPDIR)/disk/$(PLATFORM)/consistt.o

$(XPPDIR)/disk/$(PLATFORM)/disklibx.o : FORCE
	cd $(XPPDIR)/disk/$(PLATFORM) ; xumake disklibx.o || (rm -f $@ ; false)

$(XPPDIR)/disk/$(PLATFORM)/diskmant.o : FORCE
	cd $(XPPDIR)/disk/$(PLATFORM) ; xumake diskmant.o || (rm -f $@ ; false)

$(XPPDIR)/disk/$(PLATFORM)/packert.o : FORCE
	cd $(XPPDIR)/disk/$(PLATFORM) ; xumake packert.o || (rm -f $@ ; false)

$(XPPDIR)/disk/$(PLATFORM)/consistt.o : FORCE
	cd $(XPPDIR)/disk/$(PLATFORM) ; xumake consistt.o || (rm -f $@ ; false)

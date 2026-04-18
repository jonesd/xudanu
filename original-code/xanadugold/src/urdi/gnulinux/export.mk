#
#	Exported objects from urdi
#
#	Every directory that includes server gets URDILIBX_O wrapped in SERVLIBX_O
#
#	Include after default action in client xumakefile, before
#	uses of exported libraries.
#
#  $Id: export.mk,v 1.2 1992/10/21 17:47:52 ravi Exp $
#

URDILIBX_O = $(XPPDIR)/urdi/$(PLATFORM)/urdix.o $(XPPDIR)/urdi/$(PLATFORM)/buildx.o

$(XPPDIR)/urdi/$(PLATFORM)/urdix.o : FORCE
	cd $(XPPDIR)/urdi/$(PLATFORM) ; xumake urdix.o || (rm -f $@ ; false)

$(XPPDIR)/urdi/$(PLATFORM)/buildx.o : FORCE
	cd $(XPPDIR)/urdi/$(PLATFORM) ; xumake buildx.o || (rm -f $@ ; false)


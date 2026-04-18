#
#	Exported objects from non-translated xpp
#
#  $Id: export.mk,v 1.6 1993/03/23 01:06:48 hibbert Exp $
#

XPPLIBX_O  = $(XPPDIR)/xpp/$(PLATFORM)/xpplibx.o $(XPPDIR)/xpp/$(PLATFORM)/filetpx.o
XPPLIBT_O  = $(XPPDIR)/xpp/$(PLATFORM)/xpplibx.o $(XPPDIR)/xpp/$(PLATFORM)/filetpx.o
XPPRPCX_O = $(XPPDIR)/xpp/$(PLATFORM)/xpplibx.o  $(XPPDIR)/xpp/$(PLATFORM)/filetpx.o

$(XPPDIR)/xpp/$(PLATFORM)/xpplibx.o: FORCE
	cd $(XPPDIR)/xpp/$(PLATFORM) ; xumake xpplibx.o || (rm -f $@ ; false)

$(XPPDIR)/xpp/$(PLATFORM)/filetpx.o: FORCE
	cd $(XPPDIR)/xpp/$(PLATFORM) ; xumake filetpx.o || (rm -f $@ ; false)

$(XPPDIR)/xpp/$(PLATFORM)/hashes.exe: FORCE
	cd $(XPPDIR)/xpp/$(PLATFORM) ; xumake hashes.exe || (rm -f $@ ; false)

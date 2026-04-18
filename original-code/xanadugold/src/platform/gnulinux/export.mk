#
#	Exported objects from platform/sun
#

TIMELIBX_O = $(XPPDIR)/platform/sun/timex.o

$(XPPDIR)/platform/sun/timex.o : FORCE
	cd $(XPPDIR)/platform/sun ; xumake timex.o || (rm -f $@ ; false)

	BEGIN {
		print "void doStaticInit () {"
	}
	$2 == "T" && substr($3,1,7) == "___sti_" {
		print " ", substr($3,2,length($3)-1), "();"
	}
	$2 == "T" && substr($3,1,6) == "__sti_" {
		print " ", $3, "();"
	}
	END {
		print "}"
	}

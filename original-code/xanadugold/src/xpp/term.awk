	BEGIN {
		print "void doStaticTerm () {"
	}
	$2 == "T" && substr($3,1,7) == "___std_" {
		print " ", substr($3,2,length($3)-1), "();"
	}
	$2 == "T" && substr($3,1,6) == "__std_" {
		print " ", $3, "();"
	}
	END {
		print "}"
	}

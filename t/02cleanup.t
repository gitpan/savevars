# -*- perl -*-

BEGIN {
    $0 = "savevarstest";
}

use savevars;

my $cfgfile = savevars::cfgfile();
unlink $cfgfile;

print "1..1\nok 1\n";

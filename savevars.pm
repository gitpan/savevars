# -*- perl -*-

#
# $Id: savevars.pm,v 1.6 1999/05/04 18:43:34 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998,1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package savevars;

$VERSION = "0.03";

# parts stolen from "vars.pm"

my $has_data_dumper = 0;
eval {
    require Data::Dumper;
    $has_data_dumper = 1;
};

my @imports;
my $callpack;

sub import {
    $callpack = caller;
    my $pack = shift;
    @imports = @_;
    my($sym, $ch);
    foreach my $s (@imports) {
        if ($s =~ /::/) {
            require Carp;
            Carp::croak("Can't declare another package's variables");
        }
        ($ch, $sym) = unpack('a1a*', $s);
        *{"${callpack}::$sym"} =
          (   $ch eq "\$"                       ? \$ {"${callpack}::$sym"}
	   : ($ch eq "\@" and $has_data_dumper) ? \@ {"${callpack}::$sym"}
	   : ($ch eq "\%" and $has_data_dumper) ? \% {"${callpack}::$sym"}
	   : do {
	       require Carp;
	       if (!$has_data_dumper) {
		   Carp::croak("Can't handle variable '$ch$sym' without module Data::Dumper.\n");
	       } else {
		   Carp::croak("Can't handle variable '$ch$sym'.\n");
	       }
	   });
    }

    my $cfgfile = cfgfile();
    if (-r $cfgfile) {
	require Safe;
	my $cpt = new Safe;
	$cpt->permit(qw(:base_core));
	$cpt->share_from($callpack, \@imports);
	$cpt->rdo($cfgfile);
    }
}

sub cfgfile {
    my $basename = ($0 =~ /([^\/]+)$/ ? $1 : $0);
    my $cfgfile = eval { (getpwuid($<))[7] } || $ENV{'HOME'} || '';
    $cfgfile . "/.${basename}rc";
}

sub writecfg {
    my $cfgfile = cfgfile();
    if (open(CFG, ">$cfgfile")) {
	my($sym, $ch);
	foreach $sym (@imports) {
	    ($ch, $sym) = unpack('a1a*', $sym);
	    if ($has_data_dumper) {
		my($ref, $varname);
		if ($ch eq "\$") {
		    $ref = eval "$ch${callpack}::$sym";
		    $varname = "${callpack}::$sym";
		} else {
		    $ref = eval "\\" . "$ch${callpack}::$sym";
		    $varname = "*${callpack}::$sym";
		}
		print CFG Data::Dumper->Dump([$ref], [$varname]);
	    } else {
		if ($ch eq "\$") {
		    my $var = "${callpack}::$sym";
		    my $val = eval '$$var';
		    next if !defined $val;
		    $val =~ s/([\'\\])/\\$1/g;
		    print CFG "\$" . $callpack . "::" . $sym . " = '$val';\n";
		} else {
		    die;
		}
	    }
	}
	close CFG;
	1;
    } else {
	warn "Can't write configuration file $cfgfile";
	0;
    }
}

END {
    writecfg();
}

1;

__END__

=head1 NAME

savevars - Perl pragma to auto-load and save global variables

=head1 SYNOPSIS

    use savevars qw($frob @mung %seen);

=head1 DESCRIPTION

This module will, like C<use vars>, predeclare the variables in the
list. In addition, the listed variables are retrieved from a
per-script configuration file and the values are stored on program
end. The filename of the configuration file is
"$ENV{HOME}/.${progname}rc", where progname is the name of the current
script.

The values are stored using the Data::Dumper module, which is already
installed with perl5.005 and better.

=head1 AUTHOR

Slaven Rezic <eserte@cs.tu-berlin.de>

Copyright (c) 1998,1999 Slaven Rezic. All rights reserved. This
package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<vars>.

=cut

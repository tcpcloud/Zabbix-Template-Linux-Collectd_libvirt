#!/usr/bin/perl

use strict;
use warnings;

use Collectd::Unixsock();

{ # main
	my $path = $ARGV[0] || "/var/run/collectd-unixsock";
	my $command = $ARGV[1] || "LISTVAL";
	my @vals;
	our $val = $ARGV[2] || "undef";
	our $val_type = $ARGV[3] || "undef";
        our $collectd_version;

        $collectd_version = `collectd -h |grep \'http://\' | sed \'s/\^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/\' | tr -d '\n'`;

#        print "INFO: collectd version: " . $collectd_version . "\n";

	if( $command eq "LISTVAL" and $val eq "undef"){
	    $val = "ALL"
	}

	if( $command eq "GETVAL"){
	
	    if( $val =~ /^.*-virt_cpu_total/ ){
		@vals = split(/-virt/, $val);
		
		if( $collectd_version =~ /5.5/ ){
		   $val = $vals[0] . "/virt-" . $vals[0] . "/virt" . $vals[1]
		}
		else{
		   $val = $vals[0] . "/libvirt/" . "virt" . $vals[1]
		}
	    }
	    elsif($val =~ /^.*-disk-/ and $val_type =~ /^OPS/){
		@vals = split(/-disk/, $val);
		
		if( $collectd_version =~ /5.5/ ){
		  $val = $vals[0] . "/virt-" . $vals[0] . "/disk_ops" .$vals[1]
		}
		else {
		  $val = $vals[0] . "/libvirt/disk_ops" .$vals[1]
		}
	    }
	    elsif($val =~ /^.*-disk-/ and $val_type =~ /^OCT/){
		@vals = split(/-disk/, $val);
		
		if( $collectd_version =~ /5.5/ ){
		    $val = $vals[0] . "/virt-" . $vals[0] . "/disk_octets" .$vals[1]
		}
		else {
		    $val = $vals[0] . "/libvirt/disk_octets" .$vals[1]
		}
	    }
	    elsif($val =~ /^.*-if-/ and $val_type =~ /^NET-PACKETS/){
		@vals = split(/-if/, $val);
		if( $collectd_version =~ /5.5/ ){
		    $val = $vals[0] . "/virt-" . $vals[0] . "/if_packets" . $vals[1]
		}
		else {
		    $val = $vals[0] . "/libvirt/if_packets" . $vals[1]
		}
	    }
	    elsif($val =~ /^.*-if-/ and $val_type =~ /^NET-OCTETS/){
		@vals = split(/-if/, $val);
		if( $collectd_version =~ /5.5/ ){
		    $val = $vals[0] . "/virt-" . $vals[0] . "/if_octets" .$vals[1]
		}
		else{
		    $val = $vals[0] . "/libvirt/if_octets" .$vals[1]
		}
	    }
	    $command .= " " . $val;
	    
	    #debug 
	    #print "DEBUG: command: " . $command . " val: " . $val . " \n";
	}

	my $sock = Collectd::Unixsock->new($path);

        my $cmds = {
                HELP    => \&cmd_help,
                PUTVAL  => \&putval,
                GETVAL  => \&getval,
                GETTHRESHOLD  => \&getthreshold,
                FLUSH   => \&flush,
                LISTVAL => \&listval,
                PUTNOTIF => \&putnotif,
        };


	if (! $sock) {
		print STDERR "Unable to connect to $path!\n";
		exit 1;
	}

	my $line = $command;

	last if (! $line);

	chomp $line;

	last if ($line =~ m/^quit$/i);

	my ($cmd) = $line =~ m/^(\w+)\s*/;
	$line = $';

	next if (! $cmd);
	$cmd = uc $cmd;

	my $f = undef;
	if (defined $cmds->{$cmd}) {
		$f = $cmds->{$cmd};
	}
	else {
		print STDERR "ERROR: Unknown command $cmd!\n";
		next;
	}

	if (! $f->($sock, $line)) {
	    print STDERR "ERROR: Command failed!\n";
	    next;
	}

	$sock->destroy();
	exit 0;
}

sub tokenize {
        my $line     = shift || return;
        my $line_ptr = $line;
        my @line     = ();

        my $token_pattern = qr/[^"\s]+|"[^"]+"/;

        while (my ($token) = $line_ptr =~ m/^($token_pattern)\s+/) {
                $line_ptr = $';
                push @line, $token;
        }

        if ($line_ptr =~ m/^$token_pattern$/) {
                push @line, $line_ptr;
        }
        else {
                my ($token) = split m/ /, $line_ptr, 1;
                print STDERR "Failed to parse line: $line\n";
                print STDERR "Parse error near token \"$token\".\n";
                return;
        }

        foreach my $l (@line) {
                if ($l =~ m/^"(.*)"$/) {
                        $l = $1;
                }
        }
        return @line;
}

sub getid {
        my $string = shift || return;

        my ($h, $p, $pi, $t, $ti) =
                $string =~ m#^([^/]+)/([^/-]+)(?:-([^/]+))?/([^/-]+)(?:-([^/]+))?\s*#;
        $string = $';

        return if ((! $h) || (! $p) || (! $t));

        my %id = ();

        ($id{'host'}, $id{'plugin'}, $id{'type'}) = ($h, $p, $t);

        $id{'plugin_instance'} = $pi if defined ($pi);
        $id{'type_instance'} = $ti if defined ($ti);
        return \%id;
}

sub putid {
        my $ident = shift || return;

        my $string;

	our $val;

        $string = $ident->{'host'} . "/" . $ident->{'plugin'};

        if (defined $ident->{'plugin_instance'}) {
                $string .= "-" . $ident->{'plugin_instance'};
        }

        $string .= "/" . $ident->{'type'};

        if (defined $ident->{'type_instance'}) {
                $string .= "-" . $ident->{'type_instance'};
        }

	if( $val eq "ALL"){
    	    return $string . $/;
	}
	elsif( $ident->{'type'} eq "virt_cpu_total" and $val eq "CPU"){
    	    return $string . $/;
	}
}

sub putidjson {
        my $ident = shift || return;
        my $string;
        my $stringjson;
#        my $stringjson5;
	our $val;
#	our $collectd_version;

        #debug dumping
        sub print_hash {
            my $href = shift;
            print "$_\t=> $href->{$_}\n" for keys %{$href};
        }
        #print_hash($ident);
        #end of debug dumping

        $string = $ident->{'host'};

	if( $val eq "ALL"){
	    $string .= "-" . $ident->{'plugin'};
	}

        if (defined $ident->{'plugin_instance'} and $ident->{'plugin'} ne "virt") {
                $string .= "-" . $ident->{'plugin_instance'};
        }

	if ($ident->{'plugin'} eq "libvirt" and $ident->{'type'} =~ /^disk/ and $val eq "LIBVIRT-DISK"){
	    $ident->{'type'} =~ s/_ops//;
            $string .= "-" . $ident->{'type'};
	}
	elsif ($ident->{'plugin'} eq "libvirt" and $ident->{'type'} =~ /^if/ and $val eq "LIBVIRT-NET") {
	    $ident->{'type'} =~ s/_packets//;
    	    $string .= "-" . $ident->{'type'};
	}
	elsif ($ident->{'plugin'} eq "virt" and $ident->{'type'} =~ /^disk/ and $val eq "LIBVIRT-DISK"){
	    $ident->{'type'} =~ s/_ops//;
            $string .= "-" . $ident->{'type'};
	}
	elsif ($ident->{'plugin'} eq "virt" and $ident->{'type'} =~ /^if/ and $val eq "LIBVIRT-NET") {
	    $ident->{'type'} =~ s/_packets//;
    	    $string .= "-" . $ident->{'type'};
	}
	else{	
            $string .= "-" . $ident->{'type'};
	}

        if (defined $ident->{'type_instance'}) {
                $string .= "-" . $ident->{'type_instance'};
        }

	$stringjson = "{#NAME}\":\"" . $string . "\"";

	if( $val eq "ALL"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "libvirt" and $ident->{'type'} eq "virt_cpu_total" and $val eq "LIBVIRT-CPU"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "libvirt" and $ident->{'type'} =~ /^disk$/ and $val eq "LIBVIRT-DISK"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "libvirt" and $ident->{'type'} =~ /^if$/ and $val eq "LIBVIRT-NET"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "virt" and $ident->{'type'} eq "virt_cpu_total" and $val eq "LIBVIRT-CPU"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "virt" and $ident->{'type'} =~ /^disk$/ and $val eq "LIBVIRT-DISK"){
    	    return $stringjson;
	}
	elsif( $ident->{'plugin'} eq "virt" and $ident->{'type'} =~ /^if$/ and $val eq "LIBVIRT-NET"){
    	    return $stringjson;
	}
	# unknown plugin / known plugin not found
}

sub listval {
	my $sock = shift || return;
	my $line = shift;

	my @res;

	if ($line ne "") {
		print STDERR "Synopsis: LISTVAL" . $/;
		return;
	}

	@res = $sock->listval();

	if (! @res) {
	    print STDERR "socket error: " . $sock->{'error'} . $/;
	    return;
	}

	my $firstline = 1;

	print "{\n\t\"data\":[\n\n";

	foreach my $ident (@res) {

      my $rs = putidjson($ident);
	   
	   if(length($rs) > 0){

	   	print "\t,\n" if not $firstline;
	   	$firstline = 0;
	   	print "\t{\n";

	   	print "\t\t\"" . putidjson($ident) . "\n";

	   	print "\t}\n";
	   } #end of if

	} #end of foreach

	print "\n\t]\n";
	print "}\n";

	return 1;
}

sub getval {
        my $sock = shift || return;
        my $line = shift || return;

        my @line = tokenize($line);

        my $id;
        my $vals;

	my $err_msg;
	our $val_type;

        if (! @line) {
                return;
        }

        if (scalar(@line) < 1) {
                print STDERR "Synopsis: GETVAL <id>" . $/;
                return;
        }

        $id = getid($line[0]);

        if (! $id) {
                print STDERR "Invalid id \"$line[0]\"." . $/;
                return;
        }

        $vals = $sock->getval(%$id);

        if (! $vals) {

		$err_msg = $sock->{'error'};

		if ("$err_msg" eq "No such value") {
		    print "0" .$/;
		    return 1;
		}
#		else
		{
#            	    print STDERR "socket error: " . $sock->{'error'} . $/;
            	    print STDERR "socket error: " . $sock->{'error'} . $/;
		    return;
                }
        }

        foreach my $key (keys %$vals) {

	    #debug
	    #print $line[0] . "\n";

	    if( $line[0] =~ /^.*\/.*virt.*\/virt_cpu_total/ ){
                print "$vals->{$key}\n";
	    }
	    elsif( $line[0] =~ /^.*\/.*virt.*\/disk_ops/ ){

		if($val_type eq "OPS-READ" and $key eq "read"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "OPS-WRITE" and $key eq "write"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "OPS"){
                    print "\t$key: $vals->{$key}\n";
		}
	    }
	    elsif($line[0] =~ /^.*\/.*virt.*\/disk_octets/){
	    
		#debug
		#print "DEBUG: disk_octets options ..." . $/;
		
		if($val_type eq "OCT-READ" and $key eq "read"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "OCT-WRITE" and $key eq "write"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "OCT"){
                    print "\t$key: $vals->{$key}\n";
		}

	    }
	    elsif($line[0] =~ /^.*\/.*virt.*\/if_packets/){

		#debug
		#print "DEBUG: if_packets options ..." . $/;
		
		if($val_type eq "NET-PACKETS-RX" and $key eq "rx"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "NET-PACKETS-TX" and $key eq "tx"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "NET-PACKETS"){
                    print "\t$key: $vals->{$key}\n";
		}
		
	    }
	    elsif($line[0] =~ /^.*\/.*virt.*\/if_octets/){

		#debug
		#print "DEBUG: if_octets options ..." . $/;
		
		if($val_type eq "NET-OCTETS-RX" and $key eq "rx"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "NET-OCTETS-TX" and $key eq "tx"){
            	    print "$vals->{$key}\n";
		}
		elsif($val_type eq "NET-OCTETS"){
                    print "\t$key: $vals->{$key}\n";
		}
		
	    }
	    else{
                print "\t$key: $vals->{$key}\n";
	    }
        }
        return 1;
}



#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use Time::HiRes "time";

$| = 1;

my $server  = 'albin.abo.fi';
my $port    = '5000';
my $timeout = 2;

$SIG{INT} = \&exit_func;
$SIG{TERM} = \&exit_func; 

my $socket = 0;
createSocket();

if (doHandshake())
{
	print "Connected to $server.\n";
	print "Listening for commands from $server...\n";
	
	my $recv = '';
	while (1) {
		
		eval {
			local $SIG{ALRM} = \&reestablishConnection;
			alarm($timeout);
				do { $recv = <$socket>; } while (not defined($recv));
			alarm(0);
		};
		if ($@) { next; }
	
		chomp($recv);
		
		my ($command, $args) = ('', '');
		($command, $args) = split(/ /, $recv, 2);
		
		if ($command eq "PING")
		{
			print $socket "PONG\n";
		}
		elsif ($command eq "POPUP")
		{
			my $t0 = time;
			system("osascript", "irssi-popup.scpt", ">", "/dev/null", "2>&1");
			my $elapsed = (time - $t0) * 1000;
#			print("Osascript execution time: ", $elapsed, " milliseconds.");
		}
		elsif ($command eq "ALPHA")
		{
			if (defined($args) and !($args eq ''))
			{
				my $ans = `perl alpha-client.pl \'$args\'`;
				print $socket "alphaReceive " . $ans;
			}
		}
		elsif ($command eq "GROWL") {
			my ($nick, $msg) = split(/ /, $args, 2);
			system("growlnotify", "-m", "<$nick> $msg", "-t", "Irssi");
		}
		elsif ($command eq "SHUTDOWN")
		{
			eval {
				reestablishConnection();
			};
		}
		else
		{
			print "Received unknown command: $command\n";
		}
	}
}
else
{
	exit_func();
}

sub createSocket {
	while (1)
	{
		$socket = new IO::Socket::INET (PeerAddr  => $server,
										PeerPort  => $port,
										Proto => 'tcp');
		if($socket) {
			return;
		}
		else {
			print "Couldn't create socket! Retrying in 5 seconds...\n";
			sleep(5);
		}
	}
}

sub doHandshake {
	my $recv = '';
	do { $recv = <$socket>; } while (not defined($recv));
	
	chomp($recv);
	
	if ($recv eq "PING") {
		print $socket "PONG\n";
		return 1;
	}
	else {
		print "No handshake received from other end.\n";
		return 0;
	}	
}

sub reestablishConnection {
	print "Lost contact with server; trying to reconnect...\n";
	close($socket);
	createSocket();
	doHandshake();
	print "Connection established with $server.\n";
	die "terminate read from socket";
}

sub exit_func {
	if($socket) {
		print "Closing socket.\n";
		close($socket);
	}
	print "Exiting...\n";
	exit(0);
}
#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;

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
				$recv = <$socket>;
			alarm(0);
		};
		if ($@) {
			next;
		}
	
		chomp($recv);
		
		if ($recv eq "PING")
		{
			print $socket "PONG\n";
		}
		elsif ($recv eq "POPUP")
		{
			system("osascript irssi-popup.scpt");
		}
		elsif ($recv eq "SHUTDOWN")
		{
			eval {
				reestablishConnection();
			};
		}
		elsif (eof($recv))
		{
			print "Received EOF!\n";
		}
		else
		{
			print "Received unknown command: $recv\n";
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
			print "Couldn't create socket! Retrying in 10 seconds...\n";
			sleep(10);
		}
	}
}

sub doHandshake {
	my $recv = '';
	$recv = <$socket>;
	chomp($recv);
	
	if ("$recv" eq "PING") {
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
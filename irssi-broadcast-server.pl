#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use Irssi;
use Irssi::TextUI;
use Time::HiRes "time";

my $server = 'albin.abo.fi';
my $port   = '5000';
my $pingTime = 1000;

use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
    authors     => 'David Eränen',
    contact     => 'davideranen@hotmail.com',
    name        => 'irssi-broadcast-server.pl',
    description => 'Server part of a script used to broadcast information about events in irssi to another computer',
    license     => 'Public Domain',
);

########
# MAIN #
########

my $client_socket = 0;

my $socket = new IO::Socket::INET (
                                  LocalHost => $server,
                                  LocalPort => $port,
                                  Proto => 'tcp',
                                  Listen => 5,
                                  Reuse => 1,
                                  Blocking => 0,
                               );
die "Couldn't open socket" unless $socket;

$SIG{INT} = \&UNLOAD;
$SIG{TERM} = \&UNLOAD;

Irssi::print("Waiting for incoming connections...");
establishConnection();
Irssi::timeout_add($pingTime, \&maintainConnection, undef);

########
# SUBS #
########

sub connectionOpen {
	return ($client_socket and defined($client_socket));
}

sub maintainConnection {
	if ( not connectionOpen() ) {
		establishConnection();
	}
	else {
		my $t0 = time;
		doHandshake();
		my $elapsed = (time - $t0) * 1000;
#		Irssi::print("Ping time: " . $elapsed . " milliseconds.");
	}
}

sub establishConnection {
	$client_socket = $socket->accept();
	
	if (defined($client_socket))
	{
		Irssi::print("Connection established with " . $client_socket->sockhost() . " !");
		if (doHandshake())
		{
			Irssi::print("Handshake successful!");
			Irssi::print("Listening for Irssi signals...");
			return 1;
		}
	}
	return 0;
}
 
sub doHandshake {
	print $client_socket "PING\n";
	my $response = '';
	$response = <$client_socket>;
	if ("$response" eq "PONG\n") {
		return 1;
	} else {
		Irssi::print("No handshake response from other end. Closing client socket.");
		close($client_socket);
		$client_socket = 0;
		return 0;
	}
}

sub sendCommand {
	my $command = '';
	$command = shift;
	if(connectionOpen) {
		print $client_socket $command;
	}
	else {
		chomp($command);
		Irssi::print("Command \"$command\" not broadcasted because no connection has been established.");
	}
}
 
sub UNLOAD {
	if($socket) {
		if($client_socket) {
			print $client_socket "SHUTDOWN\n";
		}
		Irssi::print("Closing socket.");
		close($socket);
	}
	Irssi::print("Exiting...");
}

#################
# IRSSI SIGNALS #
#################

Irssi::signal_add("scoring", \&sendCommand);
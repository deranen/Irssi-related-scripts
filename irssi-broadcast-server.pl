#!/usr/bin/perl

use warnings;
use strict;
use IO::Socket;
use Irssi;
use Irssi::TextUI;
use Time::HiRes "time";

$| = 1;

my $server = 'albin.abo.fi';
my $port   = '5000';
my $ping   = 0;
my $pingTime = 1000; # ms
my $socketReadTime = 25; # ms

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
Irssi::timeout_add($socketReadTime, \&receiveCommand, undef);

########
# SUBS #
########

sub connectionOpen {
	return (defined($client_socket) && $client_socket);
}

sub maintainConnection {
	if (not connectionOpen()) {
		establishConnection();
	}
	else {
		doHandshake();
	}
}

sub establishConnection {
	$client_socket = $socket->accept();
	
	if (defined($client_socket))
	{
		Irssi::print("Connection established with " . $client_socket->sockhost() . "!");
		doHandshake();
		Irssi::print("Listening for Irssi signals...");
		return 1;
	}
	return 0;
}
 
sub doHandshake {
	print $client_socket "PING\n";
	$ping = time;
}

sub handleHandshakeResponse {
	my $elapsed = (time - $ping) * 1000;
	if($elapsed > 100) {
#		Irssi::print("Ping time: " . $elapsed . "ms.");
	}
}

sub sendCommand {
	my $command = shift;
	if(connectionOpen) {
		print $client_socket $command;
		chomp($command);
		return 1;
	}
	else {
		chomp($command);
		Irssi::print("Command \"$command\" not broadcasted because no connection has been established.");
		return 0;
	}
}

sub receiveCommand {
	if(socketContainsData()) {
		my $resp = '';
		$resp = <$client_socket>;
		if (defined($resp) and !($resp eq '')) {
			if($resp eq "PONG\n") {
				handleHandshakeResponse();
				return 1;
			}
			else {
#				Irssi::print($resp);
				my ($respSignal, $ans) = split(/ /, $resp, 2);
				Irssi::signal_emit($respSignal, ($ans));
				return 1;
			}
		} else {
			Irssi::print("Socket contained data, but \$resp is undefined. Closing socket.");
			close($client_socket);
			$client_socket = 0;
			return 0;
		}
	}
}

sub socketContainsData {
	# Doing non-blocking read to check if there is data in socket
	# http://www.perlmonks.org/?node_id=55241
	if($client_socket) {
		my $rfd = '';
		vec ($rfd, fileno($client_socket), 1) = 1;
		if (select ($rfd, undef, undef, 0) >= 0 && vec($rfd, fileno($client_socket), 1))
		{
			return 1;
		} else {
			return 0;
		}
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
Irssi::signal_add("alphaSend", \&sendCommand);
Irssi::signal_add("growlNotify", \&sendCommand);
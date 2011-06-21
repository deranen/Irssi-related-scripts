#!/usr/bin/perl

use strict;
use Irssi;

our ($VERSION, %IRSSI);

$VERSION = '1.00';
%IRSSI = (
    authors     => 'David Eränen',
    contact     => 'davideranen@hotmail.com',
    name        => 'alpha-server.pl',
    description => '',
    license     => 'Public Domain',
);

$| = 1;

my @argQueue = ();

sub redirBroadcastSend {
	my ($server, $msg, $target) = @_;
	broadcastSend($server, $msg, $server->{nick}, undef, $target);
}

sub broadcastSend {
	my @args = @_;
	my ($server, $msg, $target) = ($args[0], $args[1], $args[4]);
	
	chomp($msg);
	if( $msg =~ /^!wa\s*$/ ) {
		$server->command("/MSG $target Usage: !wa <query>");
	}
	elsif( $msg =~ /^!wa\s(.+)/ ) {
		unshift (@argQueue, \@args);
		Irssi::signal_emit("alphaSend", ("ALPHA $1\n"));
	}
}

sub broadcastReceive {
	my ($result) = @_;
	my @args = @{pop(@argQueue)};
	my ($server, $nick, $target) = ($args[0], $args[2], $args[4]);
	$server->command("/MSG $target <WolframAlpha> $nick: $result");
}

my $signal_config_hash = { "alphaSend" => [ "string" ] };
Irssi::signal_register($signal_config_hash);

my $signal_config_hash = { "alphaReceive" => [ "string" ] };
Irssi::signal_register($signal_config_hash);

Irssi::signal_add('message public', 'broadcastSend');
Irssi::signal_add('message own_public', 'redirBroadcastSend');
Irssi::signal_add('alphaReceive', 'broadcastReceive');
#!/usr/bin/perl

use strict;
use Irssi;

our ($VERSION, %IRSSI);

$VERSION = '1.00';
%IRSSI = (
    authors     => 'David Eränen',
    contact     => 'davideranen@hotmail.com',
    name        => 'My First Perl script :-D',
    description => 'Easily prints a link to WolframAlpha with given search input',
    license     => 'Public Domain',
);

my %argHash = ();
my $ID = 0;

sub redirBroadcastSend {
	my ($server, $msg, $target) = @_;
	broadcastSend($server, $msg, $server->{nick}, undef, $target);
}

sub broadcastSend {
	my @args = @_;
	my $msg = $args[1];
	
	chomp($msg);
	if( $msg =~ /^!wa\s*$/ ) {
		Irssi::print("Usage: !wa <query>");
	}
	elsif( $msg =~ /^!wa\s(.+)/ ) {
		$argHash{$ID+=1} = @args;
		Irssi::signal_emit("alphaSend", ("ALPHA $1\n", "alphaReceive", $ID));
	}
}

sub broadcastReceive {
	Irssi::print("Now in alpha-server-broadcastReceive");
	my ($result, $ID) = @_;
	Irssi::print("result: $result\nID: $ID");
	my @args = $argHash{$ID};
	my ($server, $target) = ($args[0], $args[4]);
	$server->command("/MSG $target $result");
	delete($argHash{$ID});
}

my $signal_config_hash = { "alphaSend" => [ "string", "string", "int"] };
Irssi::signal_register($signal_config_hash);

my $signal_config_hash = { "alphaReceive" => [ "string", "int" ] };
Irssi::signal_register($signal_config_hash);

Irssi::signal_add('message public', 'broadcastSend');
Irssi::signal_add('message own_public', 'redirBroadcastSend');
Irssi::signal_add('alphaReceive', 'broadcastReceive');
#!/usr/bin/perl

use warnings;
use strict;
use Irssi;

our ($VERSION, %IRSSI);

$VERSION = '1.00';
%IRSSI = (
    authors     => 'David Eränen',
    contact     => 'davideranen@hotmail.com',
    name        => 'irssi-growl-notify.pl',
    description => '',
    license     => 'Public Domain',
);

$| = 1;

sub notifySend {
	my ($server, $msg, $nick, $address, $channel) = @_;
	if($msg =~ m/zguL(~)?/) {
		Irssi::signal_emit('growlNotify', ("GROWL $nick $msg\n"));
	}
}

Irssi::signal_add('message public', 'notifySend');

my $signal_config_hash = { "growlNotify" => [ "string" ] };
Irssi::signal_register($signal_config_hash);
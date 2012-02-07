#!/usr/bin/perl

use strict;
use Time::HiRes "time";
use WWW::WolframAlpha;

$| = 1;

my $wa = WWW::WolframAlpha->new (
    appid => 'V96Y7G-EV8EAAWJHW',
);


my $queryString = shift;
my $scanTimeout = 5;

my $t0 = time;
my $query = $wa->query(
	'input' => $queryString,
#	'scantimeout' => $scanTimeout,
#	'podtimeout' => $scanTimeout,
#	'formattimeout' => 0.5,
#	'parsetimeout' => 2,
	'podindex' => 2,
	'format' => 'plaintext'
);
my $elapsed = (time - $t0) * 1000;

my $result = '';
if ($query->success)
{
	foreach my $pod (@{$query->pods})
	{
		if (!$pod->error) {
			foreach my $subpod (@{$pod->subpods}) {
				$result = $result . $subpod->plaintext();
			}
		}
	}
	$result = formatResult($result) . "\n";
	print $result;
	exit(1);
}
# No success, but no error either.
elsif (!$query->error)
{
    print "No result.\n";
}
# Error contacting WA.
elsif ($wa->error) {
    print "Net::WolframAlpha error: ", $wa->errmsg , "\n" if $wa->errmsg;
# Error returned by WA.    
} elsif ($query->error) {
    print "WA error ", $query->error->code, ": ", $query->error->msg, "\n";
}

exit(1);

sub formatResult {
	my $result = shift;
	$result =~ s/\n/ \|\| /g;
	return $result;
}

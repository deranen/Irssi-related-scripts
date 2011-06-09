# irssi_mm script
#
#
# To activate the scoring indicator do:
# /statusbar window add scoring_indicator
# after loading the script
#
# To activate hyper hilight (= hilight until answer or scoring over):
# /set ranks_hyper_hilight ON
#
# The beep interval can be set in the following way:
# /set ranks_hyper_hilight_beep_interval 3000
# will beep every third second.
#
# When mirggi phone scoring is enabled the script sends
# the first scoring line in private to the phone, which 
# will cause an hilight on the phone.
#
# If you want to you can answer to in private to yourself instead
# of directly to MACHINE, if you do this you can use the calc
# feature as you do when answering in irssi. For instance if it comes
# a bonus with question 17*7 i will answer "17 7" (without quotation ofc -,-)
# in private to my irssi clientfrom my phone.
# 
# To enable phone hilight:
# /set ranks_mirggi_hilight ON
# /set ranks_mirggi_nick MyPhoneNick
#
# CHANGELOG:
#
# 1.01: now impossible to score from another channel
#
# 1.02: doesn't matter what second line is
#
# 1.04: removed "xiit"
#
# 1.05: !lasttime myNick added
#
# 1.06: added scoring indicator
#
# 1.07: added "hyper hilight" option
#
# 1.08: added options for phone scoring with mirggi client
#
# 1.09: changed so that phone hilight sends second scoring line

use vars qw($VERSION %IRSSI);
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use Irssi;
use Irssi::TextUI;

$VERSION = '1.09';
%IRSSI = (
    authors     => 'Jonkka, rawl, zarillo, zguL',
    contact     => 'zguL@IRCnet',
    name        => 'Irssi_mm',
    description => 'Hilight script for #ranks@IRCnet',
    license     => 'Public Domain',
);


my $second_line = [gettimeofday];
my $first_line = [gettimeofday];
my $scorestatus = 0;
my $scoringstatus = 0;
my $second_scoring_line = 0;
my $didscore = 0;
my $result = "UNKNOWN";
my $timeout_tag = 0;
my $inputline = "";

sub line_timer {
	my ($server, $msg, $nick, $address, $target) = @_ ;
	@splitfitt = split(/ /, $msg);
	
	# received line from machine
        if ($nick eq "MACHINE[]") {
			# machine second scoring line
			if (($target eq "#ranks") && ($second_scoring_line)) {
				$second_line = [gettimeofday];
				$second_scoring_line = 0;
				$line_diff = tv_interval $first_line, $second_line;
				$didscore = 0;
				refresh_indicator();
				$scorestatus = 1;	# scoring is on! = forward msg said on #ranks directly to machine
				if (Irssi::settings_get_bool('ranks_mirggi_hilight')) {
					my $phone_nick = Irssi::settings_get_str('ranks_mirggi_nick');
					$server->command("/MSG $phone_nick $msg");
				}
				

			}
			# machine first scoring line
			if (($splitfitt[2] eq "MEGA") || ($splitfitt[2] eq "BONUS") || (($splitfitt[2] eq "IS") && ($splitfitt[3] eq "SCORING")) || ($splitfitt[2] eq "QUICK-ROUND))[][][][][][][][][][][]]")) {
				$first_line = [gettimeofday];
				$server->command("/join #ranks");
				Irssi::signal_emit("scoring", ("POPUP\n"));
				beep();
				if (Irssi::settings_get_bool('ranks_hyper_hilight')) {
					my $beepinterval = Irssi::settings_get_int('ranks_hyper_hilight_beep_interval');
					$timeout_tag = Irssi::timeout_add($beepinterval, 'beep', undef);
				}
				$second_scoring_line = 1;
				$result = "UNKNOWN";
				$scoringstatus = 1;

			}
			
			# machine scoring over line
			if (($splitfitt[2] eq "over") && ($splitfitt[3] eq "--")) {
				$scorestatus = 0;
				$scoringstatus = 0;
				refresh_indicator();
				if (Irssi::settings_get_bool('ranks_hyper_hilight')) {
					Irssi::timeout_remove($timeout_tag);
				}
			}
		}

		elsif ($scorestatus == 0)
		{
			$myOwnNick = $server->{nick};
			if ($msg eq "!lasttime $myOwnNick" || $msg eq "!lasttime $myOwnNick ") 
			{
				if ($didscore==0) 
				{
					$server->command("/msg $target I didn't score on last scoring");
				}
				else 
				{
					$rounded1 = sprintf("%.3f", $answer2);
					$rounded2 = sprintf("%.3f", $line_diff);
					$server->command("/msg $target I answered in $rounded1 secs, time between 2 first lines was $rounded2 secs, I got $result");
				}
			}
		}

}


sub send_answer {
	my($server, $msg, $target2, $org_target) = @_ ;
	if ($target2 eq "MACHINE[]") {
		$answer_time = [gettimeofday];
		my $answer = tv_interval $second_line, $answer_time;
		$answer2 = tv_interval $second_line, $answer_time;
		$stringen = "Answer: $answer - LineDiff: $line_diff";
		my $awin = Irssi::active_win();
		$awin->print($stringen );


	}
}
 

sub redirect_machine {
	my($line, $server, $window) = @_ ;
	if ( ($scorestatus == 1) && ($window->{name} eq "#ranks") ) {
		@send = split(/ /, $line);
		if ($send[1]) {
			$answer = $send[0] * $send[1];
		}
		else {
			if ($line) {
				$answer = $line; 
			}
            else { 
				$answer = 0; 
			}		        
		}
		$didscore = 1;
		$scorestatus = 0;
		refresh_indicator();
		$server->command("/MSG MACHINE[] $answer");
		if (Irssi::settings_get_bool('ranks_hyper_hilight')) {
			Irssi::timeout_remove($timeout_tag);
		}
		Irssi::signal_stop();	
	}
}

sub redirect_phone_to_machine {
	my($line, $server) = @_;
	@send = split(/ /, $line);
	if ($send[1]) {
		$answer = $send[0] * $send[1];
	}
	else {
		if ($line) {
			$answer = $line; 
		}
           else { 
			$answer = 0; 
		}		        
	}
	$didscore = 1;
	$scorestatus = 0;
	refresh_indicator();
	$server->command("/MSG MACHINE[] $answer");
	if (Irssi::settings_get_bool('ranks_hyper_hilight')) {
		Irssi::timeout_remove($timeout_tag);
	}
}	


sub handle_private {
	my ($server, $msg, $nick, $address, $target) = @_ ;
	if ($nick eq "MACHINE[]")
	{
		@privline = split(/ /, $msg);
		if($privline[0] eq "Right,")
		{
			$result = $privline[5];
		}
		elsif($privline[0] eq "Wrong")
		{	
			$result = -50.0;
		}	
	}
	if ($nick eq Irssi::settings_get_str('ranks_mirggi_nick')) {
		redirect_phone_to_machine($msg, $server);
	}
}


sub scoring_indicator {
	my ($item, $get_size_only) = @_;
	my $wi = !Irssi::active_win() ? undef : Irssi::active_win()->{active};
	if(!ref $wi || $wi->{type} ne "CHANNEL") { # only works on channels
		return unless ref $item;
		$item->{min_size} = $item->{max_size} = 0;
		return;
	}
    # use the default look
	$format = "{sb ";
	if (!$didscore && $scoringstatus) {
		$format .= "\%GUNANSWERED SCORING ON";
	}
	elsif ($scoringstatus) {
		$format .= "\%nON";
	}
	else {
		$format .= "\%nOFF";
	}
	$format =~ s/ $//;
	$format .= "\%c}";
	$item->default_handler($get_size_only, $format, undef, 1);
}


sub refresh_indicator {
	Irssi::statusbar_items_redraw('scoring_indicator');
}


sub beep {
	Irssi::command("/beep");
}


Irssi::statusbar_item_register('scoring_indicator', undef, 'scoring_indicator');
Irssi::statusbars_recreate_items();
Irssi::settings_add_bool('irssi_mm', 'ranks_hyper_hilight', 0);
Irssi::settings_add_int('irssi_mm', 'ranks_hyper_hilight_beep_interval', 1000);
Irssi::settings_add_bool('irssi_mm', 'ranks_mirggi_hilight', 0);
Irssi::settings_add_str('irssi_mm', 'ranks_mirggi_nick', '');
Irssi::signal_add('message public', 'line_timer');
Irssi::signal_add('message own_private', 'send_answer');
Irssi::signal_add('send text', 'redirect_machine');
Irssi::signal_add('message private', 'handle_private');

my $signal_config_hash = { "scoring" => [ "string" ] };
Irssi::signal_register($signal_config_hash);

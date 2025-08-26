#!/usr/bin/perl
# perl_mailer.pl
# send emails with perl

use strict;
use warnings;
use Mail::Send;

my ($subject, $message, $recipient) = @ARGV;

die "Usage: $0 <subject> <message> <recipient>\n" unless $recipient;

my $msg = Mail::Send->new;
$msg->to($recipient);
$msg->subject($subject);
$msg->set('From', 'dao_ops@discover-cron');

my $fh = $msg->open;
print $fh $message;
$fh->close;

print "Mail sent to $recipient\n";

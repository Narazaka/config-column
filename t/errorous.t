use utf8;
use strict;
use warnings;
use Test::More tests => 5;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

my $datafile = 'errorous';
my $encoding = 'utf8';
my $order = [qw(1 name subject date value mail url key host addr)];
my $delimiter = "\t";
my $cc0 = Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,42);
is(ref $cc0,'Config::Column','valid index');
my $cc1 = $cc0->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,-1);
isnt(ref $cc1,'Config::Column','invalid index');
my $cc2 = $cc0->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'宇宙');
isnt(ref $cc2,'Config::Column','invalid index');
my $cc3 = Config::Column::new(undef,$FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'宇宙');
isnt(ref $cc3,'Config::Column','invalid initialize');

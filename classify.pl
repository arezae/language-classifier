#!/usr/bin/perl -w

# Created: 29 April 2014
# By: Ali Reza Ebadat

# The goal is to classify sentences based on their languages



use strict;
use warnings;

use utf8;
binmode(STDOUT, ":utf8");
binmode(STDIN, ":utf8");


sub ngram($$){
	# return ngram of the given word
	my ($word, $n) = @_;
	my %ngram = ();
	my @chars = split("",$word);
	for(my $i=0; $i<length($word);$i++){
		my $str = substr($word,$i,$n);
		$ngram{$str}++ if(length($str)==$n);
	}
	return \%ngram;
}
###############################
# main
my $testFileName = "data/corpus-test.txt";
my $trainFileName = "data/corpus-train.txt";

my $N = 2; # for ngram
$N = $ARGV[0] if(defined $ARGV[0]);

print "ngram = $N gram\n";
print "Press any key to continue ...\n";
<STDIN>;

my %lgCodes = ();
my %lgCodeNgramCount = (); # lgCode:ngram-count
my %allNgram = (); # ngram
my %langNgram = (); # lgCode:ngram
my $lineNo = 0;
open (inFile , "<$trainFileName") or die "Cannot open $trainFileName \n";
while(my $line = <inFile>){
	chomp($line);
	$lineNo++;
	my @parts = split(" ", $line);
	my $lgCode = pop(@parts);
	my $sentence = join(" ", @parts);
	$lgCodes{$lgCode}++;
	my $ngramHash = ngram($sentence, $N);
	foreach my $ng (keys %$ngramHash){
		$langNgram{$lgCode}{$ng}++;
		$lgCodeNgramCount{$lgCode}++;
		$allNgram{$ng}++;
	}
}
close(inFile);
print keys(%lgCodes)." languages\n";

# there is an error in line 28490 of the training data 
foreach my $lg(keys(%lgCodes)){
	next if($lg =~ /HASH/);
#	print "$lg \t ".$lgCodes{$lg}."\n";
	delete $lgCodes{$lg} if($lgCodes{$lg} == 1);
}
# read test file
my %result = (); # sentence:lgCode
my $precision = 0;
my $correct = 0;
my $totalLines = 0;
open(inFile, "<$testFileName") or die "Cannot open test file:\n $testFileName\n";
while(my $line = <inFile>){
	chomp($line);
	$totalLines++;
	my @tokens = split(" ", $line);
	my $lgCode = pop(@tokens);
	my $sentence = join(" ", @tokens);
	my $ngramHash = ngram($sentence, $N);
	my $totalNgramCount = 0;
	foreach my $ng(keys %$ngramHash){
		$totalNgramCount += $ngramHash->{$ng};
	} 
	my $minDistance;
	my $lgRes;
	foreach my $lg(keys %lgCodes){
		# calcualte the distance of the current sentence from each language
		next if($lg =~ /HASH/);
		my $distance = 0;
		foreach my $ng(keys %$ngramHash){
			next if($ng =~ /HASH/);
			if ( defined $allNgram{$ng}){ # ignore new ngrams from test data
				my $ngCount = 0.5; 
				$ngCount = $langNgram{$lg}{$ng} if (defined $langNgram{$lg}{$ng}); 
				my $qx = $ngCount / $lgCodeNgramCount{$lg};
				my $px = $ngramHash->{$ng} / $totalNgramCount;				
				$distance += $px + log($px/$qx);
			}
		}
		if (defined $minDistance){
			if($distance < $minDistance){
				$minDistance = $distance;
				$lgRes = $lg;
			}
		}
		else{
			$minDistance = $distance;
			$lgRes = $lg;
		}
#		print "The best lg --> $lgRes ($lgCode) [$minDistance]\n";
	}
#	$result{$sentence} = $lgRes."_".$lgCode;
	$correct++ if($lgRes eq $lgCode);
#	print $result{$sentence}."\n";
#	<STDIN>;
}
close(inFile);

$precision = 100*$correct/$totalLines;
print "Final result: \n";
print "     Precision: $precision\n";
print "     correct: $correct\n";
print "     total: $totalLines\n";

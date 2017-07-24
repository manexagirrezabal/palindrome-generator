#!/usr/bin/perl

#############################################################################################
#                                                                                           #
#  Palindrome generator                                                                     #
#                                                                                           #
#  Usage: pg.perl [options]                                                                 #
#                                                                                           #
#         OPTIONS:                                                                          #
#                                                                                           #
#         -d             print debug info                                                   #
#         -m limit       max. length of sentences to generate (def 50)                      #
#         -s limit       max. number of sentences to generate for each recursion (def 20)   #
#         -l "string"    force palindrome to start with "string"                            #
#         -r "string"    force palindrome to end with "string"                              #
#         -1 file        read 1-grams from file                                             #
#         -2 file        read 2-grams from file                                             #
#         -3 file        read 3-grams from file                                             #
#         -4 file        read 4-grams from file                                             #
#         -f             when generating randomly, prefer high-frequency sequences/words    #
#                        as opposed to long words (the default behavior)                    #
#         -R "wordlist"  allow repetion of the words given, e.g. -R "the a an of in and"    #
#                        -R "*" allows repetition of any words                              #
#                                                                                           #
# Authors: Mans Hulden                                                                      #
#          Manex Agirrezabal                                                                #
#          2013/02/28                                                                       #
#                                                                                           #
# License: GPL v2                                                                           #
#                                                                                           #
#############################################################################################

use strict;
use Getopt::Std;

my %prefixes;
my %suffixes;
my %allwordshash;
my $lengthLimit = 50;
my @allwords = (); my @repetition_stoplist = (); my %repetition_hash;
my $debugging = 0; my $length1; my $length2; my $length3; my $length4; my $length5; my $filename; my $ngramorder;
my $start_over_limit = 20;
my $allow_repetitions = 0;
my $leftinit = ""; my $rightinit = ""; my $freqsort = 0;
my %opts;

getopts("dm:l:r:f1:2:3:4:R:s:",\%opts);

if (defined($opts{d})) { $debugging = 1;               } # Print debug info
if (defined($opts{m})) { $lengthLimit = $opts{m};      } # Sentence length upper limit
if (defined($opts{s})) { $start_over_limit = $opts{s}; } # Num. sentences to generate before starting over with recursion
if (defined($opts{l})) { $leftinit = $opts{l};         } # Set sentence start seed
if (defined($opts{r})) { $rightinit = $opts{r};        } # Set sentence end seed
if (defined($opts{1})) { $filename = $opts{1}; $ngramorder = 1;        } #
if (defined($opts{2})) { $filename = $opts{2}; $ngramorder = 2;        } #
if (defined($opts{3})) { $filename = $opts{3}; $ngramorder = 3;        } #
if (defined($opts{4})) { $filename = $opts{4}; $ngramorder = 4;        } #
if (defined($opts{f})) { $freqsort = 1;                } # Weight sort by frequency (instead of word length)
if (defined($opts{R})) { 
    if ($opts{R} eq "*") {
	$allow_repetitions = 1;
    } else {
	@repetition_stoplist = split / +/, $opts{R};    
	foreach (@repetition_stoplist) { $repetition_hash{$_} = 1; }
    }
}                                                        # Allow repetition of certain words, e.g. -R "the a an in on"
                                                         # Allow any repetition by saying -R "*"

open (WORDS, $filename) or die("No n-grams/lexicon file found");

print STDERR "Reading $ngramorder-grams from $filename\n";

my $i = 0;
while (<WORDS>) {
    chomp;
    my $freq = 0;
    my @wordsline = split '\t';
    if (defined $wordsline[$ngramorder]) {
	$freq = $wordsline[$ngramorder];
    } else {
	$freq = 1;
    }
    # Create n-gram hash: word_1/word_2/.../word_n
    my $hashstring = join('/',  @wordsline[0 .. $ngramorder-1]);
    dprint("HASHSTRING: $hashstring FREQ: $freq\n");
    if ($ngramorder > 1) {
	$allwordshash{$hashstring} = $freq;
    }
    # Always add first word to 1-gram dictionary
    if ($wordsline[0] ne "#") {
	if (!defined $allwordshash{$wordsline[0]}) {
	    dprint("Adding word $wordsline[0]\n");
	    addPreSuff($wordsline[0]);
	    push @allwords, $wordsline[0];
	}
	$allwordshash{$wordsline[0]} += $freq;
    }
    if ($i % 100000 == 0) {
	print STDERR ".";
	my $old_fh = select(STDERR);
	$| = 1;
	select($old_fh);
    }
    $i++;
}

close (WORDS);

print STDERR "\nDone.\n";

my $num_prints;
for ($num_prints == 0;;$num_prints = 0) {
    main($leftinit, $rightinit);
}

#################################################################################
# Calculate the "quotient" of two strings L and reverse(R)                      #
# e.g. differ(a b c d, b a) = c d                                               #
# returns the quotient, and the side of the remainder as a list ($q, $side)     #
# ("left" or "right" or "error")                                                #
#################################################################################

sub differ {
    my $strL = shift ();
    my $strR = shift ();
    $strL =~ s/\s//g;
    $strR =~ s/\s//g;
    my $minL = length($strL) < length($strR) ?  length($strL) : length($strR) ;
    $strR = reverse ($strR);
    
    if (substr ($strL, 0, $minL) ne substr ($strR, 0, $minL)) {
	return (-1, "error");
    } else {
	if (length($strL) < length($strR)) {
	    return (substr($strR, $minL), "right");
	} else {
	    return (substr($strL, $minL), "left");
	}
    }
}

sub dprint {
    my $arg = shift;
    if ($debugging == 1) {
        print $arg;
    }
}

# Returns true if string is a palindrome (ignoring spaces)
sub isPalindrome {
    my $str1 = shift;
    $str1 =~ s/\s//g;
    return ($str1 eq reverse ($str1));
}

##############################################################################
# Adds a word to the hash $prefixes{$pref} where $pref is any prefix of word #
# And likewise with $suffixes{$suff} where $suff is any suffix of the word   #
##############################################################################

sub addPreSuff {
    my $word = shift ();

    for (my $i = 1; $i <= length($word); $i++) {
	my $pref = substr ($word, 0, $i);
	my $suff = substr ($word, length($word) - $i, $i);
	push (@{$prefixes{$pref}}, $word);
	push (@{$suffixes{$suff}}, $word);
    }
}

##############################################################
# To generate a palindrome, we recursively call main         #
# with two arguments $l and $r (the left and right parts     #
# of the current palindrome.  We then do the following:      #
# if the overhang from comparing $l and $r (in reverse) is a #
# palindrome, then $l $r is a palindrome and is printed;     #
# otherwise a matching word is chosen and added to $l or $r  #
# and main($l,$r) is called recursively.  When choosing a    #
# matching word to $l or $r, we only choose from such words  #
# that would yield attested n-gram sequences.                #
# Also, given a choice, we prefer to add longer words, or    #
# words that yield high-frequency n-grams, and disallow      #
# word repetitions within the phrase, unless the words       #
# appear in a stoplist given by the user.                    #
# Normally, we start off by calling main("","") , that is,   #
# with $l and $r empty.  However,  the initial $l and $r     #
# can be set by the user for fine-grained artistic control.  #
##############################################################

sub main {
    if ($num_prints == $start_over_limit) {
	return;
    }
    my $l = shift;
    my $r = shift;
    dprint("LEFT:[$l] RIGHT:[$r]\n");
    if (length($r) + length ($l) > $lengthLimit) {
	dprint("LENGTH LIMIT $lengthLimit REACHED\n");;
	return;
    }
    if ($l eq "" and $r eq "") {
	my $randomword = $allwords[rand @allwords];
	main($randomword, "");
	return;
    }

    my ($D, $side) = differ($l, $r);
    dprint("D: [$D] side:[$side]\n");

    if (isPalindrome($D)) {
	$num_prints++;
	print "$l $r\n";
    }

    my @H = ();

    if ($D eq "") {
	@H = @allwords;
    } elsif ($side eq "left") {
	my $Dinv = reverse($D);
	for (my $i = 1; $i <= length($Dinv); $i++) {
	    my $suff = substr ($Dinv, length($Dinv) - $i, $i);
	    if (defined $allwordshash{$suff}) {		
		push @H, $suff;
	    }
	}
	if (defined $suffixes{$Dinv}) {
	    push @H, @{$suffixes{$Dinv}};
	}
    }    

    if ($D ne ""  and $side eq "left") {
	my $rc = "$r # #";

        ############################################
	# Remove words that don't occur as n-grams #
        ############################################

	if ($ngramorder > 1) {
	    @H = grep { $allwordshash{ $_ ."/" .join('/',(split ' ', $rc)[0 .. $ngramorder - 2]) } >= 1 } @H;
	}
	if ($allow_repetitions == 0) {
	    my @wll = split / +/, "$l $r";
	    my %seenw = ();
	    foreach (@wll) {
		$seenw{$_} = 1;
	    }
	    @H = grep { $repetition_hash{$_} == 1 or $seenw{$_} != 1 } @H;
	}
	
        #############################################################
	# The following may go down in history as the most          #
	# unspeakable abuse of the sort function ever witnessed...  #
	# Weighted sort of candidate list H by word length:         #
        #############################################################

	if ($freqsort == 0) { @H = sort { rand(length($a) + length($b)) <=> length($a) } @H };

	# Weighted sort of candidate list H by word frequency:
	if ($freqsort == 1 and $ngramorder == 3) { @H = sort { rand($allwordshash{$a} + $allwordshash{$b}) <=> $allwordshash{$a} } @H };
	    
	if ($freqsort == 1 and $ngramorder == 2) { @H = sort { rand($allwordshash{ $a ."/" .(split ' ', $rc)[0] } + $allwordshash{ $b ."/" .(split ' ', $rc)[0] }) <=> $allwordshash{ $a ."/" .(split ' ', $rc)[0] } } @H };

	foreach (@H) {
	    main($l, $_ ." $r");
	}
    } elsif ($side eq "right" or $D eq "") {
	my $Dinv = $D;
	for (my $i = 1; $i <= length($Dinv); $i++) {
	    my $pref = substr ($Dinv, 0, $i);
	    if (defined $allwordshash{$pref}) {		
		push @H, $pref;
	    }
	}
	if (defined $prefixes{$Dinv}) {
	    push @H, @{$prefixes{$Dinv}};
	}
	dprint("Dinv [$Dinv]  H[" .join("-",@H). "]\n");
	return if (scalar(@H) == 0);
	my $lc = "# # $l";
	if ($ngramorder > 1) {
	    @H = grep { $allwordshash{ join('/',(split ' ', $lc)[1-$ngramorder .. -1]) . "/" ."$_" } >= 1 } @H;
	}
	# Remove words that would repeat, except those explicitly allowed
	if ($allow_repetitions == 0) {
	    my @wll = split / +/, "$l $r";
	    my %seenw = (); 
	    foreach (@wll) {
		$seenw{$_} = 1;
	    }
	    @H = grep { $repetition_hash{$_} == 1 or $seenw{$_} != 1 } @H;
	}

	# Weighted sort of candidate list by word length:
	if ($freqsort == 0) { @H = sort { rand(length($a) + length($b)) <=> length($a) } @H };
	# Weighted sort of candidate list by word frequency:
	if ($freqsort == 1 and $ngramorder == 3) { @H = sort { rand($allwordshash{$a} + $allwordshash{$b}) <=> $allwordshash{$a} } @H };
	if ($freqsort == 1 and $ngramorder == 2) { @H = sort { rand($allwordshash{ substr($lc, rindex($lc, ' ') + 1) ."/" .$a } + $allwordshash{ substr($lc, rindex($lc, ' ') + 1) ."/" .$b }) <=> $allwordshash{ substr($lc, rindex($lc, ' ') + 1) ."/" .$a } } @H };
	
	foreach (@H) {
	    main($l ." " .$_, $r);
	}
    } else {
	return;
    }
}

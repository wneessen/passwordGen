#!/usr/bin/env perl

## Load required modules
use warnings;
use strict;
use v5.12;
use Carp;
use Encode;
use Crypt::PRNG;
use Data::Dumper;
use Getopt::Long;
use MIME::Base64;

## Global defaults
my $VERSION                 = 1.02;
my $DEFAULT_RAND_FUNC       = 'ChaCha20';
my $DEFAULT_PASS_LENGTH     = 20;
my $PW_LOWER_CHARS_HUMAN    = qq(abcdefghjkmnpqrstuvwxyz);
my $PW_UPPER_CHARS_HUMAN    = qq(ABCDEFGHJKMNPQRSTUVWXYZ);
my $PW_LOWER_CHARS          = qq(abcdefghijklmnopqrstuvwxyz);
my $PW_UPPER_CHARS          = qq(ABCDEFGHIJKLMNOPQRSTUVWXYZ);
my $PW_SPECIAL_CHARS_HUMAN  = qq(#/\\\$%&+-*);
my $PW_SPECIAL_CHARS        = qq(#/!\$%&+-*.,"?=\(\)[]{}:;~^|);
my $PW_NUMBERS_HUMAN        = qq(23456789);
my $PW_NUMBERS              = qq(1234567890);

## Global variables
my %config;

## Add defaults
$config{useLowerCase}       = 1;
$config{useUpperCase}       = 0;
$config{useNumbers}         = 0;
$config{useSpecialChars}    = 0;
$config{humanReadable}      = 1;
$config{numberPasswords}    = 1;
$config{minPassLength}      = 1;
$config{maxPassLength}      = $DEFAULT_PASS_LENGTH;

## Read CLI arguments
Getopt::Long::Configure('bundling', 'no_ignore_case');
GetOptions(
    'minpasslen|m=i'    => \$config{minPassLength},
    'maxpasslen|x=i'    => \$config{maxPassLength},
    'numofpass|n=i'     => \$config{numberPasswords},
    'complex|C'         => \$config{complexPass},
    'uppercase|U'       => \$config{useUpperCase},
    'numbers|N'         => \$config{useNumbers},
    'special|S'         => \$config{useSpecialChars},
    'human|H'           => \$config{humanReadable},
    'exclude|E=s'       => \$config{excludeChars},
    'help|h'            => \$config{showHelp},
    'version|v'         => \$config{showVersion},
);
_showVersion() if defined($config{showVersion});
_showHelp() if defined($config{showHelp});
_showHelp('Min. password length too small') if($config{minPassLength} && $config{minPassLength} < 1);
_showHelp('Max. password length too small') if($config{maxPassLength} && $config{maxPassLength} < 1);
_showHelp('Max. password length cannot be smaller than min. lenght') if(
    (defined($config{minPassLength}) && defined($config{maxPassLength})) &&
    $config{maxPassLength} < $config{minPassLength}
);

## Generate random password(s)
for(1..$config{numberPasswords}) {
    say _genPass();
}

## Generate a random password string // _genPass() {{{
##  Requires:   undef
##  Optional:   undef
##  onSuccess:  passString
##  onFailure:  undef
sub _genPass {

    my $pseudoRandNumGen = _getRandObj();
    my $pwLength = int($pseudoRandNumGen->double($config{maxPassLength}));
    $pwLength = $config{minPassLength} if($pwLength < $config{minPassLength});
    $pwLength = $config{maxPassLength} if($pwLength > $config{maxPassLength});
    
    ## Do we want complex passwords?
    if(defined($config{complexPass}) && $config{complexPass} == 1) {
        $config{useUpperCase} = 1;
        $config{useNumbers} = 1;
        $config{useSpecialChars} = 1;
        $config{humanReadable} = 0;
    }

    ## Define the character classes (human readable or not)
    my $pwUpperChars = $PW_UPPER_CHARS;
    my $pwLowerChars = $PW_LOWER_CHARS;
    my $pwNumbers = $PW_NUMBERS;
    my $pwSpecialChars = $PW_SPECIAL_CHARS;
    if(defined($config{humanReadable}) && $config{humanReadable} == 1) {
        $pwUpperChars = $PW_UPPER_CHARS_HUMAN;
        $pwLowerChars = $PW_LOWER_CHARS_HUMAN;
        $pwNumbers = $PW_NUMBERS_HUMAN;
        $pwSpecialChars = $PW_SPECIAL_CHARS_HUMAN;
    }

    ## Generate a secure password
    my $charRange = $pwLowerChars;
    $charRange .= (defined($config{useUpperCase}) && $config{useUpperCase} == 1) ? $pwUpperChars : '';
    $charRange .= (defined($config{useNumbers}) && $config{useNumbers} == 1) ? $pwNumbers : '';
    $charRange .= (defined($config{useSpecialChars}) && $config{useSpecialChars} == 1) ? $pwSpecialChars : '';
    if(defined($config{excludeChars})) {
        $charRange =~ s/[$config{excludeChars}]//g;
    }

    return $pseudoRandNumGen->string_from($charRange, $pwLength);
}
# }}}

## Provide a cryptographical secure pseudo-random number generator // _getRandObj() {{{
##  Requires:   undef
##  Optional:   undef
##  onSuccess:  randObj
##  onFailure:  croak
sub _getRandObj {
    my ($self, $randFunc) = @_;
    my $randObj = eval {
        Crypt::PRNG->new($randFunc || $DEFAULT_RAND_FUNC);
    };
    if($@ || !defined($randObj)) {
        croak('Error while creating PRNG object: ' . $@);
    }

    return $randObj;
}
# }}}

## Show CLI help text // _showHelp() {{{
##  Requires:   undef
##  Optional:   undef
##  onSuccess:  Prints help text
##  onFailure:  undef
sub _showHelp {
    my $hasError = shift;

    if(defined($hasError)) {
        say STDERR 'Error: ' . $hasError;
        say '';
    }
    say STDERR 'Advanced Password Generator v' . $VERSION;
    say STDERR 'Usage: ' . $0 . ' <arguments>';
    say STDERR '';
    say STDERR '    -m, --minpasslen       Minimum password length';
    say STDERR '    -x, --maxpasslen       Maximum password length';
    say STDERR '    -n, --numofpass        Number of passwords to generate';
    say STDERR '    -C, --complex          Generate complex passwords (enables -U -N -S and disabled -H)';
    say STDERR '    -U, --uppercase        Use uppercase characters in passwords';
    say STDERR '    -N, --numbers          Use numbers in passwords';
    say STDERR '    -S, --special          Use special characters in passwords';
    say STDERR '    -H, --human            Avoid ambiguous characters (like l, 1 o, O, 0)';
    say STDERR '    -h, --help             Show this help text';
    say STDERR '';

    if(defined($hasError)) {
        exit 1;
    }
    else {
        exit 0;
    }
}

## Show CLI version text // _showVersion() {{{
##  Requires:   undef
##  Optional:   undef
##  onSuccess:  Prints version string
##  onFailure:  undef
sub _showVersion {

    say STDERR 'Advanced Password Generator v' . $VERSION;
    exit 0;
}

1;
#!/usr/bin/env perl
#
# Update Ghostty theme randomly.

use strict;
use warnings;
use Cwd 'abs_path';

my $DOTFILES_ROOT = abs_path($0);
$DOTFILES_ROOT =~ s!/ghostty/[^/]+$!!;

system("source $DOTFILES_ROOT/lib/logger.sh && info 'Updating Ghostty theme'");

# Set random seed if provided
srand($ARGV[0]) if @ARGV;

# Get available themes and select one randomly
my $themes = [ map { s/ \(.*\)$//; $_ } `ghostty +list-themes` ];
chomp @$themes;
my $new_theme = $themes->[int(rand(@$themes))];

# Config file path
my $config_file = "$DOTFILES_ROOT/ghostty/config";

my $updated = 0;
my $content = '';

# Read existing configuration
open(my $in, '<', $config_file) or die "Cannot open $config_file: $!";
while (my $line = <$in>) {
    if ($line =~ /^theme/) {
        # Replace existing theme line
        $content .= "theme = $new_theme\n";
        $updated = 1;
    } else {
        $content .= $line;
    }
}
close $in;

# Append theme if not found in existing config
if (!$updated) {
    $content .= "theme = $new_theme\n";
}

# Write updated configuration
open(my $out, '>', $config_file) or die "Cannot write to $config_file: $!";
print $out $content;
close $out;

system("source $DOTFILES_ROOT/lib/logger.sh && success 'Theme updated to: $new_theme'");

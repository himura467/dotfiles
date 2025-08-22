#!/usr/bin/env perl
#
# Update Ghostty theme randomly.

use strict;
use warnings;
use Cwd 'abs_path';

my $DOTFILES_ROOT = abs_path($0);
$DOTFILES_ROOT =~ s!/ghostty/[^/]+$!!;

# Set random seed if provided
srand($ARGV[0]) if @ARGV;

# Get favorites file path
my $favorites_file = "$DOTFILES_ROOT/ghostty/favorites.txt";

# Get available themes
my $themes = [ map { s/ \(.*\)$//; $_ } `ghostty +list-themes` ];
chomp @$themes;

my $new_theme;

# Use favorites 50% of the time if favorites file exists and has content
if (-f $favorites_file && rand() < 0.5) {
    my $favorites = [];
    open(my $fav_in, '<', $favorites_file) or die "Cannot open $favorites_file: $!";
    while (my $line = <$fav_in>) {
        chomp $line;
        push @$favorites, $line if $line;
    }
    close $fav_in;
    
    if (@$favorites) {
        $new_theme = $favorites->[int(rand(@$favorites))];
        system("source $DOTFILES_ROOT/lib/logger.sh && info 'Selected from favorites'");
    } else {
        # Fall back to all themes if favorites is empty
        $new_theme = $themes->[int(rand(@$themes))];
        system("source $DOTFILES_ROOT/lib/logger.sh && info 'Selected from all themes'");
    }
} else {
    # Select from all themes
    $new_theme = $themes->[int(rand(@$themes))];
    system("source $DOTFILES_ROOT/lib/logger.sh && info 'Selected from all themes'");
}

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

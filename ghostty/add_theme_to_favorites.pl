#!/usr/bin/env perl
#
# Add current Ghostty theme to favorites.

use strict;
use warnings;
use Cwd 'abs_path';

my $DOTFILES_ROOT = abs_path($0);
$DOTFILES_ROOT =~ s!/ghostty/[^/]+$!!;

# Config and favorites file paths
my $config_file = "$DOTFILES_ROOT/ghostty/config";
my $favorites_file = "$DOTFILES_ROOT/ghostty/favorites.txt";

# Get current theme from config
my $current_theme = '';
open(my $in, '<', $config_file) or die "Cannot open $config_file: $!";
while (my $line = <$in>) {
    if ($line =~ /^theme\s*=\s*(.+)$/) {
        $current_theme = $1;
        chomp $current_theme;
        last;
    }
}
close $in;

if (!$current_theme) {
    system("source $DOTFILES_ROOT/lib/logger.sh && error 'No theme found in config'");
    exit 1;
}

# Read existing favorites
my $favorites = [];
if (-f $favorites_file) {
    open(my $fav_in, '<', $favorites_file) or die "Cannot open $favorites_file: $!";
    while (my $line = <$fav_in>) {
        chomp $line;
        push @$favorites, $line if $line;
    }
    close $fav_in;
}

# Check if already in favorites
my $already_favorite = 0;
for my $theme (@$favorites) {
    if ($theme eq $current_theme) {
        $already_favorite = 1;
        last;
    }
}

if ($already_favorite) {
    system("source $DOTFILES_ROOT/lib/logger.sh && info 'Theme \"$current_theme\" is already in favorites'");
    exit 0;
}

# Add to favorites
push @$favorites, $current_theme;

# Write updated favorites (sorted)
open(my $fav_out, '>', $favorites_file) or die "Cannot write to $favorites_file: $!";
for my $theme (sort @$favorites) {
    print $fav_out "$theme\n";
}
close $fav_out;

system("source $DOTFILES_ROOT/lib/logger.sh && success 'Added \"$current_theme\" to favorites'");

# Copyright (C) 2002-2009 Will Norris. All Rights Reserved. (wbniv@saneasylumstudios.com)
# Copyright (C) 2005-2020 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html
#

package Foswiki::Plugins::ImageGalleryPlugin;
use strict;
use warnings;

our $VERSION = '8.20';
our $RELEASE = '26 Oct 2020';
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Displays image gallery with auto-generated thumbnails from attachments';
our $core;

sub initPlugin {
  #my ($topic, $web, $user, $installWeb) = @_;

  $core = undef;

  Foswiki::Func::registerTagHandler('IMAGEGALLERY', sub {
    getCore()->handleIMAGEGALLERY(@_);
  });

  return 1;
}

sub finishPlugin {

  $core->finish() if defined $core;
  #undef $core; # EXPERIMENTAL: keep it in memory
}

sub getCore {

  unless (defined $core) {
    require Foswiki::Plugins::ImageGalleryPlugin::Core;
    $core = Foswiki::Plugins::ImageGalleryPlugin::Core->new(@_);
  }

  return $core;
}

1;

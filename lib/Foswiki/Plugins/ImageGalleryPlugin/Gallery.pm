# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
# 
# Copyright (C) 2024-2026 Michael Daum, http://michaeldaumconsulting.com
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::ImageGalleryPlugin::Gallery;

=begin TML

---+ package Foswiki::Plugins::ImageGalleryPlugin::Gallery

This is the perl stub for the image gallery plugin.

=cut

use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin::Plugin ();
use Foswiki::Plugins::ImageGalleryPlugin ();
our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

=begin TML

---++ ClassMethod new( $class, $session, ... )

Constructor

=cut

sub new {
  my $class = shift;
  my $session = shift || $Foswiki::Plugins::SESSION;

  my $this = bless($class->SUPER::new( 
    $session,
    name => 'ImageGallery',
    version => $Foswiki::Plugins::ImageGalleryPlugin::VERSION,
    author => 'Michael Daum',
    homepage => 'http://foswiki.org/Extensions/ImageGalleryPlugin',
    puburl => '%PUBURLPATH%/%SYSTEMWEB%/ImageGalleryPlugin',
    documentation => "$Foswiki::cfg{SystemWebName}.ImageGalleryPlugin",
    javascript => ['build/igp.js'],
    css => ['build/igp.css'],
  ), $class);

  return $this;
}

1;

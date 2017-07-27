# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2002-2009 Will Norris. All Rights Reserved. (wbniv@saneasylumstudios.com)
# Copyright (C) 2005-2017 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::ImageGalleryPlugin::Core;

use strict;
use warnings;

use Foswiki::Func ();

use constant TRACE => 0; # toggle me

###############################################################################
# constructor
sub new {
  my $class = shift;

  my $this = bless({
    thumbSizes => $Foswiki::cfg{ImageGalleryPlugin}{ThumbSizes} // {
      thin => '25x25',
      small => '50x50',
      medium => '95x95',
      large => '150x150',
      huge => '350x350',
    },
    defaultSize => $Foswiki::cfg{ImageGalleryPlugin}{DefaultSize} // "medium",
    excludeSuffix => $Foswiki::cfg{ImageGalleryPlugin}{ExcludeSuffix} // "psd",
    @_
  }, $class);

  $this->{_doneZone} = 0;

  return $this;
}

###############################################################################
sub finish {
  my $this = shift;

  undef $this->{mage};
  undef $this->{types};
}

###############################################################################
sub handleIMAGEGALLERY {
  my ($this, $session, $params, $topic, $web) = @_;

  $params->{field} //= 'name';
  $params->{sort} //= 'name';
  $params->{reverse} //= 'off';
  $params->{size} //= $this->{defaultSize};
  $params->{warn} = Foswiki::Func::isTrue($params->{warn} // "on", 1);
  $params->{crop} //= "on";
  $params->{tooltip} = Foswiki::Func::isTrue($params->{tooltip} // "off", 0)?"on":"off";
  $params->{titles} = Foswiki::Func::isTrue($params->{titles} // "off", 0);
  $params->{lazyload} = Foswiki::Func::isTrue($params->{lazyload} // "on", 1);
  $params->{format} //= '%IMAGE{"$name" topic="$web.$topic" align="left" size="$size" crop="$crop" caption="$title" tooltip="$tooltip" filter="$filter"}%';
  $params->{header} //= '<noautolink><div class="$class clearfix" data-item-selector=".imageSimple">';
  $params->{footer} //= '</div></noautolink>';
  $params->{separator} //= '';
  $params->{limit} //= 0;
  $params->{skip} //= 0;
  $params->{filter} //= '';

  $params->{filter} = '' if $params->{filter} eq 'none';

  if (defined $this->{thumbSizes}{$params->{size}}) {
    $params->{size} = $this->{thumbSizes}{$params->{size}};
  }

  my @class = ("igp");
  push @class, $params->{class} if defined $params->{class};

  my $context = Foswiki::Func::getContext();

  # get best frontend
  if (!defined($params->{frontend}) || $params->{frontend} eq 'default') {
    foreach my $frontend (qw(PhotoSwipe PrettyPhoto Slimbox)) {
      if ($context->{$frontend."Registered"}) {
        $params->{frontend} = lc($frontend);
        last;
      }
    }
  }

  Foswiki::Plugins::JQueryPlugin::createPlugin($params->{frontend});
  push @class, 'jqPhotoSwipe' if $params->{frontend} eq 'photoswipe';
  push @class, 'jqPretyPhoto' if $params->{frontend} eq 'prettyphoto';
  push @class, 'jqSlimbox' if $params->{frontend} eq 'slimbox';

  if (defined $params->{layout}) {
    Foswiki::Plugins::JQueryPlugin::createPlugin($params->{layout});
    if ($params->{layout} eq 'packery') {
      push @class, 'jqPackery';
      $params->{size} =~ s/\d+x(\d+)/x$1^/;
    } elsif ($params->{layout} eq 'masonry') {
      push @class, 'jqMasonry';
      $params->{size} =~ s/(\d+)x\d+/$1x^/;
    }
  }

  my @images = $this->getImages($web, $topic, $params);
  unless (@images) {
    return _inlineError("no images found") if $params->{warn};
    return "";
  }

  my @result = ();
  my $index = 0;
  foreach my $image (@images) {
    $index++;
    next if $params->{skip} && $index <= $params->{skip};
    my $line = $params->{format};
    my $title = $params->{titles}?_getAttachmentTitle($image->{attachment}):'';
    $line =~ s/\$name/$image->{attachment}{name}/g;
    $line =~ s/\$web/$image->{web}/g;
    $line =~ s/\$topic/$image->{topic}/g;
    $line =~ s/\$size/$params->{size}/g;
    $line =~ s/\$crop/$params->{crop}/g;
    $line =~ s/\$tooltip/$params->{tooltip}/g;
    $line =~ s/\$title/$title/g;
    $line =~ s/\$filter/$params->{filter}/g;
    push @result, $line;
    last if $params->{limit} && $index >= $params->{limit};
  }
  return "" unless @result;

  my $header = $params->{header};
  my $footer = $params->{footer};
  my $separator = $params->{separator};

  my $result = $header.join($separator, @result).$footer;

  my $class = join(" ", @class);
  $result =~ s/\$class/$class/g;

  $this->addToZone();

  if ($params->{lazyload} && $context->{'LazyLoadPluginEnabled'}) {
    Foswiki::Plugins::JQueryPlugin::createPlugin("lazyload");
    $result = '%STARTLAZYLOAD%'.$result.'%ENDLAZYLOAD%';
  }

  return Foswiki::Func::decodeFormatTokens($result);
}


###############################################################################
sub addToZone {
  my $this = shift;

  return if $this->{_doneZone};
  $this->{_doneZone} = 1;

  Foswiki::Func::addToZone("head", "IMAGEGALLERYPLUGIN", <<'HERE', 'IMAGEPLUGIN');
<link rel="stylesheet" href="%PUBURLPATH%/%SYSTEMWEB%/ImageGalleryPlugin/style.css" type="text/css" media="all" />
HERE
}

###############################################################################
sub getImages {
  my ($this, $web, $topic, $params) = @_;

  my @topics = split (/\s*,\s*/, $params->{topic} // $params->{topics} // $topic);

  my $wikiName = Foswiki::Func::getWikiName();
  my @images = ();

  foreach my $theTopic (@topics) {
    my $theWeb;
    ($theWeb, $theTopic) = Foswiki::Func::normalizeWebTopicName($web, $theTopic);

    #_writeDebug("reading from $theWeb.$theTopic");
    my ($meta) = Foswiki::Func::readTopic($theWeb, $theTopic);

    unless (Foswiki::Func::checkAccessPermission("view", $wikiName, undef, $theTopic, $theWeb, $meta)) {
      _writeDebug("no view access to ... skipping");
      next;
    }

    foreach my $attachment ($meta->find('FILEATTACHMENT')) {
      next unless $this->isImage($attachment->{name});
      next if $params->{exclude} && $attachment->{$params->{field}} =~ /$params->{exclude}/;
      next if $params->{include} && $attachment->{$params->{field}} !~ /$params->{include}/;
      push @images, {
        web => $theWeb,
        topic => $theTopic,
        attachment => $attachment,
      };
    }
  }

  # pre sort
  if ($params->{sort} eq 'date') {
    @images = sort {$a->{attachment}{date} <=> $b->{attachment}{date}} @images;
  } elsif ($params->{sort} eq 'name') {
    @images = sort {lc($a->{attachment}{name}) cmp lc($b->{attachment}{name})} @images;
  } elsif ($params->{sort} eq 'comment') {
    @images = sort {lc($a->{attachment}{comment}) cmp lc($b->{attachment}{comment})} @images;
  } elsif ($params->{sort} eq 'size') {
    @images = sort {$a->{attachment}{size} <=> $b->{attachment}{size}} @images;
  }
  @images = reverse @images if $params->{reverse} eq 'on';

  return @images;
}

###############################################################################
sub isImage {
  my ($this, $file) = @_;

  my $mimeType = $this->getMimeType($file);
  my $isImage = $mimeType =~ /^image\//?1:0;

  #_writeDebug("isImage($file), mimeType=$mimeType, isImage=$isImage");

  return $isImage;
}

###############################################################################
sub getMimeType {
  my ($this, $file) = @_;

  my $mimeType = '';

  if ($file && $file =~ /\.([^.]+)$/) {
    my $suffix = $1;
   
    return "" if $this->{excludeSuffix} && $suffix =~ /^(?:$this->{excludeSuffix})$/i; # ignore these

    unless (defined $this->{types}) {
      $this->{types} = join("\n", grep {/^image\//} split(/\n/, Foswiki::Func::readFile($Foswiki::cfg{MimeTypesFileName})));
    }

    if ($this->{types} =~ /^([^#]\S*).*?\s$suffix(?:\s|$)/im) {
      $mimeType = $1;
    }
  }

  return $mimeType;
}

###############################################################################
# static
sub _writeDebug {
  #Foswiki::Func::writeDebug("ImageGalleryPlugin - $_[0]");
  print STDERR "ImageGalleryPlugin - $_[0]\n" if TRACE;
}

sub _inlineError {
  my $msg = shift;
  return '' unless $msg;
  return "<span class='foswikiAlert'>Error: $msg</span>" ;
}

###############################################################################
sub _getAttachmentTitle {
  my $attachment = shift;

  my $title;
  if ($attachment->{comment} && $attachment->{comment} !~ /^Auto\-attached/) {
    $title = $attachment->{comment};
  } else {
    $title =  $attachment->{name};
    $title =~ s/^(.*)\.[a-zA-Z0-9]*$/$1/;
  }
  $title =~ s/^\s+|\s+$//g;

  return $title;
}

1;

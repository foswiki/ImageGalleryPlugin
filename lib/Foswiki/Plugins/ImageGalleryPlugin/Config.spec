# ---+ Extensions
# ---++ ImageGalleryPlugin

# **PERL**
# Defintion of thumbnailsizes 
$Foswiki::cfg{ImageGalleryPlugin}{ThumbSizes} = {
    thin => '25x25',
    small => '50x50',
    medium=> '95x95',
    normal => '120x120',
    large => '150x150',
    huge => '250x250',
};

# **STRING**
# Default thumbnail size to be used when no size parameter is specified to the %IMAGEGALLERY macro
$Foswiki::cfg{ImageGalleryPlugin}{DefaultSize} = 'large';

# **STRING**
# A pattern of filetype suffixes to be excluded from imagegalleries even though they are 
# valid images
$Foswiki::cfg{ImageGalleryPlugin}{ExcludeSuffix} = 'psd';

1;

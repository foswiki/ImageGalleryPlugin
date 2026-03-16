/*
 * ImageGalleryPlugin
 *
 * Copyright (c) 2024-2026 Michael Daum https://michaeldaumconsulting.com
 *
 * Licensed under the GPL licenses http://www.gnu.org/licenses/gpl.html
 *
 */

"use strict";
(function($) {

  // Create the defaults once
  var defaults = {};

  // The actual plugin constructor
  function ImageGallery(elem, opts) {
    var self = this;

    self.elem = $(elem);
    self.opts = $.extend({}, defaults, self.elem.data(), opts);

    self.elem.on("refresh.igp", function(ev) {
      self.load();
      ev.stopPropagation();
    });

    self.initEvents();
  }

  ImageGallery.prototype.initEvents = function() {
    var self = this;

    if (self._initedEvents) {
      return;
    }

    if (!foswiki.eventClient) {
      $(document).one("eventClient", function() {
        self.initEvents();
      });
      return;
    }

    self._initedEvents = true;

    foswiki.eventClient.bind("upload", function(msg) {
      self.load();
    });
    foswiki.eventClient.bind("moveAttachment", function(msg) {
      self.load();
    });
  };

  ImageGallery.prototype.getParams = function() {
    var self = this;

    if (typeof(self.opts.params) === 'undefined') {
      self.opts.params = JSON.parse(self.elem.children(".igpParams").text());

      for (const [key, val] of Object.entries(self.opts.params)) {
        self.opts.params[key] = decodeURIComponent(val);
      }

      //console.log("params=",self.opts.params);
    }

    return self.opts.params;
  };

  ImageGallery.prototype.load = function() {
    var self = this,
        web = self.opts.web || foswiki.getPreference("WEB"),
        topic = self.opts.topic || foswiki.getPreference("TOPIC"),
        params = $.extend({}, self.getParams()),
        url = foswiki.getScriptUrl("rest", "RenderPlugin", "tag");

    params.web = web;
    params.topic = web + "." + topic;
    params.render = 'on';
    params.name = 'IMAGEGALLERY';
    params.skin = 'text';
    params.t = Date.now();

    $.get(
      url,
      params,
      function(data) {
        self.elem.replaceWith(data);
      }, 'html');
  };

  // A plugin wrapper around the constructor,
  // preventing against multiple instantiations
  $.fn.imageGallery = function (opts) {
    return this.each(function () {
      if (!$.data(this, "ImageGallery")) {
        $.data(this, "ImageGallery", new ImageGallery(this, opts));
      }
    });
  };

  // Enable declarative widget instanziation
  $(function() {
    $(".igp").livequery(function() {
      $(this).imageGallery();
    });
  });

})(jQuery);


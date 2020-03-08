// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

'use strict';

chrome.browserAction.onClicked.addListener(function(tab) {
  openOrFocusBackgroundPage();
});

// Open options page
function openOrFocusBackgroundPage() {
  var optionsUrl = chrome.extension.getURL('index.html');
  chrome.tabs.query({}, function(extensionTabs) {
   var found = false;

   for (var i=0; i < extensionTabs.length; i++) {
    if (optionsUrl == extensionTabs[i].url) {
     found = true;
     chrome.tabs.update(extensionTabs[i].id, {'selected': true});
    }
   }

   if (found == false) {
     chrome.tabs.create({url: 'index.html'});
   }
  });
}



// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

'use strict';

chrome.browserAction.onClicked.addListener(function (tab) {
  openOrFocusBackgroundPage();
  // debug()
  // fetchHistoryWords();
});


function debug() {
  chrome.storage.local.set({ 'key': true }, function () {
    console.log('Value is set to ');
  });

  chrome.storage.local.get(['t'], function (result) {
    console.log('Value currently is ' + result.key);
  });

  // localStorage.setItem('k', 'v');

}
// Open options page
function openOrFocusBackgroundPage() {
  var optionsUrl = chrome.extension.getURL('index.html');
  chrome.tabs.query({}, function (extensionTabs) {
    var found = false;

    for (var i = 0; i < extensionTabs.length; i++) {
      if (optionsUrl == extensionTabs[i].url.split('#')[0]) {
        found = true;
        chrome.tabs.update(extensionTabs[i].id, { 'selected': true });
      }
    }

    if (found == false) {
      chrome.tabs.create({ url: 'index.html' });
    }
  });
}


function fetchHistoryWords() {
  var transformWordHistory;

  chrome.runtime.sendMessage('mgijmajocgfcbeboacabfgobmjgjcoja', { getHistory: true }, {}, function (words) {
    console.log(typeof words);
    console.log(words);
    var w = transformWordHistory(words);
    console.log(typeof w);
    console.log(w);
  });

  // transform word history from google dictionary into our format
  transformWordHistory = function (words) {
    // words in an object which key is the word and value is the definition
    var vocabWords = [];
    var k, splited;
    for (k in words) {
      if (words.hasOwnProperty(k)) {
        splited = k.split('<');
        if (splited.length >= 3) {
          vocabWords.push({ from: splited[0], to: splited[1], word: splited[2], definition: words[k] });
        }
      }
    }
    return vocabWords;
  };
}



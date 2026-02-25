/*
 * Copyright (C) 2025  Sander Klootwijk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * intouch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "../components"

Page {
    id: searchPage

    property bool searchLoading: false
    property int currentPage: 0
    property int pageCount: 0

    header: PageHeader {
        id: searchPageHeader

        contents: TextField {
            id: searchField

            property bool searchExecuted: false

            width: Math.min(parent.width)
            
            anchors.centerIn: parent

            objectName: "searchField"
            
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            placeholderText: i18n.tr("Search")
            hasClearButton: true

            onTextChanged: {
                searchDelayTimer.restart()
            }

            Timer {
                id: searchDelayTimer
                interval: 350
                running: false
                repeat: false
                onTriggered: {
                    if (searchField.text == "") {
                        searchField.searchExecuted = false;
                        searchResultsListModel.clear();
                    }
                    else {
                        fetchSearchResults(searchField.text, 1);
                        searchField.searchExecuted = true;
                    }
                }
            }
        }

        onVisibleChanged: if (visible) searchField.forceActiveFocus()

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                onTriggered: {
                    pageStack.pop()
                    searchField.text = null
                    searchField.searchExecuted = false
                    searchResultsListModel.clear()
                }
            }
        ]
    }

    ActivityIndicator {
        id: loadingIndicator
        running: root.searchLoading || searchDelayTimer.running

        anchors {
            top: searchPageHeader.bottom
            topMargin: units.gu(13)
            horizontalCenter: parent.horizontalCenter
        }
    }

    Label {
        width: parent.width - units.gu(8)

        visible: !loadingIndicator.running

        anchors {
            top: searchPageHeader.bottom
            topMargin: units.gu(13.5)
            horizontalCenter: parent.horizontalCenter
        }

        text: searchResultsListModel.count == 0 && searchField.searchExecuted ? i18n.tr("No results") : ""

        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    ListModel {
        id: searchResultsListModel
    }

    ListView {
        id: searchResultsListView

        visible: !loadingIndicator.running

        anchors {
            fill: parent
            topMargin: searchPageHeader.height
        }

        model: searchResultsListModel
        delegate: TopicListItem {}

        // Loading more pages of search result disabled for now, as it requires a valid login session
        // onAtYEndChanged: {
        //     if (searchPage.currentPage < searchPage.pageCount && !root.searchLoading) {
        //         fetchSearchResults(searchField.text, searchPage.currentPage + 1);
        //     }
        // }
    }

    Scrollbar {
        id: searchResultsScrollbar

        flickableItem: searchResultsListView
        align: Qt.AlignTrailing
    }

    // Fetch search results
    function fetchSearchResults(term, page) {
        var xhr = new XMLHttpRequest;
        // Loading more pages of search result disabled for now, as it requires a valid login session
        xhr.open("GET", "https://forums.ubports.com/api/search?term=" + term + "&in=titles", true); //?page=" + page, true);

        searchLoading = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let data = JSON.parse(xhr.responseText);
                    let posts = data.posts;

                    currentPage = page;
                    pageCount = data.pagination.pageCount;

                    if (page == 1) {
                        searchResultsListModel.clear();
                        searchResultsListView.contentY = 0;
                    }

                    for (let i = 0; i < posts.length; i++) {
                        searchResultsListModel.append({
                            "title": posts[i].topic.titleRaw,
                            "pinned": 0,
                            "postcount": posts[i].topic.postcount,
                            "deleted": 0,
                            "lastposttimeISO": posts[i].timestampISO,
                            "picture": posts[i].user.picture == null ? "" : "https://forums.ubports.com/" + posts[i].user.picture,
                            "username": posts[i].user.username,
                            "bgColor": posts[i].user["icon:bgColor"],
                            "usernameText": posts[i].user["icon:text"],
                            "topicID": posts[i].topic.tid,
                            "slug": posts[i].topic.slug.toString()
                        });
                    }

                    searchLoading = false;
                    
                    console.log("Search results fetched successfully");
                } else {
                    searchLoading = false;

                    console.log("Failed to fetch search results:", xhr.status, xhr.statusText);
                }
            }
        };

        xhr.send();
    }
}
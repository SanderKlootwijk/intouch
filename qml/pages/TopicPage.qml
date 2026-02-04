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
    id: topicPage

    property bool initialLoadComplete: false
    property bool topicLoading: false
    property string topicSlug: ""
    property var initialPostID
    property int currentPage: 0
    property int pageCount: 0
    property int currentPost: 0

    property bool pinned: false
    property bool locked: false
    property int postCount: 0
    property int posterCount: 0
    property int viewCount: 0
    property int followerCount: 0

    Component.onCompleted: fetchTopic(topicSlug, 1);

    onVisibleChanged: {
        if (visible && initialLoadComplete) {
            reloadTopic(topicSlug);
        }
    }

    header: PageHeader {
        id: topicPageHeader
        
        Label {
            id: topicPageHeaderTitle

            anchors {
                left: parent.left
                leftMargin: units.gu(5)
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            text: ""

            textFormat: Text.PlainText
            textSize: text.length * units.gu(1.25) > width ? Label.Medium : Label.Large
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }

    ProgressBar {
        visible: topicLoading

        anchors {
            top: topicHeader.bottom
            left: parent.left
            right: parent.right
        }

        indeterminate: true
    }

    Item {
        id: topicHeader
        
        width: parent.width
        height: units.gu(6)

        anchors {
            top: topicPageHeader.bottom
            horizontalCenter: parent.horizontalCenter
        }

        Row {
            height: parent.height

            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            Icon {
                id: postCountIcon

                visible: postCount > 0

                width: units.gu(2)
                height: units.gu(2)

                anchors.verticalCenter: parent.verticalCenter
                
                name: "message"
                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(0.75)
                height: parent.height
            }

            Label {
                id: postCountLabel

                visible: postCount > 0

                width: implicitWidth
                height: implicitHeight

                anchors.verticalCenter: parent.verticalCenter

                text: formatCount(postCount)
                
                elide: Text.ElideRight

                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(2)
                height: parent.height
            }

            Icon {
                id: posterCountIcon

                visible: postCount > 0

                width: units.gu(2)
                height: units.gu(2)

                anchors.verticalCenter: parent.verticalCenter
                
                name: "contact"
                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(0.75)
                height: parent.height
            }

            Label {
                id: posterCountLabel

                visible: postCount > 0

                width: implicitWidth
                height: implicitHeight

                anchors.verticalCenter: parent.verticalCenter

                text: formatCount(posterCount)
                
                elide: Text.ElideRight

                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(2)
                height: parent.height
            }

            Icon {
                id: viewCountIcon

                visible: viewCount > 0

                width: units.gu(2)
                height: units.gu(2)

                anchors.verticalCenter: parent.verticalCenter
                
                name: "view-on"
                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(0.75)
                height: parent.height
            }

            Label {
                id: viewCountLabel

                visible: viewCount > 0

                width: implicitWidth
                height: implicitHeight

                anchors.verticalCenter: parent.verticalCenter

                text: formatCount(viewCount)
                
                elide: Text.ElideRight

                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(2)
                height: parent.height
            }

            Icon {
                id: followerCountIcon

                visible: followerCount > 0

                width: units.gu(2)
                height: units.gu(2)

                anchors.verticalCenter: parent.verticalCenter
                
                name: "notification"
                color: theme.palette.normal.foregroundText
            }

            Item {
                width: units.gu(0.75)
                height: parent.height
            }

            Label {
                id: followerCountLabel

                visible: followerCount > 0

                width: implicitWidth
                height: implicitHeight

                anchors.verticalCenter: parent.verticalCenter

                text: formatCount(followerCount)
                
                elide: Text.ElideRight

                color: theme.palette.normal.foregroundText
            }
        }

        ActionBar {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: units.gu(1)
            }

            actions: [
                Action {
                    iconName: locked == 0 ? "mail-reply" : "lock"
                    text: locked == 0 ? i18n.tr("Reply") : i18n.tr("Locked")
                    enabled: locked == 0
                    onTriggered: {
                        webEngineViewPage.topicSlug = topicSlug;
                        webEngineViewPage.replyPid = "0";
                        webEngineViewPage.replyMode = "topicreply";
                        webEngineViewPage.replyTriggered = false;
                        webEngineViewPage.topicWebView.url = "https://forums.ubports.com/topic/" + topicSlug + "/" + currentPost + "#";
                        pageStack.push(webEngineViewPage);
                    }
                }
            ]
        }

        Rectangle {
            width: parent.width
            height: units.dp(1)

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            color: theme.palette.normal.base
        }
    }

    ListModel {
        id: topicListModel
    }

    ListView {
        id: topicListView

        anchors {
            fill: parent
            topMargin: topicPageHeader.height + topicHeader.height
            bottomMargin: paginationBar.height
        }

        model: topicListModel
        delegate: PostListItem {}
        cacheBuffer: 1000
        clip: true

        onAtYEndChanged: {
            if (atYEnd == true) {
                if (currentPage < pageCount && !topicLoading) {
                    fetchTopic(topicSlug, currentPage + 1);
                }
            }
        }

        onContentHeightChanged: findCurrentPost()
        onContentYChanged: findCurrentPost()

        function findCurrentPost() {
            var currentIndexY;

            if (topicListView.contentHeight < topicListView.height) {
                currentIndexY = contentY + topicListView.contentHeight - units.gu(1);
            }
            else if (currentPage == pageCount && topicListView.atYEnd) {
                currentIndexY = contentY + topicListView.height - units.gu(1);
            }
            else {
                currentIndexY = contentY + topicListView.height / 2;
            }

            var currentIndex = topicListView.indexAt(1, currentIndexY) + 1;
            
            if (currentIndex <= 0) {
                currentIndex = postCount;
            }

            currentPost = currentIndex;
        }
    }

    Scrollbar {
        id: topicScrollbar

        flickableItem: topicListView
        align: Qt.AlignTrailing
    }

    Item {
        id: paginationBar

        width: parent.width
        height: units.gu(4)

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }

        Rectangle {
            width: parent.width
            height: units.dp(1)

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
            }
            
            color: theme.palette.normal.base
        }

        Row {
            anchors.fill: parent

            spacing: (parent.width - (upButton.width + postsLabel.width + downButton.width)) / 4

            Item {
                width: units.dp(1)
                height: units.gu(4)
            }

            MouseArea {
                id: upButton

                width: units.gu(4)
                height: units.gu(4)

                enabled: !topicListView.atYBeginning
                onClicked: topicListView.positionViewAtBeginning()

                Icon {
                    width: units.gu(2.5)
                    height: units.gu(2.5)

                    anchors.centerIn: parent

                    color: topicListView.atYBeginning ? theme.palette.disabled.baseText : theme.palette.normal.baseText
                    name: "go-up"
                }
            }

            Label {
                id: postsLabel

                width: units.gu(14)

                anchors.verticalCenter: parent.verticalCenter

                horizontalAlignment: Text.AlignHCenter                
                text: postCount == 0 ? "" : i18n.tr("Post %1 from %2").arg(currentPost).arg(postCount)                
            }

            MouseArea {
                id: downButton

                width: units.gu(4)
                height: units.gu(4)

                enabled: !topicListView.atYEnd
                onClicked: topicListView.positionViewAtEnd()

                Icon {
                    width: units.gu(2.5)
                    height: units.gu(2.5)

                    anchors.centerIn: parent

                    color: topicListView.atYEnd ? theme.palette.disabled.baseText : theme.palette.normal.baseText
                    name: "go-down"
                }
            }

            Item {
                width: units.dp(1)
                height: units.gu(4)
            }
        }
    }

    // Fetch topic
    function fetchTopic(slug, page) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forums.ubports.com/api/topic/" + slug + "?page=" + page, true);

        topicLoading = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let data = JSON.parse(xhr.responseText);
                    let posts = data.posts;

                    topicPageHeaderTitle.text = data.titleRaw;
                    currentPage = page;

                    pinned = data.pinned;
                    locked = data.locked;
                    pageCount = data.pagination.pageCount;
                    postCount = data.postcount;
                    posterCount = data.postercount;
                    viewCount = data.viewcount;
                    followerCount = data.followercount;

                    for (let i = 0; i < posts.length; i++) {
                        topicListModel.append({
                            "username": posts[i].user.username,
                            "picture": posts[i].user.picture == null ? "" : "https://forums.ubports.com/" + posts[i].user.picture,
                            "bgColor": posts[i].user["icon:bgColor"],
                            "usernameText": posts[i].user["icon:text"], 
                            "content": posts[i].content.replace(/<img /g, '<img width="' + units.gu(35) + '" height="auto" ').replace(/class="not-responsive emoji /g, ' width="' + units.gu(1.75) + '" height="auto" class="not-responsive emoji ').replace(/<a /g, '<a style="color: ' + theme.palette.normal.activity + ';"').replace(/src="\/assets/g, 'src="https://forums.ubports.com/assets'),
                            "timestampISO": posts[i].timestampISO,
                            "postIndex": posts[i].index,
                            "votes": posts[i].votes,
                            "postID": posts[i].pid,
                            "slug": posts[i].slug,
                            "deleted": posts[i].deleted,
                            "locked": data.locked
                        });
                    }
                    
                    console.log("Topic fetched successfully, page " + currentPage + "/" + pageCount);

                    if (currentPage < pageCount) {
                        fetchTopic(topicSlug, currentPage + 1);
                        return;
                    }

                    topicLoading = false;

                    if (!initialLoadComplete && initialPostID !== undefined) {
                        for (var i = 0; i < topicListView.count; i++) {
                            if (topicListView.model.get(i).postID === initialPostID) {
                                topicListView.positionViewAtIndex(i, ListView.Beginning);
                                break;
                            }
                        }
                    }
                    
                    initialLoadComplete = true;

                    return;

                } else {
                    topicLoading = false;

                    console.log("Failed to fetch topic:", xhr.status, xhr.statusText);
                }
            }
        };

        xhr.send();
    }

    function reloadTopic(slug) {
        if (topicLoading || !initialLoadComplete) {
            return;
        }

        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forums.ubports.com/api/topic/" + slug + "?page=1", true);

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            if (xhr.status !== 200) {
                console.log("Reload check failed:", xhr.status);
                return;
            }

            console.log("Checking if reload is needed");

            let data = JSON.parse(xhr.responseText);
           
            const newPageCount = data.pagination.pageCount;
            const newPostCount = data.postcount;

            if (newPageCount !== pageCount || newPostCount !== postCount) {
                console.log("Topic updated, reloading");

                topicListModel.clear();
                fetchTopic(slug, 1);
                return;
            }

            console.log("No new posts found, not reloading");
        };

        xhr.send();
    }

    // Numbers above 999 are returned as e.g. 1k
    function formatCount(count) {
        if (count < 1000) return count.toString();

        const k = count / 1000;

        return (k % 1 === 0 ? k : k.toFixed(1)) + 'k';
    }
}
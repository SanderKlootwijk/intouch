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
import Lomiri.Connectivity 1.0
import QtQuick.Layouts 1.3
import "../components"

Page {
    id: mainPage

    property bool categoriesLoading: false
    property bool recentTopicsLoading: false

    Component.onCompleted: {
        mainPageHeaderSections.selectedIndex = settings.defaultTab;

        if (settings.defaultTab == 0) {
            fetchCategories();
        }
    }

    Connections {
        target: Connectivity

        onStatusChanged: {
            if (Connectivity.status == NetworkingStatus.Online) {
                if (mainPageHeaderSections.selectedIndex == 0) {
                    fetchCategories();
                    categoriesListView.contentY = 0;
                    recentTopicsItem.currentPage = 0;
                    recentTopicsItem.pageCount = 0;
                }
                if (mainPageHeaderSections.selectedIndex == 1) {
                    fetchRecentTopics(1);
                    recentTopicsListView.contentY = 0;
                }
            }
        }
    }

    header: PageHeader {
        id: mainPageHeader
        title: mainPageHeaderSections.selectedIndex == 0 ? i18n.tr("Home") : i18n.tr("Recent topics")

        trailingActionBar {
            numberOfSlots: 3

            actions: [
                Action {
                    iconName: "settings"
                    text: i18n.tr("Settings")
                    onTriggered: pageStack.push(settingsPage)
                },
                Action {
                    iconName: "toolkit_input-search"
                    text: i18n.tr("Search")
                    onTriggered: pageStack.push(searchPage)
                }
            ]
        }

        extension: Sections {
            id: mainPageHeaderSections

            actions: [
                Action {
                    text: i18n.tr("Categories")
                },
                Action {
                    text: i18n.tr("Recent")
                }
            ]

            onSelectedIndexChanged: {
                if (selectedIndex == 0) {
                    fetchCategories();
                    categoriesListView.contentY = 0;
                    recentTopicsItem.currentPage = 0;
                    recentTopicsItem.pageCount = 0;
                }
                if (selectedIndex == 1) {
                    fetchRecentTopics(1);
                    recentTopicsListView.contentY = 0;
                }
            }
        }
    }

    ProgressBar {
        visible: categoriesLoading || recentTopicsLoading

        anchors {
            top: mainPageHeader.bottom
            left: parent.left
            right: parent.right
        }

        indeterminate: true
    }

    Item {
        id: categoriesItem

        visible: mainPageHeaderSections.selectedIndex == 0

        anchors {
            fill: parent
            topMargin: mainPageHeader.height
        }

        ListModel {
            id: categoriesListModel
        }

        ListView {
            id: categoriesListView

            anchors.fill: parent

            model: categoriesListModel
            delegate: CategoryListItem {}
        }

        Scrollbar {
            id: categoriesScrollbar

            flickableItem: categoriesListView
            align: Qt.AlignTrailing
        }
    }

    Item {
        id: recentTopicsItem

        property int currentPage: 0
        property int pageCount: 0

        visible: mainPageHeaderSections.selectedIndex == 1

        anchors {
            fill: parent
            topMargin: mainPageHeader.height
        }

        ListModel {
            id: recentTopicsListModel
        }

        ListView {
            id: recentTopicsListView

            anchors.fill: parent

            model: recentTopicsListModel
            delegate: TopicListItem {}

            onAtYEndChanged: {
                if (recentTopicsItem.currentPage < recentTopicsItem.pageCount && !recentTopicsLoading) {
                    fetchRecentTopics(recentTopicsItem.currentPage + 1);
                }
            }
        }

        Scrollbar {
            id: recentTopicsScrollbar

            flickableItem: recentTopicsListView
            align: Qt.AlignTrailing
        }
    }

    // Fetch categories from the forum API
    function fetchCategories() {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forums.ubports.com/api/categories", true);

        categoriesLoading = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let data = JSON.parse(xhr.responseText);
                    let categories = data.categories;

                    categoriesListModel.clear();

                    for (let i = 0; i < categories.length; i++) {
                        categoriesListModel.append({
                            "name": categories[i].name,
                            "icon": categories[i].icon,
                            "iconColor": categories[i].color,
                            "bgColor": categories[i].bgColor,
                            "description": categories[i].descriptionParsed.replace("<p>", "").replace("</p>", "").replace('<p dir="auto">', ""),
                            "teasertimeISO": categories[i].teaser.timestampISO,
                            "slug": categories[i].slug.toString()
                        });
                    }

                    categoriesLoading = false;

                    console.log("Categories fetched successfully");
                } else {
                    categoriesLoading = false;

                    console.log("Failed to fetch categories:", xhr.status, xhr.statusText);
                }
            }
        };

        xhr.send();
    }

    // Fetch recent topics
    function fetchRecentTopics(page) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forums.ubports.com/api/recent?page=" + page, true);

        recentTopicsLoading = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let data = JSON.parse(xhr.responseText);
                    let topics = data.topics;

                    recentTopicsItem.currentPage = page;
                    recentTopicsItem.pageCount = data.pagination.pageCount;

                    if (page == 1) {
                        recentTopicsListModel.clear();
                    }

                    for (let i = 0; i < topics.length; i++) {
                        recentTopicsListModel.append({
                            "title": topics[i].titleRaw,
                            "postcount": topics[i].postcount,
                            "lastposttimeISO": topics[i].lastposttimeISO,
                            "pinned": 0,
                            "deleted": topics[i].deleted,
                            "picture": topics[i].user.picture == null ? "" : "https://forums.ubports.com/" + topics[i].user.picture,
                            "username": topics[i].user.username,
                            "bgColor": topics[i].user["icon:bgColor"],
                            "usernameText": topics[i].user["icon:text"],
                            "slug": topics[i].slug.toString()
                        });
                    }

                    recentTopicsLoading = false;
                    
                    console.log("Recent topics fetched successfully, page " + page + "/" + data.pagination.pageCount);
                } else {
                    recentTopicsLoading = false;

                    console.log("Failed to fetch recent topics:", xhr.status, xhr.statusText);
                }
            }
        };

        xhr.send();
    }
}
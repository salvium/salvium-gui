// Copyright (c) 2026, Salvium
// Portions copyright (c) 2026, The Salvium Project (SRCG, auruya)
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import moneroComponents.Wallet 1.0
import FontAwesome 1.0

import "../components" as MoneroComponents
import "../components/effects/" as MoneroEffects

Rectangle {
    id: pageCreateToken
    signal createTokenClicked(string assetType, string supply, string metadata, string name, int size, string hash, string url)
    color: "transparent"
    property alias createTokenHeight: mainLayout.height

    ColumnLayout {
        id: mainLayout
        anchors.margins: 20
        anchors.topMargin: 40
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 20

        MoneroComponents.LabelSubheader {
            Layout.fillWidth: true
            textFormat: Text.RichText
            text: qsTr("Create Token") + translationManager.emptyString
        }

        MoneroComponents.TextPlain {
            Layout.fillWidth: true
            font.family: MoneroComponents.Style.fontRegular.name
            font.pixelSize: 14
            color: MoneroComponents.Style.defaultFontColor
            text: qsTr("Create a new token") + translationManager.emptyString
            wrapMode: Text.WordWrap
        }

        // Token Ticker
        MoneroComponents.LineEdit {
            id: tokenNameInput
            Layout.fillWidth: true
            labelText: qsTr("Token Ticker") + translationManager.emptyString
            placeholderText: qsTr("4 characters (e.g. ABCD)") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
            validator: RegExpValidator {
                regExp: /^[A-Za-z0-9]{0,4}$/
            }
            onTextChanged: {
                text = text.toUpperCase();
            }
        }

        // supply
        MoneroComponents.LineEdit {
            id: amountInput
            Layout.fillWidth: true
            labelText: qsTr("Supply") + translationManager.emptyString
            placeholderText: qsTr("Supply to be created") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
            validator: RegExpValidator {
                regExp: /^\s*(\d{1,18})?([\.,]\d{1,12})?\s*$/
            }
            onTextChanged: {
                text = text.trim().replace(",", ".");
            }
        }

        // Name
        MoneroComponents.LineEdit {
            id: nameInput
            Layout.fillWidth: true
            labelText: qsTr("Name") + translationManager.emptyString
            placeholderText: qsTr("Full token name (e.g. My Token)") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
        }

        // URL
        MoneroComponents.LineEdit {
            id: urlInput
            Layout.fillWidth: true
            labelText: qsTr("URL") + translationManager.emptyString
            placeholderText: qsTr("Token website or info URL") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
        }

        // Size
        MoneroComponents.LineEdit {
            id: sizeInput
            Layout.fillWidth: true
            labelText: qsTr("Size") + translationManager.emptyString
            placeholderText: qsTr("Size") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
            validator: IntValidator {
                bottom: 0
            }
        }

        // Hash
        MoneroComponents.LineEdit {
            id: hashInput
            Layout.fillWidth: true
            labelText: qsTr("Hash") + translationManager.emptyString
            placeholderText: qsTr("Hash signature") + translationManager.emptyString
            placeholderFontSize: 16
            fontSize: 16
            validator: RegExpValidator {
                regExp: /^[A-Fa-f0-9]{0,64}$/
            }
        }

        // Metadata
        MoneroComponents.LineEditMulti {
            id: metadataInput
            Layout.fillWidth: true
            labelText: qsTr("Metadata") + translationManager.emptyString
            placeholderText: qsTr("If metadata is provided, name, URL, size, and hash fields will be ignored.") + translationManager.emptyString
            placeholderFontSize: 16
        }

        // Create Token button
        RowLayout {
            Layout.topMargin: 10

            MoneroComponents.StandardButton {
                id: createTokenButton
                rightIcon: "qrc:///images/rightArrow.png"
                text: qsTr("Create Token") + translationManager.emptyString
                enabled: tokenNameInput.text.length === 4 && amountInput.text !== ""
                onClicked: {
                    console.log("CreateToken: createTokenClicked");
                    pageCreateToken.createTokenClicked(
                        tokenNameInput.text,
                        amountInput.text,
                        metadataInput.text,
                        nameInput.text,
                        parseInt(sizeInput.text) || 0,
                        hashInput.text,
                        urlInput.text
                    );
                }
            }
        }
    }

    function onPageCompleted() {
        console.log("CreateToken page loaded");
    }

    function onPageClosed() {
    }

    function clearFields() {
        tokenNameInput.text = "";
        amountInput.text = "";
        nameInput.text = "";
        urlInput.text = "";
        sizeInput.text = "";
        hashInput.text = "";
        metadataInput.text = "";
    }
}

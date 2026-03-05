// Copyright (c) 2014-2019, The Monero Project
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

import QtQml.Models 2.2
import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import moneroComponents.Clipboard 1.0
import moneroComponents.YieldInfo 1.0
import moneroComponents.PendingTransaction 1.0
import moneroComponents.Wallet 1.0
import moneroComponents.NetworkType 1.0
import FontAwesome 1.0
import "../components"
import "../components" as MoneroComponents
import "../components/effects/" as MoneroEffects
import "." 1.0
import "../js/TxUtils.js" as TxUtils
import "../js/Utils.js" as Utils


Rectangle {
    id: root
    signal stakeClicked(var recipients, string paymentId, int mixinCount, int priority, string description)
    signal sweepUnmixableClicked()

    color: "transparent"
    property alias stakingHeight: pageRoot.height
    property int mixin: 15  // (ring size 16)
    property string amount: ""
    property string warningContent: ""
    property string stakeButtonWarning: {
        // Currently opened wallet is not view-only
        if (appWindow.viewOnly) {
            return qsTr("Wallet is view-only and sends are only possible by using offline transaction signing. " +
                        "Unless key images are imported, the balance reflects only incoming but not outgoing transactions.") + translationManager.emptyString;
        }

        // There are sufficient unlocked funds available
      // if (walletManager.amountFromString(amountInput.text) > (appWindow.currentWallet ? appWindow.currentWallet.unlockedBalance("SAL1") : 0)) {
       if (walletManager.amountFromString(amountInput.text) > (appWindow.currentWallet ? appWindow.currentWallet.unlockedBalance("SAL1") : 0)) {
            return qsTr("Amount is more than unlocked balance.") + translationManager.emptyString;
        }

        // Amount is nonzero
        if (amountInput.isEmpty()) {
            return qsTr("Enter an amount.") + translationManager.emptyString;
        }

        return "";
    }
    property string startLinkText: "<style type='text/css'>a {text-decoration: none; color: #FF6C3C; font-size: 14px;}</style><a href='#'>(%1)</a>".arg(qsTr("Start daemon")) + translationManager.emptyString

    Clipboard { id: clipboard }

    function oa_message(text) {
      oaPopup.title = qsTr("OpenAlias error") + translationManager.emptyString
      oaPopup.text = text
      oaPopup.icon = StandardIcon.Information
      oaPopup.onCloseCallback = null
      oaPopup.open()
    }

    // Information dialog
    StandardDialog {
        // dynamically change onclose handler
        property var onCloseCallback
        id: oaPopup
        cancelVisible: false
        onAccepted:  {
            if (onCloseCallback) {
                onCloseCallback()
            }
        }
    }

    ColumnLayout {
      id: pageRoot
      anchors.margins: 20
      anchors.topMargin: 40

      anchors.left: parent.left
      anchors.top: parent.top
      anchors.right: parent.right

      spacing: 30

      RowLayout {
          visible: root.warningContent !== ""

          MoneroComponents.WarningBox {
              text: warningContent
              onLinkActivated: {
                  appWindow.startDaemon(appWindow.persistentSettings.daemonFlags);
              }
          }
      }
/*
      RowLayout {
          visible: leftPanel.minutesToUnlock !== ""

          MoneroComponents.WarningBox {
              text: qsTr("Spendable funds: %1 SAL. Please wait ~%2 minutes for your whole balance to become spendable.").arg(leftPanel.balanceUnlockedString).arg(leftPanel.minutesToUnlock)
          }
      }
*/
        Item {
            Layout.fillWidth: true
            implicitHeight: stakingLayout.height

            ColumnLayout {
                id: stakingLayout
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                ColumnLayout {
                    id: newstakeLayout
                    spacing: 0

                    MoneroComponents.LabelSubheader {
                        Layout.fillWidth: true
                        Layout.topMargin: 24
                        fontSize: 24
                        textFormat: Text.RichText
                        text: qsTr("Staking") + translationManager.emptyString
                    }

                    RowLayout {
                        Layout.topMargin: 10
    
                        MoneroComponents.TextPlain {
                            text: qsTr("Spendable balance: ") + translationManager.emptyString
                            Layout.fillWidth: true
                            color: MoneroComponents.Style.defaultFontColor
                            font.pixelSize: 16
                            font.family: MoneroComponents.Style.fontRegular.name
                            themeTransition: false
                        }

                        MoneroComponents.TextPlain {
                            text: (appWindow.currentWallet ? walletManager.displayAmount(appWindow.currentWallet.unlockedBalance("SAL1")) : "?.??") + " SAL1 " + translationManager.emptyString;
                            Layout.rightMargin: 20
                            font.family: MoneroComponents.Style.fontMonoRegular.name;
                            font.pixelSize: 16
                            color: MoneroComponents.Style.defaultFontColor
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.topMargin: 1
                        Layout.bottomMargin: 1
                        color: MoneroComponents.Style.inputBorderColorInActive
                        width: 1

                        RowLayout {

                            Layout.topMargin: 2
                            Layout.fillWidth: true
        
                            MoneroComponents.TextPlain {
                                id: newstakeLabel
                                font.pixelSize: 16
                                font.family: MoneroComponents.Style.fontRegular.name
                                textFormat: Text.RichText
                                text: qsTr("Stake new amount: ") + translationManager.emptyString
                            }

                            MoneroComponents.LineEdit {
                                id: amountInput
                                KeyNavigation.backtab: parent.children[0]
                                KeyNavigation.tab: stakeButton
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                Layout.topMargin: 2
                                Layout.bottomMargin: 2
                                Layout.preferredWidth: 125
                                Layout.maximumWidth: 125
                                borderDisabled: false
                                fontFamily: MoneroComponents.Style.fontMonoRegular.name
                                fontSize: 16
                                inputPaddingLeft: 10
                                inputPaddingRight: 10
                                inputPaddingTop: 2
                                inputPaddingBottom: 2
                                placeholderFontFamily: MoneroComponents.Style.fontMonoRegular.name
                                placeholderFontSize: 16
                                placeholderLeftMargin: 10
                                placeholderText: "0.00"
                                text: amount
                                onTextChanged: {
                                    text = text.trim().replace(",", ".");
                                    const match = text.match(/^0+(\d.*)/);
                                    if (match) {
                                        const cursorPosition = cursorPosition;
                                        text = match[1];
                                        cursorPosition = Math.max(cursorPosition, 1) - 1;
                                    } else if(text.indexOf('.') === 0){
                                        text = '0' + text;
                                        if (text.length > 2) {
                                            cursorPosition = 1;
                                        }
                                    }
                                error = (text == "") || (walletManager.amountFromString(text) == 0) || (walletManager.amountFromString(text) > (appWindow.currentWallet ? appWindow.currentWallet.unlockedBalance("SAL1") : 0));

                                // error = (text == "") || (walletManager.amountFromString(text) == 0) || (walletManager.amountFromString(text) > appWindow.getUnlockedBalance());
                                    stakeButton.enabled = !error;
                                    amount = text;
                                }
                                validator: RegExpValidator {
                                    regExp: /^\s*(\d{1,8})?([\.,]\d{1,12})?\s*$/
                                }
                            }

                            MoneroComponents.TextPlain {
                                horizontalAlignment: Text.AlignHCenter
                                font.family: MoneroComponents.Style.fontRegular.name
                                font.bold: true
                                themeTransition: false
                                color: "#FF0000"
                                text: "  SAL1    "
                                visible: true
                            }

                            StandardButton {
                                id: stakeButton
                                rightIcon: "qrc:///images/rightArrow.png"
                                Layout.rightMargin: 4
                                Layout.topMargin: 4
                                text: qsTr("Stake") + translationManager.emptyString
                                enabled: !stakeButtonWarningBox.visible && !warningContent
                                onClicked: {
                                    console.log("Staking: stakeClicked")
                                    root.stakeClicked(root.amount, "", root.mixin, 0, "")
                                }
                            }
                        }
                    }

                    MoneroComponents.TextPlain {
                        visible: appWindow.persistentSettings.assetType !== "SAL1"
                        Layout.topMargin: 70
                        font.pixelSize: 13
                        font.family: MoneroComponents.Style.fontRegular.name
                        themeTransition: false
                        color: "#FF6C3C"
                        text: qsTr("Note: Staking is only available for SAL1.") + translationManager.emptyString
                    }
                }
            }
        }
                    RowLayout {
                        Layout.topMargin: 30
                        MoneroComponents.WarningBox {
                            id: stakeButtonWarningBox
                            text: root.stakeButtonWarning
                            visible: root.stakeButtonWarning !== ""
                        }
                    }
    
                    RowLayout {
                        Layout.bottomMargin: 10
                        MoneroComponents.WarningBox {
                            id: stakeInfoWarningBox
                            text: "<style type='text/css'>a {text-decoration: none; color: #FF6C3C; font-size: 14px;}</style>" +
                                  qsTr("Staking locks your SAL1 for 21,600 blocks (about 30 days) to earn rewards. ") + translationManager.emptyString +
                                  qsTr("This lock is non-reversible. Stakers currently receive 20% of block rewards, ") + translationManager.emptyString +
                                  qsTr("shared proportionally. Learn more at ") + translationManager.emptyString +
                                  "<a href='https://salvium.io/staking'>https://salvium.io/staking</a>."
                            visible: true
                            onLinkActivated: Qt.openUrlExternally("https://salvium.io/staking")
                        }
                    }
    }

     // pageRoot

    Component.onCompleted: {
        //Disable password page until enabled by updateStatus
        pageRoot.enabled = false
    }

    // fires on every page load
    function onPageCompleted() {
        console.log("staking page loaded")
        updateStatus();
    }

    //TODO: Add daemon sync status
    //TODO: enable send page when we're connected and daemon is synced

    function updateStatus() {
        var messageNotConnected = qsTr("Wallet is not connected to daemon.");
        if(appWindow.walletMode >= 2 && !persistentSettings.useRemoteNode) messageNotConnected += root.startLinkText;
        pageRoot.enabled = true;
        if(typeof currentWallet === "undefined") {
            root.warningContent = messageNotConnected;
            return;
        }

        if (currentWallet.viewOnly) {
           // warningText.text = qsTr("Wallet is view only.")
           //return;
        }
        //pageRoot.enabled = false;

        switch (currentWallet.connected()) {
        case Wallet.ConnectionStatus_Connecting:
            root.warningContent = qsTr("Wallet is connecting to daemon.")
            break
        case Wallet.ConnectionStatus_Disconnected:
            root.warningContent = messageNotConnected;
            break
        case Wallet.ConnectionStatus_WrongVersion:
            root.warningContent = qsTr("Connected daemon is not compatible with GUI. \n" +
                                   "Please upgrade or connect to another daemon")
            break
        default:
            if(!appWindow.daemonSynced){
                root.warningContent = qsTr("Waiting on daemon synchronization to finish.")
            } else {
                // everything OK, enable transfer page
                // Light wallet is always ready
                pageRoot.enabled = true;
                root.warningContent = "";
            }
        }
    }

    // Popuplate fields from addressbook.
    function sendTo(address, paymentId, description, amount) {
        middlePanel.state = 'Staking';

        fillPaymentDetails(address, paymentId, amount, description);
    }
}

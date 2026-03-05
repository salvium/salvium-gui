// Copyright (c) 2024, Salvium (author: SRCG)
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

#include "YieldInfo.h"


YieldInfo::Status YieldInfo::status() const
{
    return static_cast<Status>(m_pYI->status());
}

QString YieldInfo::errorString() const
{
    return QString::fromStdString(m_pYI->errorString());
}

bool YieldInfo::update()
{
    return m_pYI->update();
}

quint64 YieldInfo::burnt() const
{
    return m_pYI->burnt();
}

quint64 YieldInfo::locked() const
{
    return m_pYI->locked();
}

quint64 YieldInfo::supply() const
{
    return m_pYI->supply();
}

quint64 YieldInfo::yield() const
{
    return m_pYI->yield();
}

quint64 YieldInfo::yield_per_stake() const
{
    return m_pYI->yield_per_stake();
}

QString YieldInfo::period() const
{
  // Take the number of entries and convert to a human-readable period
  return m_pYI->period().c_str();
}

QString YieldInfo::payouts() const
{
  std::vector<std::tuple<size_t, std::string, std::string, uint64_t, uint64_t>> raw_payouts = m_pYI->payouts();
  QStringList result;
  for (auto &rp : raw_payouts) {
    size_t height;
    std::string txid;
    std::string asset_type;
    uint64_t burnt;
    uint64_t yield;
    std::tie(height, txid, asset_type, burnt, yield) = rp;
    QString qtxid = QString::fromStdString(txid);
    QString payout = tr("{\"blockheight\":%1,\"hash\":\"%2\",\"burnt\":%3,\"yield\":%4}").arg(height).arg(qtxid).arg(burnt).arg(yield);
    result.append(payout);
  }
  return "[" + result.join(",") + "]";
}

YieldInfo::YieldInfo(Monero::YieldInfo *pt, QObject *parent)
    : QObject(parent), m_pYI(pt)
{

}

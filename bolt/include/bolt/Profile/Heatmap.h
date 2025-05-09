//===- bolt/Profile/Heatmap.h -----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef BOLT_PROFILE_HEATMAP_H
#define BOLT_PROFILE_HEATMAP_H

#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include <cstdint>
#include <map>
#include <vector>

namespace llvm {
class raw_ostream;

namespace bolt {

/// Struct representing a section name and its address range in the binary.
struct SectionNameAndRange {
  StringRef Name;
  uint64_t BeginAddress;
  uint64_t EndAddress;
};

class Heatmap {
  /// Number of bytes per entry in the heat map.
  size_t BucketSize;

  /// Minimum address that is considered to be valid.
  uint64_t MinAddress;

  /// Maximum address that is considered to be valid.
  uint64_t MaxAddress;

  /// Count invalid ranges.
  uint64_t NumSkippedRanges{0};

  /// Map buckets to the number of samples.
  std::map<uint64_t, uint64_t> Map;

  /// Map section names to their address range.
  const std::vector<SectionNameAndRange> TextSections;

  uint64_t getNumBuckets(uint64_t Begin, uint64_t End) const {
    return End / BucketSize + !!(End % BucketSize) - Begin / BucketSize;
  };

public:
  explicit Heatmap(uint64_t BucketSize = 4096, uint64_t MinAddress = 0,
                   uint64_t MaxAddress = std::numeric_limits<uint64_t>::max(),
                   std::vector<SectionNameAndRange> TextSections = {})
      : BucketSize(BucketSize), MinAddress(MinAddress), MaxAddress(MaxAddress),
        TextSections(TextSections) {}

  inline bool ignoreAddress(uint64_t Address) const {
    return (Address > MaxAddress) || (Address < MinAddress);
  }

  /// Register a single sample at \p Address.
  void registerAddress(uint64_t Address, uint64_t Count) {
    if (!ignoreAddress(Address))
      Map[Address / BucketSize] += Count;
  }

  /// Register \p Count samples at [\p StartAddress, \p EndAddress ].
  void registerAddressRange(uint64_t StartAddress, uint64_t EndAddress,
                            uint64_t Count);

  /// Return the number of ranges that failed to register.
  uint64_t getNumInvalidRanges() const { return NumSkippedRanges; }

  void print(StringRef FileName) const;

  void print(raw_ostream &OS) const;

  void printCDF(StringRef FileName) const;

  void printCDF(raw_ostream &OS) const;

  /// Struct describing individual section hotness.
  struct SectionStats {
    uint64_t Samples{0};
    uint64_t Buckets{0};
  };

  uint64_t getNumBuckets(StringRef Name) const;

  /// Mapping from section name to associated \p SectionStats. Special entries:
  /// - [total] for total stats,
  /// - [unmapped] for samples outside any section, if non-zero.
  using SectionStatsMap = StringMap<SectionStats>;

  SectionStatsMap computeSectionStats() const;

  void printSectionHotness(const SectionStatsMap &, StringRef Filename) const;

  void printSectionHotness(const SectionStatsMap &, raw_ostream &OS) const;

  size_t size() const { return Map.size(); }
};

} // namespace bolt
} // namespace llvm

#endif

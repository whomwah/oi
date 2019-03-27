//
//  extensions.swift
//  Oi
//
//  Created by Duncan Robertson on 27/03/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Foundation

extension Collection {
  func find(where predicate: (Iterator.Element) throws -> Bool) rethrows -> Iterator.Element? {
    return try self.index(where: predicate).flatMap { self[$0] }
  }
}

extension Collection where Index == Int {
  subscript(safe index: Int) -> Iterator.Element? {
    return index < self.count && index >= 0 ? self[index] : nil
  }
}

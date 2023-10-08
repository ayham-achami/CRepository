//
//  ChatInfo.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Community Arch
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import RealmSwift
import Foundation
import CRepository

struct ChatInfo: Equatable {
    
    let id: Int
    let users: List<String>
}

extension ChatInfo: ManageableRepresented {

    typealias RepresentedType = ManageableChatInfo
    
    init(from represented: ManageableChatInfo) {
        self.id = represented.id
        self.users = represented.list
    }
}

final class ManageableChatInfo: Object, ManageableSource, ListManageable {
    
    typealias Value = String
    
    @Persisted(primaryKey: true) var id: Int = .zero
    @Persisted var list: List<String>
    
    required convenience init(from chat: ChatInfo) {
        self.init()
        self.id = chat.id
        self.list = chat.users
    }
    
    convenience init(id: Int, users: List<String>) {
        self.init()
        self.id = id
        self.list = users
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ManageableChatInfo else { return false }
        return id == other.id && list == other.list
    }
}

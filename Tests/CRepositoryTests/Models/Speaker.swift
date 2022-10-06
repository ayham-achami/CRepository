//
//  Speaker.swift
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
import CRepository

struct Speaker {
    
    let id: Int
    let name: String
    let isPinned: Bool
    let entryTime: Date
}

extension Speaker: ManageableRepresented {

    typealias RepresentedType = ManageableSpeaker
    
    init(from represented: RepresentedType) {
        self.id = represented.id
        self.name = represented.name
        self.isPinned = represented.isPinned
        self.entryTime = represented.entryTime
    }
}

final class ManageableSpeaker: Object, ManageableSource {
    
    override class func primaryKey() -> String? { "id" }
    
    @Persisted var id: Int = .zero
    @Persisted var name: String = ""
    @Persisted var isPinned: Bool = false
    @Persisted var entryTime: Date = Date()
    
    
    required convenience init(from speaker: Speaker) {
        self.init()
        self.id = speaker.id
        self.name = speaker.name
        self.isPinned = speaker.isPinned
        self.entryTime = speaker.entryTime
    }
}

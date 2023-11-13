//
//  Speaker.swift
//

import CRepository
import Foundation
import RealmSwift

struct Speaker: Equatable {
    
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
    
    @Persisted(primaryKey: true) var id: Int = .zero
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
    
    convenience init(id: Int, name: String, isPinned: Bool, entryTime: Date) {
        self.init()
        self.id = id
        self.name = name
        self.isPinned = isPinned
        self.entryTime = entryTime
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ManageableSpeaker else { return false }
        return id == other.id && name == other.name && isPinned == other.isPinned && entryTime == other.entryTime
    }
}

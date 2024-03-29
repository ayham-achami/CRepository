//
//  ChatInfo.swift
//

import CRepository
import Foundation
import RealmSwift

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
    
    @Persisted var list: List<String>
    @Persisted(primaryKey: true) var id: Int = .zero
    
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

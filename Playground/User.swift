//
//  User.swift
//  Playground
//
//  Created by Ayham Hylam on 15.03.2023.
//

import RealmSwift
import CRepository

struct User {

    enum Role: String, PersistableEnum {
        
        case unknown = ""
        case guest
        case admin
        case recorder
        case sipClient
    }
    
    let id: String
    let name: String
    let roles: [Role]
    let email: String
    let initials: String
    let avatarHttpPath: String
    let position: String
    let isProfileFilled: Bool
}

// MARK: - User + ManageableRepresented
extension User: ManageableRepresented {

    init(from represented: ManageableUser) {
        self.id = represented.id
        self.name = represented.name
        self.roles = .init(represented.roles)
        self.email = represented.email
        self.initials = represented.initials
        self.avatarHttpPath = represented.avatarHttpPath
        self.position = represented.position
        self.isProfileFilled = represented.isProfileFilled
    }
}

// MARK: - User + ManageableSource
final class ManageableUser: Object, ManageableSource {
    
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var name: String
    @Persisted var email: String
    @Persisted var initials: String
    @Persisted var roles: List<User.Role>
    @Persisted var avatarHttpPath: String
    @Persisted var position: String
    @Persisted var isProfileFilled: Bool

    required convenience init(from user: User) {
        self.init()
        self.id = user.id
        self.name = user.name
        self.roles = .init(user.roles)
        self.email = user.email
        self.initials = user.initials
        self.avatarHttpPath = user.avatarHttpPath
        self.position = user.position
        self.isProfileFilled = user.isProfileFilled
    }
}

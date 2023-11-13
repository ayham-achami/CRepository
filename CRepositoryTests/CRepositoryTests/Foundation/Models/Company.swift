//
//  Company.swift
//

import CRepository
import Foundation
import RealmSwift

// MARK: - Company
struct Company: Equatable {
    
    let id: Int
    let name: String
    let logoId: Int?
}

// MARK: - Company + ManageableRepresented
extension Company: ManageableRepresented {
    
    typealias RepresentedType = ManageableCompany
    
    init(from represented: Self.RepresentedType) {
        self.id = represented.id
        self.name = represented.name
        self.logoId = represented.logoId
    }
}

// MARK: - Company + ManageableSource
final class ManageableCompany: Object, ManageableSource {
    
    @Persisted(primaryKey: true) var id: Int = .zero
    @Persisted var name: String = ""
    @Persisted var logoId: Int?
    
    required convenience init(from company: Company) {
        self.init()
        self.id = company.id
        self.name = company.name
        self.logoId = company.logoId
    }
    
    convenience init(id: Int, name: String, logoId: Int?) {
        self.init()
        self.id = id
        self.name = name
        self.logoId = logoId
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ManageableCompany else { return false }
        return id == other.id && name == other.name && logoId == other.logoId
    }
}

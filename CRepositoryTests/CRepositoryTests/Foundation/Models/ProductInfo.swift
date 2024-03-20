//
//  ProductInfo.swift
//

import CRepository
import Foundation
import RealmSwift

struct ProductInfo: Equatable {
    
    let id: Int
    let name: String
}

extension ProductInfo: ManageableRepresented {

    typealias RepresentedType = ManageableProductInfo
    
    init(from represented: ManageableProductInfo) {
        self.id = represented.id
        self.name = represented.name
    }
}

final class ManageableProductInfo: Object, ManageableSource {
        
    @Persisted(primaryKey: true) var id: Int = .zero
    @Persisted var name: String = ""
    
    required convenience init(from company: ProductInfo) {
        self.init()
        self.id = company.id
        self.name = company.name
    }
    
    convenience init(id: Int, name: String) {
        self.init()
        self.id = id
        self.name = name
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ManageableProductInfo else { return false }
        return id == other.id && name == other.name
    }
}

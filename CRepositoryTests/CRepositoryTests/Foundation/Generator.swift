//
//  Generator.swift
//

import Foundation
import RealmSwift

// MARK: - ModelGenerator
protocol ModelGenerator {
    
    func company(id: Int) -> Company
    
    func speakers(id: Int) -> Speaker
    
    func productInfo(id: Int) -> ProductInfo
    
    func companions(count: Int) -> [Company]
    
    func speakers(count: Int) -> [Speaker]
    
    func productInfos(count: Int) -> [ProductInfo]
    
    func chatInfo(id: Int) -> ChatInfo
}

// MARK: - ModelGenerator + Default
extension ModelGenerator {
    
    func company(id: Int) -> Company {
        .init(id: id, name: .random, logoId: Int.randomOrNil(to: id))
    }
    
    func speakers(id: Int) -> Speaker {
        .init(id: id, name: .random, isPinned: .random(), entryTime: .random)
    }
    
    func productInfo(id: Int) -> ProductInfo {
        .init(id: id, name: .random)
    }
    
    func companions(count: Int) -> [Company] {
        (1...count).map { id in
            company(id: id)
        }
    }
    
    func speakers(count: Int) -> [Speaker] {
        (1...count).map { id in
            speakers(id: id)
        }
    }
    
    func productInfos(count: Int) -> [ProductInfo] {
        (1...count).map { id in
            productInfo(id: id)
        }
    }
    
    func chatInfo(id: Int) -> ChatInfo {
        .init(id: id, users: List(["0"]))
    }
}

// MARK: - ManageableModelGenerator
protocol ManageableModelGenerator {
    
    func manageableCompany(id: Int) -> ManageableCompany
    
    func manageableSpeaker(id: Int) -> ManageableSpeaker
    
    func manageableProductInfo(id: Int) -> ManageableProductInfo
    
    func manageableCompanions(count: Int) -> [ManageableCompany]
    
    func manageableSpeakers(count: Int) -> [ManageableSpeaker]
    
    func manageableProductInfos(count: Int) -> [ManageableProductInfo]
    
    func manageableChatInfo(id: Int) -> ManageableChatInfo
}

// MARK: - ManageableModelGenerator + Default
extension ManageableModelGenerator {

    func manageableCompany(id: Int) -> ManageableCompany {
        .init(id: id, name: .random, logoId: Int.randomOrNil(to: id))
    }
    
    func manageableSpeaker(id: Int) -> ManageableSpeaker {
        .init(id: id, name: .random, isPinned: .random(), entryTime: .random)
    }
    
    func manageableProductInfo(id: Int) -> ManageableProductInfo {
        .init(id: id, name: .random)
    }
    
    func manageableCompanions(count: Int) -> [ManageableCompany] {
        (1...count).map { id in
            manageableCompany(id: id)
        }
    }
    
    func manageableSpeakers(count: Int) -> [ManageableSpeaker] {
        (1...count).map { id in
            manageableSpeaker(id: id)
        }
    }
    
    func manageableProductInfos(count: Int) -> [ManageableProductInfo] {
        (1...count).map { id in
            manageableProductInfo(id: id)
        }
    }
    
    func manageableChatInfo(id: Int) -> ManageableChatInfo {
        .init(id: id, users: List(["0"]))
    }
}

typealias ModelsGenerator = ModelGenerator & ManageableModelGenerator

// MARK: Types + Generation
private extension Int {
    
    static func randomOrNil(to limit: Int) -> Int? {
        let random = random(in: 1...limit)
        guard random.isMultiple(of: 2) else { return nil }
        return random
    }
}

private extension String {
    
    static var random: String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

private extension Date {
    
    static var random: Date {
        Date().addingTimeInterval(.random(in: 1...100))
    }
}

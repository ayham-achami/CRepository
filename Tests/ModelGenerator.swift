//
//  ModelGenerator.swift
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

import Foundation

protocol ModelGenerator {
    
    func company(id: Int) -> Company
    
    func speakers(id: Int) -> Speaker
    
    func productInfo(id: Int) -> ProductInfo
    
    func companions(count: Int) -> [Company]
    
    func speakers(count: Int) -> [Speaker]
    
    func productInfos(count: Int) -> [ProductInfo]
}

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
}

protocol ManageableModelGenerator {
    
    func manageableCompany(id: Int) -> ManageableCompany
    
    func manageableSpeaker(id: Int) -> ManageableSpeaker
    
    func manageableProductInfo(id: Int) -> ManageableProductInfo
    
    func manageableCompanions(count: Int) -> [ManageableCompany]
    
    func manageableSpeakers(count: Int) -> [ManageableSpeaker]
    
    func manageableProductInfos(count: Int) -> [ManageableProductInfo]
}

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
}

typealias ModelsGenerator = ModelGenerator & ManageableModelGenerator

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

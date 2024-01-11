//
//  RepositoryError.swift
//

import Foundation

/// Ошибки обращения хранилище
public enum RepositoryError: LocalizedError {

    /// Ошибка инициализации
    case initialization(fileURL: URL?)
    /// Не удалось осуществляет конвертацию между типами
    case conversion
    /// Транзакция записи не может быть успешно завершена
    case transaction

    public var errorDescription: String {
        switch self {
        case .initialization:
            return NSLocalizedString("Failed to access data file", comment: "Failed to access data file")
        case .conversion:
            return NSLocalizedString("Failed to convert type", comment: "Failed to convert type")
        case .transaction:
            return NSLocalizedString("Requested transaction access", comment: "Requested transaction access")
        }
    }
}

/// Ошибка 
public enum RepositoryFetchError: LocalizedError {

    /// Объект не был найден в базе
    case notFound(Any.Type)

    public var errorDescription: String {
        switch self {
        case let .notFound(type):
            return .init(format: NSLocalizedString("Not found in repository %s", comment: "Not found in repository %s"),
                         String(describing: type.self))
        }
    }
}

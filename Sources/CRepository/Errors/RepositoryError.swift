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

/// <#Description#>
public enum RepositoryFetchError: LocalizedError {

    /// <#Description#>
    case notFound

    public var errorDescription: String {
        switch self {
        case .notFound: // FIXME: 
            return NSLocalizedString("Not found in repository", comment: "Not found in repository")
        }
    }
}

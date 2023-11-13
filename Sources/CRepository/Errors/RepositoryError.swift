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
            return "Failed to access data file".localized
        case .conversion:
            return "Failed to convert type".localized
        case .transaction:
            return "Requested transaction access".localized
        }
    }
}

/// <#Description#>
public enum RepositoryFetchError: LocalizedError {

    /// <#Description#>
    case notFound

    public var errorDescription: String {
        switch self {
        case .notFound:
            return "Not found in repository".localized
        }
    }
}

//
//  motipetwatchos.swift
//  motipetwatchos
//
//  Created by MovingHUI on 2025/9/17.
//

import AppIntents

struct motipetwatchos: AppIntent {
    static var title: LocalizedStringResource { "motipetwatchos" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

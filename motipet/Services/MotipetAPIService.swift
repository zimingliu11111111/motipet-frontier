import Foundation

enum MotipetAPIError: Error {
    case baseURLNotConfigured
    case invalidResponse
    case serverError(statusCode: Int)
}

struct MotipetDailyStateRequest: Codable {
    let userId: String
    let date: String
    let gender: String?
    let sleepDurationHours: Double?
    let sleepEfficiency: Double?
    let restorativeSleepRatio: Double?
    let hrvRmssdToday: Double?
    let hrvRmssd3DayAvg: Double?
    let hrvRmssd7DayAvg: Double?
    let restingHeartRate: Double?
    let trainingLoadAu: Double?
}

struct MotipetDailyStateResponse: Codable {
    let petState: String
    let stateReason: String
    let xpGainBase: Int
    let xpGainBonus: Int
    let xpGainTotal: Int
    let readinessScore: Int
    let readinessDiagnosis: String
    let happinessScore: Int
    let happinessState: String
    let level: Int
    let leveledUp: Bool
    let totalXP: Int
    let xpIntoLevel: Int
    let xpToNextLevel: Int
    let levelProgressRatio: Double
    let forceHappySeconds: Int
}

final class MotipetAPIService {
    struct Config {
        static var baseURL: URL? = URL(string: "http://127.0.0.1:8000")
        static var userID: String = "demo_user"
        static var defaultGender: String? = "male"
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchDailyState(using score: Double) async throws -> MotipetDailyStateResponse {
        guard let baseURL = Config.baseURL else {
            throw MotipetAPIError.baseURLNotConfigured
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/motipet/daily_state"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(makePayload(using: score))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MotipetAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MotipetAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(MotipetDailyStateResponse.self, from: data)
    }

    private func makePayload(using score: Double) -> MotipetDailyStateRequest {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let sleepHours = Double.random(in: 7.0...8.5)
        let efficiency = Double.random(in: 0.85...0.95)
        let restorative = Double.random(in: 0.32...0.45)
        let hrvToday = max(40, min(120, score + Double.random(in: -6...6)))
        let hrv3Day = hrvToday + Double.random(in: -4...3)
        let hrv7Day = hrvToday + Double.random(in: -6...2)
        let restingHR = Double.random(in: 48...60)
        let trainingLoad = Double.random(in: 120...420)

        return MotipetDailyStateRequest(
            userId: Config.userID,
            date: dateString,
            gender: Config.defaultGender,
            sleepDurationHours: sleepHours,
            sleepEfficiency: efficiency,
            restorativeSleepRatio: restorative,
            hrvRmssdToday: hrvToday,
            hrvRmssd3DayAvg: hrv3Day,
            hrvRmssd7DayAvg: hrv7Day,
            restingHeartRate: restingHR,
            trainingLoadAu: trainingLoad
        )
    }
}
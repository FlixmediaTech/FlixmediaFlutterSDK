@preconcurrency import Flutter
import UIKit
import FlixMediaSDK

public class FlixInpagePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flix_media/methods", binaryMessenger: registrar.messenger())
        let instance = FlixInpagePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call: call, result: result)
        case "getInpageHtml":
            handleGetInpageHtml(call: call, result: result)
        case "openUrl":
            handleOpenUrl(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleOpenUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString)
        else {
            result(FlutterError(code: "ARG", message: "Missing url", details: nil))
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        }
    }

    private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let username = args["username"] as? String,
            let password = args["password"] as? String
        else {
            result(FlutterError(code: "ARG", message: "Missing credentials", details: nil))
            return
        }

        let useSandbox = args["useSandbox"] as? Bool ?? false

        Task {
            do {
                try await FlixMedia.shared.initialize(username: username, password: password, useSandbox: useSandbox)
                await MainActor.run { result(nil) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "INIT", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleGetInpageHtml(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let rawProductParams = args["productParams"] as? [String: Any]
        else {
            result(FlutterError(code: "ARG", message: "Missing productParams", details: nil))
            return
        }

        let productParamsDTO: ProductRequestParametersDTO
        do {
            let data = try JSONSerialization.data(withJSONObject: rawProductParams, options: [])
            productParamsDTO = try JSONDecoder().decode(ProductRequestParametersDTO.self, from: data)
        } catch {
            result(FlutterError(code: "ARG", message: "Invalid productParams", details: error.localizedDescription))
            return
        }

        let baseURLString = (args["baseURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = URL(string: baseURLString ?? "") ?? URL(string: "https://www.example.com")!

        Task {
            do {
                let html = try await buildFlixHTML(productParamsDTO: productParamsDTO, baseURL: baseURL)
                await MainActor.run { result(html) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "HTML", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func buildFlixHTML(productParamsDTO: ProductRequestParametersDTO, baseURL: URL) async throws -> String {
        let productParams = ProductRequestParameters(
            mpn: productParamsDTO.mpn ?? "",
            ean: productParamsDTO.ean ?? "",
            distId: productParamsDTO.distId ?? "",
            isoCode: productParamsDTO.isoCode ?? "",
            flIsoCode: productParamsDTO.flIsoCode ?? "",
            brand: productParamsDTO.brand ?? "",
            title: productParamsDTO.title ?? "",
            price: productParamsDTO.price ?? "",
            currency: productParamsDTO.currency ?? ""
        )

        let config = WebViewConfiguration(productParams: productParams, baseURL: baseURL)
        return try await FlixMedia.shared.loadHTML(configuration: config)
    }
}

private struct ProductRequestParametersDTO: Decodable, Sendable {
    let mpn: String?
    let ean: String?
    let distId: String?
    let isoCode: String?
    let flIsoCode: String?
    let brand: String?
    let title: String?
    let price: String?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case mpn
        case ean
        case distId
        case distributorId
        case isoCode
        case flIsoCode
        case brand
        case title
        case price
        case currency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        mpn = try c.decodeIfPresent(String.self, forKey: .mpn)
        ean = try c.decodeIfPresent(String.self, forKey: .ean)
        isoCode = try c.decodeIfPresent(String.self, forKey: .isoCode)
        flIsoCode = try c.decodeIfPresent(String.self, forKey: .flIsoCode)
        brand = try c.decodeIfPresent(String.self, forKey: .brand)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)

        if let dist = ProductRequestParametersDTO.decodeFlexibleString(c, key: .distId) {
            distId = dist
        } else {
            distId = ProductRequestParametersDTO.decodeFlexibleString(c, key: .distributorId)
        }

        price = ProductRequestParametersDTO.decodeFlexibleString(c, key: .price)
    }

    private static func decodeFlexibleString(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}

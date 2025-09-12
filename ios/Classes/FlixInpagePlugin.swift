import Flutter
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
            Task {
                do {
                    guard
                        let args = call.arguments as? [String: Any],
                        let username = args["username"] as? String,
                        let password = args["password"] as? String else {
                        result(FlutterError(code: "ARG", message: "Missing credentials", details: nil))
                        return
                    }
                    try await FlixMedia.shared.initialize(username: username, password: password)
                    result(nil)
                } catch {
                    result(FlutterError(code: "INIT", message: error.localizedDescription, details: nil))
                }
            }
        case "getInpageHtml":
            guard let dict = call.arguments as? [String: Any],
                  let prod = dict["productParams"] as? [String: Any] else {
                result(FlutterError(code: "ARG", message: "Missing productParams", details: nil))
                return
            }
            buildFlixHTML(productParams: prod) { html, error in
                if let e = error {
                    result(FlutterError(code: "HTML", message: e.localizedDescription, details: nil))
                } else {
                    result(html ?? "")
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func buildFlixHTML(productParams: [String: Any],
                               completion: @escaping (String?, Error?) -> Void) {
        Task {
            do {
                let data = try JSONSerialization.data(withJSONObject: productParams, options: [])
                let productParamsDTO = try JSONDecoder().decode(ProductRequestParametersDTO.self, from: data)
                
                let productParams = ProductRequestParameters(mpn: productParamsDTO.mpn ?? "",
                                                             ean: productParamsDTO.ean ?? "",
                                                             distId: productParamsDTO.distributorId ?? "",
                                                             isoCode: productParamsDTO.isoCode ?? "",
                                                             flIsoCode: productParamsDTO.flIsoCode ?? "")
                
                let config = WebViewConfiguration(productParams: productParams)
                let html = try await FlixMedia.shared.loadHTML(configuration: config)
                completion(html, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}

struct ProductRequestParametersDTO: Decodable {
    let mpn: String?
    let ean: String?
    let distributorId: String?   // <- trzymamy jako String, ale dekodujemy Int albo String
    let isoCode: String?
    let flIsoCode: String?

    enum CodingKeys: String, CodingKey {
        case mpn, ean, distributorId, isoCode, flIsoCode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mpn = try c.decodeIfPresent(String.self, forKey: .mpn)
        ean = try c.decodeIfPresent(String.self, forKey: .ean)

        // distributorId może przyjść jako "6" albo 6
        if let s = try? c.decode(String.self, forKey: .distributorId) {
            distributorId = s
        } else if let n = try? c.decode(Int.self, forKey: .distributorId) {
            distributorId = String(n)
        } else {
            distributorId = nil
        }

        isoCode = try c.decodeIfPresent(String.self, forKey: .isoCode)
        flIsoCode = try c.decodeIfPresent(String.self, forKey: .flIsoCode)
    }
}


import Foundation
import Moya
import Moya_ObjectMapper
import ObjectMapper
import PromiseKit

public class OAuthMoyaPromise<Target>: MoyaProvider<Target> where Target: TargetType {
	private(set) var oAuth: OAuth
	
	init(oAuth: OAuth,
	     endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
	     requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
	     stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
	     manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
	     plugins: [PluginType] = []) {
		
		self.oAuth = oAuth
		
		let requesPromisetClosure: RequestClosure = { endpoint, requestResult in
			requestClosure(endpoint, requestResult)
			
			if let request = endpoint.urlRequest {
				oAuth.authenticateRequest(request) { result in
					switch result {
					case .success(let request):
						requestResult(.success(request))
					case .failure(let error):
						requestResult(.failure(MoyaError.underlying(error)))
					}
				}
			} else {
				requestResult(.failure(MoyaError.requestMapping(endpoint.url)))
			}
		}
		super.init(endpointClosure: endpointClosure,
		           requestClosure:  requesPromisetClosure,
		           stubClosure: stubClosure,
		           manager: manager,
		           plugins: [NetworkLoggerPlugin(verbose: true)])
	}
}

public extension MoyaProvider {
	func requestPromise<T: BaseMappable>(_ target: Target, type: T.Type, atKeyPath keyPath: String? = nil) -> Promise<T> {
		return Promise<T> { [weak self] fulfill, reject in
			self?.request(target) { result in
				switch result {
				case .success(var response):
					do {
						response = try response.filterSuccessfulStatusAndRedirectCodes()
						fulfill(try response.mapObject(T.self, withKeyPath: keyPath))
					} catch let error {
						reject(error)
					}
				case .failure(let error):
					reject(error)
				}
			}
		}
	}
	
	func requestPromiseForCollection<T: BaseMappable>(_ target: Target, type: T.Type, atKeyPath keyPath: String? = nil) -> Promise<[T]> {
		return Promise<[T]> { [weak self] fulfill, reject in
			self?.request(target) { result in
				switch result {
				case .success(var response):
					do {
						response = try response.filterSuccessfulStatusAndRedirectCodes()
						fulfill(try response.mapArray(T.self, withKeyPath: keyPath))
					} catch let error {
						reject(error)
					}
				case .failure(let error):
					reject(error)
				}
			}
		}
	}
}

extension Moya.Response {
	
	typealias JSON = [String: Any]
	
	func mapObject<T: BaseMappable>(_ type: T.Type = T.self, withKeyPath keyPath: String?) throws -> T {
		
		if let keyPath = keyPath {
			guard let JSONObject = try self.mapJSON() as? JSON,
				let JSONForKeyPath = JSONObject[keyPath]  as? JSON,
				let parsedJSONObject = Mapper<T>().map(JSON:JSONForKeyPath) else {
					throw MoyaError.jsonMapping(self)
			}
			return parsedJSONObject
		} else {
			return try self.mapObject(T.self)
		}
	}
	
	func mapArray<T: BaseMappable>(_ type: T.Type = T.self, withKeyPath keyPath: String?) throws -> [T] {
		
		if let keyPath = keyPath {
			guard let JSONObject = try self.mapJSON() as? JSON,
				let JSONForKeyPath = JSONObject[keyPath],
				let parsedJSONObject = Mapper<T>().mapArray(JSONObject: JSONForKeyPath) else {
					throw MoyaError.jsonMapping(self)
			}
			return parsedJSONObject
		} else {
			return try self.mapArray(T.self)
		}
	}
}

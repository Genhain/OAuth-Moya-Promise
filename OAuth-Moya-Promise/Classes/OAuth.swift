import Result

public typealias OAuthRequestResult = Result<URLRequest, NSError>

public protocol OAuth {
	func authenticateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, NSError>) -> Swift.Void)
}

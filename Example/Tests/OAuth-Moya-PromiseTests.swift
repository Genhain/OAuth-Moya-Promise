//
//  OAuth_Moya_PromiseTests.swift
//  OAuth Moya PromiseTests
//
//  Created by Ben Fowler on 14/6/2017.
//  Copyright © 2017 Genhain. All rights reserved.
//

import Quick
import Nimble
import Moya
import ObjectMapper
import Alamofire

@testable import OAuth_Moya_Promise

enum TestService {
	case user(forId: Int)
	case updateUser(forId: Int, username: String, age: Int, weight: Double)
	case uploadUserImage(forId: Int, data: [Moya.MultipartFormData])
}

extension TestService: TargetType {
	var baseURL: URL {
		return URL(string: "baseURL")!
	}
	
	var path: String {
		switch self {
		case .user(let id):
			return "/user/\(id)"
		case .updateUser(let id, _, _, _):
			return "/user/\(id)/update"
		case .uploadUserImage(let id, _):
			return "/user/\(id)/uploadImage"
		}
	}
	
	var method: Moya.Method {
		switch self {
		case .user:
			return .get
		case .updateUser:
			return .put
		case .uploadUserImage:
			return .patch
		}
	}
	
	var parameters: [String : Any]? {
		switch self {
		case .user: return nil
		case .updateUser(_, let username, let age, let weight):
			return ["username":username, "age": age, "weight": weight]
		case .uploadUserImage:
			return nil
		}
	}
	
	var parameterEncoding: ParameterEncoding {
		switch self {
		case .user, .updateUser:
			return URLEncoding.default
		case .uploadUserImage:
			return JSONEncoding.default
		}
	}
	
	var task: Task {
		switch self {
		case .uploadUserImage(_, let data):
			return .upload(.multipart(data))
		default:
			return .request
		}
	}
	
	var sampleData: Data {
		switch self {
		case .user(let id):
			return try! JSONSerialization.data(withJSONObject: TestServiceUser(JSON: ["id": id])!.toJSON())
		case .updateUser(let id, let username, let age, let weight):
			return try! JSONSerialization.data(withJSONObject:["id": id, "username": username, "age": age, "weight": weight])
		case .uploadUserImage(let id, _):
			return try! JSONSerialization.data(withJSONObject:["id": id, "namecard_url": "https/test"])
		}
	}
}

class TestServiceUser: Mappable {
	
	var id: Int!
	var username: String? = "test"
	var age: Int? = 404
	var weight: Double! = 9001
	var businessCardURLString: String?
	
	required init?(map: Map) {}
	
	func mapping(map: Map) {
		id			<- map["id"]
		username    <- map["username"]
		age         <- map["age"]
		weight      <- map["weight"]
		businessCardURLString <- map["namecard_url"]
	}
}


class OAuthFake: OAuth  {
	private(set) var lastRequest: URLRequest?
	private(set) var lastCompletion: ((OAuthRequestResult) -> Swift.Void)?
	
	var OAuthRequestResultToReturn: OAuthRequestResult?
	
	func authenticateRequest(_ request: URLRequest, completion: @escaping (OAuthRequestResult) -> Void) {
		self.lastRequest = request
		self.lastCompletion = completion
		
		if let OAuthRequestResultToReturn = OAuthRequestResultToReturn {
			completion(OAuthRequestResultToReturn)
		} else {
			let urlRequest = URLRequest(url: try! "www.test.com".asURL())
			completion(OAuthRequestResult(urlRequest, failWith: NSError(domain: "", code: 0, userInfo: nil)))
		}
	}
}



import Result

class OAuthMoyaPromiseTests: QuickSpec {
	
	override func spec() {
		
		describe(".requestPromise") {
			context("when getting user with default fields") {
				it("will return test user with default fields") {
					waitUntil{ done in
						let oAuthSpy = OAuthFake()
						let SUT = OAuthMoyaPromise<TestService>(oAuth: oAuthSpy, stubClosure: MoyaProvider.immediatelyStub)
						
						SUT.requestPromise(.user(forId: 20), type: TestServiceUser.self).then { testUser -> Void in

							expect(testUser.id).to(equal(20))
							expect(testUser.username).to(equal("test"))
							expect(testUser.age).to(equal(404))
							expect(testUser.weight).to(equal(9001))
							
							done()
						}.catch {_ in }
					}
				}
			}
			
			context("when updating User") {
				var expectedID: Int!
				var expectedUsername: String!
				var expectedAge: Int!
				var expectedWeight: Double!
				
				context("when forId: 100, username: \"hello\", age: 21, weight: 80") {
					it("will return user with passed in data") {
						waitUntil{ done in
							
							expectedID = 100
							expectedUsername = "hello"
							expectedAge = 21
							expectedWeight = 80
							
							let oAuthSpy = OAuthFake()
							let SUT = OAuthMoyaPromise<TestService>(oAuth: oAuthSpy, stubClosure: MoyaProvider.immediatelyStub)
							
							SUT.requestPromise(TestService.updateUser(forId: expectedID, username: expectedUsername, age: expectedAge, weight: expectedWeight), type: TestServiceUser.self).then { testUser -> Void in
								
								expect(testUser.id).to(equal(expectedID))
								expect(testUser.username).to(equal(expectedUsername))
								expect(testUser.age).to(equal(expectedAge))
								expect(testUser.weight).to(equal(expectedWeight))
								
								done()
							}.catch {_ in }
						}
					}
				}
				
				context("when forId: 222, username: \"goodbye\", age: 99, weight: 1888") {
					it("will return user with passed in data") {
						waitUntil{ done in
							
							expectedID = 222
							expectedUsername = "goodbye"
							expectedAge = 123
							expectedWeight = 1989
							
							let oAuthSpy = OAuthFake()
							let SUT = OAuthMoyaPromise<TestService>(oAuth: oAuthSpy, stubClosure: MoyaProvider.immediatelyStub)
							
							SUT.requestPromise(TestService.updateUser(forId: expectedID, username: expectedUsername, age: expectedAge, weight: expectedWeight), type: TestServiceUser.self).then { testUser -> Void in
								
								expect(testUser.id).to(equal(expectedID))
								expect(testUser.username).to(equal(expectedUsername))
								expect(testUser.age).to(equal(expectedAge))
								expect(testUser.weight).to(equal(expectedWeight))
								
								done()
							}.catch {_ in }
						}
					}
				}
			}
			
			context("when uploading image") {
				it("will contain businessCardURLString of https/test") {
					waitUntil{ done in
						let oAuthSpy = OAuthFake()
					
						let SUT = OAuthMoyaPromise<TestService>(oAuth: oAuthSpy, stubClosure: MoyaProvider.immediatelyStub)
						
						let multipartFormDataArray: [Moya.MultipartFormData] = [MultipartFormData(provider: MultipartFormData.FormDataProvider.file(URL.init(fileURLWithPath: "yabba/dabba/doo")), name: "image")]
						
						SUT.requestPromise(TestService.uploadUserImage(forId: 53, data: multipartFormDataArray), type: TestServiceUser.self).then { testUser -> Void in
							
							expect(testUser.id).to(equal(53))
							expect(testUser.businessCardURLString).to(equal("https/test"))
							
							done()
						}.catch {_ in }
					}
				}
			}
		}
	}
}

public extension UIImage {
	public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
		let rect = CGRect(origin: .zero, size: size)
		UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
		color.setFill()
		UIRectFill(rect)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		guard let cgImage = image?.cgImage else { return nil }
		self.init(cgImage: cgImage)
	}
	
	public func png() -> Data? {
		return UIImagePNGRepresentation(self)
	}
	
	public func jpeg(quality: CGFloat = 1.0) -> Data? {
		return UIImageJPEGRepresentation(self, quality)
	}
}

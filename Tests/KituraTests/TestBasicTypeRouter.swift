/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import Foundation

@testable import Kitura
@testable import KituraNet

#if swift(>=4.0)

class TestBasicTypeRouter: KituraTest {
    static var allTests: [(String, (TestBasicTypeRouter) -> () throws -> Void)] {
        return [
            ("testBasicPost", testBasicPost),
            ("testBasicGet", testBasicGet),
            ("testBasicSingleGet", testBasicSingleGet),
            ("testBasicDelete", testBasicDelete),
            ("testBasicSingleDelete", testBasicSingleDelete),
            ("testBasicPut", testBasicPut),
            //("testBasicPatch", testBasicPatch),
        ]
    }
    
    //Need to initialise to avoid compiler error
    var router = Router()
    var userStore: [Int: User] = [:]
    var optionalUserStore: [Int: OptionalUser] = [:]
    //Reset for each test
    override func setUp() {
        router = Router()
        userStore = [1: User(id: 1, name: "Mike"), 2: User(id: 2, name: "Chris"), 3: User(id: 3, name: "Ricardo")]
        optionalUserStore = [1: OptionalUser(id: 1, name: "Mike"), 2: OptionalUser(id: 2, name: "Chris"), 3: OptionalUser(id: 3, name: "Ricardo")]
    }
    
    struct User: Codable {
        let id: Int
        let name: String
        
        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }        
    }
    
    struct OptionalUser: Codable {
        let id: Int?
        let name: String?
        
        init(id: Int?, name: String?) {
            self.id = id
            self.name = name
        }
    }
    
    struct Item: Identifier {
        public let id: Int
        public init(value: String) throws {
            if let id = Int(value) {
                self.id = id
            } else {
                id = 0
            }
        }
    }
    
    func testBasicPost() {

        router.post("/users") { (user: User, respondWith: (User) -> Void) in
            print("POST on /users for user \(user)")
            // Let's keep the test simple
            // We just want to test that we can register a handler that 
            // receives and sends back a Codable instance
            self.userStore[user.id] = user            
            respondWith(user)
        }
        
        performServerTest(router, timeout: 30) { expectation in
            // Let's create a User instance
            let expectedUser = User(id: 4, name: "David")
            // Create JSON representation of User instance
            guard let userData = try? JSONEncoder().encode(expectedUser) else {
                XCTFail("Could not generate user data from string!")
                return
            }
            
            self.performRequest("post", path: "/users", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }               
               
                XCTAssertEqual(response.statusCode, HTTPStatusCode.created, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length > 0, "Expected some bytes, received \(String(describing: length)) bytes.")
                    guard let user = try? JSONDecoder().decode(User.self, from: data) else {
                    XCTFail("Could not decode response! Expected response decodable to User, but got \(String(describing: String(data: data, encoding: .utf8)))")
                    return
                }

                // Validate the data we got back from the server
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.id, expectedUser.id)
                     
                expectation.fulfill()
            }, requestModifier: { request in
                request.write(from: userData)
            })
        }
    }
    
    func testBasicGet() {
        router.get("/users") { (respondWith: ([User]) -> Void) in
            print("GET on /users")
        
            respondWith(self.userStore.map({ $0.value }))
        }
        performServerTest(router, timeout: 30) { expectation in
            let expectedUsers = self.userStore.map({ $0.value }) // TODO: Write these out explicitly?
            
            self.performRequest("get", path: "/users", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }
                
                XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length > 0, "Expected some bytes, received \(String(describing: length)) bytes.")
                guard let users = try? JSONDecoder().decode([User].self, from: data) else {
                    XCTFail("Could not decode response! Expected response decodable to array of Users, but got \(String(describing: String(data: data, encoding: .utf8)))")
                    return
                }
                
                // Validate the data we got back from the server
                for (index, user) in users.enumerated() {
                    XCTAssertEqual(user.id, expectedUsers[index].id)
                    XCTAssertEqual(user.name, expectedUsers[index].name)
                }
                
                expectation.fulfill()
            })
        }
    }
    
    //Need to handle error, see next comment
    struct NotFoundError: Swift.Error {}
    
    func testBasicSingleGet() {
        router.get("/users") { (id: Item, respondWith: (User) -> Void) in
            print("GET on /users")
            guard let user = self.userStore[id.id] else {
                XCTFail("ERROR!!! Couldn't find user with id \(id.id)")
                throw NotFoundError() // TODO: This is not sufficient for an async function
            }
            respondWith(user)
        }
        performServerTest(router, timeout: 30) { expectation in
            guard let expectedUser = self.userStore[1] else {
                XCTFail("ERROR!!! Couldn't find user with id 1")
                return
            }
            
            self.performRequest("get", path: "/users/1", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }
                
                XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length > 0, "Expected some bytes, received \(String(describing: length)) bytes.")
                guard let user = try? JSONDecoder().decode(User.self, from: data) else {
                    XCTFail("Could not decode response! Expected response decodable to array of Users, but got \(String(describing: String(data: data, encoding: .utf8)))")
                    return
                }
                
                // Validate the data we got back from the server
                XCTAssertEqual(user.id, expectedUser.id)
                XCTAssertEqual(user.name, expectedUser.name)
                
                expectation.fulfill()
            })
        }
    }
    
    func testBasicDelete() {
        
        router.delete("/users") { (respondWith: (Swift.Error?) -> Void) in
            self.userStore.removeAll()
            respondWith(nil)
        }
        
        performServerTest(router, timeout: 30) { expectation in
            
            self.performRequest("delete", path: "/users", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }
                
                XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length == 0, "Expected zero bytes, received \(String(describing: length)) bytes.")
                
                expectation.fulfill()
            })
        }
    }
    
    func testBasicSingleDelete() {
        
        router.delete("/users") { (id: Item, respondWith: (Swift.Error?) -> Void) in
            respondWith(nil)
        }
        
        performServerTest(router, timeout: 30) { expectation in
            
            self.performRequest("delete", path: "/users/1", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }
                
                XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length == 0, "Expected zero bytes, received \(String(describing: length)) bytes.")
                
                expectation.fulfill()
            })
        }
    }
    
    func testBasicPut() {
        
        router.put("/users") { (id: Item, user: User, respondWith: (User) -> Void) in
            self.userStore[id.id] = user
            respondWith(user)
        }
        
        performServerTest(router, timeout: 30) { expectation in
            // Let's create a User instance
            let expectedUser = User(id: 1, name: "David")
            // Create JSON representation of User instance
            guard let userData = try? JSONEncoder().encode(expectedUser) else {
                XCTFail("Could not generate user data from string!")
                return
            }
            
            self.performRequest("put", path: "/users/1", callback: { response in
                guard let response = response else {
                    XCTFail("ERROR!!! ClientRequest response object was nil")
                    return
                }
                
                XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response.statusCode))")
                var data = Data()
                guard let length = try? response.readAllData(into: &data) else {
                    XCTFail("Error reading response length!")
                    return
                }
                
                XCTAssert(length > 0, "Expected some bytes, received \(String(describing: length)) bytes.")
                guard let user = try? JSONDecoder().decode(User.self, from: data) else {
                    XCTFail("Could not decode response! Expected response decodable to User, but got \(String(describing: String(data: data, encoding: .utf8)))")
                    return
                }
                
                // Validate the data we got back from the server
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.id, expectedUser.id)
                
                expectation.fulfill()
            }, requestModifier: { request in
                request.write(from: userData)
            })
        }
    }
    
    //TODO: Currently fails, investigation is needed
//    func testBasicPatch() {
//
//        router.patch("/users") { (id: Item, user: OptionalUser, respondWith: (OptionalUser) -> Void) in
//
//            self.optionalUserStore[id.id] = user
//            respondWith(user)
//        }
//
//        performServerTest(router, timeout: 30) { expectation in
//            // Let's create a User instance
//            let expectedUser = OptionalUser(id: nil, name: "David")
//            // Create JSON representation of User instance
//            guard let userData = try? JSONEncoder().encode(expectedUser) else {
//                XCTFail("Could not generate user data from string!")
//                return
//            }
//
//            self.performRequest("patch", path: "/users/2", callback: { response in
//                guard let response = response else {
//                    XCTFail("ERROR!!! ClientRequest response object was nil")
//                    return
//                }
//
//                XCTAssertEqual(response.statusCode, HTTPStatusCode.created, "HTTP Status code was \(String(describing: response.statusCode))")
//                var data = Data()
//                guard let length = try? response.readAllData(into: &data) else {
//                    XCTFail("Error reading response length!")
//                    return
//                }
//
//                XCTAssert(length > 0, "Expected some bytes, received \(String(describing: length)) bytes.")
//                guard let user = try? JSONDecoder().decode(User.self, from: data) else {
//                    XCTFail("Could not decode response! Expected response decodable to User, but got \(String(describing: String(data: data, encoding: .utf8)))")
//                    return
//                }
//
//                // Validate the data we got back from the server
//                XCTAssertEqual(user.name, expectedUser.name)
//                XCTAssertEqual(user.id, expectedUser.id)
//
//                expectation.fulfill()
//            }, requestModifier: { request in
//                request.write(from: userData)
//            })
//        }
//    }
}

#endif


/**
 * Copyright IBM Corporation 2016
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
import Glibc
@testable import KituraTests

srand(UInt32(time(nil)))

// http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift

#if !swift(>=3.2)
extension MutableCollection where Indices.Iterator.Element == Index {
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(random() % numericCast(unshuffledCount))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}
#else
extension MutableCollection {
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(random() % numericCast(unshuffledCount))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            self.swapAt(firstUnshuffled, i)
        }
    }
}
#endif

extension Sequence {
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

XCTMain([
    testCase(MiscellaneousTests.allTests.shuffled()),
    testCase(TestContentType.allTests.shuffled()),
    testCase(TestCookies.allTests.shuffled()),
    testCase(TestErrors.allTests.shuffled()),
    testCase(TestMultiplicity.allTests.shuffled()),
    testCase(TestRequests.allTests.shuffled()),
    testCase(TestResponse.allTests.shuffled()),
    testCase(TestRouteRegex.allTests.shuffled()),
    testCase(TestRouterHTTPVerbsGenerated.allTests.shuffled()),
    testCase(TestServer.allTests.shuffled()),
    testCase(TestSubrouter.allTests.shuffled()),
    testCase(TestStaticFileServer.allTests.shuffled()),
    testCase(TestTemplateEngine.allTests.shuffled())
    ].shuffled())

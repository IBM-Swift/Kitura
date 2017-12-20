/*
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
 */

// MARK LinkParameter

/** Possible parameters of Link HTTP header.
In this example, a function to add a link to a HTTP `Header` where the user must specify a LinkParameter from the enum to be added.
 See [RFC 5988](https://tools.ietf.org/html/rfc5988) for more details.
### Usage Example: ###
```swift
public mutating func addLink(_ link: String, linkParameters: [LinkParameter: String]) {
   var headerValue = "<\(link)>"
   for (linkParamer, value) in linkParameters {
       headerValue += "; \(linkParamer.rawValue)=\"\(value)\""
   }
   self.append("Link", value: headerValue)
}
```
*/
public enum LinkParameter: String {

    /// The relation type of the link.
    case rel

    /// The context of a link conveyed in the Link header field.
    case anchor

    /// An indication that the semantics of the relationship are in the reverse direction.
    case rev

    /// A hint indicating what the language of the result of dereferencing the link should be.
    case hreflang

    /// An intended destination medium or media for style information.
    case media

    /// A human-readable label of the destination of a link.
    case title

    /// A hint indicating what the media type of the result of dereferencing the link should be.
    case type
}

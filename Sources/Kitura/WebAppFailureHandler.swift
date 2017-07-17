//
//  WebAppFailureHandler.swift
//  Kitura-Next-Perf
//
//  Created by Carl Brown on 5/8/17.
//
//

import Foundation
import HTTP

class WebAppFailureHandler: ResponseCreating {
    func serve(request req: HTTPRequest, context: RequestContext, response res: HTTPResponseWriter ) -> HTTPBodyProcessing {
        //Assume the router gave us the right request - at least for now
        res.writeHeader(status: .notFound, headers: [.transferEncoding: "chunked"])
        return .processBody { (chunk, stop) in
            switch chunk {
            case .chunk(_, let finishedProcessing):
                finishedProcessing()
            case .end:
                res.done()
            default:
                stop = true /* don't call us anymore */
                res.abort()
            }
        }
    }
}

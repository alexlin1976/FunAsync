# FunAsync
Fun(tional)Async(hronous) is a Swift project to simplify asynchronous programming but not using iOS 13 only Combine or great but complex RxSwift

## The purpose
1. do **asynchronous** operation by **functional** programming
1. What operations to apply:
  1. Web API query
  1. Notification center
  1. UI components actions

## What it is going to be like
1. Web API query asyncronously with functional
```swift
FunasyncWebRequest(urlString: "http://test.123.com", parameters: ["test": 1], timeoutList: [3,6,30], method: .post)
.jsonResponse() // general map for parsing response into JSON
.map(clousre: { (jsonResponse) -> Int? in // process the JSON dictionary to get the target data
    guard let dict = jsonResponse as? [String:Any] else { return nil }
    return dict["statusCode"] as? Int
})
.catchError { (error) in
    // deal with the error
    print(String(describing: error))
}
.observe(on: DispatchQueue.main) // set the target dispatch queue to main queue
.subscribe {
    guard let statusCode = $0 as? Int else { return }
    if statusCode == 0 {
        print("operation success with status code is 0")
    }
}```

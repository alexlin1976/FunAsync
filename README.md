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
URLSession.shared.dataTask(urlString: "http://validate.jsontest.com/", params: ["json":"{\"key\":\"value\"}"])
.jsonResponse() // general map for parsing response into JSON
.map(clousre: { (jsonResponse) -> Bool? in // process the JSON dictionary to get the target data
    guard let dict = jsonResponse as? [String:Any] else { return nil }
    return dict["validate"] as? Bool
})
.catchError { (error) in
    // deal with the error
    print(String(describing: error))
}
.observe(on: DispatchQueue.main) // set the target dispatch queue to main queue
.subscribe {
    if let validate = $0, validate {
        print("Yeah")
    }
}
```

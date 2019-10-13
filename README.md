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
        .jsonResponse()
        .catchError { (error) in
                
        }
        .observe(on: DispatchQueue.main)
        .subscribe { (jsonResponse) in
            
        }
```

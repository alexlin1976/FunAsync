//
//  ViewController.swift
//  FunAsyncSample
//
//  Created by Alex Lin on 2019/10/13.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import UIKit
import FunAsync

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        FunasyncWebRequest(urlString: "https://api.github.com/repos/alexlin1976/FunAsync", parameters: [:], timeoutList: [3,6,30], method: .post)
        .jsonResponse() // general map for parsing response into JSON
        .map(clousre: { (jsonResponse) -> Int? in // process the JSON dictionary to get the target data
            guard let dict = jsonResponse as? [String:Any] else { return nil }
            return dict["watchers_count"] as? Int
        })
        .catchError { (error) in
            // deal with the error
            print(String(describing: error))
        }
        .observe(on: DispatchQueue.main) // set the target dispatch queue to main queue
        .subscribe {
            guard let watchersCount = $0 as? Int else { return }
            if watchersCount == 0 {
                print("Ahhhhh....")
            }
        }
    }


}


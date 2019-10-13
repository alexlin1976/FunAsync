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
        
        FunasyncWebRequest(urlString: "http://test.123.com", parameters: ["test": 1], timeoutList: [3,6,30], method: .post)
        .jsonResponse()
        .catchError { (error) in
                
        }
        .observe(on: DispatchQueue.main)
        .subscribe { (jsonResponse) in
            
        }
    }


}


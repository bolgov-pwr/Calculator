//
//  ViewController.swift
//  Calc
//
//  Created by admin on 13.11.2017.
//  Copyright © 2017 Ivan Bolgov. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {

    var yForX : ((Double) -> Double)? { didSet { updateUI() }}
    @IBOutlet weak var graphView: GraphView! { didSet {
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(GraphView.scale(_:))))
        graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: #selector(GraphView.originMove(_:))))
        
        let doubleTap = UITapGestureRecognizer(target: graphView, action: #selector(GraphView.origin(_:)))
        doubleTap.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(doubleTap)
        updateUI()
        }
    }
    
    func updateUI() {
        graphView?.yForX = yForX
    }
    
    /*override func viewDidLoad() {
        super.viewDidLoad()
        yForX = { sin($0) / cos($0) }
    }*/
}


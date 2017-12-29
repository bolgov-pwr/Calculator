//
//  ViewController.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/26/17.
//  Copyright © 2017 Tatiana Kornilova. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var displayM: UILabel!
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var tochka: UIButton!{
        didSet {
            tochka.setTitle(decimalSeparator, for: UIControlState())
        }
    }
    private var brain = CalculatorBrain ()
    
    private var variableValues = [String:Double]()
    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
            userInTheMiddleOfTyping = true
        }
    }
    @IBAction func setM(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        let symbol = String(sender.currentTitle!.dropLast())
        variableValues[symbol] = displayValue
        displayResult = brain.evauate(using: variableValues)
    }
    @IBAction func pushM(_ sender: UIButton) {
        brain.setOperand(variable: sender.currentTitle!)
        displayResult = brain.evauate(using: variableValues)
    }
    
    var displayValue: Double? {
        get {
            if let text = display.text, let value = Double(text){
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                display.text = formatter.string(from: NSNumber(value:value))
            }
        }
    }
    
    var displayResult: (result: Double?, isPending: Bool,
        description: String, error: String?) = (nil, false, " ", nil){
        // Наблюдатель Свойства модифицирует три IBOutlet метки
        didSet {
            switch displayResult {
            case (nil, _, " ",nil) : displayValue = 0
            case (let result, _,_, nil): displayValue = result
            case (_, _, _, let error): display.text = error!
            }
            history.text = displayResult.description != " " ? displayResult.description + (displayResult.isPending ? " …" : " =") : " "
            displayM.text = "M = " + formatter.string(from: NSNumber(value:variableValues["M"] ?? 0))!
        }
    }
    
    @IBAction func performOPeration(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            if let value = displayValue{
                brain.setOperand(value)
            }
            userInTheMiddleOfTyping = false
        }
        if  let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayResult = brain.evauate(using: variableValues)
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        userInTheMiddleOfTyping = false
        brain.clear()
        variableValues = [:]
        displayResult = brain.evauate()
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            guard !display.text!.isEmpty else { return }
            display.text = String (display.text!.dropLast())
            if display.text!.isEmpty{
                displayValue = 0
            }
        }
        else {
            brain.undo()
            displayResult = brain.evauate(using: variableValues)
        }
    }
}


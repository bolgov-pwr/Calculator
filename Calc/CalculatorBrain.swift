//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Tatiana Kornilova on 3/8/17.
//  All rights reserved.
//

import Foundation

struct CalculatorBrain {
    
    private enum OpStack {
        case operand(Double)
        case operation(String)
        case variable(String)
    }
    private var internalProgram = [OpStack]()
    
    private enum Operation {
        case nullaryOperation(() -> Double,String)
        case constant (Double)
        case unaryOperation ((Double) -> Double,((String) -> String)?, ((Double) -> String?)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?, ((Double, Double) -> String?)?, Int)
        case equals
    }
  
    private var operations : Dictionary <String,Operation> = [
        
        "Ran": Operation.nullaryOperation({ Double(arc4random())/Double(UInt32.max)},"rand()"),
        
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "±": Operation.unaryOperation({ -$0 },nil,nil),           // { "±(" + $0 + ")"}
        "√": Operation.unaryOperation(sqrt,nil, { $0<0 ? "√ отриц. числа" : nil}),              // { "√(" + $0 + ")"}
        "cos": Operation.unaryOperation(cos,nil, nil),             // { "cos(" + $0 + ")"}
        "sin": Operation.unaryOperation(sin,nil, nil),             // { "sin(" + $0 + ")"}
        "tan": Operation.unaryOperation(tan,nil, nil),             // { "tan(" + $0 + ")"}
        "sin⁻¹" : Operation.unaryOperation(asin,nil, { $0 < -1.0 || $0 > 1.0 ? "не в диапазоне [-1;1]" : nil }),         // { "sin⁻¹(" + $0 + ")"}
        "cos⁻¹" : Operation.unaryOperation(acos,nil, { $0 < -1.0 || $0 > 1.0 ? "не в диапазоне [-1;1]" : nil }),         // { "cos⁻¹(" + $0 + ")"}
        "tan⁻¹" : Operation.unaryOperation(atan, nil, nil),        // { "tan⁻¹(" + $0 + ")"}
        "ln" : Operation.unaryOperation(log,nil, { $0<=0 ? "ln отриц. числа" : nil }),             //  { "ln(" + $0 + ")"}
        "x⁻¹" : Operation.unaryOperation({1.0/$0}, {"(" + $0 + ")⁻¹"}, { $0 == 0.0 ? "деление на ноль" : nil }),
        "х²" : Operation.unaryOperation({$0 * $0}, { "(" + $0 + ")²"}, nil),
        "×": Operation.binaryOperation(*, nil, nil, 1),                // { $0 + " × " + $1 }
        "÷": Operation.binaryOperation(/, nil, { $1 == 0.0 ? "деление на ноль" : nil },1),                // { $0 + " ÷ " + $1 }
        "+": Operation.binaryOperation(+, nil, nil, 0),                // { $0 + " + " + $1 }
        "−": Operation.binaryOperation(-, nil, nil, 0),                // { $0 + " - " + $1 }
        "xʸ" : Operation.binaryOperation(pow, { $0 + " ^ " + $1 }, nil,2),
        "=": Operation.equals
    ]
    func evauate(using variables: Dictionary<String, Double>? = nil) -> (result: Double?, isPending: Bool, description: String, error: String?) {
        
        var cache: (accumulator: Double?, descriptionAccumulator: String?)
        var error: String?
        var pendingBinaryOperation: PendingBinaryOperation?
        var prevPrecedence = Int.max
        var description: String? {
            get {
                if pendingBinaryOperation == nil {
                    return cache.descriptionAccumulator
                } else {
                    return  pendingBinaryOperation!.descriptionFunction(
                        pendingBinaryOperation!.descriptionOperand,
                        cache.descriptionAccumulator ?? "")
                }
            }
        }
        
        var result: Double? {
            get {
                return cache.accumulator
            }
        }
        
        var resultIsPending: Bool {
            get {
                return pendingBinaryOperation != nil
            }
        }
        
        func setOperand (_ operand: Double){
            cache.accumulator = operand
            if let value = cache.accumulator {
                cache.descriptionAccumulator =
                    formatter.string(from: NSNumber(value:value)) ?? ""
            }
        }
        
        func setOperand (variable named: String) {
            cache.accumulator = variables?[named] ?? 0
            cache.descriptionAccumulator = named
        }
        
        func performOperation(_ symbol: String) {
            if let operation = operations[symbol]{
                switch operation {
                    
                case .nullaryOperation(let function, let descriptionValue):
                    cache = (function(), descriptionValue)
                    
                case .constant(let value):
                    cache = (value,symbol)
                    
                case .unaryOperation (let function, var descriptionFunction, let validator):
                    if cache.accumulator != nil {
                        error = validator?(cache.accumulator!)
                        cache.accumulator = function (cache.accumulator!)
                        if  descriptionFunction == nil{
                            descriptionFunction = {symbol + "(" + $0 + ")"}   //standard
                        }
                        cache.descriptionAccumulator =
                            descriptionFunction!(cache.descriptionAccumulator!)
                    }
                    
                case .binaryOperation (let function, var descriptionFunction, let validator, let precedence):
                    performPendingBinaryOperation()
                    if cache.accumulator != nil {
                        if  descriptionFunction == nil{
                            descriptionFunction = {$0 + " " + symbol + " " + $1}   //standard
                        }
                        
                        pendingBinaryOperation = PendingBinaryOperation (function: function,
                                                                    firstOperand: cache.accumulator!,
                                                                    descriptionFunction: descriptionFunction!,
                                                                descriptionOperand: cache.descriptionAccumulator!,
                                                                validator: validator,
                                                                prevPrecedence: prevPrecedence,
                                                                precedence: precedence)
                        cache = (nil, nil)
                    }
                    
                case .equals:
                    performPendingBinaryOperation()
                }
            }
        }
        
        func  performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && cache.accumulator != nil {
                error = pendingBinaryOperation!.validate(with: cache.accumulator!)
                cache.accumulator =  pendingBinaryOperation!.perform(with: cache.accumulator!)
                cache.descriptionAccumulator =
                    pendingBinaryOperation!.performDescription(with: cache.descriptionAccumulator!)
                prevPrecedence = pendingBinaryOperation!.precedence
                pendingBinaryOperation = nil
                
            }
        }
        
        guard !internalProgram.isEmpty else { return (nil, false, " ", nil)}
        for op in internalProgram {
            switch op {
            case .operand(let operand):
                setOperand(operand)
            case .variable(let symbol):
                setOperand(variable: symbol)
            case .operation(let operation):
                performOperation(operation)
            }
        }
        return (result, resultIsPending, description ?? "", error)
    }
    
    mutating func setOperand (_ operand: Double){
        internalProgram.append(OpStack.operand(operand))
    }
    
    mutating func setOperand (variable named:String) {
        internalProgram.append(OpStack.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        internalProgram.append(OpStack.operation(symbol))
    }
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private struct PendingBinaryOperation {
        let function: (Double,Double) -> Double
        let firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        var validator: ((Double, Double) -> String?)?
        var prevPrecedence :Int
        var precedence :Int
        
        func perform (with secondOperand: Double) -> Double {
            return function (firstOperand, secondOperand)
        }
        
        func performDescription (with secondOperand: String) -> String {
            var descriptionNew = descriptionOperand
            if prevPrecedence < precedence {
                descriptionNew = "(" + descriptionNew + ")"
            }
            return descriptionFunction ( descriptionOperand, secondOperand)
        }
        
        func validate(with secondOperand:Double) -> String? {
            guard let valid = validator else { return nil }
            return valid(firstOperand,secondOperand)
        }
    }
    
    mutating func undo() {
        if !internalProgram.isEmpty {
            internalProgram = Array(internalProgram.dropLast())
        }
    }
    mutating func clear() {
        internalProgram.removeAll()
    }
    @available(iOS, deprecated, message: "No longer needed")
    var description: String? {
        get {
            return evauate().description
        }
    }
    @available(iOS, deprecated, message: "No longer needed")
    var result: Double? {
        get {
            return evauate().result
        }
    }
    @available(iOS, deprecated, message: "No longer needed")
    var resultIsPending: Bool {
        get {
            return evauate().isPending
        }
    }
}

    let formatter:NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.notANumberSymbol = "Error"
        formatter.groupingSeparator = " "
        formatter.locale = Locale.current
        return formatter
        
    } ()

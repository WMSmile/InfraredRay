//
//  Signal.swift
//  InfraredRay
//
//  Created by apple on 2018/1/23.
//  Copyright © 2018年 wumeng. All rights reserved.
//

import UIKit

class Signal: NSObject {
    var signal:Int32?
    var isSignal:Bool?
    override init() {
        super.init();
    }
    
    convenience init(_ signal:Int32 ,isSignal:Bool) {
        self.init();
        self.signal = signal;
        self.isSignal = isSignal
        
    }
    
    
    

}

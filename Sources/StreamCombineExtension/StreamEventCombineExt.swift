//
//  OutputStreamCombineExt.swift
//
//
//  Created by Sébastien Luneau on 19/11/2020.
//  Copyright © 2020 Sébastien Luneau. All rights reserved.
//


import Foundation
public enum  StreamEvent {
    case openCompleted
    case endEncountered
    case dataSent
    case dataReceived
    case errorOccurred
} 

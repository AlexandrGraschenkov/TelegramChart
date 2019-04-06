//
//  Lock.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 06/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import Foundation

internal final class Mutex {
    private var mutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()
    
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
}

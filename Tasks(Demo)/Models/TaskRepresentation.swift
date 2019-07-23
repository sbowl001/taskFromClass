//
//  TaskRepresentation.swift
//  Tasks(Demo)
//
//  Created by Stephanie Bowles on 7/16/19.
//

import Foundation

struct TaskRepresentation: Codable {
    var name: String
    var notes: String?
    var priority: String
    var identifier: String 
}

//
//  TaskController.swift
//  Tasks(Demo)
//
//  Created by Stephanie Bowles on 7/16/19.
//

import Foundation
import CoreData
let baseURL = URL(string: "https://tasks-3f211.firebaseio.com/")!

class TaskController {
    
    typealias CompletionHandler = (Error?)  -> Void
    
    
    init() {
        fetchTasksFromServer()
    }
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in}) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching tasks: \(error)" )
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("no data returned by data task")
                completion(NSError())
                return
            }
            
            do {
                let taskRepresentations = Array(try JSONDecoder().decode([String: TaskRepresentation].self, from: data).values)
                let moc = CoreDataStack.shared.container.newBackgroundContext()
                try self.updateTasks(with: taskRepresentations, context: moc )
                completion(nil)
            } catch {
                NSLog("Error decoding task representations: \(error)")
                completion(error)
                return
                
                
            }
        } .resume()
    }
    
    private func updateTasks(with representations: [TaskRepresentation], context: NSManagedObjectContext)  throws {
        var error: Error? = nil
        
        context.performAndWait {
            
            for taskRep in representations {
                guard let uuid = UUID(uuidString: taskRep.identifier) else {continue}
                
                let task = self.task(forUUID: uuid, in: context)
                
                if let task = task {
                    self.update(task: task, with: taskRep)
                } else {
                    let _ = Task(taskRepresentation: taskRep)
                }
                
            }
            do {
                try context.save()
                
            } catch let saveError{
                error = saveError
            }
        }
        if let error = error {throw error}
    }
    //GEt task from UUID
    
    private func task(forUUID uuid: UUID, in context: NSManagedObjectContext) -> Task? {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", uuid as NSUUID)
        
        var result: Task? = nil
        context.performAndWait {
            do {
               result = try context.fetch(fetchRequest).first
            } catch {
                NSLog("Error fetching task with uuid \(uuid):  \(error)")
            }
        }
        return result
//        do{
//            let moc = CoreDataStack.shared.mainContext
//            return try moc.fetch(fetchRequest).first
//        } catch {
//            NSLog("Error fetching task with uuid \(uuid) : \(error)")
//            return nil
//        }
    }
    //Update Task with Task Representation from Server
    private func update(task: Task, with representation: TaskRepresentation) {
        task.name = representation.name
        task.notes = representation.notes
        task.priority = representation.priority
    }
    
    
    // PUT request
    func put(task: Task, completion: @escaping CompletionHandler = { _ in }){
        let uuid = task.identifier ?? UUID()
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            guard var representation = task.taskRepresentation else {
                completion(NSError())
                return
            }
            representation.identifier = uuid.uuidString
            task.identifier = uuid
            try saveToPersistentStore()
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("error encoding task: \(task) \(error)")
            completion(error)
            return
            
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error putting task to server: \(error)")
                completion(error)
                return
            }
            completion(nil)
        }.resume()
    }
    
    
    func saveToPersistentStore() throws {
        let moc = CoreDataStack.shared.mainContext
        try moc.save()
    }
    
    func deleteTaskFromServer(_ task: Task, completion: @escaping CompletionHandler = {_ in }) {
        guard let uuid = task.identifier else {
            completion(NSError())
            return
        }
        
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, response, error)  in
            print(response!)
            completion(error)
        } .resume()
    }
}

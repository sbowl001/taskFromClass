//
//  TasksTableViewController.swift
//  Tasks(Demo)
//
//  Created by Johnny Hicks on 7/9/19.
//  Copyright © 2019 Johnny Hicks. All rights reserved.
//

import UIKit
import CoreData

class TasksTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    
    
    
    // MARK: - Properties
    lazy var fetchedResultsController: NSFetchedResultsController<Task> = {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true),
                                        NSSortDescriptor(key: "name", ascending: true)]
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "priority", cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    private let taskController = TaskController()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    
    //IBActions
    @IBAction func refreshControl(_ sender: Any) {
        self.taskController.fetchTasksFromServer { (_) in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        
        let task = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = task.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return nil }
        return sectionInfo.name.capitalized
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = self.fetchedResultsController.object(at: indexPath)
            
            taskController.deleteTaskFromServer(task) { (error) in
                if let error = error {
                    NSLog("Error deleting task from server: \(error)")
                    return
                }
                let moc = CoreDataStack.shared.mainContext
                moc.performAndWait {
                    
                    moc.delete(task)
                    do {
                        try moc.save()
                        self.tableView.reloadData()
                    } catch {
                        moc.reset()
                        NSLog("Error saving managed object context: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case.delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            return
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editTaskSegue",
            let detailView = segue.destination as? TasksDetailViewController,
            let indexPath = self.tableView.indexPathForSelectedRow {
            let task = self.fetchedResultsController.object(at: indexPath)
            detailView.task = task
            detailView.taskController = self.taskController
        }
        
        if segue.identifier == "CreateTaskSegue",
            let detailView = segue.destination as? TasksDetailViewController   {
            detailView.taskController = self.taskController 
        }
    }
}

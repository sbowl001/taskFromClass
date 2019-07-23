//
//  TasksDetailViewController.swift
//  Tasks(Demo)
//
//  Created by Johnny Hicks on 7/9/19.
//  Copyright © 2019 Johnny Hicks. All rights reserved.
//

import UIKit

class TasksDetailViewController: UIViewController, UITextFieldDelegate {
    // MARK: - Outlets and Properties
    var task: Task? {
        didSet {
            self.updateViews()
        }
    }
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var noteTextView: UITextView!
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet var prioritySegementedControl: UISegmentedControl!
    
    
    var taskController: TaskController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateViews()
        self.nameTextField.delegate = self
        self.nameTextField.addTarget(self, action: #selector(toggleSaveButton), for: .editingChanged)
    }
    
    @IBAction func saveTask(_ sender: Any) {
        guard let taskName = self.nameTextField.text,
            !taskName.isEmpty else { return }
        
        let priorityIndex = prioritySegementedControl.selectedSegmentIndex
        let priority = TaskPriority.allCases[priorityIndex]
        let notes = self.noteTextView.text
        
        if let task = task {
            // Editing existing task
            task.name = taskName
            task.priority = priority.rawValue
            task.notes = notes
            taskController.put(task: task)
        } else {
            let task = Task(name: taskName, notes: notes, priority: priority)
            taskController.put(task: task)
        }
        
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    private func updateViews() {
        guard isViewLoaded else { return }
        
        let priority: TaskPriority
        if let taskPriority = task?.priority {
            priority = TaskPriority(rawValue: taskPriority)!
        } else {
            priority = .normal
        }
        
        prioritySegementedControl.selectedSegmentIndex = TaskPriority.allCases.firstIndex(of: priority)!
        
        self.title = self.task?.name ?? "Create Task"
        self.nameTextField.text = task?.name
        self.noteTextView.text = task?.notes
        toggleSaveButton()
    }
    
    @objc private func toggleSaveButton() {
        self.saveBarButtonItem.isEnabled = !self.nameTextField.text!.isEmpty
    }
}

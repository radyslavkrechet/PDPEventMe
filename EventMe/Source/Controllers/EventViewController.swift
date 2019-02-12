//
//  EventViewController.swift
//  EventMe
//
//  Created by Radislav Crechet on 6/21/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import UIKit
import EventKit

class EventViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var allDaySwitch: UISwitch!
    @IBOutlet var startsDateTextField: UITextField!
    @IBOutlet var endsDateTextField: UITextField!

    var event: EKEvent!
    
    private var startsDatePicker: UIDatePicker!
    private var endsDatePicker: UIDatePicker!
    
    private var dates: (starts: Date, ends: Date) {
        let calendar = Calendar.current
        
        let date = calendar.date(byAdding: .hour, value: 1, to: Date())!
        let startsDate = calendar.date(byAdding: .minute, value: -calendar.component(.minute, from: date), to: date)!
        let endsDate = calendar.date(byAdding: .hour, value: 1, to: startsDate)!
        
        return (startsDate, endsDate)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUserInterface()
    }
    
    // MARK: - Configuration
    
    private func configureUserInterface() {
        startsDatePicker = UIDatePicker()
        startsDatePicker.addTarget(self, action: #selector(startsDatePickerValueDidChange), for: .valueChanged)
        startsDateTextField.inputView = startsDatePicker
        
        endsDatePicker = UIDatePicker()
        endsDatePicker.addTarget(self, action: #selector(endsDatePickerValueDidChange), for: .valueChanged)
        endsDateTextField.inputView = endsDatePicker
        
        if let event = event {
            titleTextField.text = event.title
            allDaySwitch.isOn = event.isAllDay
            
            startsDatePicker.date = event.startDate
            endsDatePicker.date = event.endDate
            
            updateDateTextField(startsDateTextField, withDate: event.startDate)
            updateDateTextField(endsDateTextField, withDate: event.endDate)
        } else {
            setDefaultDates()
            createEvent()
        }
    }
    
    private func setDefaultDates() {
        let dates = self.dates
        startsDatePicker.date = dates.starts
        endsDatePicker.date = dates.ends
        
        updateDateTextField(startsDateTextField, withDate: dates.starts)
        updateDateTextField(endsDateTextField, withDate: dates.ends)
    }
    
    private func updateDateTextField(_ textField: UITextField, withDate date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        textField.text = dateFormatter.string(from: date)
    }

    private func createEvent() {
        event = EventManager.shared.createEvent()
        event.startDate = startsDatePicker.date
        event.endDate = endsDatePicker.date
    }

    private func changeEvent(title: String) {
        event.title = title
    }

    private func changeEvent(isAllDay: Bool) {
        event.isAllDay = isAllDay
    }

    private func changeEvent(startDate: Date) {
        event.startDate = startDate
    }

    private func changeEvent(endDate: Date) {
        event.endDate = endDate
    }

    private func saveEvent() {
        EventManager.shared.saveEvent(event)
    }
    
    // MARK: - Actions
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        saveEvent()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func allDaySwitchValueDidChange(_ sender: UISwitch) {
        changeEvent(isAllDay: sender.isOn)
        
        if !sender.isOn {
            setDefaultDates()
            changeEvent(startDate: startsDatePicker.date)
            changeEvent(endDate: endsDatePicker.date)
        }
        
        doneButton.isEnabled = event.hasChanges && !titleTextField.text!.isEmpty
    }
    
    @objc func startsDatePickerValueDidChange() {
        let date = startsDatePicker.date
        updateDateTextField(startsDateTextField, withDate: date)
        changeEvent(startDate: date)
        
        doneButton.isEnabled = event.hasChanges && !titleTextField.text!.isEmpty
    }
    
    @objc func endsDatePickerValueDidChange() {
        let date = endsDatePicker.date
        updateDateTextField(endsDateTextField, withDate: date)
        changeEvent(endDate: date)
        
        doneButton.isEnabled = event.hasChanges && !titleTextField.text!.isEmpty
    }

    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == titleTextField {
            changeEvent(title: textField.text!)
            doneButton.isEnabled = event.hasChanges && !textField.text!.isEmpty
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

//
//  A simple iBeacon Detector App. Scans for Beacons based on their UUID.
//
//
//  Created by Tobias Wirth
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UITextFieldDelegate {
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cellIdentifier"
    
    let locationManager = CLLocationManager()
    
    var uuid: UUID!
    
    var region:CLRegion!
    
    var major:CLBeaconMajorValue = 0
    var minor:CLBeaconMinorValue = 0
    
    var constraint:CLBeaconIdentityConstraint!
    
    var tableViewSections = [beaconSection]()
    
    @IBOutlet weak var BeaconLabel: UILabel!
    @IBOutlet weak var scanSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var uuidTextfield: UITextField!
    @IBOutlet weak var uuidErrorLabel: UILabel!
    @IBAction func SwitchAction(_ sender: Any) {
        
        if scanSwitch.isOn{
            startBeaconScanning()
            
        } else{
            stopBeaconScanning()
        }
        
    }
    

    class beaconSection {
        
        let uuid: String
        var beaconAttributes: [String]
        var isOpened:Bool = false
        
        init(uuid: String,
             attributes: [String],
             isOpened: Bool = false){
            
            self.uuid = uuid
            self.beaconAttributes = attributes
            self.isOpened = isOpened
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
      
        locationManager.delegate = self
        
        if(locationManager.authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse){
            locationManager.requestWhenInUseAuthorization()
        }
        
        uuid = UUID(uuidString: "A3421560-A148-A2AB-F178-022A12A279CD")
        
        major = 123
        minor = 456
        
        constraint = CLBeaconIdentityConstraint(uuid: uuid!, major: major, minor: minor)
        
        region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "MyBeacon")
        
        
        uuidTextfield.delegate = self
        
        uuidTextfield.text = uuid?.uuidString
        
       // Scan for Beacons SwitchUI
        scanSwitch.setOn(false, animated: false)
        
        // hide not valid uuid error message
        uuidErrorLabel.isHidden = true
                
                
    }
    
    // Start scanning for iBeacons
    func startBeaconScanning() {
        
        tableViewSections = [beaconSection]()
        
        constraint = CLBeaconIdentityConstraint(uuid: uuid!, major: major, minor: minor)
        
        region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "MyBeacon")
        
        self.locationManager.startMonitoring(for: region)
        self.locationManager.startRangingBeacons(satisfying: constraint)
    
        }
    
    // Stop scanning for iBeacons
    func stopBeaconScanning() {

          self.locationManager.stopMonitoring(for: region)
          self.locationManager.stopRangingBeacons(satisfying: constraint)
        
          tableViewSections.removeAll()
          tableView.reloadData()

      }
    
    // avoid hidden text field by keyboard
    func textFieldDidBeginEditing(_ textField: UITextField) {
                
        view.frame.origin.y = -250
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
       
        view.frame.origin.y = 0
    }
    
    // Check if user entered a valid UUID
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let textFieldString = textField.text
        
        if !((textFieldString?.isEmpty)!) {
        
            let range = NSRange(location: 0, length: (textFieldString?.utf16.count)!)
            
            // check if text field contains valid uuid
            let regex = try! NSRegularExpression(pattern: "[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12}")
            
            if regex.firstMatch(in: textFieldString!, options: [], range: range) != nil {
                
                uuid = UUID(uuidString: textFieldString!)
                
                uuidErrorLabel.isHidden = true
                
                // clear table first
                stopBeaconScanning()
                
                startBeaconScanning()
                
            }
            else{
                print("not a valid uuid")
                uuidErrorLabel.isHidden = false
            }
        }
          
        return true
    }
    
    
    // Build TableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) else {
                return UITableViewCell()
            }
            
            cell.textLabel?.text = tableViewSections[indexPath.section].uuid
            
            
            return cell
            
        } else{
            // Use different cellIdentifier if needed
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) else {
                return UITableViewCell()
            }
            
            cell.textLabel?.text = tableViewSections[indexPath.section].beaconAttributes[indexPath.row - 1]
            
            return cell
        }
    }
    
     
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !tableViewSections.isEmpty {
            // open or close table sections
            if indexPath.row == 0 {
                if tableViewSections[indexPath.section].isOpened == true {
                    tableViewSections[indexPath.section].isOpened = false
                    
                    let sectionsSet = IndexSet.init(integer: indexPath.section)
                    
                    tableView.reloadSections(sectionsSet, with: .none)
                    
                    
                } else {
                    tableViewSections[indexPath.section].isOpened = true
                    
                    let sectionsSet = IndexSet.init(integer: indexPath.section)
                    
                    tableView.reloadSections(sectionsSet, with: .none)
                }
            } else {
                print("tapped a sub cell")
            }
        
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewSections.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableViewSections[section].isOpened == true {
            return tableViewSections[section].beaconAttributes.count + 1
        } else {
            return 1
        }
        
    }
    
    // look for iBeacons by UUID and note their proximity, major and minor value
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        print(beacons)
        
        var beaconsToBeAdded: [beaconSection] = []
        
        for beacon in beacons {
            
            let uuid = beacon.uuid.uuidString
            
            var proximity = "distance unknown"
                        
            if beacon.proximity == CLProximity.far {
                proximity = "far"
            } else if beacon.proximity == CLProximity.near {
                proximity = "near"
            } else if beacon.proximity == CLProximity.immediate {
                proximity = "immediate"
            }
            
            let major = "Major: " + beacon.major.description
            let minor = "Minor: " + beacon.minor.description
            
            let foundBeacon = beaconSection(uuid: uuid, attributes: [proximity, major, minor])
            
            beaconsToBeAdded.append(foundBeacon)
            
        }
        
        
        if !tableViewSections.isEmpty && !beaconsToBeAdded.isEmpty {
            
            for i in 0 ... tableViewSections.count-1 {
                
                for j in 0 ... beaconsToBeAdded.count-1 {
                    
                    if beaconsToBeAdded[j].uuid == tableViewSections[i].uuid {
                        

                        // remove already present beacon
                        if  beaconsToBeAdded[j].beaconAttributes == tableViewSections[j].beaconAttributes
                            {
                            
                            beaconsToBeAdded.remove(at: j)
                            
                            
                        } else {
                            // update already present beacon
                            tableViewSections[i].beaconAttributes = beaconsToBeAdded[j].beaconAttributes
                            beaconsToBeAdded.remove(at: j)
                            
                        }
            
                        }
                    }
                }
            
            }
        
 
        tableViewSections.append(contentsOf: beaconsToBeAdded)
                
        self.tableView.reloadData()
        
        }


    // Check authorization status
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    
                }
            }
        }
    }
    
}



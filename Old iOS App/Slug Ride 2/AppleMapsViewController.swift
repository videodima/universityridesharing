//
//  AppleMapsViewController.swift
//  Slug Ride 2
//
//Copyright © 2015 Thorn Technologies. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation
import Foundation

protocol HandleMapSearch: class {
    func dropPinZoomIn(_ placemark:MKPlacemark)
}

class customPin: MKPointAnnotation {
    var pinColor: UIColor?
}


class AppleMapsViewController: UIViewController {
    
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!
    
    let locationManager = CLLocationManager()
    var myRoute :MKRoute = MKRoute()
    var destinationArray : [CLLocationCoordinate2D] = []
    var annotationArray : [customPin] = []
    var updateAnnotationArray : [customPin] = []
    @IBOutlet weak var mapView: MKMapView!
    
    var start = false
    var curr = 1
    var madefar = false
    let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        //Load up the Current Location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        //Set up the Naviation Bar
        let backButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.backButtonAction(_:)))
        self.navigationItem.leftBarButtonItem = backButton
    
        //Search Bar Code
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        

    }
    

    //////////////////////////////////
    //Used to go back to the main page
    //////////////////////////////////
    func backButtonAction(_ button: UIBarButtonItem) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        
        //Animation Code
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        
        present(newViewController, animated: false, completion: nil)
        
    }
    
    //////////////////////////////////
    //Used to get directions from the user location to the pin
    //////////////////////////////////
    func getDirections(){
        guard let selectedPin = selectedPin else { return }
        let directionsRequest = MKDirectionsRequest()
        let markSource = MKPlacemark(coordinate: CLLocationCoordinate2DMake((locationManager.location?.coordinate.latitude)!, (locationManager.location?.coordinate.longitude)!), addressDictionary: nil)
        
        let markDestination = MKPlacemark(coordinate: CLLocationCoordinate2DMake(selectedPin.coordinate.latitude, selectedPin.coordinate.longitude), addressDictionary: nil)
        
        self.destinationArray.append(CLLocationCoordinate2DMake(selectedPin.coordinate.latitude, selectedPin.coordinate.longitude))
        
        //let mapItem = MKMapItem(placemark: selectedPin)
        //let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        //mapItem.openInMaps(launchOptions: launchOptions)
        directionsRequest.source = MKMapItem(placemark: markSource)
        directionsRequest.destination = MKMapItem(placemark: markDestination)
        
        directionsRequest.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: directionsRequest)
        
        directions.calculate(completionHandler: {
            
            response, error in
            
            if error == nil {
                
                self.myRoute = response!.routes[0] as MKRoute
                
                self.mapView.add(self.myRoute.polyline)
                
            }
        })
        //
        startRide()
        locationManager.startUpdatingLocation()
    }
    
    //////////////////////////////////
    //Starts the ride and sends info to the server
    //////////////////////////////////
    func startRide() {
        guard let selectedPin = selectedPin else { return }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let dict = ["user_email":appDelegate.user_email,
                    "location_latitude": (locationManager.location?.coordinate.latitude)! ,
                    "location_longitude":(locationManager.location?.coordinate.longitude)!,
                    "destination_latitude": selectedPin.coordinate.latitude ,
                    "destination_longitude":selectedPin.coordinate.longitude,
                    "driver_status":appDelegate.driver_status] as [String: Any]
        print(dict)
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted){
            print("success")
            //SUBJECT TO URL CHANGE!!!!!
            let url = NSURL(string: "http://138.68.252.198:8000/rideshare/post_ride/")!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "POST"
            request.setValue("Token \(appDelegate.token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest){
                data, response, error in
                if let httpResponse = response as? HTTPURLResponse{
                    print(httpResponse.statusCode)
                    if(httpResponse.statusCode != 200){
                        print("error")
                        return
                    }
                }
                print("success1")
                guard error == nil else{
                    print(error!)
                    return
                }
                print("success2")
                guard data != nil else{
                    print("data is empty")
                    return
                }
                print("success3")
                //let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                //print(json)
                DispatchQueue.main.async(execute: self.postDone)
            }
            task.resume()
        }
    }
    
    var timer = Timer()
    
    //////////////////////////////////
    //Process after the function is done
    //////////////////////////////////
    func postDone() {
        navigationItem.titleView = nil
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.driver_status == false) {
            let QRButton = UIBarButtonItem(title: "QR Code Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.scanInModalAction(_:)))
            self.navigationItem.leftBarButtonItem = QRButton
        } else {
            let QRButton = UIBarButtonItem(title: "Display QR Code", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.QRDisplay(_:)))
            self.navigationItem.leftBarButtonItem = QRButton
        }

        
        
        let backButton2 = UIBarButtonItem(title: "End Ride", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.endRideButtonAction(_:)))
        self.navigationItem.rightBarButtonItem = backButton2
        
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.pollforUsers(_:)), userInfo: nil, repeats: false)
    }
    
    
    //////////////////////////////
    //User Poll for polling for new users in the area
    //////////////////////////////
    func pollforUsers(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let dict = ["user_email":appDelegate.user_email,
                    "location_latitude": (locationManager.location?.coordinate.latitude)! ,
                    "location_longitude":(locationManager.location?.coordinate.longitude)!,
                    "destination_longitude":self.destinationArray[0].longitude,
                    "destination_latitude":self.destinationArray[0].latitude,
                    "driver_status":appDelegate.driver_status] as [String: Any]
        print(dict)
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted){
            //print("success")
            //SUBJECT TO URL CHANGE!!!!!
            let url = NSURL(string: "http://138.68.252.198:8000/rideshare/query_ride/")!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "POST"
            request.setValue("Token \(appDelegate.token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest){
                data, response, error in
                if let httpResponse = response as? HTTPURLResponse{
                    print(httpResponse.statusCode)
                    if(httpResponse.statusCode != 200){
                        print("error")
                        return
                    }
                }
                //print("success1")
                guard error == nil else{
                    print(error!)
                    return
                }
                //print("success2")
                guard let data = data else {
                    print("Data Empty")
                    return
                }
                //print("success3")
                let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                //print(json)
                
                //Clears previous markers
                self.updateAnnotationArray.removeAll()
                let userss = json["user_list"] as? [[String: Any]]
                for user in userss! {
                    if user["user_email"] as! String != appDelegate.user_email {
                        let annotation = customPin()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: user["location_latitude"] as! Double,
                                                                       longitude: user["location_longitude"] as! Double)
                        annotation.title = user["user_email"] as? String
                        if (user["driver_status"] as! Bool == true) {
                            annotation.pinColor = .green
                        } else {
                            annotation.pinColor = .purple
                        }
                        
                        //marker.snippet = "Destination: \(user["destination_longitude"] as! Double)"
                        self.updateAnnotationArray.append(annotation)
                    }
                    
                }
                
                
                DispatchQueue.main.async(execute: self.updateInfo)
                //DispatchQueue.main.async(execute: self.postDone)
            }
            task.resume()
        }
        
    }
    
    func updateInfo() {
        //updates new markers
        //print("check")
        var region = mapView.region
        region.center = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!,
                                               longitude: (locationManager.location?.coordinate.longitude)!)
        mapView.setRegion(region, animated: true)
        mapView.removeAnnotations(annotationArray)
        annotationArray.removeAll()
        mapView.addAnnotations(updateAnnotationArray)
        for annotation in updateAnnotationArray {
            annotationArray.append(annotation)
        }
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.pollforUsers(_:)), userInfo: nil, repeats: false)
        self.updateAnnotationArray.removeAll()
    }
    
    //////////////////////////////
    //QR Code Generator Stuff
    //////////////////////////////
    @IBOutlet weak var QRCode: UIImageView!
    func QRDisplay(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let image = generateQrImage(from: appDelegate.user_email)
        self.QRCode.image = image
        
        if(self.QRCode.isHidden == false) {
            let QRButton = UIBarButtonItem(title: "Display QR Code", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.QRDisplay(_:)))
            self.navigationItem.leftBarButtonItem = QRButton
            self.QRCode.isHidden = true
        } else {
            let QRButton = UIBarButtonItem(title: "Hide QR Code", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AppleMapsViewController.QRDisplay(_:)))
            self.navigationItem.leftBarButtonItem = QRButton
            self.QRCode.isHidden = false
        }
    }
    
    //////////////////////////////
    //QR Code Generator Stuff
    //////////////////////////////
    func generateQrImage(from text: String) -> UIImage?{
        let data = text.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator"){
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y:3)
            if let output = filter.outputImage?.applying(transform){
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    //////////////////////////////
    //QR Code Reader Stuff
    //////////////////////////////
    @IBOutlet weak var previewView: UIView!
    lazy var reader: QRCodeReader = QRCodeReader()
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode], captureDevicePosition: .back)
            $0.showTorchButton = true
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    // MARK: - Actions
    
    private func checkScanPermissions() -> Bool {
        do {
            return try QRCodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController?
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)
                
                alert?.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.openURL(settingsURL)
                        }
                    }
                }))
                
                alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            case -11814:
                alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
                alert?.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            default:
                alert = nil
            }
            
            guard let vc = alert else { return false }
            
            present(vc, animated: true, completion: nil)
            
            return false
        }
    }
    
    func scanInModalAction(_ sender: AnyObject) {
        guard checkScanPermissions() else { return }
        
        readerVC.modalPresentationStyle = .formSheet
        readerVC.delegate               = self as? QRCodeReaderViewControllerDelegate
        
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            if let result = result {
                print("Completion with result: \(result.value) of type \(result.metadataType)")
            }
        }
        
        present(readerVC, animated: true, completion: nil)
    }
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true) { [weak self] in
            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let dict = ["user_email":appDelegate.user_email,"driver_email":result.value] as [String: Any]
            print(dict)
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted){
                print("success")
                let url = NSURL(string: "http://138.68.252.198:8000/rideshare/scan_qr_code/")!
                let request = NSMutableURLRequest(url: url as URL)
                request.httpMethod = "POST"
                request.setValue("Token \(appDelegate.token)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request as URLRequest){
                    data, response, error in
                    if let httpResponse = response as? HTTPURLResponse{
                        print(httpResponse.statusCode)
                        if(httpResponse.statusCode != 200){
                            print("error")
                            return
                        }
                    }
                    print("success1")
                    guard error == nil else{
                        print(error!)
                        return
                    }
                    print("success2")
                    guard let data = data else {
                        print("Data Empty")
                        return
                    }
                    print("success3")
                    let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                    print(json)
                    appDelegate.point_count = (json["user_points"] as? Int)!
                    let approveCheck = json["approved"] as? Bool
                    if (approveCheck == true) {
                        let alert = UIAlertController(
                            title: "Driver Approved",
                            message: String (format:"Enjoy your ride"),
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        
                        self?.present(alert, animated: true, completion: nil)
                        if self?.timer != nil {
                            self?.timer.invalidate()
                        }
                        //self?.coins.text = "\(appDelegate.point_count)"
                    } else {
                        let alert = UIAlertController(
                            title: "Driver Not Approved",
                            message: String (format:"Ride not approved please try again or wait for another driver"),
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        
                        self?.present(alert, animated: true, completion: nil)
                    }
                    //DispatchQueue.main.async(execute: self.postDone)
                    
                }
                task.resume()
            }
            
            //This is where I should add the code to get the QR Code Scanner working.
            
        }
    }
    
    func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
        if let cameraName = newCaptureDevice.device.localizedName {
            print("Switching capturing to: \(cameraName)")
        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }

    ////////////////////////////////
    //Poly LIne Rendering
    ////////////////////////////////
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) ->MKOverlayRenderer {
        
        let myLineRenderer = MKPolylineRenderer(polyline: myRoute.polyline)
        
        myLineRenderer.strokeColor = UIColor.red
        
        myLineRenderer.lineWidth = 3
        
        print(myRoute.steps)
        self.navigationItem.title = self.myRoute.steps[0].instructions
        return myLineRenderer
    }
    
    ////////////////////////////
    //End Ride FUnctions
    ////////////////////////////
    func endRideButtonAction(_ button: UIBarButtonItem) {
        if self.timer != nil {
            self.timer.invalidate()
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let dict = ["user_email":appDelegate.user_email] as [String: Any]
        print(dict)
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted){
            print("success")
            let url = NSURL(string: "http://138.68.252.198:8000/rideshare/end_ride/")!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "POST"
            request.setValue("Token \(appDelegate.token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest){
                data, response, error in
                if let httpResponse = response as? HTTPURLResponse{
                    print(httpResponse.statusCode)
                    if(httpResponse.statusCode != 200){
                        print("error")
                        return
                    }
                }
                print("success1")
                guard error == nil else{
                    print(error!)
                    return
                }
                print("success2")
                guard let data = data else {
                    print("Data Empty")
                    return
                }
                print("success3")
                let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                print(json)
                appDelegate.ratingList.removeAll()
                let userss = json["user_emails"] as? [String]
                var count = 0
                for user in userss! {
                    count = 1
                    appDelegate.ratingList.append(user)
                }
                print (count)
                print(appDelegate.ratingList)
                if count != 0 {
                    DispatchQueue.main.async(execute: self.gotoRating)
                } else {
                    DispatchQueue.main.async(execute: self.gotoMenu)
                }
            }
            task.resume()
        }
        
        
    }
    
    func gotoRating() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "userRatingViewController") as! userRatingViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotoMenu() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        self.present(newViewController, animated: true, completion: nil)
    }
    
}

extension AppleMapsViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        
        if self.start == false {
            let span:MKCoordinateSpan = MKCoordinateSpanMake(0.05, 0.05)
            let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            mapView.setRegion(region, animated: true)
            self.start = true
        }
        
        print(location.altitude)
        print(location.speed)
        
        self.mapView.showsUserLocation = true
        ////////////
        //Code for updating route
        ////////////
        // Updating current instruction
        if self.myRoute.steps.count > self.curr {
            print("Check")
            // Getting the coordinates in the polyline
            let poly = self.myRoute.steps[self.curr].polyline
            var coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: poly.pointCount)
            poly.getCoordinates(coordsPointer, range: NSMakeRange(0, poly.pointCount))
            var coords: [CLLocationCoordinate2D] = []
            for i in 0..<poly.pointCount {
                coords.append(coordsPointer[i])
            }
            coordsPointer.deallocate(capacity: poly.pointCount)
            
            // Getting the end point of the step
            let point = coords[0]
            let location2 = CLLocation(latitude: point.latitude, longitude: point.longitude)
            
            // If the current location is less than 50 meters from the end of the route step, announce the instruction
            if  Int((location.distance(from: location2))) < 50 {
                if (madefar) {
                    let utterance = AVSpeechUtterance(string: navigationItem.title!)
                    utterance.rate = 0.5
                    self.synthesizer.speak(utterance)
                    self.madefar  = false
                }
            }
            // If the current location is now more than 50 meters away from the last step
            else if (!madefar) {
                
                // Converting the distance from meters to feet
                var distance=Int(self.myRoute.steps[self.curr].distance * 3.28)
                
                // Declaring the utterance for the next step
                var utterance = AVSpeechUtterance()
                
                // Setting the utterance based on how far the next step is (using miles, fractinos of miles, or feet)
                // and rounding that distance
                if distance > 5280 {
                    distance = distance / 528
                    let newDistance = Double(distance)/10.0
                    utterance = AVSpeechUtterance(string: "In " + String(newDistance) + " miles, " + self.myRoute.steps[self.curr].instructions )
                } else if distance > 528 {
                    distance = (distance / 528)
                    utterance = AVSpeechUtterance(string: "In point " + String(distance) + " miles, " + self.myRoute.steps[self.curr].instructions)
                    
                } else if distance > 100 {
                    distance = (distance / 100) * 100
                    utterance = AVSpeechUtterance(string:  "In " + String(distance) + " feet, " + self.myRoute.steps[self.curr].instructions)
                } else {
                    utterance = AVSpeechUtterance(string: "In " + String(distance) + " feet, " + self.myRoute.steps[self.curr].instructions)
                }
                
                // Speaking the next step
                utterance.rate = 0.5
                self.synthesizer.speak(utterance)
                self.navigationItem.title = self.myRoute.steps[self.curr].instructions
                
                // Updating to the next step
                self.madefar = true
                curr+=1
            }
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
    
}

extension AppleMapsViewController: HandleMapSearch {
    
    func dropPinZoomIn(_ placemark: MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        annotation.subtitle = "Press Car to Begin Ride"

        
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}

extension AppleMapsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        //print("Check1")
        if let pin = annotation as? customPin {
            guard !(annotation is MKUserLocation) else { return nil }
            let reuseId = "pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            pinView?.pinTintColor = pin.pinColor
            pinView?.canShowCallout = true
            
            let leftIconView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 53, height: 53))
            leftIconView.image = UIImage(named: "mapspin.png")
            pinView?.leftCalloutAccessoryView = leftIconView
            return pinView
        } else {
            guard !(annotation is MKUserLocation) else { return nil }
            let reuseId = "pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            pinView?.pinTintColor = UIColor.orange
            pinView?.canShowCallout = true
            let smallSquare = CGSize(width: 30, height: 30)
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "car"), for: UIControlState())
            button.addTarget(self, action: #selector(AppleMapsViewController.getDirections), for: .touchUpInside)
            pinView?.rightCalloutAccessoryView = button
            
            return pinView
        }

    }
}

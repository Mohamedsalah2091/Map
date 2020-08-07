//
//  ViewController.swift
//  Map
//
//  Created by MAK on 8/5/20.
//  Copyright © 2020 MAK. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CustomPin : NSObject, MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    init(pinTitle : String ,pinSubtitle: String , location : CLLocationCoordinate2D  ) {
        self.coordinate = location
        self.title = pinTitle
        self.subtitle = pinSubtitle
    }
}


class ViewController: UIViewController , CLLocationManagerDelegate , MKMapViewDelegate {
    
    @IBOutlet weak var startTextField: UITextField!
    @IBOutlet weak var endTextField: UITextField!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var textLabelOnMap: UILabel!
    
    var oldrootes = [MKRoute]()
    var pins = [CustomPin]()
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var doneButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationServices()
        doneButton.layer.cornerRadius = 15
        
    }
    
    
    func checkLocationServices(){
        if  CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            map.delegate = self
        }else{
            print("please open Location Services")
        }
    }
    
    @IBAction func chooseStart(_ sender: Any) {
        getAdress()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
    }
    
    
    func getAdress(){
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(startTextField.text!) { (placemarks, error) in
            guard let placemarks = placemarks , let locationOne = placemarks.first?.location else{
                print("Error in getAdress One")
                return
            }
            
            geoCoder.geocodeAddressString(self.endTextField.text!) { (placemarks, error) in
                guard let placemarks = placemarks , let locationTwo = placemarks.first?.location else{
                    print("Error in getAdress Two")
                    return
                }
                
                self.mapthis(startCoord: locationOne.coordinate , endCoord: locationTwo.coordinate)
            }
            
            
        }
    }
    
    
    func mapthis(startCoord : CLLocationCoordinate2D  , endCoord : CLLocationCoordinate2D ){
        
        let startPlaceMark = MKPlacemark(coordinate: startCoord)
        let endPlaceMark = MKPlacemark(coordinate: endCoord)
        
        let startItem = MKMapItem(placemark: startPlaceMark)
        let endItem = MKMapItem(placemark: endPlaceMark)
        
        let destinationRequset = MKDirections.Request()
        destinationRequset.source = startItem
        destinationRequset.destination = endItem
        destinationRequset.transportType = .automobile
        destinationRequset.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: destinationRequset)
        directions.calculate { (response, error) in
            guard let response = response else{
                print(error?.localizedDescription)
                return
            }
            
            let route = response.routes[0]
            self.removeOldRoute()
            self.removeOldPins()
            self.addNewRoute(route: route)
            self.addNewPins(startCoord: startCoord, endCoord: endCoord)
            
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline )
        render.strokeColor = .blue
        return render
    }
    
    
    
    
    func addNewRoute(route : MKRoute){
        map.addOverlay(route.polyline)
        map.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        oldrootes.append(route)
        
    }
    func addNewPins(startCoord : CLLocationCoordinate2D  , endCoord : CLLocationCoordinate2D ){
        var pin = CustomPin(pinTitle: self.startTextField.text!, pinSubtitle: "Start", location: startCoord )
        map.addAnnotation(pin)
        pins.append(pin)
        pin = CustomPin(pinTitle: self.endTextField.text!, pinSubtitle: "End", location: endCoord )
        pins.append(pin)
        map.addAnnotation(pin)
    }
    func removeOldRoute(){
        if oldrootes.count > 0{
            map.removeOverlay(self.oldrootes[0].polyline)
            oldrootes.removeAll()
        }
    }
    func removeOldPins(){
        if pins.count > 0{
            map.removeAnnotation(self.pins[0])
            map.removeAnnotation(self.pins[1])
            pins.removeAll()
        }
    }
    
    @IBAction func gestureRecog(_ sender: UIGestureRecognizer) {
        
        if sender.state == .ended{
            let locationInView = sender.location(in: map)
            let tappedCoordinate = map.convert(locationInView, toCoordinateFrom: map)
            geocode(lat: tappedCoordinate.latitude, lng: tappedCoordinate.longitude)
        }
    }
    func geocode( lat : Double , lng : Double ){
        let location = CLLocation(latitude: lat, longitude: lng)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            self.getPressedPlaceOnMap(withPlacemarks: placemarks, error: error)
        }
    }
    
    
    
    
    private func getPressedPlaceOnMap(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        if let placemarks = placemarks, let placemark = placemarks.first {
            textLabelOnMap.text = placemark.compactAddress
        } else {
            textLabelOnMap.text  = "No Matching Addresses Found"
        }
    }
    
    
    @IBAction func copyButton(_ sender: Any) {
        UIPasteboard.general.string = textLabelOnMap.text
    }
    
    
    
    
    
    
}


extension CLPlacemark {
    
    var compactAddress: String? {
        if let name = name {
            var result = ""
            
            if let city = locality {
                result += "\(city)"
            }
            if let street = thoroughfare {
                if result != ""{result += ", \(street)"}
                else {result += "\(street)"}
                
            }
            
            return result
        }
        
        return nil
    }
    
}


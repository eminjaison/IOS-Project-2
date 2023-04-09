//
//  ViewController.swift
//  iOS-Project-2-Emin
//
//  Created by Emin Jaison on 2023-04-08.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate {
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    private var locations: [Locations] = []
    var location = ""
    var feelslike = 0.0
    var temperature = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //table View
        loadList()
        tableView.dataSource = self
        locationManger.delegate = self
        locationManger.requestWhenInUseAuthorization()
        locationManger.requestLocation()
    }
    
    private
    let locationManger = CLLocationManager()
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "Map"
        
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as?
            MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        }else{
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: 0.0, y: 10.0)
            
            let button = UIButton(type: .detailDisclosure)
            view.rightCalloutAccessoryView = button
            button.tag = 10
            
            let image = UIImage(systemName: "cloud")
            view.leftCalloutAccessoryView = UIImageView(image: image)
            view.tintColor = UIColor.blue
        
             if let myAnnotation = annotation as? MyAnnotation{
                 view.markerTintColor = myAnnotation.color
                 view.glyphText = myAnnotation.glyphText
             }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control.tag == 10){
            performSegue(withIdentifier: "onDetailScreen", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "onDetailScreen" {
            guard let seague = segue.destination as? DetailsViewController else { return }
            seague.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        // get the longitude and latitude of the current location
        let locValue: CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")

        // get the current location
        let currentLocation = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        
        // get the current location name
        CLGeocoder().reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            if let placemark = placemarks?[0] {
                print(placemark)
                let locality = placemark.locality
                self.loadWeather(search: locality)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error Occured", error)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationTable", for: indexPath)
        let location = locations[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = location.title
        content.secondaryText = location.subtitle
        content.image = location.icon
        
        
        cell.contentConfiguration = content
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.loadWeather(search: "\(self.locations[indexPath.row].title)")
    }

    // loadList
    private func loadList(){
        
    }
    
    func setupMap(location: CLLocation){
        
        // set delegate
        mapView.delegate = self
        
        // user location
        mapView.showsUserLocation = true
        
        // visualising the current location into the map
        let location = location
        let radiusInMeters: CLLocationDistance = 1000

        let region = MKCoordinateRegion(center: location.coordinate,
            latitudinalMeters: radiusInMeters,
            longitudinalMeters: radiusInMeters)
        mapView.setRegion(region, animated: true)
        let cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(cameraBoundary, animated: true)

        // control zooming
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 100000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
    }
    
    
    
    func colorForTemperature(temperature: Double) -> UIColor {
        if(temperature < 0) {
            return UIColor.purple
        } else if(temperature >= 0 && temperature <= 11) {
            return UIColor.blue
        } else if(temperature > 11 && temperature <= 16 ) {
            return UIColor.systemBlue
        } else if(temperature > 16 && temperature <= 24 ) {
            return UIColor.yellow
        } else if(temperature > 24 && temperature <= 30 ) {
            return UIColor.orange
        } else {
            return UIColor.red
        }
    }
    
    func addLocation(location: String){
        locations.append(Locations(title: location,
                                   subtitle: "Sunny",
                                   icon: UIImage(systemName: "sun.max")))
        // loadWeather of the location
        loadWeather(search: location)
        tableView.reloadData()
        self.location = location
    }
    
    class MyAnnotation: NSObject, MKAnnotation{
        var coordinate: CLLocationCoordinate2D
        var title: String?
        var subtitle: String?
        var glyphText: String?
        var color: UIColor?
        
        init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, glyphText: String?, color: UIColor?) {
            self.coordinate = coordinate
            self.title = title
            self.subtitle = subtitle
            self.glyphText = glyphText
            self.color = color
            super.init()
        }
    }
    
    private func loadWeather(search: String?){
       guard let search = search else{
           return
       }
       
       // 1. Get Url
       guard let url = getUrl(searchFor: search) else{
           print("Could not get URL")
           return
       }
       
       // 2. Create url session
       let urlSession = URLSession.shared
       
       // 3. Create a task for the URL session
       let dataTask = urlSession.dataTask(with: url) {data, response, error in
           // network call completed
           print("Network Call completed")
           
           guard error == nil else{
               print(error!)
               return
           }

           guard let data = data else{
               print("not data received")
               return
           }

           if let weatherResponse = self.parseJson(data: data){
               
               DispatchQueue.main.async { [self] in
                   let annontation = MyAnnotation(coordinate: CLLocationCoordinate2D(latitude: weatherResponse.location.lat, longitude: weatherResponse.location.lon),
                                                  title: weatherResponse.current.condition.text,
                                                  subtitle: "\(weatherResponse.current.temp_c)C",
                                                  glyphText: "\(weatherResponse.current.temp_c)C",
                                                  color: colorForTemperature(temperature: Double(weatherResponse.current.temp_c)))
                   print(weatherResponse.location.name, weatherResponse.current.condition.text, colorForTemperature(temperature: Double(weatherResponse.current.temp_c)))
                   self.mapView.addAnnotation(annontation)
                   self.setupMap(location: CLLocation(latitude: weatherResponse.location.lat, longitude: weatherResponse.location.lon))
               }

           }
       }
       dataTask.resume()
   }
    
    // get URL start
    func getUrl(searchFor: String) -> URL?{
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "b6cf89ae823047ff855163826231903"
        let locationParam = "q=\(searchFor)"

        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&\(locationParam)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{
            return nil
        }
       return URL(string: url)
    }
    
    private func parseJson(data: Data) -> WeatherResponse?{
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        }catch {
            print("Error Decoding..")
        }
        
        return weather
    }
    
    struct WeatherResponse: Decodable{
        var location: Location
        let current: Weather
    }

    struct Location: Decodable{
        let name: String
        let lat: Double
        let lon: Double
    }

    struct Weather: Decodable{
        let temp_c: Float
        let condition: WeatherCondition
    }

    struct WeatherCondition: Decodable{
        let text: String
        let code: Int
    }
}

struct Locations{
    let title: String
    let subtitle: String
    let icon: UIImage?
}



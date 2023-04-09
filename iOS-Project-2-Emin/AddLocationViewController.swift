//
//  AddLocationViewController.swift
//  iOS-Project-2-Emin
//
//  Created by Emin Jaison on 2023-04-08.
//

import UIKit

class AddLocationViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    var code: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.endEditing(true)
            print(textField.text ?? "")
            loadWeather(search: searchTextField.text)
            return true
        }
    
    
    @IBAction func searchButton(_ sender: Any) {
        
        loadWeather(search: searchTextField.text)
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
        if let delegate = self.presentingViewController as? ViewController {
            delegate.addLocation(location: locationLabel.text!)
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    
    private func loadWeather(search: String?){
            guard let search = search else{
                return
            }
            
            guard let url = getURL(query: search) else {
                print("Could not get URL")
                return
            }
            
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: url) {data, response, error in
                print("Network call complete")
                
                guard error == nil else{
                    print("Recieved Error")
                    return
                }
                guard let data = data else{
                    print("No data found")
                    return
                }
                
                if let weatherResponse = self.parseJson(data: data){
                    print(weatherResponse.location.name)
                    print(weatherResponse.current.temp_c)
                    DispatchQueue.main.async { [self] in
                        
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_c)C"
                        self.locationLabel.text = weatherResponse.location.name
                        self.conditionLabel.text = weatherResponse.current.condition.text
                        self.code = weatherResponse.current.condition.code
                        self.displaySampleImageForDemo(code: self.code)
                        
                    }
                }
            }
            
            dataTask.resume()
        }
        
        private func getURL(query: String) -> URL? {
            let baseUrl = "https://api.weatherapi.com/v1/"
            let currentEndpoint = "current.json"
            let apiKey = "b6cf89ae823047ff855163826231903"
            guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            
            return URL(string: url)
        }
        
        private func parseJson(data: Data) -> WeatherResponse? {
            let decoder = JSONDecoder()
            var weather: WeatherResponse?
            do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
            } catch {
                print("Error decoding")
            }
            
            return weather
        }
        
        private func displaySampleImageForDemo(code: Int){
            let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .systemBlue])
            
            self.weatherConditionImage.preferredSymbolConfiguration = config
            
            switch code{
            case 1000:
                self.weatherConditionImage.image = UIImage(systemName: "sun.max.fill")
                break
            case 1003:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.sun.fill")
                break
            case 1006:
                self.weatherConditionImage.image = UIImage(systemName: "smoke")
                break
            case 1009:
                self.weatherConditionImage.image = UIImage(systemName: "sun.min")
                break
            case 1030:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.fog")
                break
            case 1063:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.sun.rain")
                break
            case 1066:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.snow")
                break
            case 1069:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.sleet")
                break
            case 1072:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.drizzle")
                break
            case 1087:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.bolt")
                break
            case 1114:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.hail")
                break
            case 1117:
                self.weatherConditionImage.image = UIImage(systemName: "tornado")
                break
            case 1183:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.sun.rain")
                break
            case 1195:
                self.weatherConditionImage.image = UIImage(systemName: "cloud.bolt.rain")
                break
            case 1213:
                self.weatherConditionImage.image = UIImage(systemName: "snowflake")
                break
            case 1225:
                self.weatherConditionImage.image = UIImage(systemName: "snowflake.circle")
                break
            default:
              break
            }
            
        }
        
    }

    struct WeatherResponse: Decodable{
        let location: Location
        let current: Weather
    }

    struct Location: Decodable{
        let name: String
    }

    struct Weather: Decodable{
        let temp_c: Float
        let temp_f: Float
        let condition: WeatherCondition
    }
    struct WeatherCondition: Decodable{
        let text: String
        let code: Int
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */



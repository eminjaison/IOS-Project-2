//
//  DetailsViewController.swift
//  iOS-Project-2-Emin
//
//  Created by Emin Jaison on 2023-04-08.
//

import UIKit

class DetailsViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    var location = ""
    
    var dayList: [weekDay] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadWeather(search: location)
        
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "forecast", for: indexPath)
        let item = dayList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.image = item.icon
        content.text = item.day
        content.secondaryText = "\(item.max) \(item.min)"
        content.prefersSideBySideTextAndSecondaryText = true
        cell.contentConfiguration = content
        return cell
    }

    func getDayOfWeek(_ today:String) -> String? {
            let formatter  = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let todayDate = formatter.date(from: today) {
                let myCalendar = Calendar(identifier: .gregorian)
                let weekDay = myCalendar.component(.weekday, from: todayDate)
                print("weekDay: \(weekDay)")
                switch weekDay {
                case 1:
                    return "Sunday"
                case 2:
                    return "Monday"
                case 3:
                    return "Tuesday"
                case 4:
                    return "Wednesday"
                case 5:
                    return "Thursday"
                case 6:
                    return "Friday"
                case 7:
                    return "Saturday"
                default:
                    print("Error fetching days")
                    return nil
                }
            } else {
                return nil
            }
        }
        
        func weatherImage(code: Int) -> UIImage{
            // images according to the weather response code
           
            if (code == 1006){
                return UIImage(systemName: "cloud")!
            }else if(code == 1000){
                return UIImage(systemName: "sun.max")!
            }else if(code == 1003){
                return UIImage(systemName: "cloud.sun")!
            }else if(code == 1009){
                return UIImage(systemName: "cloud.sun.rain")!
            }else if(code == 1063 || code == 1153 || code == 1183){
                return UIImage(systemName: "cloud.rain")!
            }else if(code == 1030 || code == 1135){
                return UIImage(systemName: "cloud.fog")!
            }else if(code == 1066){
                return UIImage(systemName: "cloud.snow")!
            }else if(code == 1114){
                return UIImage(systemName: "wind.snow")!
            }else if(code == 1195 || code == 1201){
                return UIImage(systemName: "cloud.bolt.rain")!
            }else{
                return UIImage(systemName: "cloud")!
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
                
                // to overcome the threading issue
                DispatchQueue.main.async { [self] in
                    temperatureLabel.text = "\(weatherResponse.current.temp_c)C"
                    conditionLabel.text = weatherResponse.current.condition.text
                    locationLabel.text = weatherResponse.location.name
                    highLabel.text = "H: \(weatherResponse.forecast.forecastday[0].day.maxtemp_c)°C"
                    lowLabel.text = "L: \(weatherResponse.forecast.forecastday[0].day.mintemp_c)°C"
                    
                    
                    var i = 0
                    while i < 3 {
                        let day = getDayOfWeek(weatherResponse.forecast.forecastday[i].date)
                        let max = "H: \(weatherResponse.forecast.forecastday[i].day.maxtemp_c)°C"
                        let min = "L: \(weatherResponse.forecast.forecastday[i].day.mintemp_c)°C"
                        let image = weatherImage(code: weatherResponse.forecast.forecastday[i].day.condition.code)
                        
                        let dayItem = weekDay(day: day!, max: max, min: min, icon: image)
                        dayList.append(dayItem)
                        tableView.reloadData()
                        i += 1
                    }
                }
            }
        }
        
        // 4. Stop the task
        dataTask.resume()
    }
    
    func getUrl(searchFor: String) -> URL?{
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "forecast.json"
        let apiKey = "b6cf89ae823047ff855163826231903"
        let locationParam = "q=\(searchFor)"

        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&days=3&\(locationParam)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{
            return nil
        }
        print(url)
        
       return URL(string: url)
    }
    
    
    // decoding the API
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
    
    // structung accroding to the api
    struct WeatherResponse: Decodable{
        var location: Location
        let current: Weather
        let forecast: Forecast
    }

    struct Location: Decodable{
        let name: String
    }

    struct Weather: Decodable{
        let temp_c: Float
        let condition: WeatherCondition
    }

    struct WeatherCondition: Decodable{
        let text: String
        let code: Int
    }

    struct Forecast: Codable{
        let forecastday: [Forecastday]

    }

    struct Forecastday: Codable{
        let date: String
        let day: Day
    }
    
    struct Day: Codable{
        let maxtemp_c: Float
        let mintemp_c: Float
        let condition: ForecastConditon
    }
    
    struct ForecastConditon: Codable{
        let code: Int
    }
    
    
    struct weekDay{
        let day: String
        let max: String
        let min: String
        let icon: UIImage
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

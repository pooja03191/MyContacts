import Foundation

class APICallService {
    
    func fetchCountryNames(completionHandler: @escaping ([String]?, Error?) -> Void) {
        makeServiceCall() { (data, error) -> Void in
            if error != nil {
                completionHandler(nil, error)
            } else {
                completionHandler(data, nil)
            }
        }
//        var response = [String]()
//        makeServiceCall() { (data, error) -> Void in
//            if error != nil {
//                print(error.debugDescription)
//            } else {
//                if let jsonData = data {
//                    response = jsonData
//                }
//            }
//        }
//        return response
    }
    
    private func parseJSONResponse(json: [[String:Any]]) -> [String] {
        var jsonString = [String]()
        
        for data in json {
               if let shortName = data["alpha2Code"],
                let name = data["name"] {
                jsonString.append("\(name) \(shortName)")
            }
        }
        return jsonString
    }
    
    private func makeServiceCall(completionHandler: @escaping ([String]?, Error?) -> Void) {
        let url = URL(string: "https://restcountries.eu/rest/v1/all")
        var jsonString = [String]()
        let task = URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            if error != nil {
                completionHandler(nil, error)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as! [[String:Any]]
                jsonString = self.parseJSONResponse(json: json)
                completionHandler(jsonString, nil)
                return
            } catch let error as NSError {
                print(error)
            }
        })
        task.resume()
    }
}

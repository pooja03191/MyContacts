import UIKit
import CoreData

class AddContactViewController: UIViewController {

    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var firstNameTextfield: UITextField!
    @IBOutlet weak var lastNameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    @IBOutlet weak var countryTextfield: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var imagePicker = UIImagePickerController()
    var pickerView = UIPickerView()
    var countries = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set delegate for imagePicker
        imagePicker.delegate = self
        
        // Set delegate and datasource for pickerView
        pickerView.dataSource = self
        pickerView.delegate = self
        
        // Pickerview will be activated on countryTextfield tap
        countryTextfield.inputView = pickerView
        
        // For validation purpose
        emailTextfield.delegate = self
        phoneTextfield.delegate = self
        
        // Caliing API
        let apiServiceCall = APICallService()
        apiServiceCall.fetchCountryNames() { (data, error) -> Void in
            if error != nil {
                print(error.debugDescription)
            } else {
                if let response = data {
                    self.countries = response
                }
            }
        }
        
        contactImage.setUp()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pickerViewWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pickerViewWillHide(notification:)), name: .UIKeyboardWillShow, object: nil)
    }
    
    @IBAction func addNewContact(_ sender: Any) {
        
        guard let firstName = firstNameTextfield.text,
            let lastName = lastNameTextfield.text,
            let email = emailTextfield.text,
            let country = countryTextfield.text,
            let phoneText = phoneTextfield.text,
            let image = contactImage.image else {
                return
        }
        saveContact(firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone: Int(phoneText)!,
                    country: country,
                    image: image)
    }
    
    @IBAction func changeContactImage(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func saveContact(firstName: String,
                     lastName: String,
                     email: String,
                     phone: Int,
                     country: String,
                     image: UIImage) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Contact", in: managedObjectContext)!
        let contact = NSManagedObject(entity: entity, insertInto: managedObjectContext)
        
        contact.setValue(firstName, forKey: "firstName")
        contact.setValue(lastName, forKey: "lastName")
        contact.setValue(email, forKey: "email")
        contact.setValue(phone, forKey: "phone")
        contact.setValue(country, forKey: "country")
        
        let imageData: NSData = UIImagePNGRepresentation(image)! as NSData
        
        contact.setValue(imageData, forKey: "image")
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Could not save data \(error.description)")
        }
    }
    
    @objc func pickerViewWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= 150
    }
    
    @objc func pickerViewWillHide(notification: NSNotification) {
        self.view.frame.origin.y += 150
    }
    
    func validateEmailAndPhone() {
        guard let emailText = emailTextfield.text,
            let phoneText = phoneTextfield.text else {
                return
        }
        
        if !isValidEmail(email: emailText) || !isValidPhone(phone: phoneText) {
            let alertController = UIAlertController(title: "Email Validation Alert",
                                                message: "Email or phone data not valid",
                                                preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func isValidPhone(phone: String) -> Bool {
        let phoneRegex = "^[0-9]{6,14}$";
        let valid = NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
        return valid
    }
    
    func isValidEmail(email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        var valid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
        if valid {
            valid = !email.contains("..")
        }
        return valid
    }
}

extension AddContactViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            contactImage.contentMode = .scaleAspectFit
            contactImage.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
    }
}

extension AddContactViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countries[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        countryTextfield.text = countries[row]
        countryTextfield.resignFirstResponder()
    }
}

extension AddContactViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var alertController: UIAlertController
        
        if textField == emailTextfield {
            if let emailText = textField.text,
                let isTextfieldEmpty = textField.text?.isEmpty,
                !isValidEmail(email: emailText),
                !isTextfieldEmpty {
                alertController = UIAlertController(title: "Email Validation Alert",
                                                    message: "Email not valid",
                                                    preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: { action in
                    self.clearTextfield(textfield: textField)
                })
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
            }
            
        } else if textField == phoneTextfield {
            if let phoneText = textField.text,
                let isTextfieldEmpty = textField.text?.isEmpty,
                !isValidPhone(phone: phoneText),
                !isTextfieldEmpty {
                alertController = UIAlertController(title: "Phone number Validation Alert",
                                                    message: "Email not valid",
                                                    preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: {action in
                    self.clearTextfield(textfield: textField)
                })
                alertController.addAction(alertAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func clearTextfield(textfield: UITextField) {
        textfield.text = ""
        textfield.becomeFirstResponder()
    }
}

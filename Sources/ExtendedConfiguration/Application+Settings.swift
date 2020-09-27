import Vapor

extension Application {
    public var settings: Settings {
        .init(application: self)
    }

    public struct Settings {
        let application: Application

        public enum SettingsEnvironmentVariablesFiltr {
            case all
            case withPrefix(_ prefix: String)
        }
        
        public enum SettingsItem {
            case jsonFile(_ file: String, optional: Bool)
            case environmentVariables(_ filtr: SettingsEnvironmentVariablesFiltr)
        }
        
        public enum SettingsError: Error {
            case fileNotExists
            case jsonFormat
        }
        
        public struct Configuration {
            public var items: [String: Any] = [:]
            
            public mutating func appendOrReplace(key: String, value: Any) {
                self.items[key] = value
            }
        }
                
        struct SettingsKey: StorageKey {
            typealias Value = Configuration
        }

        public func load(_ settingItems: [SettingsItem]) throws {
            for settingItem in settingItems {
                try load(settingItem)
            }
        }
        
        private func load(_ settingItem: SettingsItem) throws {
            
            switch settingItem {
            case .jsonFile(let fileName, optional: let optional):
                guard let fileHandle = FileHandle(forReadingAtPath: fileName) else {
                    if optional == false {
                        throw SettingsError.fileNotExists
                    }
                    
                    return
                }
                
                let fileData = fileHandle.readDataToEndOfFile()
                guard let jsonObject = try JSONSerialization.jsonObject(with: fileData, options: []) as? [String: Any] else {
                    if optional == false {
                        throw SettingsError.jsonFormat
                    }
                    
                    return
                }
                
                jsonObject.forEach { (key: String, value: Any) in
                    self.append(jsonKey: key, jsonValue: value)
                }
                
                break
            case .environmentVariables(let filtr):
                
                switch filtr {
                case .withPrefix(let prefix):
                    ProcessInfo.processInfo.environment.forEach { (key: String, value: String) in
                        if key.starts(with: prefix) {
                            self.configuration.appendOrReplace(key: key, value: value)
                        }
                    }
                default:
                    ProcessInfo.processInfo.environment.forEach { (key: String, value: String) in
                        self.configuration.appendOrReplace(key: key, value: value)
                    }
                }
           
                break
            }
        }
        
        private func append(jsonKey: String, jsonValue: Any) {
            if let jsonObject = jsonValue as? [String: Any] {
                jsonObject.forEach { (key: String, value: Any) in
                    self.append(jsonKey: jsonKey + "." + key, jsonValue: value)
                }
            } else {
                self.configuration.appendOrReplace(key: jsonKey, value: jsonValue)
            }
        }
        
        public func getString(for key: String) -> String? {
            return self.configuration.items[key] as? String
        }

        public func getString(for key: String, withDefault defaultValue: String) -> String {
            if let value = self.configuration.items[key] as? String {
                return value
            }
            
            return defaultValue
        }
        
        public func getInt(for key: String) -> Int? {
            let value = self.configuration.items[key]
            if let value = value as? Int {
                return value
            }
                        
            if let stringValue = value as? String, let value = Int(stringValue) {
                return value
            }
            
            return nil
        }
        
        public func getInt(for key: String, withDefault defaultValue: Int) -> Int {
            let value = self.configuration.items[key]
            if let value = value as? Int {
                return value
            }
            
            if let stringValue = value as? String, let value = Int(stringValue) {
                return value
            }
            
            return defaultValue
        }
        
        public var configuration: Configuration {
            get {
                self.application.storage[SettingsKey.self] ?? .init()
            }
            nonmutating set {
                self.application.storage[SettingsKey.self] = newValue
            }
        }
    }
}

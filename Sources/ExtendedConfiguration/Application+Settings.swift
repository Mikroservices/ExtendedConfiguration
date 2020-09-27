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
            internal var items: [String: Any] = [:]
                        
            public subscript(index: String) -> Any? {
                self.items[index]
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
                    self.set(value, forKey: key)
                }
                
                break
            case .environmentVariables(let filtr):
                
                switch filtr {
                case .withPrefix(let prefix):
                    ProcessInfo.processInfo.environment.forEach { (key: String, value: String) in
                        if key.starts(with: prefix) {
                            self.configuration.items[key] = value
                        }
                    }
                default:
                    ProcessInfo.processInfo.environment.forEach { (key: String, value: String) in
                        self.configuration.items[key] = value
                    }
                }
           
                break
            }
        }

        public func set(_ setting: Any, forKey jsonKey: String) {
            if let jsonObject = setting as? [String: Any] {
                jsonObject.forEach { (key: String, value: Any) in
                    self.set(value, forKey: jsonKey + "." + key)
                }
            } else {
                self.configuration.items[jsonKey] = setting
            }
        }
        
        public func set<T>(_ setting: Any, for type: T.Type) {
            let key = String(describing: T.self)
            self.set(setting, forKey: key)
        }

        public func get<T>(_ type: T.Type) -> T? {
            let key = String(describing: T.self)
            return self.get(type, for: key)
        }
        
        public func get<T>(_ type: T.Type, for key: String) -> T? {
            return self.configuration.items[key] as? T
        }

        public func get<T>(_ type: T.Type, for key: String, withDefault defaultValue: T) -> T? {
            if let value = self.configuration.items[key] as? T {
                return value
            }
            
            return defaultValue
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

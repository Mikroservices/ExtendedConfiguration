import XCTest
import XCTVapor
@testable import ExtendedConfiguration

final class ExtendedConfigurationTests: XCTestCase {
    func testConfigurationShouldLoadCorrectSettings() throws {
        // Arrange.
        try createSettingsFile(fileName: "appsettings.json")
        try createSettingsFileForTestting(fileName: "appsettings.testing.json")
        Environment.process[dynamicMember: "env.key03"] = "System environment"
        Environment.process[dynamicMember: "env.key04"] = 999
        let app = Application(.testing)
        defer { app.shutdown() }

        // Act.
        try app.settings.load([
            .jsonFile("appsettings.json", optional: false),
            .jsonFile("appsettings.\(app.environment.name).json", optional: true),
            .environmentVariables(.withPrefix("env"))
        ])
        
        // Assert.
        XCTAssertEqual("altStringValue01", app.settings.getString(for: "key01"))
        XCTAssertEqual(456, app.settings.getInt(for: "key02"))
        XCTAssertEqual("altStringValue03", app.settings.getString(for: "group01.key03"))
        XCTAssertEqual(666, app.settings.getInt(for: "group01.key04"))
        XCTAssertEqual("stringValue03", app.settings.getString(for: "group02.key03"))
        XCTAssertEqual(321, app.settings.getInt(for: "group02.key04"))
        XCTAssertEqual("System environment", app.settings.getString(for: "env.key03"))
        XCTAssertEqual(999, app.settings.getInt(for: "env.key04"))
    }
    
    func testConfigurationShouldThrowExceptionWhenRequiredFileNotExists() throws {
        // Arrange.
        let app = Application(.testing)
        defer { app.shutdown() }

        // Act.
        XCTAssertThrowsError(try app.settings.load([.jsonFile("appsettings-not-exists.json", optional: false)])) { error in
            XCTAssertEqual(error as! Application.Settings.SettingsError, Application.Settings.SettingsError.fileNotExists)
        }
    }
    
    func testConfigurationShouldNotThrowExceptionWhenOptionsFileNotExists() throws {
        // Arrange.
        try createSettingsFile(fileName: "configuration.json")
        let app = Application(.testing)
        defer { app.shutdown() }

        // Act.
        try app.settings.load([
            .jsonFile("configuration.json", optional: false),
            .jsonFile("configuration.\(app.environment.name).json", optional: true),
            .environmentVariables(.withPrefix("env"))
        ])
        
        // Assert.
        XCTAssertEqual("stringValue01", app.settings.getString(for: "key01"))
        XCTAssertEqual(123, app.settings.getInt(for: "key02"))
        XCTAssertEqual("stringValue03", app.settings.getString(for: "group01.key03"))
        XCTAssertEqual(321, app.settings.getInt(for: "group01.key04"))
        XCTAssertEqual("stringValue03", app.settings.getString(for: "group02.key03"))
        XCTAssertEqual(321, app.settings.getInt(for: "group02.key04"))
    }
    
    func testCustomConfigurationShouldBeReturnedForKey() throws {
        // Arrange.
        try createSettingsFile(fileName: "configuration.json")
        let app = Application(.testing)
        defer { app.shutdown() }

        // Act.
        app.settings.set(AppModel(name: "name01", version: "1.0.0"), forKey: "customkey")
        let appModel = app.settings.get(AppModel.self, for: "customkey")
        
        // Assert.
        XCTAssertEqual("name01", appModel?.name)
        XCTAssertEqual("1.0.0", appModel?.version)
    }
    
    func testCustomConfigurationShouldBeReturnedForType() throws {
        // Arrange.
        try createSettingsFile(fileName: "configuration.json")
        let app = Application(.testing)
        defer { app.shutdown() }

        // Act.
        app.settings.set(AppModel(name: "name02", version: "2.0.0"), for: AppModel.self)
        let appModel = app.settings.get(AppModel.self)
        
        // Assert.
        XCTAssertEqual("name02", appModel?.name)
        XCTAssertEqual("2.0.0", appModel?.version)
    }
        
    private func createSettingsFile(fileName: String) throws {
        let content = """
        {
            "key01": "stringValue01",
            "key02": 123,
            "group01": {
                "key03": "stringValue03",
                "key04": 321
            },
            "group02": {
                "key03": "stringValue03",
                "key04": 321
            },
            "env": {
                "key03": "stringValue03",
                "key04": 321
            }
        }
        """
        
        let filePath: URL = URL(fileURLWithPath: fileName)
        let data = content.data(using: .utf8)!
        try data.write(to: filePath, options: .atomic)
    }
    
    private func createSettingsFileForTestting(fileName: String) throws {
        let content = """
        {
            "key01": "altStringValue01",
            "key02": 456,
            "group01": {
                "key03": "altStringValue03",
                "key04": 666
            }
        }
        """
        
        let filePath: URL = URL(fileURLWithPath: fileName)
        let data = content.data(using: .utf8)!
        try data.write(to: filePath, options: .atomic)
    }
}

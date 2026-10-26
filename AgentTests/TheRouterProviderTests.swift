import Testing
import Foundation
import AgentLLM
@testable import Agent_

// TheRouter.ai provider wiring — APIProvider identity, keychain/defaults keys,
// picker visibility, and the LLMProviderSetup config (endpoint, protocol, caps).

@MainActor
struct TheRouterProviderTests {

    @Test func rawValueRoundTrips() {
        #expect(APIProvider.theRouter.rawValue == "theRouter")
        #expect(APIProvider(rawValue: "theRouter") == .theRouter)
    }

    @Test func displayName() {
        #expect(APIProvider.theRouter.displayName == "TheRouter")
    }

    @Test func keychainAndDefaultsKeys() {
        #expect(APIProvider.theRouter.keychainAccount == "com.agent.therouter-api-key")
        #expect(APIProvider.theRouter.modelDefaultsKey == "theRouterModel")
        #expect(APIProvider.theRouter.temperatureDefaultsKey == "theRouterTemperature")
    }

    @Test func keychainAccountIsUnique() {
        let others = APIProvider.allCases.filter { $0 != .theRouter }.map(\.keychainAccount)
        #expect(!others.contains(APIProvider.theRouter.keychainAccount))
    }

    @Test func appearsInPicker() {
        #expect(APIProvider.selectableProviders.contains(.theRouter))
    }

    @Test func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(APIProvider.theRouter)
        #expect(try JSONDecoder().decode(APIProvider.self, from: data) == .theRouter)
    }

    @Test func setupConfig() {
        let config = LLMProviderSetup.config(for: .theRouter)
        #expect(config.id == "theRouter")
        #expect(config.displayName == "TheRouter")
        #expect(config.kind == .cloudAPI)
        #expect(config.apiProtocol == .openAI)
        #expect(config.contextSize == 200_000)
        #expect(config.apiKeyOptional == false)
        #expect(config.requiresAPIKey)
    }

    @Test func setupEndpoint() {
        let endpoint = LLMProviderSetup.config(for: .theRouter).endpoint
        #expect(endpoint.chatURL == "https://api.therouter.ai/v1/chat/completions")
        #expect(endpoint.modelsURL == "https://api.therouter.ai/v1/models")
        #expect(endpoint.authHeader == "Authorization")
        #expect(endpoint.authPrefix == "Bearer ")
        #expect(URL(string: endpoint.chatURL) != nil)
        #expect(URL(string: endpoint.modelsURL) != nil)
    }

    @Test func setupCapabilities() {
        let caps = LLMProviderSetup.config(for: .theRouter).capabilities
        #expect(caps.contains(.streaming))
        #expect(caps.contains(.tools))
        #expect(caps.contains(.vision))
        #expect(caps.contains(.systemPrompt))
    }

    @Test func registeredConfigMatchesSetup() {
        LLMProviderSetup.registerAllProviders()
        #expect(APIProvider.theRouter.apiProtocol == .openAI)
        #expect(APIProvider.theRouter.config.endpoint.chatURL == "https://api.therouter.ai/v1/chat/completions")
    }
}

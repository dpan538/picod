import Foundation

enum PetMood: String, CaseIterable, Codable {
    case calm
    case curious
    case happy
    case sleepy
    case cautious
}

enum PetEventType: String, Codable {
    case sawAnimal
    case foundWater
    case restedByTree
    case noticedObject
    case exploredMushroomPatch
    case wandered
    case tappedByUser
}

struct PetEvent: Hashable, Codable {
    let type: PetEventType
    let timestamp: Date
    let summary: String
    let sourceAnimal: AnimalKind?
    let sourceProp: PropKind?
    let sourcePlace: Landform?

    init(
        type: PetEventType,
        timestamp: Date = Date(),
        summary: String,
        sourceAnimal: AnimalKind? = nil,
        sourceProp: PropKind? = nil,
        sourcePlace: Landform? = nil
    ) {
        self.type = type
        self.timestamp = timestamp
        self.summary = summary
        self.sourceAnimal = sourceAnimal
        self.sourceProp = sourceProp
        self.sourcePlace = sourcePlace
    }
}

struct PetState: Codable {
    var mood: PetMood
    var energy: Int
    var curiosity: Int
    var comfort: Int

    var seenAnimalsToday: [AnimalKind]
    var seenPropsToday: [PropKind]
    var seenPlacesToday: [Landform]
    var recentEvents: [PetEvent]

    var lastInteraction: PetEvent?
    var currentStatusText: String

    static func initial(languageCode: String) -> PetState {
        PetState(
            mood: .calm,
            energy: 72,
            curiosity: 50,
            comfort: 55,
            seenAnimalsToday: [],
            seenPropsToday: [],
            seenPlacesToday: [],
            recentEvents: [],
            lastInteraction: nil,
            currentStatusText: languageCode == "zh"
                ? "我在草地上慢慢散步。"
                : "I am wandering quietly in the meadow."
        )
    }

    mutating func registerMovementStep(didMove: Bool) {
        if didMove {
            energy = clamp(energy - 1)
            curiosity = clamp(curiosity + 1)
            if energy < 28 {
                mood = .sleepy
            }
        } else {
            energy = clamp(energy + 1)
            comfort = clamp(comfort + 1)
            if comfort > 68 {
                mood = .calm
            }
        }
    }

    mutating func register(event: PetEvent) {
        lastInteraction = event
        currentStatusText = event.summary

        appendRecent(event)

        if let animal = event.sourceAnimal {
            appendUnique(animal, into: &seenAnimalsToday)
        }
        if let prop = event.sourceProp {
            appendUnique(prop, into: &seenPropsToday)
        }
        if let place = event.sourcePlace {
            appendUnique(place, into: &seenPlacesToday)
        }

        switch event.type {
        case .sawAnimal:
            curiosity = clamp(curiosity + 2)
            mood = .curious
        case .foundWater:
            comfort = clamp(comfort + 3)
            mood = .calm
        case .restedByTree:
            energy = clamp(energy + 3)
            comfort = clamp(comfort + 2)
            mood = .calm
        case .noticedObject:
            curiosity = clamp(curiosity + 1)
            mood = .curious
        case .exploredMushroomPatch:
            curiosity = clamp(curiosity + 2)
            mood = .curious
        case .wandered:
            energy = clamp(energy - 1)
            if energy < 25 {
                mood = .sleepy
            } else if comfort > 60 {
                mood = .happy
            }
        case .tappedByUser:
            comfort = clamp(comfort + 2)
            if mood != .sleepy {
                mood = .happy
            }
        }
    }

    private mutating func appendRecent(_ event: PetEvent) {
        recentEvents.append(event)
        if recentEvents.count > 20 {
            recentEvents.removeFirst(recentEvents.count - 20)
        }
    }

    private mutating func appendUnique<T: Equatable>(_ value: T, into array: inout [T]) {
        guard !array.contains(value) else { return }
        array.append(value)
    }

    private func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}

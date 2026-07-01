import Foundation

struct VisionLabel: Codable, Hashable {
    let identifier: String
    let confidence: Float
}

struct ClusterScore: Codable, Hashable {
    let formId: Int
    let clusterName: String
    let primaryScore: Float
    let hitCount: Int
    let matchedLabels: [String]
    let priorityWeight: Int
}

struct FormCluster: Codable, Hashable {
    let formId: Int
    let name: String
    let keywords: Set<String>
    let priorityWeight: Int
}

struct SpecialRuleCategory: Codable, Hashable {
    let key: String
    let keywords: Set<String>
    let fallbackFormIds: [Int]
}

enum MappingDatabase {
    static let confidenceThreshold: Float = 0.4
    static let spookyFallbackRange: ClosedRange<Int> = 21...35

    static let synonyms: [String: String] = [
        "tabby cat": "tabby",
        "lightning bug": "firefly",
        "grey wolf": "wolf",
        "gray wolf": "wolf",
        "paper lantern": "lantern",
        "flying fox": "bat",
        "will o wisp": "ghost fire",
        "will-o-wisp": "ghost fire",
        "white cloth": "cloth",
        "double exposure": "overlap",
        "street light": "streetlight",
        "record player": "gramophone",
        "photo camera": "camera",
        "book page": "book",
        "joss paper": "offering paper",
        "bank note": "banknote"
    ]

    static let specialCategories: [SpecialRuleCategory] = [
        .init(key: "human", keywords: ["person", "human", "face", "man", "woman", "boy", "girl", "body"], fallbackFormIds: [22, 28]),
        .init(key: "food", keywords: ["food", "meal", "dish", "fruit", "berry", "mushroom", "bread", "rice"], fallbackFormIds: [54, 51]),
        .init(key: "indoor", keywords: ["indoor", "interior", "room", "building", "house", "architecture", "furniture"], fallbackFormIds: [57, 62]),
        .init(key: "landscape", keywords: ["landscape", "sky", "mountain", "field", "horizon", "cloud"], fallbackFormIds: [55, 48]),
        .init(key: "text", keywords: ["text", "book", "letter", "document", "newspaper", "writing"], fallbackFormIds: [58, 23]),
        .init(key: "night", keywords: ["night", "dark", "moon", "lantern", "candle", "streetlight"], fallbackFormIds: [30, 41])
    ]

    static let clusters: [FormCluster] = makeClusters()

    static func normalize(_ raw: String) -> String {
        let lower = raw.lowercased()
        let separated = lower
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let scalar = separated.unicodeScalars.filter { CharacterSet.alphanumerics.union(.whitespaces).contains($0) }
        let compact = String(String.UnicodeScalarView(scalar))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return synonyms[compact] ?? compact
    }

    private static func makeClusters() -> [FormCluster] {
        [
            c(1, "狸猫", 90, ["cat", "kitten", "tabby", "persian cat", "maine coon", "raccoon", "tanuki", "red panda"]),
            c(2, "兔", 80, ["rabbit", "bunny", "hare", "cottontail"]),
            c(3, "鸟", 70, ["bird", "sparrow", "swallow", "pigeon", "crow", "parrot", "canary", "robin", "finch"]),
            c(4, "鱼", 68, ["fish", "goldfish", "koi", "carp", "salmon", "trout", "clownfish", "angelfish"]),
            c(5, "青蛙", 65, ["frog", "toad", "salamander", "newt", "amphibian"]),
            c(6, "猫头鹰", 72, ["owl", "eagle", "hawk", "falcon", "vulture", "raptor"]),
            c(7, "乌龟", 60, ["turtle", "tortoise", "snail", "shell", "terrapin"]),
            c(8, "蛇", 75, ["snake", "serpent", "eel", "worm", "centipede", "lizard", "gecko"]),
            c(9, "熊", 66, ["bear", "panda", "koala", "polar bear", "grizzly", "pig", "hippo", "boar"]),
            c(10, "狐", 74, ["fox", "wolf", "coyote", "jackal", "fennec"]),
            c(11, "鹿", 69, ["deer", "reindeer", "elk", "moose", "antelope", "stag", "fawn", "caribou"]),
            c(12, "蝙蝠", 62, ["bat", "pterodactyl"]),
            c(13, "水獭", 58, ["otter", "beaver", "mink", "muskrat", "platypus", "seal", "sea lion"]),
            c(14, "刺猬", 57, ["hedgehog", "porcupine", "echidna", "sea urchin", "pinecone", "chestnut"]),
            c(15, "螃蟹", 56, ["crab", "lobster", "shrimp", "crayfish", "scorpion", "spider"]),
            c(16, "章鱼", 61, ["octopus", "squid", "jellyfish", "nautilus", "starfish", "sea anemone"]),
            c(17, "萤火虫", 59, ["firefly", "glowworm", "fairy light", "sparkle", "lantern"]),
            c(18, "蚕", 52, ["caterpillar", "silkworm", "larva", "grub", "cocoon", "chrysalis"]),
            c(19, "鲸", 55, ["whale", "dolphin", "shark", "manatee", "dugong", "manta ray", "giant squid"]),
            c(20, "犬", 64, ["dog", "puppy", "labrador", "golden retriever", "shiba", "corgi", "husky", "dalmatian"]),
            c(21, "鬼魂", 85, ["smoke", "fog", "mist", "veil", "cloth", "curtain", "ghost", "translucent"]),
            c(22, "面具", 84, ["mask", "theatre mask", "carnival mask", "face paint", "helmet"]),
            c(23, "纸人", 83, ["paper", "origami", "newspaper", "tissue", "scroll", "parchment"]),
            c(24, "影", 83, ["shadow", "silhouette", "darkness", "black", "eclipse", "void", "outline"]),
            c(25, "雪女", 81, ["snow", "ice", "frost", "icicle", "blizzard", "white hair", "pale skin"]),
            c(26, "河童", 80, ["pond", "swamp", "lily pad", "lotus", "wetland", "marsh", "algae", "river bank"]),
            c(27, "天狗", 79, ["mountain", "cliff", "red leaves", "autumn", "tengu", "crow feather", "fan"]),
            c(28, "座敷童", 78, ["kimono", "yukata", "traditional clothing", "child room", "tatami", "doll"]),
            c(29, "轰隆", 78, ["thunder", "lightning", "storm cloud", "static", "electric", "plasma", "aurora"]),
            c(30, "提灯小僧", 82, ["lantern", "candle", "torch", "oil lamp", "festival light"]),
            c(31, "骨女", 76, ["bone", "skeleton", "fossil", "ivory", "coral", "dried wood", "bleached"]),
            c(32, "海坊主", 76, ["deep sea", "ocean", "dark water", "abyss", "kraken", "tide"]),
            c(33, "木灵", 77, ["tree hollow", "old tree", "forest", "ancient wood", "bark", "trunk", "gnarled"]),
            c(34, "泥田坊", 75, ["mud", "clay", "dirt", "soil", "one eye", "crack", "earth", "silt"]),
            c(35, "狂骨", 75, ["ruins", "broken", "torn fabric", "decay", "abandoned", "weathered", "old kimono"]),
            c(36, "僵尸", 74, ["talisman", "paper charm", "incense", "ritual", "yellow paper", "stamp", "seal"]),
            c(37, "狐仙", 74, ["multiple tails", "flowing fabric", "ethereal", "shrine", "nine tails", "spiritual"]),
            c(38, "山魈", 72, ["red face", "body hair", "primate", "ape", "monkey", "mountain creature"]),
            c(39, "夜叉", 72, ["weapon", "sword", "spear", "anger", "warrior", "blue", "fierce", "battle"]),
            c(40, "飞头", 71, ["floating head", "severed", "neck", "viscera", "organ", "entrails"]),
            c(41, "鬼火", 78, ["blue flame", "green fire", "ghost fire", "swamp gas", "phosphorescence"]),
            c(42, "纸钱鬼", 70, ["money", "coin", "banknote", "offering", "altar", "incense smoke", "offering paper"]),
            c(43, "蛊虫", 69, ["insect swarm", "ants", "flies", "beetles", "cluster", "hive", "colony", "infestation"]),
            c(44, "倒吊人", 71, ["upside down", "hanging", "rope", "chandelier", "stalactite", "inverted", "dangling"]),
            c(45, "影鬼", 74, ["mirror", "reflection", "glass", "echo", "duplicate", "copy", "symmetry"]),
            c(46, "苔藓人", 66, ["moss", "lichen", "wet stone", "damp", "green rock", "forest floor", "undergrowth"]),
            c(47, "树灵", 67, ["tree", "oak", "maple", "zelkova", "willow", "tree top", "canopy", "grove"]),
            c(48, "雨人", 68, ["rain", "drizzle", "puddle", "stream", "waterfall", "dew", "wet surface", "droplet"]),
            c(49, "雪人", 63, ["snowman", "snowball", "blizzard", "snowflake", "white mound", "powder snow"]),
            c(50, "藤蔓人", 66, ["vine", "ivy", "creeper", "tendril", "climbing plant", "overgrown", "entangled"]),
            c(51, "蘑菇", 64, ["mushroom", "fungus", "toadstool", "spore", "bracket fungus", "truffle", "mold"]),
            c(52, "樱花灵", 65, ["cherry blossom", "petal", "sakura", "plum blossom", "falling flower", "floral"]),
            c(53, "竹节人", 60, ["bamboo", "reed", "sugarcane", "stalk", "joint", "bamboo grove", "stem"]),
            c(54, "果实灵", 59, ["fruit", "berry", "apple", "persimmon", "grape", "seed pod", "gourd", "melon"]),
            c(55, "云团", 61, ["cloud", "cotton", "wool", "foam", "cumulus", "white fluffy", "pillow", "marshmallow"]),
            c(56, "灯泡头", 58, ["light bulb", "lamp", "led", "neon", "streetlight", "spotlight", "torch"]),
            c(57, "钟表", 57, ["clock", "watch", "sundial", "timer", "hourglass", "calendar", "dial", "gauge"]),
            c(58, "信封", 57, ["envelope", "letter", "postcard", "stamp", "mailbox", "parcel", "message", "note"]),
            c(59, "相机", 58, ["camera", "lens", "telescope", "binoculars", "viewfinder", "film", "photograph"]),
            c(60, "留声机", 55, ["gramophone", "vinyl", "horn", "phonograph", "music box", "accordion"]),
            c(61, "算盘", 54, ["abacus", "calculator", "counting frame", "beads", "tally", "arithmetic"]),
            c(62, "陶瓷人", 55, ["porcelain", "ceramic", "pottery", "vase", "bowl", "blue and white", "glaze", "kiln"]),
            c(63, "线轴", 53, ["thread", "spool", "yarn", "weaving", "knitting", "fabric", "textile", "loom", "needle"]),
            c(64, "烛台", 54, ["candle", "candlestick", "wax", "flame", "wick", "chandelier", "taper"]),
            c(65, "纸伞", 56, ["umbrella", "parasol", "paper umbrella", "sunshade", "awning", "canopy"]),
            c(66, "镜像", 62, ["mirror", "prism", "kaleidoscope", "reflection", "crystal", "glass surface"]),
            c(67, "残缺", 63, ["broken", "cracked", "torn", "missing", "fragment", "incomplete", "damaged", "glitch"]),
            c(68, "重影", 64, ["blur", "overlap", "transparent", "layered", "superimpose", "ghost image"]),
            c(69, "蛋形", 50, ["egg", "cocoon", "pod", "capsule", "nest", "seed", "embryo", "bud"]),
            c(70, "空", 45, ["empty", "void", "outline", "wireframe", "minimal", "transparent object"])
        ]
    }

    private static func c(_ id: Int, _ name: String, _ weight: Int, _ words: [String]) -> FormCluster {
        FormCluster(formId: id, name: name, keywords: Set(words.map(normalize)), priorityWeight: weight)
    }
}

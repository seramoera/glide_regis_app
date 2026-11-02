// lib/models/orgs.dart

class Org {
  final int id;
  final String name;
  final String status;
  final String imageUrl;
  final String description;
  final int fee;
  final String category;

  Org({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
    required this.description,
    required this.fee,
    required this.category,
  });
}

// 🔹 ALL ORGS (from your UserHome)
final List<Org> allOrgs = [
  Org(
    id: 1,
    name: "Access Point",
    status: "Open",
    imageUrl: "lib/assets/images/ACCESS_POINT.jpg",
    description:
        "The official journalism and news club of SOC, covering events and stories for the community.",
    fee: 100,
    category: "SOC",
  ),
  Org(
    id: 2,
    name: "Code Geeks",
    status: "Open",
    imageUrl: "lib/assets/images/CODE_GEEKS.jpg",
    description: "A hub for students passionate about coding and software.",
    fee: 150,
    category: "SOC",
  ),
  Org(
    id: 3,
    name: "CSIA - Cybersecurity Intelligence Alliance",
    status: "Open",
    imageUrl: "lib/assets/images/CSIA.jpg",
    description:
        "Dedicated to exploring, learning, and sharing cybersecurity skills.",
    fee: 200,
    category: "SOC",
  ),
  Org(
    id: 4,
    name: "LOOP - League of Outstanding Programmers",
    status: "Closed",
    imageUrl: "lib/assets/images/LOOP.jpg",
    description:
        "A league for outstanding SOC programmers to collaborate and grow.",
    fee: 180,
    category: "SOC",
  ),
  Org(
    id: 5,
    name: "MAFIA - Multimedia Aficionados For Interested Artists",
    status: "Closed",
    imageUrl: "lib/assets/images/MAFIA.jpg",
    description:
        "Bringing together creative students who love multimedia and design.",
    fee: 120,
    category: "SOC",
  ),
  Org(
    id: 6,
    name: "GDSC - Google Developer Students Club",
    status: "Open",
    imageUrl: "lib/assets/images/GDSC.jpg",
    description:
        "Part of Google’s global community for student developers and innovators.",
    fee: 0,
    category: "Uniwide",
  ),
  Org(
    id: 7,
    name: "HAU Debate Congress",
    status: "Open",
    imageUrl: "lib/assets/images/HAU_DEBATE_CONGRESS.jpg",
    description:
        "Sharpen your skills in debate, public speaking, and critical thinking.",
    fee: 50,
    category: "Uniwide",
  ),
  Org(
    id: 8,
    name: "Juris Orbis",
    status: "Open",
    imageUrl: "lib/assets/images/JURIS_ORBIS.jpg",
    description:
        "An academic circle for students interested in law and legal studies.",
    fee: 75,
    category: "Uniwide",
  ),
  Org(
    id: 9,
    name: "Apl.de.Ap Music Studio",
    status: "Open",
    imageUrl: "lib/assets/images/APL_DE_AP.jpg",
    description:
        "A creative studio for aspiring musicians and performing artists at HAU.",
    fee: 200,
    category: "Uniwide",
  ),
  Org(
    id: 10,
    name: "AWS Learning Club",
    status: "Open",
    imageUrl: "lib/assets/images/AWS.jpg",
    description: "A student-led club under AWS Cloud Clubs Philippines that builds skills and community around Amazon Web Services cloud technology.",
    fee: 100,
    category: "Uniwide",
    ),
];

// 🔹 USER'S REGISTERED ORGS (empty at start)
List<Org> registeredOrgs = [];

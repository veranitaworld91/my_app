import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
    const AuthCheck({super.key});

    @override
    State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
    Widget currentPage = const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );

    @override
    void initState() {
      super.initState();
      checkLogin();
    }

    void checkLogin() async {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      setState(() {
        if (token != null && token.isNotEmpty) {
          currentPage = const MainPage();
        } else {
          currentPage = const LoginPage();
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      return currentPage;
    }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    AccountsPage(),
    ReportLotPage(),
    ReportCashoutPage(),
    ReportNewAccountPage(),
  ];

  void changePage(int index) {
    setState(() => selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MAHADANA CRM")),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF0B1E3A),
          child: Column(
            children: [
              const DrawerHeader(
                child: Text("MAHADANA CRM", style: TextStyle(color: Colors.white)),
              ),
              menuItem(Icons.home, "Home", 0),
              menuItem(Icons.people, "Accounts", 1),

              ExpansionTile(
                leading: const Icon(Icons.bar_chart, color: Colors.white),
                title: const Text("Report", style: TextStyle(color: Colors.white)),
                children: [
                  subMenu("Lot", 2),
                  subMenu("Cash Out", 3),
                  subMenu("New Account", 4),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text("Logout", style: TextStyle(color: Colors.white)),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ),
      body: pages[selectedIndex],
    );
  }

  Widget menuItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: selectedIndex == index,
      onTap: () => changePage(index),
    );
  }

  Widget subMenu(String title, int index) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      onTap: () => changePage(index),
    );
  }
  
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 Hapus semua session
    await prefs.clear();

    // 🔥 Pindah ke login & hapus semua route
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

// ================= PAGES =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  Future<void> handleLogin() async {

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email & Password wajib diisi")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://crm-mtapp.com/crm_mahadana/ApiMeta/apiLoginMobile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'api-token': 'a688261eba9ef48b6f36dfb87692a6eb',
        },
        body: jsonEncode({
          'email': emailController.text,
          'psw': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (data['status'] == true) {
        final prefs = await SharedPreferences.getInstance();

        // 🔥 simpan session
        await prefs.setString('token', data['token']);
        await prefs.setString('username', data['arrData']['username']);

        // pindah ke dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login gagal')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Login CRM",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Widget card(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black,
              )),
        ],
      ),
    );
  }

  Widget chartBox(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "From",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "To",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () {}, child: const Text("Apply")),
              const SizedBox(width: 5),
              OutlinedButton(onPressed: () {}, child: const Text("Reset")),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(
            height: 150,
            child: Center(child: Text("[Chart here]")),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: card("TOTAL NET LOT", "-19.40", color: Colors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: card("TOTAL NET MARGIN", "-Rp 625", color: Colors.blue),
                ),
              ],
            ),

            const SizedBox(height: 10),

            card("TOTAL NEW ACCOUNT", "51"),

            const SizedBox(height: 20),

            chartBox("NET LOT BY SYMBOL"),

            const SizedBox(height: 20),

            chartBox("NET MARGIN TREND"),

            const SizedBox(height: 20),

            chartBox("TOTAL NEW ACCOUNT (RANGE)"),
          ],
        ),
      ),
    );
  }

}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  Widget summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          const Text("This Month",
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget tableRow(String id, String name, String email, String group, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(id)),
          Expanded(child: Text(name)),
          Expanded(child: Text(email)),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.blue),
                const SizedBox(width: 5),
                Text(group),
              ],
            ),
          ),
          Expanded(child: Text(status)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Account summary & list",
                style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 16),

            // 🔥 SUMMARY
            Row(
              children: [
                Expanded(child: summaryCard("TOTAL ACCOUNT", "62", Colors.black)),
                const SizedBox(width: 10),
                Expanded(child: summaryCard("TOTAL NEW ACCOUNT", "0", Colors.green)),
              ],
            ),

            const SizedBox(height: 20),

            // 🔥 FILTER + LIST
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Account List",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  // 🔹 FILTER
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "From",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "To",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: () {}, child: const Text("Apply")),
                      const SizedBox(width: 5),
                      OutlinedButton(onPressed: () {}, child: const Text("Reset")),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔹 BULK INPUT
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Account ID (Bulk)",
                      hintText: "81201335,81213336 atau enter",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Bulk Assign Group"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔹 ROWS + SEARCH
                  Row(
                    children: [
                      const Text("Rows "),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: 10,
                        items: const [
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 25, child: Text("25")),
                          DropdownMenuItem(value: 50, child: Text("50")),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Cari account / email / nama group ...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 🔥 HEADER
                  Row(
                    children: const [
                      Expanded(child: Text("Account ID", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Account Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Nama Group", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DATA DUMMY
                  tableRow("81201349", "Enjang Enuh Nurjaman", "enjang@gmail.com", "Group A", "AKTIF"),
                  tableRow("81201350", "Jessika Lim", "jessika@gmail.com", "Group B", "AKTIF"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportLotPage extends StatelessWidget {
  const ReportLotPage({super.key});

  Widget summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          const Text("Closed summary today",
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget tableRow(String date, String symbol, String buy, String sell, String net, bool positive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(date)),
          Expanded(child: Text(symbol)),
          Expanded(child: Text(buy)),
          Expanded(child: Text(sell)),
          Expanded(
            child: Text(
              net,
              style: TextStyle(
                color: positive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Report LOT",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("LOT Closed summary",
                style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 16),

            // 🔥 SUMMARY CARDS
            Row(
              children: [
                Expanded(child: summaryCard("Total Net Lot", "-39.60 ▼", Colors.red)),
                const SizedBox(width: 10),
                Expanded(child: summaryCard("Net Buy", "+3.40 ▲", Colors.green)),
              ],
            ),

            const SizedBox(height: 10),

            summaryCard("Net Sell", "-43.00 ▼", Colors.red),

            const SizedBox(height: 20),

            // 🔥 FILTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LOT List",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Date From",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Date To",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: () {}, child: const Text("Apply")),
                      const SizedBox(width: 5),
                      OutlinedButton(onPressed: () {}, child: const Text("Reset")),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Search symbol...",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🔥 TABLE HEADER
                  Row(
                    children: const [
                      Expanded(child: Text("TANGGAL", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("SYMBOL", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("BUY LOT", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("SELL LOT", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("NET LOT", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DATA LIST (dummy dulu)
                  tableRow("14-04-2026", "XAUUSD10", "8.10", "0.20", "-0.10 ▼", false),
                  tableRow("14-04-2026", "XAUUSD3", "2.60", "0.00", "+2.60 ▲", true),
                  tableRow("13-04-2026", "HKK50", "0.00", "2.50", "-2.50 ▼", false),
                  tableRow("13-04-2026", "XAUUSD10", "0.60", "0.00", "+0.60 ▲", true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportCashoutPage extends StatelessWidget {
  const ReportCashoutPage({super.key});

  Widget summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          const Text("This Month",
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget tableRow(
      String date, String account, String name, String amount, String ticket) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(date)),
          Expanded(child: Text(account)),
          Expanded(child: Text(name)),
          Expanded(child: Text(amount)),
          Expanded(child: Text(ticket)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Report Cash Out",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Report Performance Summary",
                style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 16),

            // 🔥 SUMMARY
            Row(
              children: [
                Expanded(
                    child: summaryCard(
                        "TOTAL CASHOUT", "\$18,091,856.3", Colors.blue)),
                const SizedBox(width: 10),
                Expanded(
                    child: summaryCard(
                        "HIGHEST", "\$700,000", Colors.green)),
              ],
            ),

            const SizedBox(height: 10),

            summaryCard("TRANSACTIONS", "3,574", Colors.purple),

            const SizedBox(height: 20),

            // 🔥 FILTER + TABLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cash Out List",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "From",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "To",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: () {}, child: const Text("Apply")),
                      const SizedBox(width: 5),
                      OutlinedButton(onPressed: () {}, child: const Text("Reset")),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Cari account / email...",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🔥 TOTAL BAR
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Total Amount  \$18,091,856.30",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 HEADER
                  Row(
                    children: const [
                      Expanded(child: Text("Close Time", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Account", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Account Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("No. Ticket", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DATA DUMMY
                  tableRow("14-04-2026", "88207263", "Aloisius Erlansyah", "\$3.50", "3893337"),
                  tableRow("14-04-2026", "88206679", "Heppy Iswahyudi", "\$3.50", "3893334"),
                  tableRow("14-04-2026", "88206729", "Raymond Steven", "\$3.50", "3893320"),
                  tableRow("14-04-2026", "88207228", "Irwan Nopiandi", "\$3.50", "3893290"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportNewAccountPage extends StatelessWidget {
  const ReportNewAccountPage({super.key});

  Widget summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          const Text("This Month",
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget tableRow(
      String id, String name, String email, String status, String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(id)),
          Expanded(child: Text(name)),
          Expanded(child: Text(email)),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 5),
                Text(status),
              ],
            ),
          ),
          Expanded(child: Text(date)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("New Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Account summary & list",
                style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 16),

            // 🔥 SUMMARY
            Row(
              children: [
                Expanded(
                    child: summaryCard(
                        "TOTAL ACCOUNT", "51", Colors.black)),
                const SizedBox(width: 10),
                Expanded(
                    child: summaryCard(
                        "TOTAL NEW ACCOUNT", "0", Colors.green)),
              ],
            ),

            const SizedBox(height: 20),

            // 🔥 LIST + FILTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account List",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "From",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "To",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: () {}, child: const Text("Apply")),
                      const SizedBox(width: 5),
                      OutlinedButton(onPressed: () {}, child: const Text("Reset")),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text("Rows "),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: 10,
                        items: const [
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 25, child: Text("25")),
                          DropdownMenuItem(value: 50, child: Text("50")),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Cari account / email...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // 🔥 HEADER
                  Row(
                    children: const [
                      Expanded(child: Text("Account ID", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Account Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text("Created", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 DATA DUMMY
                  tableRow("112363955", "MAB63955", "-", "AKTIF", "01-04-2026"),
                  tableRow("112363949", "MAB63949", "-", "AKTIF", "06-04-2026"),
                  tableRow("112356020", "MAB56020", "-", "AKTIF", "09-04-2026"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

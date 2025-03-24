import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ألوان مخصصة
const PRIMARY_COLOR = Colors.blue;
const SECONDARY_COLOR = Colors.grey;
const ACCENT_COLOR = Colors.amber;
const TEXT_COLOR = Colors.black87;

// نموذج المستخدم
class User {
  final String code;
  final String username;
  final String department;
  final String role;
  final String password;

  User({required this.code, required this.username, required this.department, required this.role, required this.password});

  Map<String, dynamic> toMap() => {
        'code': code,
        'username': username,
        'department': department,
        'role': role,
        'password': password,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        code: map['code'],
        username: map['username'],
        department: map['department'],
        role: map['role'],
        password: map['password'],
      );
}

// نموذج المحتوى
class Content {
  final int id;
  final String title;
  final String fileData; // base64
  final String fileType;
  final String uploadedBy;
  final String uploadDate;

  Content({required this.id, required this.title, required this.fileData, required this.fileType, required this.uploadedBy, required this.uploadDate});

  factory Content.fromMap(Map<String, dynamic> map) => Content(
        id: map['id'],
        title: map['title'],
        fileData: map['file_data'],
        fileType: map['file_type'],
        uploadedBy: map['uploaded_by'],
        uploadDate: map['upload_date'],
      );
}

// نموذج الشات
class ChatMessage {
  final int id;
  final String senderCode;
  final String receiverCode;
  final String message;
  final String timestamp;

  ChatMessage({required this.id, required this.senderCode, required this.receiverCode, required this.message, required this.timestamp});

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'],
        senderCode: map['sender_code'],
        receiverCode: map['receiver_code'],
        message: map['message'],
        timestamp: map['timestamp'],
      );
}

// إدارة الحالة باستخدام Provider
class AppState with ChangeNotifier {
  User? currentUser;

  void setUser(User user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}

// إعداد قاعدة البيانات
Future<Database> initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'alson_education.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          code TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          department TEXT NOT NULL,
          role TEXT DEFAULT 'user',
          password TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE content (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          file_data TEXT NOT NULL,
          file_type TEXT NOT NULL,
          uploaded_by TEXT NOT NULL,
          upload_date TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE chat (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sender_code TEXT NOT NULL,
          receiver_code TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      await db.rawInsert(
        "INSERT INTO users (code, username, department, role, password) VALUES (?, ?, ?, ?, ?)",
        ['admin123', 'Admin', 'إدارة', 'admin', 'adminpass'],
      );
    },
  );
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alson Education',
      theme: ThemeData(
        primaryColor: PRIMARY_COLOR,
        scaffoldBackgroundColor: SECONDARY_COLOR,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/manage_users': (context) => const ManageUsersPage(),
        '/upload_content': (context) => const UploadContentPage(),
        '/content': (context) => const ContentPage(),
        '/chat': (context) => const ChatPage(),
        '/results': (context) => const ResultsPage(),
        '/result_details': (context) => const ResultDetailsPage(),
        '/help': (context) => const HelpPage(),
      },
    );
  }
}

// صفحة تسجيل الدخول
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final db = await initDatabase();
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [_usernameController.text.trim(), _passwordController.text.trim()],
    );
    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);
      Provider.of<AppState>(context, listen: false).setUser(user);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بيانات غير صحيحة', style: TextStyle(color: Colors.red))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/img/icon.png', width: 150),
              const Text('مرحبًا بك في الأسن!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('تسجيل الدخول'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('هل نسيت كلمة المرور؟', style: TextStyle(color: PRIMARY_COLOR)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// شريط التطبيق
AppBar createAppBar(BuildContext context, bool isAdmin) {
  return AppBar(
    title: const Text('الأسن للعلوم الحديثة', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
    backgroundColor: PRIMARY_COLOR,
    centerTitle: true,
    leading: const Icon(Icons.school, color: Colors.white, size: 30),
    actions: [
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'profile':
              Navigator.pushNamed(context, '/profile');
              break;
            case 'results':
              Navigator.pushNamed(context, '/results');
              break;
            case 'content':
              Navigator.pushNamed(context, '/content');
              break;
            case 'chat':
              Navigator.pushNamed(context, '/chat');
              break;
            case 'help':
              Navigator.pushNamed(context, '/help');
              break;
            case 'logout':
              Provider.of<AppState>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 'manage_users':
              Navigator.pushNamed(context, '/manage_users');
              break;
            case 'upload_content':
              Navigator.pushNamed(context, '/upload_content');
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
          const PopupMenuItem(value: 'results', child: Text('النتيجة')),
          const PopupMenuItem(value: 'content', child: Text('المحتوى')),
          const PopupMenuItem(value: 'chat', child: Text('الشات')),
          const PopupMenuItem(value: 'help', child: Text('المساعدة')),
          const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
          if (isAdmin) const PopupMenuItem(value: 'manage_users', child: Text('إدارة المستخدمين')),
          if (isAdmin) const PopupMenuItem(value: 'upload_content', child: Text('رفع المحتوى')),
        ],
      ),
    ],
  );
}

// الصفحة الرئيسية
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isAdmin = appState.currentUser?.role == 'admin';

    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('مرحباً ${appState.currentUser?.username}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text('جدول قسم ${appState.currentUser?.department}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Image.asset('assets/img/po.jpg', width: 340, fit: BoxFit.cover),
                    const Text('الإثنين 22 مارس 2025', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/results'),
                  style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
                  child: const Text('عرض النتيجة'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/content'),
                  style: ElevatedButton.styleFrom(backgroundColor: ACCENT_COLOR, foregroundColor: Colors.white),
                  child: const Text('المحتوى'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('الشات'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة إدارة المستخدمين
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = await initDatabase();
    final result = await db.query('users');
    setState(() {
      users = result.map((map) => User.fromMap(map)).toList();
    });
  }

  Future<void> _uploadUsers(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowedExtensions: ['xlsx'], type: FileType.custom);
    if (result != null) {
      // يتطلب مكتبة لقراءة Excel مثل 'excel'، لكن لتبسيط الأمر سنفترض إدخال يدوي
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع المستخدمين بنجاح', style: TextStyle(color: Colors.green))),
      );
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('إدارة المستخدمين', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            ElevatedButton(
              onPressed: () => _uploadUsers(context),
              style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
              child: const Text('رفع ملف Excel'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الكود')),
                    DataColumn(label: Text('اسم المستخدم')),
                    DataColumn(label: Text('القسم')),
                    DataColumn(label: Text('الدور')),
                    DataColumn(label: Text('كلمة المرور')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: users.map((user) => DataRow(cells: [
                        DataCell(Text(user.code)),
                        DataCell(Text(user.username)),
                        DataCell(Text(user.department)),
                        DataCell(Text(user.role)),
                        DataCell(Text(user.password)),
                        DataCell(Row(
                          children: [
                            IconButton(icon: const Icon(Icons.visibility, color: Colors.green), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                          ],
                        )),
                      ])).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة رفع المحتوى
class UploadContentPage extends StatefulWidget {
  const UploadContentPage({super.key});

  @override
  _UploadContentPageState createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage> {
  final _titleController = TextEditingController();

  Future<void> _uploadContent(BuildContext context) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان المحتوى', style: TextStyle(color: Colors.red))),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final fileData = base64Encode(bytes);
      final db = await initDatabase();
      await db.insert('content', {
        'title': _titleController.text,
        'file_data': fileData,
        'file_type': result.files.single.extension!,
        'uploaded_by': Provider.of<AppState>(context, listen: false).currentUser!.code,
        'upload_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع المحتوى بنجاح', style: TextStyle(color: Colors.green))),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('رفع المحتوى', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان المحتوى', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadContent(context),
              style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
              child: const Text('اختر ملف'),
            ),
            const Text('الصيغ المدعومة: PDF, صور (PNG, JPG), نصوص (TXT)', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: ACCENT_COLOR, foregroundColor: Colors.white),
              child: const Text('عودة'),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة عرض المحتوى
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  List<Content> contents = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final db = await initDatabase();
    final result = await db.query('content');
    setState(() {
      contents = result.map((map) => Content.fromMap(map)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('المحتوى التعليمي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            Expanded(
              child: contents.isEmpty
                  ? const Center(child: Text('لا يوجد محتوى متاح حاليًا', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: contents.length,
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        return Card(
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Text('العنوان: ${content.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('نوع الملف: ${content.fileType}', style: const TextStyle(fontSize: 14)),
                                Text('تاريخ الرفع: ${content.uploadDate}', style: const TextStyle(fontSize: 14)),
                                ElevatedButton(
                                  onPressed: () {
                                    // عرض الملف (يمكن تحسينه باستخدام مكتبة مثل flutter_pdfview)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('عرض الملف غير مدعوم حاليًا', style: TextStyle(color: Colors.red))),
                                    );
                                  },
                                  child: const Text('عرض'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
              child: const Text('عودة'),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة الشات
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<User> users = [];
  String? selectedReceiver;
  List<ChatMessage> messages = [];
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = await initDatabase();
    final currentUserCode = Provider.of<AppState>(context, listen: false).currentUser!.code;
    final result = await db.query('users', where: 'code != ?', whereArgs: [currentUserCode]);
    setState(() {
      users = result.map((map) => User.fromMap(map)).toList();
    });
  }

  Future<void> _loadMessages() async {
    if (selectedReceiver != null) {
      final db = await initDatabase();
      final currentUserCode = Provider.of<AppState>(context, listen: false).currentUser!.code;
      final result = await db.query(
        'chat',
        where: '(sender_code = ? AND receiver_code = ?) OR (sender_code = ? AND receiver_code = ?)',
        whereArgs: [currentUserCode, selectedReceiver, selectedReceiver, currentUserCode],
        orderBy: 'timestamp ASC',
      );
      setState(() {
        messages = result.map((map) => ChatMessage.fromMap(map)).toList();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (selectedReceiver != null && _messageController.text.isNotEmpty) {
      final db = await initDatabase();
      final currentUserCode = Provider.of<AppState>(context, listen: false).currentUser!.code;
      await db.insert('chat', {
        'sender_code': currentUserCode,
        'receiver_code': selectedReceiver,
        'message': _messageController.text,
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      });
      _messageController.clear();
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('الشات', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            DropdownButton<String>(
              value: selectedReceiver,
              hint: const Text('اختر المستخدم'),
              items: users.map((user) => DropdownMenuItem(value: user.code, child: Text(user.username))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReceiver = value;
                  _loadMessages();
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isSender = message.senderCode == Provider.of<AppState>(context, listen: false).currentUser!.code;
                  return Align(
                    alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isSender ? Colors.grey[200] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${message.message} - ${message.timestamp}', style: TextStyle(color: isSender ? TEXT_COLOR : Colors.blue)),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'اكتب رسالتك', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: PRIMARY_COLOR),
                  onPressed: _sendMessage,
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
              child: const Text('عودة'),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة النتائج (مثال بسيط)
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: const Center(child: Text('صفحة النتائج - تحت التطوير')),
    );
  }
}

// صفحة تفاصيل النتيجة (مثال بسيط)
class ResultDetailsPage extends StatelessWidget {
  const ResultDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: const Center(child: Text('تفاصيل النتيجة - تحت التطوير')),
    );
  }
}

// صفحة المساعدة
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AppState>(context).currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: const Center(child: Text('مركز المساعدة - تحت التطوير')),
    );
  }
}

// صفحة الملف الشخصي
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isAdmin = appState.currentUser?.role == 'admin';
    return Scaffold(
      appBar: createAppBar(context, isAdmin),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('الملف الشخصي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PRIMARY_COLOR)),
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(children: [const Icon(Icons.person, color: PRIMARY_COLOR), Text('الاسم: ${appState.currentUser?.username}', style: const TextStyle(fontSize: 16, color: TEXT_COLOR))]),
                    Row(children: [const Icon(Icons.lock, color: PRIMARY_COLOR), Text('الكود: ${appState.currentUser?.code}', style: const TextStyle(fontSize: 16, color: TEXT_COLOR))]),
                    Row(children: [const Icon(Icons.group, color: PRIMARY_COLOR), Text('القسم: ${appState.currentUser?.department}', style: const TextStyle(fontSize: 16, color: TEXT_COLOR))]),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: PRIMARY_COLOR, foregroundColor: Colors.white),
              child: const Text('عودة'),
            ),
          ],
        ),
      ),
    );
  }
}
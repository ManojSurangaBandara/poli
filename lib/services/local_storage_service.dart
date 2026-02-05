import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import '../models/borrower.dart';
import '../models/loan.dart';

class LocalStorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'borrowers.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE borrowers(
        id TEXT PRIMARY KEY,
        name TEXT,
        mobileNumber TEXT,
        profilePicturePath TEXT,
        bankName TEXT,
        accountNumber TEXT,
        accountHolderName TEXT,
        branchName TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE loans(
        id TEXT PRIMARY KEY,
        borrowerId TEXT,
        amount REAL,
        date TEXT,
        status TEXT,
        interestPercentage REAL,
        interest REAL,
        nextInterestDueDate TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE borrowers ADD COLUMN bankName TEXT');
      await db.execute('ALTER TABLE borrowers ADD COLUMN accountNumber TEXT');
      await db.execute('ALTER TABLE borrowers ADD COLUMN accountHolderName TEXT');
      await db.execute('ALTER TABLE borrowers ADD COLUMN branchName TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE loans(
          id TEXT PRIMARY KEY,
          borrowerId TEXT,
          amount REAL,
          date TEXT,
          status TEXT,
          interestPercentage REAL,
          installmentAmount REAL,
          nextInstallmentDate TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE loans ADD COLUMN interestPercentage REAL DEFAULT 0.0');
    }
    if (oldVersion < 6) {
      // Rename old columns if exist
      try {
        await db.execute('ALTER TABLE loans RENAME COLUMN monthlyInterestAmount TO interest');
      } catch (e) {
        await db.execute('ALTER TABLE loans ADD COLUMN interest REAL DEFAULT 0.0');
      }
      try {
        await db.execute('ALTER TABLE loans RENAME COLUMN nextInstallmentDate TO nextInterestDueDate');
      } catch (e) {
        await db.execute('ALTER TABLE loans ADD COLUMN nextInterestDueDate TEXT');
      }
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE loans ADD COLUMN repaidDate TEXT');
    }
  }

  Future<List<Borrower>> getBorrowers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('borrowers');
    return maps.map((map) => Borrower.fromMap(map)).toList();
  }

  Future<void> addBorrower(Borrower borrower) async {
    Database db = await database;
    await db.insert('borrowers', borrower.toMap());
  }

  Future<String?> saveProfilePicture(String borrowerId, XFile image) async {
    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String fileName = '$borrowerId.jpg';
      String filePath = join(appDir.path, 'profile_pictures', fileName);

      // Ensure directory exists
      Directory profileDir = Directory(join(appDir.path, 'profile_pictures'));
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final bytes = await image.readAsBytes();
      File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBorrower(Borrower borrower) async {
    Database db = await database;
    await db.update('borrowers', borrower.toMap(), where: 'id = ?', whereArgs: [borrower.id]);
  }

  Future<void> deleteBorrower(String id) async {
    Database db = await database;
    // Delete image file if exists
    List<Map<String, dynamic>> maps = await db.query('borrowers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      String? path = maps.first['profilePicturePath'];
      if (path != null && await File(path).exists()) {
        await File(path).delete();
      }
    }
    await db.delete('borrowers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Loan>> getLoansForBorrower(String borrowerId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('loans', where: 'borrowerId = ?', whereArgs: [borrowerId]);
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<Loan?> getActiveLoanForBorrower(String borrowerId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('loans', where: 'borrowerId = ? AND status = ?', whereArgs: [borrowerId, 'active']);
    if (maps.isNotEmpty) {
      return Loan.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addLoan(Loan loan) async {
    Database db = await database;
    await db.insert('loans', loan.toMap());
  }

  Future<void> updateLoan(Loan loan) async {
    Database db = await database;
    await db.update('loans', loan.toMap(), where: 'id = ?', whereArgs: [loan.id]);
  }
}
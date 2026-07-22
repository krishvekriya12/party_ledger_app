import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/party.dart';
import '../models/bill.dart';
import '../models/payment.dart';
import '../models/karigar.dart';
import '../models/karigar_work.dart';
import '../models/karigar_advance.dart';
import '../models/partner.dart';
import '../models/partner_contribution.dart';
import '../models/partner_expense.dart';
import '../models/partner_advance.dart';
import '../models/online_purchase.dart';
import '../models/online_sale_payment.dart';
import '../models/challan.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'party_ledger.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS bills');
          await db.execute('DROP TABLE IF EXISTS payments');
          await db.execute('DROP TABLE IF EXISTS parties');
          await db.execute('DROP TABLE IF EXISTS karigar_work');
          await db.execute('DROP TABLE IF EXISTS karigar_advance');
          await db.execute('DROP TABLE IF EXISTS karigars');
          await db.execute('DROP TABLE IF EXISTS partners');
          await db.execute('DROP TABLE IF EXISTS partner_contribution');
          await db.execute('DROP TABLE IF EXISTS partner_expense');
          await _createDB(db, newVersion);
        }
        if (oldVersion < 4) {
          // Add online module tables (safe — does not drop existing data)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS online_purchases (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              party_name TEXT NOT NULL,
              amount REAL NOT NULL,
              purchase_date TEXT NOT NULL,
              note TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS online_sale_payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              platform TEXT NOT NULL,
              partner_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              payment_date TEXT NOT NULL,
              note TEXT,
              FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          // Add pis column to bills (safe — existing rows default to 1)
          await db.execute(
              'ALTER TABLE bills ADD COLUMN pis REAL DEFAULT 1');
        }
        if (oldVersion < 6) {
          // Add partner_advance table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS partner_advance (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              partner_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              advance_date TEXT NOT NULL,
              note TEXT,
              FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 7) {
          // Add challans and challan_items tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS challans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bill_no TEXT NOT NULL,
              challan_date TEXT NOT NULL,
              from_name TEXT NOT NULL,
              party_name TEXT NOT NULL,
              gstin TEXT,
              total_pcs INTEGER NOT NULL,
              total_amount REAL NOT NULL,
              prepared_by TEXT,
              note TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS challan_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              challan_id INTEGER NOT NULL,
              particular TEXT NOT NULL,
              sizes_json TEXT NOT NULL,
              total_pcs INTEGER NOT NULL,
              rate REAL NOT NULL,
              amount REAL NOT NULL,
              FOREIGN KEY (challan_id) REFERENCES challans (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }


  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER NOT NULL,
        design_no TEXT NOT NULL,
        color TEXT NOT NULL,
        pis REAL NOT NULL DEFAULT 1,
        rate REAL NOT NULL,
        total REAL NOT NULL,
        bill_date TEXT NOT NULL,
        FOREIGN KEY (party_id) REFERENCES parties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        mode TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        FOREIGN KEY (party_id) REFERENCES parties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE karigars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE karigar_work (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        karigar_id INTEGER NOT NULL,
        design_no TEXT NOT NULL,
        pis REAL NOT NULL,
        rate REAL NOT NULL,
        total REAL NOT NULL,
        work_date TEXT NOT NULL,
        FOREIGN KEY (karigar_id) REFERENCES karigars (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE karigar_advance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        karigar_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        advance_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (karigar_id) REFERENCES karigars (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_contribution (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        contribution_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_expense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE online_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_name TEXT NOT NULL,
        amount REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE online_sale_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        platform TEXT NOT NULL,
        partner_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_advance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        advance_date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (partner_id) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE challans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_no TEXT NOT NULL,
        challan_date TEXT NOT NULL,
        from_name TEXT NOT NULL,
        party_name TEXT NOT NULL,
        gstin TEXT,
        total_pcs INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        prepared_by TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE challan_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challan_id INTEGER NOT NULL,
        particular TEXT NOT NULL,
        sizes_json TEXT NOT NULL,
        total_pcs INTEGER NOT NULL,
        rate REAL NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (challan_id) REFERENCES challans (id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------- PARTY CRUD ----------
  Future<int> insertParty(Party party) async {
    final db = await database;
    return await db.insert('parties', party.toMap());
  }

  Future<List<Party>> getAllParties() async {
    final db = await database;
    final maps = await db.query('parties', orderBy: 'name ASC');
    return maps.map((m) => Party.fromMap(m)).toList();
  }

  Future<int> updateParty(Party party) async {
    final db = await database;
    return await db.update(
      'parties',
      party.toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  Future<int> deleteParty(int id) async {
    final db = await database;
    return await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- BILL CRUD ----------
  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<List<Bill>> getBillsForParty(int partyId) async {
    final db = await database;
    final maps = await db.query(
      'bills',
      where: 'party_id = ?',
      whereArgs: [partyId],
      orderBy: 'bill_date DESC',
    );
    return maps.map((m) => Bill.fromMap(m)).toList();
  }

  Future<double> getTotalBillAmount(int partyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as sum FROM bills WHERE party_id = ?',
      [partyId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- PAYMENT CRUD ----------
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsForParty(int partyId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'party_id = ?',
      whereArgs: [partyId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<double> getTotalPaidAmount(int partyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM payments WHERE party_id = ?',
      [partyId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- BALANCE (PARTY) ----------
  Future<double> getOutstandingBalance(int partyId) async {
    final totalBill = await getTotalBillAmount(partyId);
    final totalPaid = await getTotalPaidAmount(partyId);
    return totalBill - totalPaid;
  }

  // Grand total across ALL parties (Total Bill | Payment | Outstanding)
  Future<Map<String, double>> getPartyGrandTotal() async {
    final db = await database;
    final billResult = await db.rawQuery('SELECT SUM(total) as sum FROM bills');
    final paymentResult = await db.rawQuery('SELECT SUM(amount) as sum FROM payments');
    final totalBill = (billResult.first['sum'] as double?) ?? 0.0;
    final totalPayment = (paymentResult.first['sum'] as double?) ?? 0.0;
    return {
      'totalBill': totalBill,
      'totalPayment': totalPayment,
      'outstanding': totalBill - totalPayment,
    };
  }

  // ---------- KARIGAR CRUD ----------
  Future<int> insertKarigar(Karigar karigar) async {
    final db = await database;
    return await db.insert('karigars', karigar.toMap());
  }

  Future<List<Karigar>> getAllKarigars() async {
    final db = await database;
    final maps = await db.query('karigars', orderBy: 'name ASC');
    return maps.map((m) => Karigar.fromMap(m)).toList();
  }

  Future<int> updateKarigar(Karigar karigar) async {
    final db = await database;
    return await db.update(
      'karigars',
      karigar.toMap(),
      where: 'id = ?',
      whereArgs: [karigar.id],
    );
  }

  Future<int> deleteKarigar(int id) async {
    final db = await database;
    return await db.delete('karigars', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- KARIGAR WORK CRUD ----------
  Future<int> insertKarigarWork(KarigarWork work) async {
    final db = await database;
    return await db.insert('karigar_work', work.toMap());
  }

  Future<List<KarigarWork>> getWorkForKarigar(int karigarId) async {
    final db = await database;
    final maps = await db.query(
      'karigar_work',
      where: 'karigar_id = ?',
      whereArgs: [karigarId],
      orderBy: 'work_date DESC',
    );
    return maps.map((m) => KarigarWork.fromMap(m)).toList();
  }

  Future<double> getTotalWorkAmount(int karigarId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as sum FROM karigar_work WHERE karigar_id = ?',
      [karigarId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- KARIGAR ADVANCE (UPAD) CRUD ----------
  Future<int> insertKarigarAdvance(KarigarAdvance advance) async {
    final db = await database;
    return await db.insert('karigar_advance', advance.toMap());
  }

  Future<List<KarigarAdvance>> getAdvancesForKarigar(int karigarId) async {
    final db = await database;
    final maps = await db.query(
      'karigar_advance',
      where: 'karigar_id = ?',
      whereArgs: [karigarId],
      orderBy: 'advance_date DESC',
    );
    return maps.map((m) => KarigarAdvance.fromMap(m)).toList();
  }

  Future<double> getTotalAdvanceGiven(int karigarId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM karigar_advance WHERE karigar_id = ?',
      [karigarId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- BALANCE (KARIGAR) ----------
  // Net Payable = Total work amount earned - Total advance already given
  Future<double> getKarigarNetPayable(int karigarId) async {
    final totalWork = await getTotalWorkAmount(karigarId);
    final totalAdvance = await getTotalAdvanceGiven(karigarId);
    return totalWork - totalAdvance;
  }

  // Grand total across ALL karigars (for the "last total of all" summary)
  Future<Map<String, double>> getKarigarGrandTotal() async {
    final db = await database;
    final workResult = await db.rawQuery('SELECT SUM(total) as sum FROM karigar_work');
    final advanceResult = await db.rawQuery('SELECT SUM(amount) as sum FROM karigar_advance');
    final totalWork = (workResult.first['sum'] as double?) ?? 0.0;
    final totalAdvance = (advanceResult.first['sum'] as double?) ?? 0.0;
    return {
      'totalWork': totalWork,
      'totalAdvance': totalAdvance,
      'netPayable': totalWork - totalAdvance,
    };
  }

  // ---------- PARTNER CRUD ----------
  Future<int> insertPartner(Partner partner) async {
    final db = await database;
    return await db.insert('partners', partner.toMap());
  }

  Future<List<Partner>> getAllPartners() async {
    final db = await database;
    final maps = await db.query('partners', orderBy: 'name ASC');
    return maps.map((m) => Partner.fromMap(m)).toList();
  }

  Future<int> updatePartner(Partner partner) async {
    final db = await database;
    return await db.update(
      'partners',
      partner.toMap(),
      where: 'id = ?',
      whereArgs: [partner.id],
    );
  }

  Future<int> deletePartner(int id) async {
    final db = await database;
    return await db.delete('partners', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PARTNER CONTRIBUTION CRUD ----------
  Future<int> insertPartnerContribution(PartnerContribution contribution) async {
    final db = await database;
    return await db.insert('partner_contribution', contribution.toMap());
  }

  Future<List<PartnerContribution>> getContributionsForPartner(int partnerId) async {
    final db = await database;
    final maps = await db.query(
      'partner_contribution',
      where: 'partner_id = ?',
      whereArgs: [partnerId],
      orderBy: 'contribution_date DESC',
    );
    return maps.map((m) => PartnerContribution.fromMap(m)).toList();
  }

  Future<double> getTotalContribution(int partnerId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM partner_contribution WHERE partner_id = ?',
      [partnerId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- PARTNER EXPENSE CRUD ----------
  Future<int> insertPartnerExpense(PartnerExpense expense) async {
    final db = await database;
    return await db.insert('partner_expense', expense.toMap());
  }

  Future<List<PartnerExpense>> getExpensesForPartner(int partnerId) async {
    final db = await database;
    final maps = await db.query(
      'partner_expense',
      where: 'partner_id = ?',
      whereArgs: [partnerId],
      orderBy: 'expense_date DESC',
    );
    return maps.map((m) => PartnerExpense.fromMap(m)).toList();
  }

  Future<double> getTotalExpense(int partnerId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM partner_expense WHERE partner_id = ?',
      [partnerId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- PARTNER ADVANCE CRUD ----------
  Future<int> insertPartnerAdvance(PartnerAdvance advance) async {
    final db = await database;
    return await db.insert('partner_advance', advance.toMap());
  }

  Future<List<PartnerAdvance>> getAdvancesForPartner(int partnerId) async {
    final db = await database;
    final maps = await db.query(
      'partner_advance',
      where: 'partner_id = ?',
      whereArgs: [partnerId],
      orderBy: 'advance_date DESC',
    );
    return maps.map((m) => PartnerAdvance.fromMap(m)).toList();
  }

  Future<double> getTotalAdvanceForPartner(int partnerId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM partner_advance WHERE partner_id = ?',
      [partnerId],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // Net = Total Contribution - Total Expense - Total Advance (kitna balance partner ka business me bacha hai)
  Future<double> getPartnerNetBalance(int partnerId) async {
    final totalContribution = await getTotalContribution(partnerId);
    final totalExpense = await getTotalExpense(partnerId);
    final totalAdvance = await getTotalAdvanceForPartner(partnerId);
    return totalContribution - totalExpense - totalAdvance;
  }

  // Grand total across ALL partners
  Future<Map<String, double>> getPartnerGrandTotal() async {
    final db = await database;
    final contributionResult =
        await db.rawQuery('SELECT SUM(amount) as sum FROM partner_contribution');
    final expenseResult = await db.rawQuery('SELECT SUM(amount) as sum FROM partner_expense');
    final advanceResult = await db.rawQuery('SELECT SUM(amount) as sum FROM partner_advance');
    final totalContribution = (contributionResult.first['sum'] as double?) ?? 0.0;
    final totalExpense = (expenseResult.first['sum'] as double?) ?? 0.0;
    final totalAdvance = (advanceResult.first['sum'] as double?) ?? 0.0;
    return {
      'totalContribution': totalContribution,
      'totalExpense': totalExpense,
      'totalAdvance': totalAdvance,
      'netBalance': totalContribution - totalExpense - totalAdvance,
    };
  }

  // Combined chronological history (contribution + expense + advance) for a partner
  Future<List<Map<String, dynamic>>> getPartnerFullHistory(int partnerId) async {
    final contributions = await getContributionsForPartner(partnerId);
    final expenses = await getExpensesForPartner(partnerId);
    final advances = await getAdvancesForPartner(partnerId);

    final history = <Map<String, dynamic>>[];
    for (final c in contributions) {
      history.add({
        'type': 'contribution',
        'amount': c.amount,
        'date': c.contributionDate,
        'label': c.note ?? 'Contribution',
      });
    }
    for (final e in expenses) {
      history.add({
        'type': 'expense',
        'amount': e.amount,
        'date': e.expenseDate,
        'label': e.description,
      });
    }
    for (final a in advances) {
      history.add({
        'type': 'advance',
        'amount': a.amount,
        'date': a.advanceDate,
        'label': a.note ?? 'Advance',
      });
    }
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return history;
  }

  // =========================================================
  // ---------------- DASHBOARD / REPORTS ----------------
  // =========================================================

  // 1 & 3. Total payment pending to receive from ALL parties (outstanding)
  Future<double> getTotalReceivableFromParties() async {
    final grandTotal = await getPartyGrandTotal();
    return grandTotal['outstanding'] ?? 0.0;
  }

  // 2. Karigar monthly payroll - total work amount grouped by month (YYYY-MM)
  Future<List<Map<String, dynamic>>> getMonthlyKarigarPayroll() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', work_date) as month, SUM(total) as total
      FROM karigar_work
      GROUP BY month
      ORDER BY month DESC
    ''');
    return result
        .map((r) => {
              'month': r['month'] as String,
              'total': (r['total'] as double?) ?? 0.0,
            })
        .toList();
  }

  // Current month's karigar payroll (quick figure for dashboard)
  Future<double> getCurrentMonthKarigarPayroll() async {
    final db = await database;
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT SUM(total) as sum FROM karigar_work
      WHERE strftime('%Y-%m', work_date) = ?
    ''', [currentMonth]);
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // 4. Partner ledger
  Future<List<Map<String, dynamic>>> getPartnerLedgerSummary() async {
    final partners = await getAllPartners();
    final list = <Map<String, dynamic>>[];
    for (final p in partners) {
      if (p.id == null) continue;
      final totalGiven = await getTotalContribution(p.id!);
      final totalSpent = await getTotalExpense(p.id!);
      final totalAdvance = await getTotalAdvanceForPartner(p.id!);
      list.add({
        'partner': p,
        'totalGiven': totalGiven,
        'totalSpent': totalSpent,
        'totalAdvance': totalAdvance,
        'net': totalGiven - totalSpent - totalAdvance,
      });
    }
    return list;
  }

  // 5. Every month calculation - combined business summary grouped by month
  Future<List<Map<String, dynamic>>> getMonthlyBusinessSummary() async {
    final db = await database;

    final billRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', bill_date) as month, SUM(total) as total
      FROM bills GROUP BY month
    ''');
    final paymentRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', payment_date) as month, SUM(amount) as total
      FROM payments GROUP BY month
    ''');
    final workRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', work_date) as month, SUM(total) as total
      FROM karigar_work GROUP BY month
    ''');
    final advanceRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', advance_date) as month, SUM(amount) as total
      FROM karigar_advance GROUP BY month
    ''');
    final contributionRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', contribution_date) as month, SUM(amount) as total
      FROM partner_contribution GROUP BY month
    ''');
    final expenseRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', expense_date) as month, SUM(amount) as total
      FROM partner_expense GROUP BY month
    ''');
    final partnerAdvanceRows = await db.rawQuery('''
      SELECT strftime('%Y-%m', advance_date) as month, SUM(amount) as total
      FROM partner_advance GROUP BY month
    ''');

    final Map<String, Map<String, double>> monthly = {};

    void addRows(List<Map<String, Object?>> rows, String key) {
      for (final r in rows) {
         final month = r['month'] as String?;
         if (month == null) continue;
         final value = (r['total'] as double?) ?? 0.0;
         monthly.putIfAbsent(
             month,
             () => {
                   'bill': 0,
                   'payment': 0,
                   'karigarWork': 0,
                   'karigarAdvance': 0,
                   'partnerContribution': 0,
                   'partnerExpense': 0,
                   'partnerAdvance': 0,
                 });
         monthly[month]![key] = value;
      }
    }

    addRows(billRows, 'bill');
    addRows(paymentRows, 'payment');
    addRows(workRows, 'karigarWork');
    addRows(advanceRows, 'karigarAdvance');
    addRows(contributionRows, 'partnerContribution');
    addRows(expenseRows, 'partnerExpense');
    addRows(partnerAdvanceRows, 'partnerAdvance');

    final months = monthly.keys.toList()..sort((a, b) => b.compareTo(a));
    return months.map((m) => {'month': m, ...monthly[m]!}).toList();
  }

  // 6. Outstanding bill pending - list of parties with balance > 0, sorted highest first
  Future<List<Map<String, dynamic>>> getOutstandingPartiesList() async {
    final parties = await getAllParties();
    final list = <Map<String, dynamic>>[];
    for (final p in parties) {
      if (p.id == null) continue;
      final balance = await getOutstandingBalance(p.id!);
      if (balance > 0) {
        list.add({'party': p, 'outstanding': balance});
      }
    }
    list.sort((a, b) => (b['outstanding'] as double).compareTo(a['outstanding'] as double));
    return list;
  }

  // 7. Party Bill Cycle (60 days) - due date report
  // Due date = oldest unpaid bill's date + 60 days, for parties with outstanding balance
  Future<List<Map<String, dynamic>>> getBillCycleReport({int cycleDays = 60}) async {
    final outstandingParties = await getOutstandingPartiesList();
    final report = <Map<String, dynamic>>[];

    for (final entry in outstandingParties) {
      final party = entry['party'] as Party;
      final outstanding = entry['outstanding'] as double;
      final bills = await getBillsForParty(party.id!);
      if (bills.isEmpty) continue;

      // oldest bill first
      bills.sort((a, b) => a.billDate.compareTo(b.billDate));
      final oldestBillDate = bills.first.billDate;
      final dueDate = oldestBillDate.add(Duration(days: cycleDays));
      final today = DateTime.now();
      final daysRemaining = dueDate.difference(today).inDays;
      final isOverdue = daysRemaining < 0;

      report.add({
        'party': party,
        'outstanding': outstanding,
        'oldestBillDate': oldestBillDate,
        'dueDate': dueDate,
        'daysRemaining': daysRemaining,
        'isOverdue': isOverdue,
      });
    }

    // Overdue first, then soonest due date
    report.sort((a, b) => (a['daysRemaining'] as int).compareTo(b['daysRemaining'] as int));
    return report;
  }
  // =========================================================
  // -------------- ONLINE MODULE CRUD -----------------
  // =========================================================

  // ---------- ONLINE PURCHASE CRUD ----------
  Future<int> insertOnlinePurchase(OnlinePurchase purchase) async {
    final db = await database;
    return await db.insert('online_purchases', purchase.toMap());
  }

  Future<List<OnlinePurchase>> getAllOnlinePurchases() async {
    final db = await database;
    final maps = await db.query('online_purchases', orderBy: 'purchase_date DESC');
    return maps.map((m) => OnlinePurchase.fromMap(m)).toList();
  }

  Future<int> deleteOnlinePurchase(int id) async {
    final db = await database;
    return await db.delete('online_purchases', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalOnlinePurchaseAmount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as sum FROM online_purchases');
    return (result.first['sum'] as double?) ?? 0.0;
  }

  // ---------- ONLINE SALE PAYMENT CRUD ----------
  Future<int> insertOnlineSalePayment(OnlineSalePayment payment) async {
    final db = await database;
    return await db.insert('online_sale_payments', payment.toMap());
  }

  /// All payments for a specific platform (flipkart / meesho)
  Future<List<OnlineSalePayment>> getSalePaymentsForPlatform(String platform) async {
    final db = await database;
    final maps = await db.query(
      'online_sale_payments',
      where: 'platform = ?',
      whereArgs: [platform],
      orderBy: 'payment_date DESC',
    );
    return maps.map((m) => OnlineSalePayment.fromMap(m)).toList();
  }

  /// All payments for a specific partner + platform
  Future<List<OnlineSalePayment>> getSalePaymentsForPartner(
      int partnerId, String platform) async {
    final db = await database;
    final maps = await db.query(
      'online_sale_payments',
      where: 'partner_id = ? AND platform = ?',
      whereArgs: [partnerId, platform],
      orderBy: 'payment_date DESC',
    );
    return maps.map((m) => OnlineSalePayment.fromMap(m)).toList();
  }

  Future<int> deleteOnlineSalePayment(int id) async {
    final db = await database;
    return await db.delete('online_sale_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalSalePaymentForPlatform(String platform) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM online_sale_payments WHERE platform = ?',
      [platform],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  Future<double> getTotalSalePaymentForPartner(int partnerId, String platform) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as sum FROM online_sale_payments WHERE partner_id = ? AND platform = ?',
      [partnerId, platform],
    );
    return (result.first['sum'] as double?) ?? 0.0;
  }

  /// Summary per partner for a given platform (for dashboard tabs)
  Future<List<Map<String, dynamic>>> getPartnerSaleSummaryForPlatform(
      String platform) async {
    final partners = await getAllPartners();
    final list = <Map<String, dynamic>>[];
    for (final p in partners) {
      if (p.id == null) continue;
      final total = await getTotalSalePaymentForPartner(p.id!, platform);
      if (total > 0) {
        list.add({'partner': p, 'total': total});
      }
    }
    list.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return list;
  }


  // ---------- CHALLAN CRUD ----------
  Future<int> insertChallan(Challan challan) async {
    final db = await database;
    return await db.transaction((txn) async {
      final challanId = await txn.insert('challans', challan.toMap());
      for (final item in challan.items) {
        final itemMap = item.toMap();
        itemMap['challan_id'] = challanId;
        await txn.insert('challan_items', itemMap);
      }
      return challanId;
    });
  }

  Future<List<Challan>> getAllChallans({String? query}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;
    if (query != null && query.trim().isNotEmpty) {
      whereClause = 'party_name LIKE ? OR bill_no LIKE ?';
      whereArgs = ['%${query.trim()}%', '%${query.trim()}%'];
    }
    final maps = await db.query(
      'challans',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    List<Challan> result = [];
    for (final map in maps) {
      final challanId = map['id'] as int;
      final itemMaps = await db.query(
        'challan_items',
        where: 'challan_id = ?',
        whereArgs: [challanId],
        orderBy: 'id ASC',
      );
      final items = itemMaps.map((m) => ChallanItem.fromMap(m)).toList();
      result.add(Challan.fromMap(map, items: items));
    }
    return result;
  }

  Future<Challan?> getChallanById(int id) async {
    final db = await database;
    final maps = await db.query('challans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final itemMaps = await db.query(
      'challan_items',
      where: 'challan_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final items = itemMaps.map((m) => ChallanItem.fromMap(m)).toList();
    return Challan.fromMap(maps.first, items: items);
  }

  Future<void> updateChallan(Challan challan) async {
    if (challan.id == null) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'challans',
        challan.toMap(),
        where: 'id = ?',
        whereArgs: [challan.id],
      );
      await txn.delete('challan_items', where: 'challan_id = ?', whereArgs: [challan.id]);
      for (final item in challan.items) {
        final itemMap = item.toMap();
        itemMap['challan_id'] = challan.id;
        await txn.insert('challan_items', itemMap);
      }
    });
  }

  Future<int> deleteChallan(int id) async {
    final db = await database;
    return await db.delete('challans', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getNextBillNo() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM challans');
    final maxId = (result.first['max_id'] as int?) ?? 0;
    return '${maxId + 1}';
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:flutter_application_1/pages/loading/models/platform_master.dart';
import 'package:flutter_application_1/pages/loading/models/railway_al.dart';
import 'package:flutter_application_1/pages/loading/models/summarydetails.dart';
import 'package:flutter_application_1/pages/loading/models/wag_type.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_condn.dart';
import 'package:flutter_application_1/pages/loading/models/pkg_desc.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('parcel_app.db');
    return _database!;
  }

  /// Absolute path of the open database file (for debugging / verification).
  Future<String> get dbFilePath async {
    final db = await instance.database;
    return db.path;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // v3: re-syncs the schema on existing installs (CREATE IF NOT EXISTS)
      // so tables like M_PLATFORM are (re)created via onUpgrade.
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _migrate(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      station_code TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      station_code TEXT NOT NULL,
      type TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "ACTUALLOAD" (
      "ACT_LOADNO" TEXT NOT NULL,
      "GUARD_MOB_NO" NUMERIC DEFAULT 0,
      "LOAD_DT" INTEGER,
      "TRAIN_NO" TEXT,
      "LOAD_UNLOAD_FLAG" TEXT,
      "ACTUAL_FINALISE_FLAG" TEXT,
      "UPLOAD" NUMERIC DEFAULT 0,
      "USERID" TEXT,
      "SHIFT" TEXT,
      "CNTR" TEXT,
      "STNCODE" TEXT,
      "ZONE" NUMERIC,
      "REMOTEADDR" TEXT,
      "REMOTEHOST" TEXT,
      "TAC" TEXT,
      "RPF" TEXT,
      "GRC" TEXT,
      "AREATYPE" TEXT,
      "AREANO" NUMERIC,
      "VCLTYPE" TEXT,
      "VEHICLE_NO" TEXT,
      "SCHLD_DT" INTEGER,
      "PROP_LOADNO" TEXT,
      "SYSTEM_DT" NUMERIC NOT NULL,
      "GUARD_FLAG" NUMERIC,
      "SEAL_TO" TEXT,
      "GUARD" TEXT,
      "GUARD_HQTR" TEXT,
      "LOADED_WT" NUMERIC DEFAULT 0,
      "LOCKED" TEXT,
      "SYNC_TRY" NUMERIC DEFAULT 0,
      "LAST_SYNC_TIME" NUMERIC,
      "WAGON_TYPE" TEXT,
      "WAGON_OWNRLY" TEXT,
      "REMARKS" TEXT,
      "DEVICE" TEXT,
      "VEHICLE_CC" NUMERIC,
      "AVAILABLE_SPACE" NUMERIC,
      "NIL_LOAD_FLG" NUMERIC,
      "NIL_LOAD_REASON" TEXT,
      "INVALID" NUMERIC DEFAULT 0,
      "UPLOAD_ERROR" TEXT,
      "IMEI_NO" TEXT DEFAULT 0,
      "IMSI_NO" TEXT DEFAULT 0,
      PRIMARY KEY("ACT_LOADNO")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "scanData" (
      "prr" INTEGER,
      "pkt_wt" INTEGER,
      "pkt_D_wt" INTEGER,
      "tbk_pkt" INTEGER,
      "item_no" INTEGER,
      "dest" TEXT,
      "src" TEXT,
      "tbk_wt" INTEGER,
      "bk_type" TEXT,
      PRIMARY KEY("prr","item_no")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "loading" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "jDate" INTEGER,
      "vechType" TEXT,
      "trainNo" INTEGER,
      "guidance" TEXT,
      "aDate" INTEGER,
      "loading_num" TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "loading_dtl" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "pfno" INTEGER,
      "insideLock" TEXT,
      "rejectWagon" TEXT,
      "coachTypeUser" TEXT,
      "ownrlyUser" TEXT,
      "coachnoUser" INTEGER,
      "rpf" TEXT,
      "remark" TEXT,
      "guardCharge" TEXT,
      "guardName" TEXT,
      "sealed" TEXT,
      "sealToStn" TEXT,
      "nil_ld_uld" TEXT,
      "changeSLR" TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "addPrrPwb" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "item_type" TEXT,
      "bk_type" TEXT,
      "prrNo" INTEGER,
      "srcStn" TEXT,
      "desStn" TEXT,
      "bkDate" INTEGER,
      "bkd_pkg" INTEGER,
      "ld_pkg" INTEGER,
      "bkd_wt" INTEGER,
      "ld_wt" INTEGER,
      "pkg_condn" TEXT,
      "pkg_desc" TEXT,
      "remarks" TEXT,
      "rackNo" INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "saveManualData" (
      "item_type" TEXT,
      "bk_type" TEXT,
      "prrNo" INTEGER,
      "srcStn" TEXT,
      "desStn" TEXT,
      "bkDate" INTEGER,
      "bkd_pkg" INTEGER,
      "ld_pkg" INTEGER,
      "bkd_wt" INTEGER,
      "ld_wt" INTEGER,
      "pkg_condn" TEXT,
      "pkg_desc" TEXT,
      "remarks" TEXT,
      "rackNo" INTEGER,
      PRIMARY KEY("prrNo")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "ACT_LOADTLS_FALLBACK" (
      "ACT_LOADNO" TEXT NOT NULL,
      "PWBLTNO" INTEGER NOT NULL,
      "CONSIGNOR_MOBILE_NO" INTEGER NOT NULL,
      "CONSIGNEE_MOBILE_NO" INTEGER NOT NULL,
      "MAJCOMMD" TEXT NOT NULL DEFAULT 0,
      "TOTCHRG" INTEGER NOT NULL DEFAULT 0,
      "NOOFITEMSLOADED" INTEGER,
      "PKGCND" TEXT,
      "LOAD_DT" NUMERIC,
      "CNTR" NUMERIC,
      "STNCODE" TEXT,
      "ZONE" NUMERIC,
      "REMOTEADDR" TEXT,
      "REMOTEHOST" TEXT,
      "BKTYPE" TEXT,
      "WEIGHT" NUMERIC DEFAULT 0,
      "STNFROM" TEXT,
      "DSTNSTN" TEXT,
      "BOOK_DT" NUMERIC,
      "BKDPACKAGE" NUMERIC,
      "TEMPPWBNO" TEXT,
      "PKGTYPE" TEXT,
      "SCHLD_DT" NUMERIC,
      "VEHICLE_NO" TEXT,
      "ITEMNOS" TEXT,
      "LOST_ITEMNO" TEXT,
      "BKWT" NUMERIC,
      "LDWT" NUMERIC,
      "REMARKS" TEXT,
      "MEMO_NIL_NO" TEXT,
      "SERIAL_NO" NUMERIC NOT NULL DEFAULT 0,
      "SYSTEM_DT" NUMERIC,
      "DESTNSTNCBA" TEXT,
      "SCH_DATETIME_ZERO_TIME" NUMERIC,
      "PKG_DESC" NUMERIC,
      "RACKNO" TEXT,
      "NOOFITEMSLD_REQ" NUMERIC,
      "SCANALL" NUMERIC DEFAULT 0,
      "COMMO" TEXT,
      "PKG_DESC_ITEMS" TEXT,
      "SCALE" TEXT,
      "LDCHRGWT" TEXT,
      "TOTCHRGWT" TEXT,
      "NOP_SCANNED" NUMERIC,
      PRIMARY KEY("PWBLTNO","ACT_LOADNO")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "OFFLINE_SUMMARY_DTLS" (
      "VCLTYPE" TEXT,
      "SCHLD_DT" NUMERIC,
      "TRAIN_NO" NUMERIC,
      "STNCODE" TEXT,
      "ID" NUMERIC,
      "PRR" TEXT,
      "SRC" TEXT,
      "DES" TEXT,
      "PKG" TEXT,
      "WGHT" TEXT,
      "BT" TEXT,
      "PKGTYPE" TEXT,
      "BKDT" TEXT,
      "CONDITION" TEXT,
      "DESCR" TEXT,
      "REMARKS" TEXT,
      "BKD" NUMERIC,
      "PKGS" NUMERIC,
      "POTENTIAL" NUMERIC,
      "MAXLOAD" NUMERIC,
      "BKWT" NUMERIC,
      "WT" NUMERIC,
      "ITEMNOS" TEXT,
      "PWBNO" TEXT,
      "RACKNO" TEXT,
      "DCMLWT" TEXT,
      "SCANALL" NUMERIC DEFAULT 0,
      "COMMO" TEXT,
      "PKG_DESC_ITEMS" TEXT,
      "MINITEMNO" NUMERIC,
      "MAXITEMNO" NUMERIC,
      "SEQUENCE_FLG" NUMERIC,
      "SCALE" TEXT,
      "CHRGWT" NUMERIC,
      "TOTCHRGWT" NUMERIC
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_STN" (
      "CODE" TEXT NOT NULL,
      "DETAIL" TEXT,
      "CRIS_STNNO" NUMERIC,
      "ZONE" NUMERIC,
      "SYSTEM_DT" NUMERIC
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_TRAIN" (
      "TRAIN_NO" NUMERIC NOT NULL,
      "TRAIN_NAME" TEXT,
      "TRAIN_TYPE" TEXT NOT NULL,
      "TRAIN_DIRECTION" TEXT,
      "OTHER_DESC" TEXT,
      "USER_NAME" TEXT,
      "USER_DATETIME" NUMERIC,
      "PARCEL_BKNG_ALLWD" NUMERIC,
      "LUGG_BKNG_ALLWD" NUMERIC,
      "TRAIN_GAUGE" TEXT NOT NULL,
      "OWNNG_RLY" TEXT,
      "MON_FLAG" NUMERIC,
      "TUE_FLAG" NUMERIC,
      "WED_FLAG" NUMERIC,
      "THU_FLAG" NUMERIC,
      "FRI_FLAG" NUMERIC,
      "SAT_FLAG" NUMERIC,
      "SUN_FLAG" NUMERIC,
      "USERID" INTEGER,
      "STNCODE" TEXT,
      "SYSTEM_DT" NUMERIC,
      "SCALECODE" TEXT,
      "VALIDITY" NUMERIC,
      "LTSCALECODE" TEXT NOT NULL,
      "TRAIN_VER" NUMERIC,
      "REMOTEHOST" TEXT,
      "USERLEVEL" NUMERIC,
      "OLD_TRAIN_NO" NUMERIC,
      "OLD_TRAIN_VER" NUMERIC,
      "VALID_FROM" NUMERIC,
      "VALID_TO" NUMERIC,
      "TRANSIT_STN_1" TEXT,
      "LINKED_TRNNO_1" TEXT,
      "TRANSIT_STN_2" TEXT,
      "LINKED_TRNNO_2" TEXT,
      "TRANSIT_STN_3" TEXT,
      "LINKED_TRNNO_3" TEXT,
      "TRANSIT_STN_4" TEXT,
      "LINKED_TRNNO_4" TEXT,
      "TRANSIT_STN_5" TEXT,
      "LINKED_TRNNO_5" TEXT,
      "TRANSIT_STN_6" TEXT,
      "LINKED_TRNNO_6" TEXT,
      "TRANSIT_STN_7" TEXT,
      "LINKED_TRNNO_7" TEXT,
      "TRANSIT_STN_8" TEXT,
      "LINKED_TRNNO_8" TEXT,
      "TRANSIT_STN_9" TEXT,
      "LINKED_TRNNO_9" TEXT,
      "ID_TRAIN_DEF" NUMERIC,
      "RAJDHANI_FLG" NUMERIC DEFAULT 0,
      "SHATABDI_FLG" NUMERIC DEFAULT 0,
      "DURANTO_FLG" NUMERIC DEFAULT 0,
      "FCFSLRSTATUS" NUMERIC,
      "RCFSLRSTATUS" TEXT,
      "FCMSLRSTATUS" TEXT,
      "RCMSLRSTATUS" TEXT,
      "FCRSLRSTATUS" TEXT,
      "RCRSLRSTATUS" TEXT,
      "AGCSTATUS" TEXT,
      "VP1STATUS" TEXT,
      "VP2STATUS" TEXT,
      "VIA_ROUTE" TEXT,
      "PM_RLY" TEXT,
      "MAX_LOAD" NUMERIC,
      "CURRENT_LOAD" NUMERIC,
      "FCFSLRSRCSTN" TEXT,
      "FCFSLRDSTNSTN" TEXT,
      "FCFSLRREVL" NUMERIC,
      "FCFSLRWAGTYPE" TEXT,
      "FCFSLRREMARK" TEXT,
      "FCMSLRSRCSTN" TEXT,
      "FCMSLRDSTNSTN" TEXT,
      "FCMSLRREVL" NUMERIC,
      "FCMSLRWAGTYPE" TEXT,
      "FCMSLRREMARK" TEXT,
      "FCRSLRSRCSTN" TEXT,
      "FCRSLRDSTNSTN" TEXT,
      "FCRSLRREVL" NUMERIC,
      "FCRSLRWAGTYPE" TEXT,
      "FCRSLRREMARK" TEXT,
      "RCFSLRSRCSTN" TEXT,
      "RCFSLRDSTNSTN" TEXT,
      "RCFSLRREVL" NUMERIC,
      "RCFSLRWAGTYPE" TEXT,
      "RCFSLRREMARK" TEXT,
      "RCMSLRSRCSTN" TEXT,
      "RCMSLRDSTNSTN" TEXT,
      "RCMSLRREVL" NUMERIC,
      "RCMSLRWAGTYPE" TEXT,
      "RCMSLRREMARK" TEXT,
      "RCRSLRSRCSTN" TEXT,
      "RCRSLRDSTNSTN" TEXT,
      "RCRSLRREVL" NUMERIC,
      "RCRSLRWAGTYPE" TEXT,
      "RCRSLRREMARK" TEXT,
      "AGCSRCSTN" TEXT,
      "AGCDSTNSTN" TEXT,
      "AGCREVL" NUMERIC,
      "AGCWAGTYPE" TEXT,
      "AGCREMARK" TEXT,
      "VP1SRCSTN" TEXT,
      "VP1DSTNSTN" TEXT,
      "VP1REMARK" TEXT,
      "VP2SRCSTN" TEXT,
      "VP2DSTNSTN" TEXT,
      "VP2REMARK" TEXT,
      "FCFSLRCAP" NUMERIC,
      "FCMSLRCAP" NUMERIC,
      "FCRSLRCAP" NUMERIC,
      "RCFSLRCAP" NUMERIC,
      "RCMSLRCAP" NUMERIC,
      "RCRSLRCAP" NUMERIC,
      "AGCCAP" NUMERIC,
      "VP1CAP" NUMERIC,
      "VP2CAP" NUMERIC,
      "PREMIUM_FLG" NUMERIC DEFAULT 0,
      "FSLRTYPE" TEXT,
      "MSLRTYPE" TEXT,
      "RSLRTYPE" TEXT,
      PRIMARY KEY("TRAIN_NO")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_TRNDTLS" (
      "TRNNO" TEXT NOT NULL,
      "STNCODE" TEXT NOT NULL,
      "DISTANCE" TEXT NOT NULL,
      "DAYCOUNT" NUMERIC NOT NULL,
      "FSLRQUOTA" NUMERIC DEFAULT 0,
      "RSLRQUOTA" NUMERIC DEFAULT 0,
      "VP1QUOTA" NUMERIC DEFAULT 0,
      "VP2QUOTA" NUMERIC DEFAULT 0,
      "OWNNG_RLY" TEXT,
      "ZONE" NUMERIC,
      "TRNROUTE" TEXT,
      "ARRTIME" NUMERIC NOT NULL,
      "DEPTIME" NUMERIC NOT NULL,
      "USERID" TEXT,
      "SYSTEM_DT" NUMERIC,
      "STN_CD" TEXT,
      "ARRTIME_TS" NUMERIC,
      "DEPTIME_TS" NUMERIC,
      "VALID" NUMERIC NOT NULL,
      "TRAIN_VER" NUMERIC NOT NULL DEFAULT 1,
      "USERLEVEL" NUMERIC,
      PRIMARY KEY("TRNNO","STNCODE")
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_USERID" (
      "USERID" TEXT NOT NULL,
      "PASSWORD" TEXT,
      "INVALID" NUMERIC,
      "STNCODE" TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_RLY" (
      "ZONE" TEXT NOT NULL,
      "CODE" TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_PLATFORM" (
      "CODE" NUMERIC NOT NULL,
      "DETAIL" TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_WAGTYPE" (
      "TYPE" TEXT NOT NULL,
      "GUAGE" TEXT NOT NULL,
      "DETAIL" TEXT NOT NULL,
      "SHORTDET" TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_PKG_DESC" (
      "SL_NO" TEXT NOT NULL,
      "PKG_DESC" TEXT NOT NULL,
      "USERID" TEXT NOT NULL,
      "STNCODE" TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS "M_PKGCONDN" (
      "CODE" TEXT NOT NULL,
      "DETAIL" TEXT NOT NULL
    )
    ''');
  }

  Future _createDB(Database db, int version) async {
    await _migrate(db);

    await db.insert('users', {
      'username': 'CRISPMS',
      'password': 'cris123',
      'station_code': 'NDLS',
    });

    await db.insert('users', {
      'username': 'Ashish',
      'password': 'cris678',
      'station_code': 'DELB',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _migrate(db);
  }

  Future<int> insertUser(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    return await db.insert('users', {
      'username': username,
      'password': password,
      'station_code': station,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    return await db.update(
      'users',
      {'password': password, 'station_code': station},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> deleteUser(String username) async {
    final db = await instance.database;

    return await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<bool> checkLogin(
    String username,
    String password,
    String station,
  ) async {
    final db = await instance.database;

    var result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND station_code = ?',
      whereArgs: [username, password, station],
    );

    return result.isNotEmpty;
  }

  Future<void> savePlatformMasters(List<PlatformMaster> items) async {
    final db = await instance.database;

    await db.delete('"M_PLATFORM"');
    for (final p in items) {
      await db.insert('"M_PLATFORM"', {'CODE': p.code, 'DETAIL': p.detail});
    }
  }

  Future<List<PlatformMaster>> getPlatformMasters() async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      'SELECT "CODE", "DETAIL" FROM "M_PLATFORM" ORDER BY "CODE" ASC',
    );

    return rows.map(PlatformMaster.fromMap).toList();
  }

  Future<void> savePkgCondns(List<PkgCondn> items) async {
    final db = await instance.database;

    await db.delete('"M_PKGCONDN"');
    for (final p in items) {
      if (p.code.trim().isEmpty) continue;
      await db.insert('"M_PKGCONDN"', {'CODE': p.code, 'DETAIL': p.detail});
    }
  }

  Future<List<PkgCondn>> getPkgCondns() async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      'SELECT "CODE", "DETAIL" FROM "M_PKGCONDN" ORDER BY "CODE" ASC',
    );

    return rows.map(PkgCondn.fromMap).toList();
  }

  Future<void> savePkgDescs(List<PkgDesc> items) async {
    final db = await instance.database;

    await db.delete('"M_PKG_DESC"');
    for (final p in items) {
      if (p.pkgDesc.trim().isEmpty) continue;
      await db.insert('"M_PKG_DESC"', {
        'SL_NO': p.slNo,
        'PKG_DESC': p.pkgDesc,
        'USERID': p.userid,
        'STNCODE': p.stncode,
      });
    }
  }

  Future<List<PkgDesc>> getPkgDescs() async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      'SELECT "SL_NO", "PKG_DESC" FROM "M_PKG_DESC" ORDER BY "SL_NO" ASC',
    );

    return rows.map(PkgDesc.fromMap).toList();
  }

  // ---- M_RLY (Own Railway master, synced from getRailwayAL) ----
  Future<void> saveRailwayALs(List<RailwayAL> items) async {
    final db = await instance.database;

    await db.delete('"M_RLY"');
    for (final r in items) {
      if (r.code.trim().isEmpty) continue;
      await db.insert('"M_RLY"', {'ZONE': r.zone, 'CODE': r.code});
    }
  }

  Future<List<RailwayAL>> getRailwayALs() async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      'SELECT "ZONE", "CODE" FROM "M_RLY" ORDER BY "CODE" ASC',
    );

    return rows.map(RailwayAL.fromMap).toList();
  }

  // ---- M_WAGTYPE (Coach Type master, synced from getWagTypeAL) ----
  Future<void> saveWagTypes(List<WagType> items) async {
    final db = await instance.database;

    await db.delete('"M_WAGTYPE"');
    for (final w in items) {
      if (w.type.trim().isEmpty) continue;
      await db.insert('"M_WAGTYPE"', {
        'TYPE': w.type,
        'GUAGE': w.guage,
        'DETAIL': w.detail,
        'SHORTDET': w.shortdet,
      });
    }
  }

  Future<List<WagType>> getWagTypes() async {
    final db = await instance.database;

    final rows = await db.rawQuery(
      'SELECT "TYPE", "GUAGE", "DETAIL", "SHORTDET" FROM "M_WAGTYPE" ORDER BY "TYPE" ASC',
    );

    return rows.map(WagType.fromMap).toList();
  }

  // ---- M_TRAIN (1 row per train, from getTrndtls top-level) ----
  Future<void> saveTrainMaster(Map<String, Object?> values) async {
    final db = await instance.database;
    final trainNo = values['TRAIN_NO']?.toString() ?? "";
    if (trainNo.isEmpty) return;

    await db.delete('"M_TRAIN"', where: '"TRAIN_NO" = ?', whereArgs: [trainNo]);
    await db.insert('"M_TRAIN"', values);
  }

  // ---- M_TRNDTLS (one row per station stop, from getTrndtls trnstpg[]) ----
  Future<void> saveTrnStops(String trainNo, List<TrainStop> stops) async {
    final db = await instance.database;
    if (trainNo.isEmpty || stops.isEmpty) return;

    await db.delete('"M_TRNDTLS"', where: '"TRNNO" = ?', whereArgs: [trainNo]);

    final batch = db.batch();
    for (final s in stops) {
      final stnCode = (s.stnCode ?? "").trim();
      if (stnCode.isEmpty) continue;

      batch.insert('"M_TRNDTLS"', {
        'TRNNO': trainNo,
        'STNCODE': stnCode,
        'STN_CD': s.stnDiv,
        'DISTANCE': (s.distance ?? "0").trim(),
        'DAYCOUNT': int.tryParse(s.dayCnt ?? '') ?? 0,
        'ARRTIME': int.tryParse(s.arrTime ?? '') ?? 0,
        'DEPTIME': int.tryParse(s.depTime ?? '') ?? 0,
        'ARRTIME_TS': int.tryParse(s.arrTimeTS ?? '') ?? 0,
        'DEPTIME_TS': int.tryParse(s.depTimeTS ?? '') ?? 0,
        'FSLRQUOTA': num.tryParse(s.fslrquota ?? '') ?? 0,
        'RSLRQUOTA': num.tryParse(s.rslrquota ?? '') ?? 0,
        'VP1QUOTA': num.tryParse(s.vp1Quota ?? '') ?? 0,
        'VP2QUOTA': num.tryParse(s.vp2Quota ?? '') ?? 0,
        'OWNNG_RLY': s.owningRly,
        'ZONE': num.tryParse(s.zone ?? '') ?? 0,
        'TRNROUTE': s.route,
        'SYSTEM_DT': num.tryParse(s.systemDt ?? '') ?? 0,
        'VALID': int.tryParse(s.valid ?? '') ?? 1,
        'TRAIN_VER': int.tryParse(s.trainVer ?? '') ?? 1,
        'USERID': s.usrVo?.userid,
      });
    }
    await batch.commit(noResult: true);
  }

  // ---- M_TRNDTLS READ: route stops for a train (seal-to-station etc.) ----
  Future<List<Map<String, Object?>>> getTrnStops(String trainNo) async {
    final db = await instance.database;
    return db.rawQuery(
      'SELECT "TRNNO", "STNCODE", "STN_CD", "DISTANCE", "DAYCOUNT", '
      '"ARRTIME", "DEPTIME", "OWNNG_RLY" FROM "M_TRNDTLS" '
      'WHERE "TRNNO" = ? ORDER BY "DAYCOUNT" ASC, "ARRTIME" ASC',
      [trainNo],
    );
  }

  // ---- ACT_LOADTLS_FALLBACK: PWB/PRR rows found by searchPwbLoad ----
  Future<void> insertActLoadTlsFallback(Map<String, Object?> values) async {
    final db = await instance.database;
    await db.insert(
      '"ACT_LOADTLS_FALLBACK"',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing ACT_LOADTLS_FALLBACK row (located by its original
  /// primary key PWBLTNO + ACT_LOADNO) with the given column values.
  /// Used by the Scan Data screen's row editor ("UPDATE" button).
  Future<int> updateActLoadTlsFallbackRow({
    required int origPwbltno,
    required String actLoadNo,
    required Map<String, Object?> values,
  }) async {
    final db = await instance.database;
    return db.update(
      '"ACT_LOADTLS_FALLBACK"',
      values,
      where: '"ACT_LOADNO" = ? AND "PWBLTNO" = ?',
      whereArgs: [actLoadNo, origPwbltno],
    );
  }

  /// Deletes one ACT_LOADTLS_FALLBACK row by its primary key
  /// (PWBLTNO + ACT_LOADNO). Used by the Scan Data screen's delete action.
  Future<int> deleteActLoadTlsFallback({
    required String actLoadNo,
    required int pwbltno,
  }) async {
    final db = await instance.database;
    return db.delete(
      '"ACT_LOADTLS_FALLBACK"',
      where: '"ACT_LOADNO" = ? AND "PWBLTNO" = ?',
      whereArgs: [actLoadNo, pwbltno],
    );
  }

  /// Reads one saved ACT_LOADTLS_FALLBACK row back by its primary key
  /// (PWBLTNO + ACT_LOADNO) so the form can be autofilled from local DB.
  Future<Map<String, Object?>?> getActLoadTlsFallback({
    required String actLoadNo,
    required int pwbltno,
  }) async {
    final db = await instance.database;
    final rows = await db.query(
      '"ACT_LOADTLS_FALLBACK"',
      where: '"ACT_LOADNO" = ? AND "PWBLTNO" = ?',
      whereArgs: [actLoadNo, pwbltno],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Reads the most recently saved ACT_LOADTLS_FALLBACK row for a PWBLTNO
  /// (regardless of ACT_LOADNO), used as a local fallback when the server
  /// search returns an empty record list.
  Future<Map<String, Object?>?> getLatestSavedPwb(int pwbltno) async {
    final db = await instance.database;
    final rows = await db.query(
      '"ACT_LOADTLS_FALLBACK"',
      where: '"PWBLTNO" = ?',
      whereArgs: [pwbltno],
      orderBy: '"SYSTEM_DT" DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Reads every saved ACT_LOADTLS_FALLBACK row for one loading number
  /// (ACT_LOADNO). Mentor: after saving all RRs locally, fetch the data back
  /// from the DB using this loading number.
  Future<List<Map<String, Object?>>> getRowsByActLoadNo(String actLoadNo) async {
    final db = await instance.database;
    return db.query(
      '"ACT_LOADTLS_FALLBACK"',
      where: '"ACT_LOADNO" = ?',
      whereArgs: [actLoadNo],
      orderBy: '"SYSTEM_DT" DESC',
    );
  }

  /// Reads every saved ACT_LOADTLS_FALLBACK row (newest first).
  /// Used by the Scan Data screen to show all locally saved PWB/PRR entries.
  Future<List<Map<String, Object?>>> getActLoadTlsFallbackRows() async {
    final db = await instance.database;
    return db.query(
      '"ACT_LOADTLS_FALLBACK"',
      orderBy: '"SYSTEM_DT" DESC',
    );
  }
}
